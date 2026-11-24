import { prisma } from '../../prisma.js';

export class HumanChatService {
  static async getMessages(currentUserId: string, friendId: string, limit = 50, beforeTimestamp?: number) {
    const whereClause: any = {
      OR: [
        { senderId: currentUserId, receiverId: friendId },
        { senderId: friendId, receiverId: currentUserId },
      ],
    };

    if (beforeTimestamp) {
      whereClause.createdAt = {
        lt: new Date(beforeTimestamp),
      };
    }

    const messages = await prisma.humanMessage.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    // Mark messages sent by friend to current user as READ
    await prisma.humanMessage.updateMany({
      where: {
        senderId: friendId,
        receiverId: currentUserId,
        status: { not: 'READ' },
      },
      data: {
        status: 'READ',
        readAt: new Date(),
      },
    });

    // Return in chronological order
    return messages.reverse().map((m) => ({
      id: m.id,
      senderId: m.senderId,
      receiverId: m.receiverId,
      content: m.content,
      mediaUrl: m.mediaUrl,
      status: m.status,
      createdAt: m.createdAt.toISOString(),
      isMe: m.senderId === currentUserId,
    }));
  }

  static async sendMessage(senderId: string, receiverId: string, content: string, mediaUrl?: string) {
    if (!content.trim() && !mediaUrl) {
      throw new Error('Message content or media is required.');
    }

    // Ensure friendship exists so both users see each other in their friend/chat list
    const existingFriendship = await prisma.friendship.findFirst({
      where: {
        OR: [
          { senderId, receiverId },
          { senderId: receiverId, receiverId: senderId },
        ],
      },
    });

    if (!existingFriendship) {
      await prisma.friendship.create({
        data: {
          senderId,
          receiverId,
          status: 'ACCEPTED',
        },
      });
    }

    const message = await prisma.humanMessage.create({
      data: {
        senderId,
        receiverId,
        content: content.trim(),
        mediaUrl: mediaUrl || null,
        status: 'SENT',
      },
    });

    return {
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      mediaUrl: message.mediaUrl,
      status: message.status,
      createdAt: message.createdAt.toISOString(),
      isMe: true,
    };
  }

  static async markAsRead(currentUserId: string, senderId: string) {
    await prisma.humanMessage.updateMany({
      where: {
        senderId,
        receiverId: currentUserId,
        status: { not: 'READ' },
      },
      data: {
        status: 'READ',
        readAt: new Date(),
      },
    });
    return { success: true };
  }
}
