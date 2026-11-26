import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { ENV } from './config/env.js';
import { HumanChatService } from './modules/human_chat/human_chat.service.js';
import { AICompanionService } from './modules/ai_companion/ai_companion.service.js';
import { ProactiveService } from './modules/ai_companion/proactive_service.js';
import { prisma } from './prisma.js';

let ioInstance: Server | null = null;

export function getSocketIO(): Server | null {
  return ioInstance;
}

export function emitToUser(userId: string, event: string, payload: any): void {
  if (ioInstance) {
    ioInstance.to(`user_${userId}`).emit(event, payload);
  }
}

export function setupSocketIO(server: HttpServer) {
  const io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  });

  ioInstance = io;

  // Track online users: userId -> Set of socketIds
  const onlineUsers = new Map<string, Set<string>>();

  // Authentication Middleware
  io.use(async (socket: Socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (!token || typeof token !== 'string') {
        if (ENV.NODE_ENV === 'development' || !ENV.NODE_ENV) {
          const defaultUser = await prisma.user.findFirst({ orderBy: { createdAt: 'desc' } });
          if (defaultUser) {
            socket.data.userId = defaultUser.id;
            return next();
          }
        }
        return next(new Error('Authentication token missing'));
      }

      const decoded = jwt.verify(token, ENV.JWT_SECRET) as { userId: string };
      socket.data.userId = decoded.userId;
      next();
    } catch (err) {
      if (ENV.NODE_ENV === 'development' || !ENV.NODE_ENV) {
        const defaultUser = await prisma.user.findFirst({ orderBy: { createdAt: 'desc' } });
        if (defaultUser) {
          socket.data.userId = defaultUser.id;
          return next();
        }
      }
      next(new Error('Invalid or expired socket token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const userId = socket.data.userId as string;

    // Join personal room
    socket.join(`user_${userId}`);

    // Update online tracking
    if (!onlineUsers.has(userId)) {
      onlineUsers.set(userId, new Set());
      io.emit('user:status', { userId, isOnline: true });
    }
    onlineUsers.get(userId)!.add(socket.id);

    console.log(`[Socket] User connected: ${userId} (${socket.id})`);

    // Handle 1-on-1 Human Message
    socket.on('human:send_message', async (data: { recipientId: string; content: string; clientTempId?: string; mediaUrl?: string }) => {
      try {
        const { recipientId, content, clientTempId, mediaUrl } = data;
        if (!recipientId || (!content && !mediaUrl)) return;

        // Persist message to database
        const message = await HumanChatService.sendMessage(userId, recipientId, content, mediaUrl);

        // Acknowledge to sender with the saved message and clientTempId
        socket.emit('human:message_sent_ack', {
          clientTempId,
          message,
        });

        // Broadcast to recipient if online
        io.to(`user_${recipientId}`).emit('human:new_message', {
          ...message,
          isMe: false,
        });

        // Also emit notification event for top banners
        const senderInfo = await prisma.user.findUnique({
          where: { id: userId },
          select: { id: true, displayName: true, avatarUrl: true },
        });
        io.to(`user_${recipientId}`).emit('notification:new_message', {
          senderId: userId,
          senderName: senderInfo?.displayName || 'Friend',
          senderAvatar: senderInfo?.avatarUrl,
          content: message.content || '📷 Sent a photo',
          timestamp: message.createdAt,
        });

        // If recipient is offline (e.g. testing with demo friend Priya on a single device),
        // simulate a friendly response so the user can verify real-time 1-on-1 human chatting!
        const recipientSockets = onlineUsers.get(recipientId);
        if (!recipientSockets || recipientSockets.size === 0) {
          const recipientUser = await prisma.user.findUnique({ where: { id: recipientId } });
          if (recipientUser && (recipientUser.email === 'priya@example.com' || recipientUser.phoneNumber === '9876543211')) {
            setTimeout(async () => {
              // Typing indicator
              socket.emit('human:typing', { senderId: recipientId, isTyping: true });

              setTimeout(async () => {
                socket.emit('human:typing', { senderId: recipientId, isTyping: false });

                const replies = [
                  "Hey! So good to hear from you! How has your day been? 😊",
                  "I just saw your message on Soulm8! Thanks for reaching out. ✨",
                  "Hey Rohan! Loving this clean private chat. Tell me what's new with you! ❤️",
                  "I was just taking an evening break. So glad we connected here! 🌸",
                ];
                const replyText = replies[Math.floor(Math.random() * replies.length)];
                const autoMsg = await HumanChatService.sendMessage(recipientId, userId, replyText);
                socket.emit('human:new_message', {
                  ...autoMsg,
                  isMe: false,
                });
              }, 1200);
            }, 600);
          }
        }
      } catch (error: any) {
        socket.emit('human:error', { error: error.message || 'Failed to send message' });
      }
    });

    // Handle Typing indicator
    socket.on('human:typing', (data: { recipientId: string; isTyping: boolean }) => {
      io.to(`user_${data.recipientId}`).emit('human:typing', {
        senderId: userId,
        isTyping: data.isTyping,
      });
    });

    // Handle Read receipts
    socket.on('human:mark_read', async (data: { friendId: string }) => {
      try {
        await HumanChatService.markAsRead(userId, data.friendId);
        io.to(`user_${data.friendId}`).emit('human:messages_read', {
          readBy: userId,
        });
      } catch (err) {
        console.error('Mark read error:', err);
      }
    });

    // ----------------------------------------------------
    // AI Companion Real-Time Streaming & Typing Gateway
    // ----------------------------------------------------
    socket.on('ai:send_message', async (data: { content: string; mode?: string; photoUrl?: string }) => {
      try {
        const { content, mode, photoUrl } = data;
        if (!content && !photoUrl) return;

        const profile = await prisma.companionProfile.findUnique({ where: { userId } });
        const companionName = profile?.name || 'Mira';

        // 1. Emit typing indicator immediately
        socket.emit('ai:typing', { isTyping: true, companionName });

        // 2. Process AI chat
        const result = await AICompanionService.chat(userId, content, mode, photoUrl);

        // 3. Emit response
        socket.emit('ai:typing', { isTyping: false, companionName });
        socket.emit('ai:new_message', {
          id: result.messageId,
          isUser: false,
          content: result.reply,
          activeMode: result.activeMode,
          photoUrl: result.photoUrl,
          audioUrl: result.audioUrl,
          createdAt: result.createdAt,
          companionName,
        });
      } catch (err: any) {
        socket.emit('ai:typing', { isTyping: false });
        socket.emit('ai:error', { error: err.message || 'AI message processing failed' });
      }
    });

    socket.on('ai:proactive_check', async () => {
      try {
        await ProactiveService.checkAndTriggerProactiveMessage(userId);
      } catch (_) {}
    });

    // Disconnect
    socket.on('disconnect', () => {
      const userSockets = onlineUsers.get(userId);
      if (userSockets) {
        userSockets.delete(socket.id);
        if (userSockets.size === 0) {
          onlineUsers.delete(userId);
          io.emit('user:status', { userId, isOnline: false });
        }
      }
      console.log(`[Socket] User disconnected: ${userId}`);
    });
  });

  return io;
}
