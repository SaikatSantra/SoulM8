import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding Soulm8 database...');

  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash('password123', salt);

  // 1. Seed User Rohan
  const rohan = await prisma.user.upsert({
    where: { email: 'rohan@example.com' },
    update: {},
    create: {
      email: 'rohan@example.com',
      phoneNumber: '9876543210',
      displayName: 'Rohan Sharma',
      bio: 'Loves evening runs, warm chai, and thoughtful conversations.',
      passwordHash,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
      companionProfile: {
        create: {
          name: 'Soulie',
          gender: 'female',
          currentMode: 'ROMANTIC',
          languageStyle: 'HINGLISH',
        },
      },
      relationshipPulse: {
        create: {
          closenessScore: 35,
          currentMood: 'Playful & affectionate',
          lastEmotionalState: 'Thinking about the upcoming weekend',
        },
      },
    },
  });

  // 2. Seed User Priya
  const priya = await prisma.user.upsert({
    where: { email: 'priya@example.com' },
    update: {},
    create: {
      email: 'priya@example.com',
      phoneNumber: '9876543211',
      displayName: 'Priya Patel',
      bio: 'Artist, bookworm, exploring mindfulness after a long transition.',
      passwordHash,
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
      companionProfile: {
        create: {
          name: 'Soulie',
          gender: 'male',
          currentMode: 'SUPPORTIVE',
          languageStyle: 'HINGLISH',
        },
      },
      relationshipPulse: {
        create: {
          closenessScore: 25,
          currentMood: 'Gentle & listening',
        },
      },
    },
  });

  // 3. Connect as friends
  await prisma.friendship.upsert({
    where: {
      senderId_receiverId: {
        senderId: rohan.id,
        receiverId: priya.id,
      },
    },
    update: {},
    create: {
      senderId: rohan.id,
      receiverId: priya.id,
      status: 'ACCEPTED',
    },
  });

  // 4. Initial sample message
  const msgCount = await prisma.humanMessage.count();
  if (msgCount === 0) {
    await prisma.humanMessage.create({
      data: {
        senderId: priya.id,
        receiverId: rohan.id,
        content: 'Hey Rohan! So glad we connected here on Soulm8. How has your week been?',
        status: 'DELIVERED',
      },
    });
  }

  console.log('✅ Seed completed! Demo accounts:');
  console.log('1. rohan@example.com / 9876543210 (pass: password123)');
  console.log('2. priya@example.com / 9876543211 (pass: password123)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
