import { prisma } from '../../prisma.js';

export class FriendsService {
  static async searchUsers(query: string, currentUserId: string) {
    const clean = query.trim();
    if (!clean || clean.length < 2) {
      return [];
    }

    const cleanPhone = clean.replace(/[\s-]/g, '');

    const users = await prisma.user.findMany({
      where: {
        AND: [
          { id: { not: currentUserId } },
          {
            OR: [
              { email: { contains: clean } },
              { phoneNumber: { contains: cleanPhone } },
              { displayName: { contains: clean } },
            ],
          },
        ],
      },
      select: {
        id: true,
        displayName: true,
        email: true,
        phoneNumber: true,
        bio: true,
        avatarUrl: true,
      },
      take: 20,
    });

    // Check friendship status for each user
    const results = await Promise.all(
      users.map(async (u) => {
        const existing = await prisma.friendship.findFirst({
          where: {
            OR: [
              { senderId: currentUserId, receiverId: u.id },
              { senderId: u.id, receiverId: currentUserId },
            ],
          },
        });

        // Also check if any messages exist between them
        const hasMessages = await prisma.humanMessage.findFirst({
          where: {
            OR: [
              { senderId: currentUserId, receiverId: u.id },
              { senderId: u.id, receiverId: currentUserId },
            ],
          },
        });

        return {
          ...u,
          isFriend: (existing !== null && existing.status === 'ACCEPTED') || hasMessages !== null,
          hasStartedChat: hasMessages !== null,
          friendshipStatus: existing ? existing.status : hasMessages ? 'ACCEPTED' : 'NONE',
        };
      })
    );

    return results;
  }

  static async addFriend(currentUserId: string, targetFriendId: string) {
    if (currentUserId === targetFriendId) {
      throw new Error('You cannot add yourself as a friend.');
    }

    const targetUser = await prisma.user.findUnique({
      where: { id: targetFriendId },
    });
    if (!targetUser) throw new Error('Target user not found.');

    // Check existing
    const existing = await prisma.friendship.findFirst({
      where: {
        OR: [
          { senderId: currentUserId, receiverId: targetFriendId },
          { senderId: targetFriendId, receiverId: currentUserId },
        ],
      },
    });

    if (existing) {
      if (existing.status === 'ACCEPTED') {
        return { message: 'You are already friends.', friendship: existing };
      }
      const updated = await prisma.friendship.update({
        where: { id: existing.id },
        data: { status: 'ACCEPTED' },
      });
      return { message: 'Friend added successfully.', friendship: updated };
    }

    const friendship = await prisma.friendship.create({
      data: {
        senderId: currentUserId,
        receiverId: targetFriendId,
        status: 'ACCEPTED',
      },
    });

    return { message: 'Friend added successfully.', friendship };
  }

  static async listFriends(currentUserId: string) {
    // Ensure all users who have exchanged messages have an ACCEPTED friendship
    const messagePartners = await prisma.humanMessage.findMany({
      where: {
        OR: [
          { senderId: currentUserId },
          { receiverId: currentUserId },
        ],
      },
      select: { senderId: true, receiverId: true },
      distinct: ['senderId', 'receiverId'],
    });

    for (const mp of messagePartners) {
      const otherId = mp.senderId === currentUserId ? mp.receiverId : mp.senderId;
      const existing = await prisma.friendship.findFirst({
        where: {
          OR: [
            { senderId: currentUserId, receiverId: otherId },
            { senderId: otherId, receiverId: currentUserId },
          ],
        },
      });
      if (!existing) {
        await prisma.friendship.create({
          data: { senderId: currentUserId, receiverId: otherId, status: 'ACCEPTED' },
        }).catch(() => {});
      }
    }

    const friendships = await prisma.friendship.findMany({
      where: {
        status: 'ACCEPTED',
        OR: [
          { senderId: currentUserId },
          { receiverId: currentUserId },
        ],
      },
      include: {
        sender: {
          select: {
            id: true,
            displayName: true,
            email: true,
            phoneNumber: true,
            bio: true,
            avatarUrl: true,
          },
        },
        receiver: {
          select: {
            id: true,
            displayName: true,
            email: true,
            phoneNumber: true,
            bio: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    const friendsList = await Promise.all(
      friendships.map(async (f) => {
        const friend = f.senderId === currentUserId ? f.receiver : f.sender;

        // Fetch last message
        const lastMsg = await prisma.humanMessage.findFirst({
          where: {
            OR: [
              { senderId: currentUserId, receiverId: friend.id },
              { senderId: friend.id, receiverId: currentUserId },
            ],
          },
          orderBy: { createdAt: 'desc' },
        });

        // Fetch unread count
        const unreadCount = await prisma.humanMessage.count({
          where: {
            senderId: friend.id,
            receiverId: currentUserId,
            status: { not: 'READ' },
          },
        });

        return {
          friendshipId: f.id,
          friend,
          lastMessage: lastMsg
            ? {
                id: lastMsg.id,
                content: lastMsg.content,
                createdAt: lastMsg.createdAt.toISOString(),
                isSender: lastMsg.senderId === currentUserId,
                status: lastMsg.status,
              }
            : null,
          unreadCount,
          hasStartedChat: lastMsg !== null,
        };
      })
    );

    // Sort so friends with active chats / latest messages are at the very top (WhatsApp style)
    friendsList.sort((a, b) => {
      if (a.lastMessage && b.lastMessage) {
        return new Date(b.lastMessage.createdAt).getTime() - new Date(a.lastMessage.createdAt).getTime();
      }
      if (a.lastMessage) return -1;
      if (b.lastMessage) return 1;
      return 0;
    });

    return friendsList;
  }
}
