import path from 'path';
import { fileURLToPath } from 'url';
import express from 'express';
import cors from 'cors';
import { ENV } from './config/env.js';
import { requireAuth } from './middlewares/auth.middleware.js';

// Controllers
import { AuthController } from './modules/auth/auth.controller.js';
import { FriendsController } from './modules/friends/friends.controller.js';
import { HumanChatController } from './modules/human_chat/human_chat.controller.js';
import { AICompanionController } from './modules/ai_companion/ai_companion.controller.js';
import { UploadController } from './modules/upload/upload.controller.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Middlewares
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (origin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  } else {
    res.setHeader('Access-Control-Allow-Origin', '*');
  }
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, X-Requested-With, x-user-id');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(cors({
  origin: true,
  credentials: true,
}));
app.options('*', cors());

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

// Media Upload (Photos from Mobile / Avatars)
app.post('/api/upload', UploadController.uploadMedia);

// Health Check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Soulm8 Backend',
    timestamp: new Date().toISOString(),
    env: ENV.NODE_ENV,
  });
});

// ----------------------------------------------------
// 1. Auth Routes
// ----------------------------------------------------
const authRouter = express.Router();
authRouter.post('/register', AuthController.register);
authRouter.post('/login', AuthController.login);
authRouter.get('/me', requireAuth, AuthController.getMe);
authRouter.put('/profile', requireAuth, AuthController.updateProfile);
app.use('/api/auth', authRouter);

// ----------------------------------------------------
// 2. Friends Routes (WhatsApp-style discovery by phone/email)
// ----------------------------------------------------
const friendsRouter = express.Router();
friendsRouter.use(requireAuth);
friendsRouter.get('/search', FriendsController.search);
friendsRouter.post('/add', FriendsController.addFriend);
friendsRouter.get('/list', FriendsController.list);
app.use('/api/friends', friendsRouter);

// ----------------------------------------------------
// 3. Human 1-on-1 Chat Routes
// ----------------------------------------------------
const humanChatRouter = express.Router();
humanChatRouter.use(requireAuth);
humanChatRouter.get('/:friendId', HumanChatController.getHistory);
humanChatRouter.post('/send', HumanChatController.sendMessage);
humanChatRouter.post('/:friendId/read', HumanChatController.markRead);
app.use('/api/human-chat', humanChatRouter);

// ----------------------------------------------------
// 4. AI Companion & Memory Engine Routes
// ----------------------------------------------------
const aiRouter = express.Router();
aiRouter.use(requireAuth);
aiRouter.post('/chat', AICompanionController.chat);
aiRouter.get('/history', AICompanionController.getHistory);
aiRouter.put('/mode', AICompanionController.switchMode);
aiRouter.get('/memories', AICompanionController.getMemories);
aiRouter.post('/learn', AICompanionController.learn);
aiRouter.delete('/memories/:id', AICompanionController.deleteMemory);
aiRouter.post('/memories/purge', AICompanionController.purgeAll);

// Training Examples (Few-Shot Conversation Tuning)
aiRouter.get('/training-examples', AICompanionController.getTrainingExamples);
aiRouter.post('/training-examples', AICompanionController.addTrainingExamples);
aiRouter.delete('/training-examples/:id', AICompanionController.deleteTrainingExample);

// Companion Profile Customization (Name, Gender, Avatar)
aiRouter.get('/companion', AICompanionController.getCompanion);
aiRouter.put('/companion', AICompanionController.updateCompanion);

app.use('/api/ai', aiRouter);

export { app };
export default app;
