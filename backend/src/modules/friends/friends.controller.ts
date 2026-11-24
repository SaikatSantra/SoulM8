import { Response } from 'express';
import { FriendsService } from './friends.service.js';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';
import { emitToUser } from '../../socket.js';
import { prisma } from '../../prisma.js';

export class FriendsController {
  static async search(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const query = (req.query.query as string) || '';
      const currentUserId = req.user!.id;
      const users = await FriendsService.searchUsers(query, currentUserId);
      res.status(200).json(users);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Search failed' });
    }
  }

  static async addFriend(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { friendId } = req.body;
      if (!friendId) {
        res.status(400).json({ error: 'friendId is required.' });
        return;
      }
      const currentUserId = req.user!.id;
      const result = await FriendsService.addFriend(currentUserId, friendId);

      // Fetch sender details to send in notification
      const sender = await prisma.user.findUnique({
        where: { id: currentUserId },
        select: { id: true, displayName: true, avatarUrl: true, phoneNumber: true, email: true },
      });

      // Emit real-time notification to the friend
      emitToUser(friendId, 'friend:added', {
        message: `${sender?.displayName || 'Someone'} connected with you on Soulm8!`,
        sender,
        timestamp: new Date().toISOString(),
      });

      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not add friend' });
    }
  }

  static async list(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const currentUserId = req.user!.id;
      const friends = await FriendsService.listFriends(currentUserId);
      res.status(200).json(friends);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not fetch friends' });
    }
  }
}
