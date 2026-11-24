import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { ENV } from '../config/env.js';
import { prisma } from '../prisma.js';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email?: string | null;
    phoneNumber?: string | null;
    displayName: string;
    role: string;
  };
}

export const requireAuth = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // In development, gracefully fall back to active user if no token provided
      if (ENV.NODE_ENV === 'development' || !ENV.NODE_ENV) {
        const defaultUser = await prisma.user.findFirst({
          orderBy: { createdAt: 'desc' },
          select: {
            id: true,
            email: true,
            phoneNumber: true,
            displayName: true,
            role: true,
          },
        });
        if (defaultUser) {
          req.user = defaultUser;
          return next();
        }
      }
      res.status(401).json({ error: 'Authentication required. No token provided.' });
      return;
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, ENV.JWT_SECRET) as { userId: string };

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        phoneNumber: true,
        displayName: true,
        role: true,
      },
    });

    if (!user) {
      if (ENV.NODE_ENV === 'development' || !ENV.NODE_ENV) {
        const defaultUser = await prisma.user.findFirst({
          select: {
            id: true,
            email: true,
            phoneNumber: true,
            displayName: true,
            role: true,
          },
        });
        if (defaultUser) {
          req.user = defaultUser;
          return next();
        }
      }
      res.status(401).json({ error: 'User session invalid or expired.' });
      return;
    }

    req.user = user;
    next();
  } catch (error) {
    if (ENV.NODE_ENV === 'development' || !ENV.NODE_ENV) {
      const defaultUser = await prisma.user.findFirst({
        select: {
          id: true,
          email: true,
          phoneNumber: true,
          displayName: true,
          role: true,
        },
      });
      if (defaultUser) {
        req.user = defaultUser;
        return next();
      }
    }
    res.status(401).json({ error: 'Invalid or expired token.' });
  }
};
