import { Response } from 'express';
import { AICompanionService } from './ai_companion.service.js';
import { MemoryEngineService } from './memory_engine.service.js';
import { TrainingService } from './training_service.js';
import { GalleryService } from './gallery_service.js';
import { ProactiveService } from './proactive_service.js';
import { TTSService } from './tts_service.js';
import { prisma } from '../../prisma.js';
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

  // ----------------------------------------------------
  // In-App Photo Gallery
  // ----------------------------------------------------
  static async getGallery(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const photos = await GalleryService.getGallery(userId);
      res.status(200).json({ success: true, count: photos.length, photos });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not fetch photo gallery' });
    }
  }

  // ----------------------------------------------------
  // Proactive Companion Check-In
  // ----------------------------------------------------
  static async proactiveCheck(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const result = await ProactiveService.checkAndTriggerProactiveMessage(userId);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Proactive check failed' });
    }
  }

  // ----------------------------------------------------
  // Neural Text-to-Speech (TTS)
  // ----------------------------------------------------
  static async tts(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const text = (req.query.text as string) || (req.body.text as string);
      const gender = (req.query.gender as string) || (req.body.gender as string) || 'female';
      if (!text || text.trim().length === 0) {
        res.status(400).json({ error: 'Text query parameter is required' });
        return;
      }
      const audioUrl = await TTSService.synthesizeSpeech(text, gender);
      res.status(200).json({ success: true, audioUrl });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'TTS generation failed' });
    }
  }

  // ----------------------------------------------------
  // Relationship Pulse & Closeness Milestones
  // ----------------------------------------------------
  static async getPulse(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      let pulse = await prisma.aIRelationshipPulse.findUnique({ where: { userId } });
      if (!pulse) {
        pulse = await prisma.aIRelationshipPulse.create({
          data: {
            userId,
            closenessScore: 20,
            currentMood: 'Warm & curious',
            lastEmotionalState: 'Eager to get to know you',
            activeNicknames: 'sweetheart,baby',
          },
        });
      }

      const score = pulse.closenessScore;
      let levelNumber = 1;
      let levelTitle = 'Acquaintance';
      let nextMilestone = 'Close Friend (Level 2 at 30%)';

      if (score >= 80) {
        levelNumber = 4;
        levelTitle = 'Romantic Soulmate';
        nextMilestone = 'Unconditional Bond (100%)';
      } else if (score >= 55) {
        levelNumber = 3;
        levelTitle = 'Soul Confidant';
        nextMilestone = 'Romantic Soulmate (Level 4 at 80%)';
      } else if (score >= 30) {
        levelNumber = 2;
        levelTitle = 'Close Friend';
        nextMilestone = 'Soul Confidant (Level 3 at 55%)';
      }

      res.status(200).json({
        success: true,
        pulse: {
          ...pulse,
          levelNumber,
          levelTitle,
          nextMilestone,
          progressPercentage: score,
        },
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not fetch pulse' });
    }
  }

  // ----------------------------------------------------
  // Custom Memory Management (Add & Edit)
  // ----------------------------------------------------
  static async addMemory(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { category, factKey, factValue } = req.body;
      if (!factKey || !factValue) {
        res.status(400).json({ error: 'factKey and factValue are required' });
        return;
      }
      const memory = await prisma.aIMemory.create({
        data: {
          userId,
          category: category || 'PREFERENCE',
          factKey: factKey.trim(),
          factValue: factValue.trim(),
        },
      });
      res.status(201).json({ success: true, memory });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not add memory' });
    }
  }

  static async updateMemory(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const id = req.params.id as string;
      const { factKey, factValue, category } = req.body;

      const updated = await prisma.aIMemory.updateMany({
        where: { id, userId },
        data: {
          ...(factKey ? { factKey: factKey.trim() } : {}),
          ...(factValue ? { factValue: factValue.trim() } : {}),
          ...(category ? { category: category.trim() } : {}),
        },
      });

      res.status(200).json({ success: true, updatedCount: updated.count });
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not update memory' });
    }
  }
}
