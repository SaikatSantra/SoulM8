import http from 'http';
import { app } from './app.js';
import { ENV } from './config/env.js';
import { setupSocketIO } from './socket.js';

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
}

export { app, server };
export default app;
