import { Response } from 'express';
import { HumanChatService } from './human_chat.service.js';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';
import { prisma } from '../../prisma.js';
import { emitToUser } from '../../socket.js';

export class HumanChatController {
  static async getHistory(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const friendId = req.params.friendId as string;
      const limit = parseInt((req.query.limit as string) || '50', 10);
      const before = req.query.before ? parseInt(req.query.before as string, 10) : undefined;
      const currentUserId = req.user!.id;

      const messages = await HumanChatService.getMessages(currentUserId, friendId, limit, before);
      res.status(200).json(messages);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not load messages' });
    }
  }

  static async sendMessage(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { receiverId, content, mediaUrl } = req.body;
      const senderId = req.user!.id;

      const message = await HumanChatService.sendMessage(senderId, receiverId, content, mediaUrl);

      // Fetch sender details
      const sender = await prisma.user.findUnique({
        where: { id: senderId },
        select: { id: true, displayName: true, avatarUrl: true },
      });

      // Emit realtime events to receiver
      emitToUser(receiverId, 'human:new_message', {
        ...message,
        isMe: false,
      });

      emitToUser(receiverId, 'notification:new_message', {
        senderId,
        senderName: sender?.displayName || 'Friend',
        senderAvatar: sender?.avatarUrl,
        content: message.content,
        timestamp: message.createdAt,
      });

      // If sending to demo friend Priya via REST, generate a companion reply so test works even without WebSockets
      const recipientUser = await prisma.user.findUnique({ where: { id: receiverId } });
      if (recipientUser && (recipientUser.email === 'priya@example.com' || recipientUser.phoneNumber === '9876543211')) {
        setTimeout(async () => {
          const replies = [
            "Hey! So good to hear from you! How has your day been? 😊",
            "I just saw your message on Soulm8! Thanks for reaching out. ✨",
            "Loving this clean private chat. Tell me what's new with you! ❤️",
          ];
          const replyText = replies[Math.floor(Math.random() * replies.length)];
          const replyMsg = await HumanChatService.sendMessage(receiverId, senderId, replyText);
          emitToUser(senderId, 'human:new_message', {
            ...replyMsg,
            isMe: false,
          });
        }, 1000);
      }

      res.status(201).json(message);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not send message' });
    }
  }

  static async markRead(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const friendId = req.params.friendId as string;
      const currentUserId = req.user!.id;
      const result = await HumanChatService.markAsRead(currentUserId, friendId);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not mark as read' });
    }
  }
}
