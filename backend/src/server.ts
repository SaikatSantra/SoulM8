import http from 'http';
import { app } from './app.js';
import { ENV } from './config/env.js';
import { setupSocketIO } from './socket.js';
import { prisma } from './prisma.js';
import { ProactiveService } from './modules/ai_companion/proactive_service.js';

const server = http.createServer(app);

// Setup Socket.io Realtime Gateway
setupSocketIO(server);

// Start Server if not in Serverless (Vercel)
if (process.env.VERCEL !== '1') {
  server.listen(ENV.PORT, '0.0.0.0', () => {
    console.log(`✨ Soulm8 Backend running on port ${ENV.PORT} [${ENV.NODE_ENV}]`);
    console.log(`🚀 REST: http://localhost:${ENV.PORT}/api/health (LAN: http://192.168.1.8:${ENV.PORT}/api/health)`);
    console.log(`🔌 WebSocket Gateway ready`);
  });

  // Background Proactive Companion Check (runs every 30 minutes)
  setInterval(async () => {
    try {
      const activeUsers = await prisma.user.findMany({
        take: 20,
        orderBy: { updatedAt: 'desc' },
        select: { id: true },
      });
      for (const u of activeUsers) {
        await ProactiveService.checkAndTriggerProactiveMessage(u.id);
      }
    } catch (err) {
      console.warn('Background proactive check cycle error:', err);
    }
  }, 30 * 60 * 1000);
}

export { app, server };
export default app;
