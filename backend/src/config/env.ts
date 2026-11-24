import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export const ENV = {
  PORT: parseInt(process.env.PORT || '5000', 10),
  NODE_ENV: process.env.NODE_ENV || 'development',
  DATABASE_URL: process.env.DATABASE_URL || '',
  DATABASE_URL_UNPOOLED: process.env.DATABASE_URL_UNPOOLED || '',
  JWT_SECRET: process.env.JWT_SECRET || 'soulm8_super_secret_jwt_key_2026_emotional_sanctuary',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '30d',
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
  AI_IMAGE_PROVIDER: process.env.AI_IMAGE_PROVIDER || 'mock_or_imagen',
};
