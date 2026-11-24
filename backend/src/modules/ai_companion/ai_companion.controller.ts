import { Response } from 'express';
import { AICompanionService } from './ai_companion.service.js';
import { MemoryEngineService } from './memory_engine.service.js';
import { TrainingService } from './training_service.js';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';

export class AICompanionController {
  static async chat(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { message, mode, photoUrl } = req.body;
      const userId = req.user!.id;
      const result = await AICompanionService.chat(userId, message, mode, photoUrl);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'AI Chat failed' });
    }
  }

  static async getCompanion(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const result = await AICompanionService.getCompanionProfile(userId);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not fetch companion profile' });
    }
  }

  static async updateCompanion(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { name, gender, avatarUrl, languageStyle } = req.body;
      const result = await AICompanionService.updateCompanionProfile(userId, {
        name,
        gender,
        avatarUrl,
        languageStyle,
      });
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not update companion profile' });
    }
  }

  static async getHistory(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const limit = parseInt((req.query.limit as string) || '50', 10);
      const history = await AICompanionService.getHistory(userId, limit);
      res.status(200).json(history);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not fetch history' });
    }
  }

  static async switchMode(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { mode } = req.body;
      const userId = req.user!.id;
      const result = await AICompanionService.switchMode(userId, mode);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not switch mode' });
    }
  }

  static async getMemories(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const memories = await MemoryEngineService.getAllUserMemories(userId);
      res.status(200).json(memories);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not fetch memories' });
    }
  }

  static async deleteMemory(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = req.params.id as string;
      const userId = req.user!.id;
      const result = await MemoryEngineService.deleteMemory(userId, id);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not delete memory' });
    }
  }

  static async purgeAll(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const result = await MemoryEngineService.purgeAllData(userId);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not purge memories' });
    }
  }

  static async learn(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { message } = req.body;
      let result;
      if (message && typeof message === 'string' && message.trim().length > 0) {
        result = await MemoryEngineService.learnFromUserMessage(userId, message.trim());
      } else {
        result = await MemoryEngineService.learnFromDatabaseHistory(userId);
      }
      res.status(200).json({ success: true, result });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Learning failed' });
    }
  }

  // ----------------------------------------------------
  // Training Examples API (Few-Shot Conversation Tuning)
  // ----------------------------------------------------
  static async getTrainingExamples(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const examples = TrainingService.getExamples();
      res.status(200).json({ success: true, count: examples.length, examples });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not fetch training examples' });
    }
  }

  static async addTrainingExamples(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const { user, companion, examples, text } = req.body;

      if (user && companion) {
        const added = TrainingService.addExample(user, companion);
        res.status(201).json({ success: true, added, totalCount: TrainingService.getExamples().length });
        return;
      }

      if (Array.isArray(examples)) {
        const result = TrainingService.batchUpload(examples);
        res.status(201).json({ success: true, ...result });
        return;
      }

      if (text && typeof text === 'string') {
        const result = TrainingService.batchUpload(text);
        res.status(201).json({ success: true, ...result });
        return;
      }

      res.status(400).json({ error: 'Please provide user/companion fields, examples array, or text payload' });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not add training examples' });
    }
  }

  static async deleteTrainingExample(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id = String(req.params.id);
      const deleted = TrainingService.deleteExample(id);
      res.status(200).json({ success: deleted });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not delete training example' });
    }
  }
}
