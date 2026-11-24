import { Request, Response } from 'express';
import { AuthService } from './auth.service.js';
import { AuthenticatedRequest } from '../../middlewares/auth.middleware.js';

export class AuthController {
  static async register(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.register(req.body);
      res.status(201).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Registration failed' });
    }
  }

  static async login(req: Request, res: Response): Promise<void> {
    try {
      const result = await AuthService.login(req.body);
      res.status(200).json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Login failed' });
    }
  }

  static async getMe(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      if (!req.user?.id) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      const user = await AuthService.getMe(req.user.id);
      res.status(200).json(user);
    } catch (error: any) {
      res.status(404).json({ error: error.message || 'User not found' });
    }
  }

  static async updateProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      if (!req.user?.id) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      const user = await AuthService.updateProfile(req.user.id, req.body);
      res.status(200).json(user);
    } catch (error: any) {
      res.status(400).json({ error: error.message || 'Could not update profile' });
    }
  }
}
