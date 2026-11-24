import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../prisma.js';
import { ENV } from '../../config/env.js';

export interface RegisterDTO {
  email?: string;
  phoneNumber?: string;
  password: string;
  displayName: string;
  bio?: string;
  companionName?: string;
  companionGender?: string;
}

export interface LoginDTO {
  identifier: string; // email or phone
  password: string;
}

export class AuthService {
  static async register(dto: RegisterDTO) {
    if (!dto.email && !dto.phoneNumber) {
      throw new Error('Please provide either an email or a phone number to register.');
    }
    if (!dto.password || dto.password.length < 6) {
      throw new Error('Password must be at least 6 characters long.');
    }
    if (!dto.displayName || dto.displayName.trim().length === 0) {
      throw new Error('Display name is required.');
    }

    // Check existing
    if (dto.email) {
      const existingEmail = await prisma.user.findUnique({ where: { email: dto.email.toLowerCase().trim() } });
      if (existingEmail) throw new Error('An account with this email already exists.');
    }
    if (dto.phoneNumber) {
      const cleanPhone = dto.phoneNumber.replace(/[\s-]/g, '').trim();
      const existingPhone = await prisma.user.findUnique({ where: { phoneNumber: cleanPhone } });
      if (existingPhone) throw new Error('An account with this phone number already exists.');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const user = await prisma.user.create({
      data: {
        email: dto.email ? dto.email.toLowerCase().trim() : null,
        phoneNumber: dto.phoneNumber ? dto.phoneNumber.replace(/[\s-]/g, '').trim() : null,
        displayName: dto.displayName.trim(),
        bio: dto.bio || 'Finding peace, healing, and connection.',
        passwordHash,
        avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(dto.displayName)}`,
        companionProfile: {
          create: {
            name: dto.companionName || 'Soulie',
            gender: dto.companionGender || 'female',
            currentMode: 'ROMANTIC',
            languageStyle: 'HINGLISH',
          },
        },
        relationshipPulse: {
          create: {
            closenessScore: 15,
            currentMood: 'Warm & curious to meet you',
            lastEmotionalState: 'Welcome to Soulm8! Ready to listen whenever you need.',
            activeNicknames: 'sweetheart,dear,jaan',
          },
        },
      },
      include: {
        companionProfile: true,
        relationshipPulse: true,
      },
    });

    const token = jwt.sign({ userId: user.id }, ENV.JWT_SECRET, { expiresIn: '30d' });

    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        bio: user.bio,
        avatarUrl: user.avatarUrl,
        companion: user.companionProfile,
        pulse: user.relationshipPulse,
      },
    };
  }

  static async login(dto: LoginDTO) {
    const raw = dto.identifier.trim();
    const cleanPhone = raw.replace(/[\s-]/g, '');

    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: raw.toLowerCase() },
          { phoneNumber: cleanPhone },
          { phoneNumber: raw },
        ],
      },
      include: {
        companionProfile: true,
        relationshipPulse: true,
      },
    });

    if (!user) {
      throw new Error('Invalid email/phone or password.');
    }

    const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isMatch) {
      throw new Error('Invalid email/phone or password.');
    }

    const token = jwt.sign({ userId: user.id }, ENV.JWT_SECRET, { expiresIn: '30d' });

    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        bio: user.bio,
        avatarUrl: user.avatarUrl,
        companion: user.companionProfile,
        pulse: user.relationshipPulse,
      },
    };
  }

  static async getMe(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        companionProfile: true,
        relationshipPulse: true,
      },
    });

    if (!user) throw new Error('User not found.');

    return {
      id: user.id,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      bio: user.bio,
      avatarUrl: user.avatarUrl,
      companion: user.companionProfile,
      pulse: user.relationshipPulse,
      createdAt: user.createdAt,
    };
  }

  static async updateProfile(
    userId: string,
    data: { displayName?: string; bio?: string; avatarUrl?: string; phoneNumber?: string }
  ) {
    const updateData: any = {};
    if (data.displayName && data.displayName.trim()) {
      updateData.displayName = data.displayName.trim();
    }
    if (data.bio !== undefined) {
      updateData.bio = data.bio.trim();
    }
    if (data.avatarUrl !== undefined) {
      updateData.avatarUrl = data.avatarUrl.trim();
    }
    if (data.phoneNumber !== undefined) {
      const clean = data.phoneNumber.replace(/[\s-]/g, '').trim();
      updateData.phoneNumber = clean.length > 0 ? clean : null;
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: updateData,
      include: {
        companionProfile: true,
        relationshipPulse: true,
      },
    });

    return {
      id: updated.id,
      email: updated.email,
      phoneNumber: updated.phoneNumber,
      displayName: updated.displayName,
      bio: updated.bio,
      avatarUrl: updated.avatarUrl,
      companion: updated.companionProfile,
      pulse: updated.relationshipPulse,
    };
  }
}
