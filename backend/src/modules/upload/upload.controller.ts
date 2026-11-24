import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const UPLOADS_DIR = path.join(__dirname, '../../../public/uploads');

export class UploadController {
  static async uploadMedia(req: Request, res: Response): Promise<void> {
    try {
      const { image, filename } = req.body;
      if (!image || typeof image !== 'string') {
        res.status(400).json({ error: 'No image data provided' });
        return;
      }

      if (!fs.existsSync(UPLOADS_DIR)) {
        fs.mkdirSync(UPLOADS_DIR, { recursive: true });
      }

      let base64Data = image;
      let extension = 'jpg';

      if (image.includes(';base64,')) {
        const parts = image.split(';base64,');
        const mime = parts[0];
        if (mime.includes('png')) extension = 'png';
        else if (mime.includes('webp')) extension = 'webp';
        else if (mime.includes('mp4')) extension = 'mp4';
        base64Data = parts[1];
      }

      const cleanName = filename
        ? `${Date.now()}_${filename.replace(/[^a-zA-Z0-9._-]/g, '_')}`
        : `upload_${Date.now()}_${Math.floor(Math.random() * 10000)}.${extension}`;

      const filePath = path.join(UPLOADS_DIR, cleanName);
      const buffer = Buffer.from(base64Data, 'base64');
      fs.writeFileSync(filePath, buffer);

      const url = `http://localhost:5000/uploads/${cleanName}`;
      res.status(200).json({ success: true, url, filename: cleanName });
    } catch (error: any) {
      console.error('Upload media error:', error);
      res.status(500).json({ error: error.message || 'File upload failed' });
    }
  }
}
