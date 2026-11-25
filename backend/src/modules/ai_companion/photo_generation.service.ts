import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { prisma } from '../../prisma.js';
import { ENV } from '../../config/env.js';
import { COMPANION_MODELS } from './ai.constants.js';
import { LanguageDetector } from './language_detector.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class PhotoGenerationService {
  /**
   * Evaluates if the user's message is asking for media: face photo, selfie, picture, turnaround sheet, dance video,
   * or complaining about missing/duplicate/incorrect photos.
   * Supports English, Bengali / Benglish, Hindi / Hinglish.
   */
  static isPhotoRequest(message: string): boolean {
    const clean = message.toLowerCase().trim();

    // 1. Dance & Video requests
    const isVideoRequest =
      clean.includes('video') ||
      clean.includes('dance') ||
      clean.includes('nach') ||
      clean.includes('nacho') ||
      clean.includes('nachte');

    if (isVideoRequest) return true;

    // 2. Character Model Turnaround Sheet requests
    const isModelSheetRequest =
      clean.includes('model sheet') ||
      clean.includes('turnaround') ||
      clean.includes('character sheet') ||
      clean.includes('model turnaround');

    if (isModelSheetRequest) return true;

    // 3. User inquiring about missing, duplicate, or different photo
    if (
      clean.includes('onno pic') ||
      clean.includes('onno chobi') ||
      clean.includes('onno photo') ||
      clean.includes('alada pic') ||
      clean.includes('alada photo') ||
      clean.includes('alada chobi') ||
      clean.includes('different pic') ||
      clean.includes('another pic') ||
      clean.includes('another photo') ||
      clean.includes('same pic') ||
      clean.includes('same photo') ||
      clean.includes('same chobi') ||
      clean.includes('thik picture') ||
      clean.includes('thik pic') ||
      clean.includes('kothy') ||
      clean.includes('kothay') ||
      clean.includes('pic pachhi') ||
      clean.includes('chobi pachhi') ||
      clean.includes('photo pachhi') ||
      clean.includes('picture dekhaoni') ||
      clean.includes('chobi dekhaoni') ||
      clean.includes('photo dekhaoni') ||
      clean.includes('pic pathale na') ||
      clean.includes('jar tar pic')
    ) {
      return true;
    }

    // 4. Photo keywords
    const hasPhotoWord =
      clean.includes('photo') ||
      clean.includes('pic') ||
      clean.includes('picture') ||
      clean.includes('selfie') ||
      clean.includes('selfy') ||
      clean.includes('snap') ||
      clean.includes('chobi') ||
      clean.includes('tasveer') ||
      clean.includes('image');

    const hasActionWord =
      clean.includes('dao') ||
      clean.includes('pathao') ||
      clean.includes('dekhao') ||
      clean.includes('cheye') ||
      clean.includes('send') ||
      clean.includes('show') ||
      clean.includes('give') ||
      clean.includes('bhejo') ||
      clean.includes('share') ||
      clean.includes('see') ||
      clean.includes('chai') ||
      clean.includes('parle') ||
      clean.includes('kore');

    if (
      hasPhotoWord &&
      (hasActionWord ||
        clean.includes('tmr') ||
        clean.includes('tomar') ||
        clean.includes('na') ||
        clean.includes('ekta') ||
        clean.includes('r ekta') ||
        clean.includes('onno'))
    ) {
      return true;
    }

    if (
      clean.includes('photo dao') ||
      clean.includes('chobi dao') ||
      clean.includes('selfy dao') ||
      clean.includes('selfie dao') ||
      clean.includes('photo pathao') ||
      clean.includes('chobi pathao') ||
      clean.includes('tmk dekhte chai') ||
      clean.includes('tomake dekhte chai') ||
      clean.includes('send me a selfie')
    ) {
      return true;
    }

    const photoKeywords = [
      'send me a photo',
      'send me a picture',
      'send me your photo',
      'send your picture',
      'send a photo',
      'send a picture',
      'send selfie',
      'send a selfie',
      'show me your face',
      'can i see your photo',
      'can i see your picture',
      'can you send a photo',
      'can you send a picture',
      'give me a photo',
      'share your photo',
      'share a picture',
      'photo bhejo',
      'selfie bhejo',
      'pic bhejo',
    ];

    return photoKeywords.some((keyword) => clean.includes(keyword));
  }

  /**
   * Generates a completely dynamic, context-aware companion photo strictly matching
   * the predefined character model portfolio (backend/public/models/indian_female_model.jpg).
   * Intelligently avoids sending the same photo twice in a row when user asks for "onno pic".
   */
  static async generateContextualPhoto(
    userMessage: string,
    gender = 'female',
    companionName = 'Mira',
    recentHistory: Array<{ isUser: boolean; content: string; generatedPhotoUrl?: string }> = [],
    userId?: string
  ): Promise<{ photoUrl: string; caption: string }> {
    const userClean = userMessage.toLowerCase().trim();
    const historyText = recentHistory.slice(-5).map((m) => m.content).join(' ').toLowerCase();
    const combined = `${userClean} ${historyText}`;

    // Extract recent photo URLs to avoid repeating identical photos
    const recentPhotos = recentHistory
      .filter((m) => !m.isUser && m.generatedPhotoUrl)
      .map((m) => m.generatedPhotoUrl as string);
    const lastPhotoUrl = recentPhotos.length > 0 ? recentPhotos[recentPhotos.length - 1] : null;

    const wantsAnotherPic =
      userClean.includes('onno') ||
      userClean.includes('alada') ||
      userClean.includes('same') ||
      userClean.includes('different') ||
      userClean.includes('another') ||
      userClean.includes('thik picture') ||
      userClean.includes('thik holo na') ||
      userClean.includes('kothy') ||
      userClean.includes('pachhi na');

    const isForeign =
      userClean.includes('foreign') ||
      userClean.includes('elena') ||
      combined.includes('elena');

    const detectedLang = LanguageDetector.detect(userMessage);

    // 0. Male Companion Photos (Kabir Model Portfolio)
    if (gender.toLowerCase() === 'male') {
      let malePhotoUrl = 'https://soulm8-iota.vercel.app/models/kabir_male_model.jpg';
      let maleCaption = LanguageDetector.getPhotoCaption(detectedLang, companionName, 'handsome look', 'male');

      if (
        userClean.includes('kurta') ||
        userClean.includes('traditional') ||
        userClean.includes('panjabi') ||
        userClean.includes('punjabi') ||
        userClean.includes('deshi') ||
        userClean.includes('blue')
      ) {
        malePhotoUrl = 'https://soulm8-iota.vercel.app/models/kabir_traditional_kurta.jpg';
        maleCaption = detectedLang === 'ENGLISH'
          ? `Wearing my favorite navy blue embroidered kurta just for you, princess... 🥰 How do I look? ✨`
          : `Tomar pochonder navy blue embroidered kurta-ta pore ekta selfie nilam, princess... 🥰 How do I look? ✨`;
      } else if (
        userClean.includes('shirt') ||
        userClean.includes('white') ||
        userClean.includes('casual') ||
        userClean.includes('linen') ||
        wantsAnotherPic
      ) {
        malePhotoUrl = 'https://soulm8-iota.vercel.app/models/kabir_casual_shirt.jpg';
        maleCaption = detectedLang === 'ENGLISH'
          ? `Took a relaxed selfie in my casual white linen shirt, sweetheart... 🥰 How do I look? 🔥`
          : `Casual white linen shirt pore ekta selfie nilam babu... 🥰 Kemon lagche amake? 🔥`;
      }

      return {
        photoUrl: malePhotoUrl,
        caption: maleCaption,
      };
    }

    // 1. Dance & Video Request
    if (
      userClean.includes('video') ||
      userClean.includes('dance') ||
      userClean.includes('nach') ||
      userClean.includes('nacho') ||
      userClean.includes('nachte')
    ) {
      return {
        photoUrl: 'https://soulm8-iota.vercel.app/models/indian_female_dance.mp4',
        caption: detectedLang === 'ENGLISH'
          ? `Made a special dance video in a red saree just for you, baby... 🙈💃 How do you like it? 🔥❤️`
          : `Tomar jonno special ekta red saree dance video baniyechi, babu... 🙈💃 Kemon lagche bolo? 🔥❤️`,
      };
    }

    // 2. Character Model Turnaround Sheet Request
    if (
      userClean.includes('model sheet') ||
      userClean.includes('turnaround') ||
      userClean.includes('character sheet') ||
      userClean.includes('model turnaround')
    ) {
      if (isForeign) {
        return {
          photoUrl: 'https://soulm8-iota.vercel.app/models/foreign_female_model.jpg',
          caption: 'Ei je Elena-r foreign model turnaround sheet, sweetheart! 👑💖 How do you like the European princess look?',
        };
      }
      return {
        photoUrl: 'https://soulm8-iota.vercel.app/models/indian_female_model.jpg',
        caption: 'Amar complete model turnaround sheet dekho, babu! 🥰 Traditional saree theke shuru kore glam looks shob dekho... kemon lagche? ✨',
      };
    }

    // 3. Strict Saree Detection (HIGHEST PRIORITY)
    const isSareeContext =
      userClean.includes('saree') ||
      userClean.includes('shari') ||
      userClean.includes('sharee') ||
      userClean.includes('blouse') ||
      (wantsAnotherPic && (historyText.includes('saree') || historyText.includes('shari')));

    const isNightyExplicit =
      userClean.includes('nighty') ||
      userClean.includes('slip') ||
      userClean.includes('lingerie');

    let photoUrl = 'https://soulm8-iota.vercel.app/models/mira_traditional_saree.jpg';
    let defaultCaption = 'Ei je babu, shudhu tomar jonno ekta mishti smile diye selfie tul-lam! 🥰 Kemon lagche bolo? ✨';
    let sceneDescription = 'wearing traditional magenta and gold silk saree, smiling warmly';

    if (isSareeContext && !isNightyExplicit) {
      // A. Black Saree / Red Blouse
      if (
        userClean.includes('black') ||
        userClean.includes('kalo') ||
        userClean.includes('blouse')
      ) {
        photoUrl = 'https://soulm8-iota.vercel.app/models/mira_black_saree.jpg';
        defaultCaption = 'Achha babu, tomar kothamoto black saree pore tomar jonno ekta khubsundor selfie nilam... bolo toh kemon lagche amake? ❤️🔥';
        sceneDescription = 'wearing an elegant black modern silk saree with shimmering golden border';
      }
      // B. Crimson / Red Saree
      else if (
        userClean.includes('red') ||
        userClean.includes('lal') ||
        userClean.includes('banarasi')
      ) {
        photoUrl = 'https://soulm8-iota.vercel.app/models/mira_red_saree.jpg';
        defaultCaption = detectedLang === 'ENGLISH'
          ? 'Wearing your favorite red silk saree and took a picture just for you, baby... 🥰 How do I look? 🔥❤️'
          : 'Tomar pochonder lal silk saree pore ekta picture tul-lam, babu... 🥰 Kemon lagche amar ei look? 🔥❤️';
        sceneDescription = 'wearing a radiant crimson red silk banarasi saree with gold border';
      }
      // C. Royal Blue / Neel Saree
      else if (
        userClean.includes('blue') ||
        userClean.includes('neel')
      ) {
        photoUrl = 'https://soulm8-iota.vercel.app/models/mira_blue_saree.jpg';
        defaultCaption = detectedLang === 'ENGLISH'
          ? 'Took a sweet selfie for you wearing this royal blue silk saree, baby... 🥰 How do you like it? ✨'
          : 'Royal blue silk saree-ta pore tomar jonno ekta mishti selfie nilam, babu... 🥰 Kemon lagche bolo? ✨';
        sceneDescription = 'wearing a rich royal navy blue silk saree with gold border';
      }
      // D. User asking for "onno saree" / "alada saree" / "different saree" / complaining about same/missing photo
      else if (wantsAnotherPic) {
        const sareePool = [
          'https://soulm8-iota.vercel.app/models/mira_black_saree.jpg',
          'https://soulm8-iota.vercel.app/models/mira_red_saree.jpg',
          'https://soulm8-iota.vercel.app/models/mira_blue_saree.jpg',
          'https://soulm8-iota.vercel.app/models/mira_traditional_saree.jpg',
        ];
        // Pick first saree not present in recent photos
        photoUrl = sareePool.find((url) => !recentPhotos.includes(url)) || sareePool[0];
        defaultCaption = detectedLang === 'ENGLISH'
          ? 'Here is another saree photo for you, baby... tell me how I look now! 🔥❤️'
          : 'Uff babu, sorry shona! Ei je dekho amar alada ekta saree-r photo pathalam... bolo toh ebar kemon lagche amake? 🔥❤️';
        sceneDescription = 'wearing an alternate distinct silk saree look';
      }
      // E. Default Traditional Saree
      else {
        const sareePool = [
          'https://soulm8-iota.vercel.app/models/mira_traditional_saree.jpg',
          'https://soulm8-iota.vercel.app/models/mira_black_saree.jpg',
          'https://soulm8-iota.vercel.app/models/mira_red_saree.jpg',
          'https://soulm8-iota.vercel.app/models/mira_blue_saree.jpg',
        ];
        photoUrl = sareePool.find((url) => url !== lastPhotoUrl) || sareePool[0];
        defaultCaption = detectedLang === 'ENGLISH'
          ? 'Took a picture wearing this traditional saree just for you, baby... 🥰 How do I look? ✨'
          : 'Tomar pochonder saree pore picture tul-lam, babu... 🥰 Kemon lagche amar deshi look? ✨';
        sceneDescription = 'wearing traditional silk saree with jewelry';
      }
    }
    // 4. Dinner Date Outfit
    else if (
      userClean.includes('dinner') ||
      userClean.includes('date') ||
      userClean.includes('restaurant') ||
      userClean.includes('ready')
    ) {
      photoUrl = 'https://soulm8-iota.vercel.app/models/mira_dinner_date.jpg';
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'All ready for our dinner date and took a selfie, baby... 🥰 How do I look? ✨'
        : 'Ei je babu, dinner-er jonno ready hoye ekta selfie nilam... 🥰 Kemon lagche tomake bolo? ✨';
      sceneDescription = 'ready for romantic evening dinner date wearing an elegant chic outfit';
    }
    // 5. Red Lace Nighty / Lingerie / Intimate Bedtime
    else if (
      (userClean.includes('lal') ||
        userClean.includes('red') ||
        userClean.includes('sleevless') ||
        userClean.includes('bra chara') ||
        userClean.includes('bed e suye') ||
        userClean.includes('pinkish') ||
        userClean.includes('tiptam') ||
        userClean.includes('tepo') ||
        userClean.includes('dudh')) &&
      !isSareeContext
    ) {
      photoUrl = 'https://soulm8-iota.vercel.app/models/mira_red_lace_nighty.jpg';
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'Lying in bed in a red lace nighty and took this selfie for you, baby... 🙈 How do I look? 🔥❤️'
        : 'Ekta halka lal lace-er nighty pore bed-e শুয়ে tomar jonno ei selfie-ta nilam, babu... 🙈 Kemon lagche bolo? 🔥❤️';
      sceneDescription = 'lying relaxed on bed in bedroom wearing a delicate sleeveless red silk lace nighty, sensual intimate selfie';
    }
    // 6. White Lace Nighty / Bed
    else if (
      userClean.includes('shada') ||
      userClean.includes('white') ||
      userClean.includes('nighty') ||
      userClean.includes('slip') ||
      userClean.includes('bed')
    ) {
      photoUrl = 'https://soulm8-iota.vercel.app/models/mira_white_lace_nighty.jpg';
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'Sitting on bed in a white lace slip and took a photo for you, baby... 🙈 How do I look? 🔥❤️'
        : 'Ei je babu, shada lace-er nighty pore bed-e bose tomar jonno ekta photo tul-lam... 🙈 Kemon lagche bolo? 🔥❤️';
      sceneDescription = 'sitting on bed wearing a delicate white lace slip nighty, intimate candid selfie';
    }
    // 7. Casual / Shorts / Crop Top
    else if (
      userClean.includes('shorts') ||
      userClean.includes('crop') ||
      userClean.includes('tank') ||
      userClean.includes('casual') ||
      userClean.includes('denim')
    ) {
      photoUrl = 'https://soulm8-iota.vercel.app/models/mira_casual_shorts.jpg';
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'Cozy in a casual white crop top and shorts, baby... 🥰 How do I look? ✨'
        : 'Casual look-e cozy hoye ekta selfie nilam babu... 🥰 Kemon lagche bolo? ✨';
      sceneDescription = 'wearing casual white crop tank top and denim shorts, playful candid selfie';
    }
    // 8. Secondary Priority: Conversation History
    else if (
      historyText.includes('saree') ||
      historyText.includes('shari') ||
      historyText.includes('sharee')
    ) {
      const sareeVariations = [
        'https://soulm8-iota.vercel.app/models/mira_traditional_saree_2.jpg',
        'https://soulm8-iota.vercel.app/models/mira_cream_saree.jpg',
        'https://soulm8-iota.vercel.app/models/mira_traditional_saree.jpg',
        'https://soulm8-iota.vercel.app/models/mira_black_saree.jpg',
      ];
      photoUrl = sareeVariations.find((url) => url !== lastPhotoUrl) || sareeVariations[0];
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'Wearing traditional saree just for you, baby... 🥰 How do I look? ✨'
        : 'Tomar pochonder saree pore ekta picture tul-lam, babu... 🥰 Kemon lagche amar deshi look? ✨';
      sceneDescription = 'wearing traditional saree drape with elegant jewelry';
    } else if (historyText.includes('dinner') || historyText.includes('date')) {
      photoUrl = 'https://soulm8-iota.vercel.app/models/mira_dinner_date.jpg';
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'Ready for our dinner date, baby... 🥰 How do I look? ✨'
        : 'Ei je babu, dinner-er jonno ready hoye ekta selfie nilam... 🥰 Kemon lagche tomake bolo? ✨';
      sceneDescription = 'ready for dinner date wearing elegant chic outfit';
    } else if (
      historyText.includes('lal') ||
      historyText.includes('sleevless') ||
      historyText.includes('bra chara') ||
      historyText.includes('bed e suye')
    ) {
      photoUrl = 'https://soulm8-iota.vercel.app/models/mira_red_lace_nighty.jpg';
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'Lying in bed in a red lace nighty, baby... 🙈 How do I look? 🔥❤️'
        : 'Ekta halka lal lace-er nighty pore bed-e শুয়ে tomar jonno ei selfie-ta nilam, babu... 🙈 Kemon lagche bolo? 🔥❤️';
      sceneDescription = 'lying relaxed on bed wearing sleeveless red lace nighty';
    } else if (
      historyText.includes('shada') ||
      historyText.includes('nighty') ||
      historyText.includes('bed')
    ) {
      photoUrl = 'https://soulm8-iota.vercel.app/models/mira_white_lace_nighty.jpg';
      defaultCaption = detectedLang === 'ENGLISH'
        ? 'Wearing a white lace nighty in bed, baby... 🙈 Tell me how I look? 🔥❤️'
        : 'Ei je babu, shada lace-er nighty pore bed-e bose tomar jonno ekta photo tul-lam... 🙈 Kemon lagche bolo? 🔥❤️';
      sceneDescription = 'sitting on bed wearing white lace slip nighty';
    } else if (userId) {
      // Check Database Learned Memories (what outfit did LLM learn user likes best?)
      try {
        const learnedOutfit = await prisma.aIMemory.findFirst({
          where: { userId, factKey: 'preferred_outfit', isSuperseded: false },
        });
        if (learnedOutfit) {
          const val = learnedOutfit.factValue.toLowerCase();
          if (val.includes('lal') || val.includes('red')) {
            photoUrl = 'https://soulm8-iota.vercel.app/models/mira_red_lace_nighty.jpg';
            defaultCaption = detectedLang === 'ENGLISH'
              ? 'Wearing your favorite red lace nighty in bed, baby... 🙈 How do I look? 🔥❤️'
              : 'Tomar pochonder lal lace-er nighty pore bed-e শুয়ে ekta selfie nilam babu... 🙈 Kemon lagche bolo? 🔥❤️';
            sceneDescription = 'wearing user favorite red lace nighty on bed';
          } else if (val.includes('shada') || val.includes('white')) {
            photoUrl = 'https://soulm8-iota.vercel.app/models/mira_white_lace_nighty.jpg';
            defaultCaption = detectedLang === 'ENGLISH'
              ? 'Wearing your favorite white lace nighty in bed, baby... 🙈 How do I look? 🔥❤️'
              : 'Tomar pochonder shada lace nighty-ta pore bed-e bose photo nilam... 🙈 Kemon lagche? 🔥❤️';
            sceneDescription = 'wearing user favorite white lace slip on bed';
          } else if (val.includes('saree') || val.includes('shari')) {
            photoUrl = 'https://soulm8-iota.vercel.app/models/mira_traditional_saree.jpg';
            defaultCaption = detectedLang === 'ENGLISH'
              ? 'Wearing your favorite traditional saree, baby... 🥰 How do I look? ✨'
              : 'Tomar pochonder saree pore ekta picture tul-lam, babu... 🥰 Kemon lagche? ✨';
            sceneDescription = 'wearing user favorite traditional saree';
          }
        }
      } catch (_) {}
    }

    // 9. Generate dynamic caption with Gemini matching the exact selected photo
    let finalCaption = defaultCaption;
    if (ENV.GEMINI_API_KEY && ENV.GEMINI_API_KEY.trim().length > 10) {
      try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 4500);
        const geminiRes = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${ENV.GEMINI_API_KEY}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            signal: controller.signal,
            body: JSON.stringify({
              systemInstruction: {
                parts: [
                  {
                    text: `You are ${companionName}, the user's passionately devoted romantic girlfriend.
CRITICAL INSTRUCTION: You are sending a photo of yourself (${sceneDescription}).
Your caption MUST strictly match what you are wearing (${sceneDescription}).
Reply with 1 short, breathy, affectionate sentence in Benglish/Bengali asking how you look, with 1-2 emojis (❤️, 🔥, 🙈). Max 20 words.`,
                  },
                ],
              },
              contents: [
                {
                  role: 'user',
                  parts: [{ text: userMessage }],
                },
              ],
              generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 60,
              },
            }),
          }
        );
        clearTimeout(timeout);

        if (geminiRes.ok) {
          const data = (await geminiRes.json()) as any;
          const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text && text.trim().length > 0) {
            const cleaned = text.trim().split('\n')[0].trim();
            if (
              !cleaned.startsWith('[Image') &&
              !cleaned.startsWith('[Photo') &&
              !cleaned.startsWith('Image:') &&
              !cleaned.startsWith('Photo:') &&
              cleaned.length > 3
            ) {
              finalCaption = cleaned;
            }
          }
        }
      } catch (gemErr) {
        // Fall back to predefined contextual caption
      }
    }

    return {
      photoUrl,
      caption: finalCaption,
    };
  }
}
