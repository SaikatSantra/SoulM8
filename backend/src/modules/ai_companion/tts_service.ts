import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';
import { LanguageDetector, SupportedLanguage } from './language_detector.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const AUDIO_DIR = path.join(__dirname, '../../../public/audio');

// Ensure audio directory exists
if (!fs.existsSync(AUDIO_DIR)) {
  try {
    fs.mkdirSync(AUDIO_DIR, { recursive: true });
  } catch (_) {}
}

const LANG_CODE_MAP: Record<SupportedLanguage, string> = {
  BENGALI_SCRIPT: 'bn',
  BENGLISH: 'bn',
  HINDI_SCRIPT: 'hi',
  HINGLISH: 'hi',
  ENGLISH: 'en',
  OTHER: 'en',
};

export class TTSService {
  /**
   * Synthesizes natural speech from text into an MP3 file and returns the static URL.
   * Uses MD5 disk caching so identical phrases are immediately served without API calls.
   */
  public static async synthesizeSpeech(
    text: string,
    gender: string = 'female',
    languageHint?: SupportedLanguage
  ): Promise<string | null> {
    if (!text || text.trim().length === 0) return null;

    // Clean text: strip emojis, asterisks, formatting
    const cleanText = text
      .replace(/[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/gu, '')
      .replace(/\*[^*]+\*/g, '')
      .replace(/\[[^\]]+\]/g, '')
      .replace(/[^\p{L}\p{N}\p{P}\s]/gu, '')
      .trim();

    if (cleanText.length < 2) return null;

    const detected = languageHint || LanguageDetector.detect(cleanText);
    const langCode = LANG_CODE_MAP[detected] || 'en';

    // Generate MD5 cache hash
    const hash = crypto.createHash('md5').update(`${langCode}_${cleanText}`).digest('hex');
    const fileName = `${hash}.mp3`;
    const filePath = path.join(AUDIO_DIR, fileName);

    // Return cached audio if already exists and is non-empty
    if (fs.existsSync(filePath) && fs.statSync(filePath).size > 1024) {
      return `/audio/${fileName}`;
    }

    try {
      const audioBuffer = await this.fetchTTSAudio(cleanText, langCode);
      if (audioBuffer && audioBuffer.length > 512) {
        fs.writeFileSync(filePath, audioBuffer);
        return `/audio/${fileName}`;
      }
    } catch (err) {
      console.warn('TTS Synthesis error (non-fatal):', err);
    }

    return null;
  }

  /**
   * Fetches high-quality neural speech MP3 chunks from the TTS service.
   * Automatically splits long sentences into digestible segments under 180 chars.
   */
  private static async fetchTTSAudio(text: string, langCode: string): Promise<Buffer | null> {
    // If short, fetch in single request
    if (text.length <= 180) {
      return this.fetchSingleChunk(text, langCode);
    }

    // Split text into natural sentence or punctuation boundaries
    const sentences = text.match(/[^.!?।\n]+[.!?।\n]*/g) || [text];
    const chunks: string[] = [];
    let current = '';

    for (const s of sentences) {
      if ((current + ' ' + s).trim().length <= 180) {
        current = (current + ' ' + s).trim();
      } else {
        if (current) chunks.push(current);
        current = s.trim();
      }
    }
    if (current) chunks.push(current);

    const buffers: Buffer[] = [];
    for (const chunk of chunks.slice(0, 4)) {
      const buf = await this.fetchSingleChunk(chunk, langCode);
      if (buf) buffers.push(buf);
    }

    if (buffers.length === 0) return null;
    return Buffer.concat(buffers);
  }

  private static async fetchSingleChunk(chunk: string, lang: string): Promise<Buffer | null> {
    try {
      const encoded = encodeURIComponent(chunk);
      const url = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encoded}&tl=${lang}&client=tw-ob`;

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 6000);

      const res = await fetch(url, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
          'Referer': 'https://translate.google.com/',
        },
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (!res.ok) return null;
      const arrayBuf = await res.arrayBuffer();
      return Buffer.from(arrayBuf);
    } catch (_) {
      return null;
    }
  }
}
