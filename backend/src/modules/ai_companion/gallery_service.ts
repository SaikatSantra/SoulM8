import { prisma } from '../../prisma.js';

export interface GalleryPhoto {
  id: string;
  url: string;
  caption: string;
  category: 'TRADITIONAL' | 'CASUAL' | 'NIGHTWEAR' | 'PORTRAIT';
  createdAt: string;
  isGenerated: boolean;
}

export class GalleryService {
  /**
   * Returns curated + user-received photos for the AI companion.
   */
  public static async getGallery(userId: string): Promise<GalleryPhoto[]> {
    // 1. Fetch companion profile
    const profile = await prisma.companionProfile.findUnique({ where: { userId } });
    const isMale = profile?.gender?.toLowerCase() === 'male';

    // 2. Fetch all messages in user's conversations that have an attached photo
    const dbMessages = await prisma.aIMessage.findMany({
      where: {
        conversation: { userId },
        generatedPhotoUrl: { not: null },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    const userPhotos: GalleryPhoto[] = dbMessages
      .filter((m) => m.generatedPhotoUrl && m.generatedPhotoUrl.trim().length > 0)
      .map((m) => ({
        id: m.id,
        url: m.generatedPhotoUrl!,
        caption: m.content.length > 50 ? m.content.substring(0, 47) + '...' : m.content,
        category: this.classifyCategory(m.content),
        createdAt: m.createdAt.toISOString(),
        isGenerated: true,
      }));

    // 3. Curated default portfolio photos
    const defaultPortfolio: GalleryPhoto[] = isMale
      ? [
          {
            id: 'kabir_traditional_1',
            url: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80',
            caption: 'Traditional Kurta for festive evening ✨',
            category: 'TRADITIONAL',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
          {
            id: 'kabir_casual_1',
            url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80',
            caption: 'Cozy weekend morning coffee ☕',
            category: 'CASUAL',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
          {
            id: 'kabir_portrait_1',
            url: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80',
            caption: 'Warm smile thinking about you 😊',
            category: 'PORTRAIT',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
        ]
      : [
          {
            id: 'mira_traditional_saree_black',
            url: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
            caption: 'Midnight Black Saree with golden borders 🖤✨',
            category: 'TRADITIONAL',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
          {
            id: 'mira_traditional_saree_red',
            url: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800&auto=format&fit=crop&q=80',
            caption: 'Classic Red Silk Saree for special moments ❤️',
            category: 'TRADITIONAL',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
          {
            id: 'mira_casual_sweater',
            url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80',
            caption: 'Cozy oversized sweater on a rainy day 🌧️☕',
            category: 'CASUAL',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
          {
            id: 'mira_nightwear_cozy',
            url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80',
            caption: 'Unwinding after a long day, bedtime selfie 🌙✨',
            category: 'NIGHTWEAR',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
          {
            id: 'mira_portrait_smile',
            url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop&q=80',
            caption: 'Thinking of you with a gentle smile 🥰',
            category: 'PORTRAIT',
            createdAt: new Date().toISOString(),
            isGenerated: false,
          },
        ];

    // Combine user generated photos with curated portfolio (avoiding duplicate URLs)
    const seenUrls = new Set<string>();
    const combined: GalleryPhoto[] = [];

    for (const p of [...userPhotos, ...defaultPortfolio]) {
      if (!seenUrls.has(p.url)) {
        seenUrls.add(p.url);
        combined.push(p);
      }
    }

    return combined;
  }

  private static classifyCategory(
    text: string
  ): 'TRADITIONAL' | 'CASUAL' | 'NIGHTWEAR' | 'PORTRAIT' {
    const lower = text.toLowerCase();
    if (lower.includes('saree') || lower.includes('shari') || lower.includes('kurta') || lower.includes('traditional')) {
      return 'TRADITIONAL';
    }
    if (lower.includes('nighty') || lower.includes('nightwear') || lower.includes('bed') || lower.includes('lace')) {
      return 'NIGHTWEAR';
    }
    if (lower.includes('casual') || lower.includes('shirt') || lower.includes('sweater') || lower.includes('jeans')) {
      return 'CASUAL';
    }
    return 'PORTRAIT';
  }
}
