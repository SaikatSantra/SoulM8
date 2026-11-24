import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function resolveExamplesFile(): string {
  const candidates = [
    path.join(process.cwd(), 'src/config/training_examples.json'),
    path.join(process.cwd(), 'dist/config/training_examples.json'),
    path.join(__dirname, '../../config/training_examples.json'),
    path.join(__dirname, '../../../src/config/training_examples.json'),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return candidates[0];
}

const EXAMPLES_FILE = resolveExamplesFile();

export interface TrainingExample {
  id: string;
  user: string;
  companion: string;
  createdAt?: string;
}

export class TrainingService {
  static getFilePath(): string {
    const candidates = [
      path.join(process.cwd(), 'src/config/training_examples.json'),
      path.join(process.cwd(), 'dist/config/training_examples.json'),
      path.join(__dirname, '../../config/training_examples.json'),
      path.join(__dirname, '../../../src/config/training_examples.json'),
    ];
    for (const c of candidates) {
      if (fs.existsSync(c)) return c;
    }
    return candidates[0];
  }

  /**
   * Load all saved conversation examples.
   */
  static getExamples(): TrainingExample[] {
    try {
      const file = this.getFilePath();
      if (fs.existsSync(file)) {
        const raw = fs.readFileSync(file, 'utf-8');
        return JSON.parse(raw);
      }
    } catch (err) {
      console.warn('Could not read training examples file:', err);
    }
    return [];
  }

  /**
   * Save examples array to disk.
   */
  private static saveExamples(examples: TrainingExample[]): void {
    try {
      const file = this.getFilePath();
      const dir = path.dirname(file);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(file, JSON.stringify(examples, null, 2), 'utf-8');
    } catch (err) {
      console.error('Could not save training examples:', err);
    }
  }

  /**
   * Add a single conversation example.
   */
  static addExample(userText: string, companionText: string): TrainingExample {
    const examples = this.getExamples();
    const newEx: TrainingExample = {
      id: `train_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
      user: userText.trim(),
      companion: companionText.trim(),
      createdAt: new Date().toISOString(),
    };
    examples.push(newEx);
    this.saveExamples(examples);
    return newEx;
  }

  /**
   * Batch upload multiple conversation examples from structured array or raw text.
   * Supports JSON arrays: [{ "user": "...", "companion": "..." }]
   * or formatted text:
   * User: ...
   * Companion: ...
   */
  static batchUpload(payload: any): { addedCount: number; totalCount: number } {
    const examples = this.getExamples();
    let incoming: Array<{ user: string; companion: string }> = [];

    if (Array.isArray(payload)) {
      incoming = payload.filter((p) => p && p.user && p.companion);
    } else if (typeof payload === 'string') {
      // Parse plain text blocks: User: ... Companion: ...
      const blocks = payload.split(/(?=User:|user:)/g);
      for (const block of blocks) {
        const userMatch = block.match(/user:\s*([\s\S]*?)(?=companion:|ai:|$)/i);
        const compMatch = block.match(/(?:companion|ai):\s*([\s\S]*?)$/i);
        if (userMatch && compMatch) {
          const u = userMatch[1].trim();
          const c = compMatch[1].trim();
          if (u.length > 0 && c.length > 0) {
            incoming.push({ user: u, companion: c });
          }
        }
      }
    }

    let addedCount = 0;
    for (const item of incoming) {
      examples.push({
        id: `train_${Date.now()}_${Math.floor(Math.random() * 10000)}`,
        user: item.user.trim(),
        companion: item.companion.trim(),
        createdAt: new Date().toISOString(),
      });
      addedCount++;
    }

    this.saveExamples(examples);
    return { addedCount, totalCount: examples.length };
  }

  /**
   * Delete an example by ID.
   */
  static deleteExample(id: string): boolean {
    let examples = this.getExamples();
    const initialLen = examples.length;
    examples = examples.filter((e) => e.id !== id);
    if (examples.length !== initialLen) {
      this.saveExamples(examples);
      return true;
    }
    return false;
  }

  /**
   * Format examples into a high-fidelity few-shot prompt section for Gemini.
   */
  static formatExamplesForPrompt(limit = 8): string {
    const examples = this.getExamples().slice(0, limit);
    if (examples.length === 0) return '';

    return examples
      .map(
        (ex, idx) =>
          `[Example ${idx + 1}]\nUser: "${ex.user}"\nCompanion: "${ex.companion}"`
      )
      .join('\n\n');
  }
}
