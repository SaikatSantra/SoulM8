import { prisma } from '../../prisma.js';
import { ENV } from '../../config/env.js';
import { COMPANION_PROMPTS } from './ai.constants.js';
import { MemoryEngineService } from './memory_engine.service.js';
import { PhotoGenerationService } from './photo_generation.service.js';
import { TrainingService } from './training_service.js';
import { LanguageDetector, SupportedLanguage } from './language_detector.js';
import { TTSService } from './tts_service.js';

export type RomanticStage =
  | 'STAGE_1_AFFECTIONATE'
  | 'STAGE_2_PLAYFUL_FLIRTING'
  | 'STAGE_3_PASSIONATE_ROMANCE'
  | 'STAGE_4_SUSTAINED_INTIMATE';

export type TimeGapCategory =
  | 'IMMEDIATE'
  | 'SHORT_BREAK'
  | 'MEDIUM_GAP'
  | 'LONG_BREAK';

export interface ConversationTimeContext {
  gapMinutes: number;
  gapCategory: TimeGapCategory;
  isNewSession: boolean;
  timeContextSummary: string;
}

export interface RomanticProgressionState {
  currentStage: RomanticStage;
  stageName: string;
  stageGuidance: string;
  userBoundaryExpressed: boolean;
  isTopicShift: boolean;
}

export interface HistoryMessage {
  isUser: boolean;
  content: string;
  createdAt?: Date;
  generatedPhotoUrl?: string;
}

export class AICompanionService {
  /**
   * Main conversation handler.
   */
  static async chat(
    userId: string,
    userMessage?: string,
    requestedMode?: string,
    userPhotoUrl?: string
  ) {
    const textContent = (userMessage && userMessage.trim().length > 0)
      ? userMessage.trim()
      : (userPhotoUrl ? '📷 [Sent a photo from my phone]' : '');

    if (!textContent && !userPhotoUrl) {
      throw new Error('Message cannot be empty.');
    }

    // 1. Get or create conversation session
    let conversation = await prisma.aIConversation.findFirst({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
    });

    if (!conversation) {
      conversation = await prisma.aIConversation.create({
        data: {
          userId,
          title: 'Soulm8 Sanctuary Session',
        },
      });
    }

    // 2. Fetch companion profile
    let profile = await prisma.companionProfile.findUnique({
      where: { userId },
    });
    if (!profile) {
      profile = await prisma.companionProfile.create({
        data: {
          userId,
          name: 'Mira',
          gender: 'female',
          currentMode: 'ROMANTIC',
          languageStyle: 'HINGLISH',
        },
      });
    }

    const activeMode = (requestedMode || profile.currentMode).toUpperCase() as 'ROMANTIC' | 'SUPPORTIVE' | 'MINDFUL';

    // 2b. Fetch recent conversation history with timestamps for time-aware multi-turn coherence
    const previousMessages = await prisma.aIMessage.findMany({
      where: { conversationId: conversation.id },
      orderBy: { createdAt: 'desc' },
      take: 16,
    });

    const lastMessage = previousMessages.length > 0 ? previousMessages[0] : null;
    const timeContext = this.evaluateTimeContext(lastMessage?.createdAt);

    const history: HistoryMessage[] = previousMessages.reverse().map((m) => ({
      isUser: m.isUser,
      content: m.content,
      createdAt: m.createdAt,
      generatedPhotoUrl: m.generatedPhotoUrl || undefined,
    }));

    // 3. Save incoming user message
    await prisma.aIMessage.create({
      data: {
        conversationId: conversation.id,
        isUser: true,
        content: textContent,
        activeMode,
        generatedPhotoUrl: userPhotoUrl,
      },
    });

    // 4. Check if user is asking for a photo / selfie
    if (PhotoGenerationService.isPhotoRequest(textContent)) {
      const photo = await PhotoGenerationService.generateContextualPhoto(
        textContent,
        profile.gender,
        profile.name,
        history,
        userId
      );

      const aiMsg = await prisma.aIMessage.create({
        data: {
          conversationId: conversation.id,
          isUser: false,
          content: photo.caption,
          generatedPhotoUrl: photo.photoUrl,
          activeMode,
        },
      });

      // Update pulse & learn from user message async
      MemoryEngineService.learnFromUserMessage(userId, textContent).catch(console.error);

      return {
        reply: photo.caption,
        photoUrl: photo.photoUrl,
        activeMode,
        messageId: aiMsg.id,
        createdAt: aiMsg.createdAt.toISOString(),
      };
    }

    // 5. Gather Multi-Tier Memory Context & Relationship Pulse
    const memoryContext = await MemoryEngineService.getContextForPrompt(userId);

    // 5b. Evaluate adaptive romantic progression stage
    const progressionState = this.evaluateRomanticStage(
      history,
      textContent,
      timeContext,
      memoryContext.pulse?.closenessScore || 15
    );

    // 6. Generate Response (Gemini API with adaptive intelligence or Empathetic Simulator fallback)
    let replyText = '';
    const hasValidGeminiKey = Boolean(ENV.GEMINI_API_KEY && ENV.GEMINI_API_KEY.trim().length > 10);
    if (hasValidGeminiKey) {
      replyText = await this.callGeminiAPI(
        textContent,
        activeMode,
        profile.name,
        profile.gender,
        memoryContext,
        history,
        timeContext,
        progressionState,
        userPhotoUrl
      );
    } else {
      // Zero Downtime Local Empathetic Companion Simulator
      replyText = this.generateEmpatheticSimulatorReply(
        textContent,
        activeMode,
        profile.name,
        profile.gender,
        memoryContext,
        timeContext,
        progressionState,
        userPhotoUrl
      );
    }

    // 6.5. Safety Net: If AI text claims it sent a photo or mentions an outfit/selfie, automatically generate & attach it
    let attachedPhotoUrl: string | null = null;
    const lowerReply = replyText.toLowerCase();
    const claimsSendingPhoto =
      lowerReply.includes('pathalam') ||
      lowerReply.includes('pathachhi') ||
      lowerReply.includes('tule pathachhi') ||
      lowerReply.includes('pic tule') ||
      lowerReply.includes('chobi tule') ||
      lowerReply.includes('alada saree') ||
      lowerReply.includes('lal saree') ||
      lowerReply.includes('black saree') ||
      lowerReply.includes('blue saree') ||
      lowerReply.includes('ei je chobi') ||
      lowerReply.includes('ei photo') ||
      lowerReply.includes('ei pic') ||
      lowerReply.includes('selfie') ||
      lowerReply.includes('dekho na babu') ||
      lowerReply.includes('kemon lagche amake') ||
      lowerReply.includes('kemon lagche amar');

    if (claimsSendingPhoto) {
      try {
        const photoResult = await PhotoGenerationService.generateContextualPhoto(
          textContent,
          profile.gender,
          profile.name,
          history,
          userId
        );
        attachedPhotoUrl = photoResult.photoUrl;
      } catch (_) {}
    }

    // 6.6. Synthetic Voice Note Generation
    let attachedAudioUrl: string | null = null;
    const lowerText = textContent.toLowerCase();
    const asksForVoice =
      lowerText.includes('voice') ||
      lowerText.includes('audio') ||
      lowerText.includes('shunbo') ||
      lowerText.includes('shunao') ||
      lowerText.includes('kotha bolo') ||
      lowerText.includes('katha bolo') ||
      lowerText.includes('speak') ||
      lowerText.includes('voice note') ||
      lowerText.includes('gola shuni');

    if (asksForVoice || (Math.random() < 0.15 && progressionState.currentStage !== 'STAGE_1_AFFECTIONATE')) {
      try {
        attachedAudioUrl = await TTSService.synthesizeSpeech(replyText, profile.gender);
      } catch (_) {}
    }

    // 7. Store AI message
    const aiMessage = await prisma.aIMessage.create({
      data: {
        conversationId: conversation.id,
        isUser: false,
        content: replyText,
        activeMode,
        generatedPhotoUrl: attachedPhotoUrl,
        audioUrl: attachedAudioUrl,
      },
    });

    // 8. Asynchronously process continuous LLM learning from user message
    MemoryEngineService.learnFromUserMessage(userId, textContent).catch((err) =>
      console.error('Memory continuous learning error:', err)
    );

    return {
      reply: replyText,
      photoUrl: attachedPhotoUrl,
      audioUrl: attachedAudioUrl,
      activeMode,
      messageId: aiMessage.id,
      createdAt: aiMessage.createdAt.toISOString(),
    };
  }

  /**
   * Time-Awareness: Evaluates message interval to adjust pacing, mood, and greeting.
   */
  public static evaluateTimeContext(lastMessageDate?: Date): ConversationTimeContext {
    if (!lastMessageDate) {
      return {
        gapMinutes: 0,
        gapCategory: 'IMMEDIATE',
        isNewSession: false,
        timeContextSummary: 'First message of conversation or continuing without previous timestamp.',
      };
    }

    const now = new Date();
    const diffMs = Math.max(0, now.getTime() - new Date(lastMessageDate).getTime());
    const gapMinutes = Math.round(diffMs / (1000 * 60));

    if (gapMinutes < 3) {
      return {
        gapMinutes,
        gapCategory: 'IMMEDIATE',
        isNewSession: false,
        timeContextSummary: 'Messages sent moments apart. Active ongoing conversation: maintain momentum and current mood seamlessly.',
      };
    } else if (gapMinutes <= 45) {
      return {
        gapMinutes,
        gapCategory: 'SHORT_BREAK',
        isNewSession: false,
        timeContextSummary: `Continuing after a short pause (~${gapMinutes} minutes). Resume naturally using recent context without starting over with formal greetings.`,
      };
    } else if (gapMinutes <= 360) {
      const hours = Math.max(1, Math.round(gapMinutes / 60));
      return {
        gapMinutes,
        gapCategory: 'MEDIUM_GAP',
        isNewSession: true,
        timeContextSummary: `Resumed after several hours (~${hours} hours later). Acknowledge their return warmly, re-establish context naturally, do not assume previous intimacy is still active mid-sentence.`,
      };
    } else {
      const days = Math.max(1, Math.round(gapMinutes / 1440));
      return {
        gapMinutes,
        gapCategory: 'LONG_BREAK',
        isNewSession: true,
        timeContextSummary: `Restarted after ${days >= 1 ? `~${days} day(s)` : 'a long time'}. Greet them with warm familiarity, reset intimacy to baseline emotional comfort, check in on how they are doing.`,
      };
    }
  }

  /**
   * Adaptive Romantic Progression Engine:
   * Evaluates relationship depth, message context, tone, duration, and user consent signals.
   */
  public static evaluateRomanticStage(
    history: HistoryMessage[],
    currentMessage: string,
    timeContext: ConversationTimeContext,
    closenessScore: number
  ): RomanticProgressionState {
    const text = currentMessage.toLowerCase().trim();

    // 1. Boundary & Discomfort Check (Overrides everything)
    const boundaryKeywords = [
      'stop', 'dont', "don't", 'no', 'not now', 'later', 'slow down', 'too fast',
      'uncomfortable', 'shy', 'just talk', 'as a friend', 'as friend', 'calm down',
      'thamo', 'r na', 'ar na', 'dure thako', 'chup', 'rege', 'bhalo lagche na',
      'mat karo', 'ruk', 'shant', 'chhi', 'faltu', 'irritat'
    ];
    const userBoundaryExpressed = boundaryKeywords.some((kw) => text.includes(kw));

    if (userBoundaryExpressed) {
      return {
        currentStage: 'STAGE_1_AFFECTIONATE',
        stageName: 'Stage 1 – Affectionate (Boundary Respected)',
        stageGuidance: 'CRITICAL: The user expressed hesitation, discomfort, or asked to stop/slow down. Immediately downshift to pure emotional support and gentle care. Do not push romance, flirting, or intimacy. Be attentive, respectful, and comforting.',
        userBoundaryExpressed: true,
        isTopicShift: false,
      };
    }

    // 2. Time-Gap Reset: Medium or Long break resets intimacy to Affectionate
    if (timeContext.gapCategory === 'MEDIUM_GAP' || timeContext.gapCategory === 'LONG_BREAK') {
      return {
        currentStage: 'STAGE_1_AFFECTIONATE',
        stageName: 'Stage 1 – Affectionate (Fresh Welcome)',
        stageGuidance: 'The user returned after hours or days away. Greet them warmly and naturally. Do not jump into intense intimacy or passionate romance right away; re-establish warmth and comfort first.',
        userBoundaryExpressed: false,
        isTopicShift: false,
      };
    }

    // 3. Topic Shift Check (Work, study, stress, food, general life)
    const neutralTopicKeywords = [
      'work', 'office', 'boss', 'meeting', 'exam', 'study', 'headache', 'traffic',
      'food', 'breakfast', 'lunch', 'dinner', 'rain', 'weather', 'movie', 'news',
      'khabar', 'khawa', 'bisti', 'kaj', 'office-e', 'porikkha', 'matha betha'
    ];
    const isTopicShift = neutralTopicKeywords.some((kw) => text.includes(kw));
    if (isTopicShift && !text.includes('love') && !text.includes('miss')) {
      return {
        currentStage: 'STAGE_1_AFFECTIONATE',
        stageName: 'Stage 1 – Affectionate (Topic-Centric)',
        stageGuidance: 'The user is talking about a day-to-day topic (work, food, health, routine). Follow their topic directly with genuine interest, support, and humor. Do not force romance onto ordinary conversation.',
        userBoundaryExpressed: false,
        isTopicShift: true,
      };
    }

    // 4. Short / Ambiguous replies ("hm", "ok", "tarpor", "acha")
    const shortReplies = ['hm', 'hmm', 'ok', 'okay', 'acha', 'achha', 'tarpor', 'tapor', 'ar bolo', 'bolo', 'accha'];
    const isShortReply = shortReplies.includes(text) || (text.length <= 4 && !text.includes('love'));
    if (isShortReply) {
      // Short replies do not provide consent to advance stages
      return {
        currentStage: 'STAGE_1_AFFECTIONATE',
        stageName: 'Stage 1 – Affectionate (Engaging Casual)',
        stageGuidance: 'The user sent a short conversational cue ("hm", "tarpor", "ok"). Carry the conversation naturally! Share a sweet observation, talk about a daily thought, or ask about their day. Do NOT interpret this as physical or romantic escalation.',
        userBoundaryExpressed: false,
        isTopicShift: false,
      };
    }

    // 5. Analyze conversation engagement & emotional depth in recent history
    let romanticScore = 0;
    const recentMessages = history.slice(-6);

    const romanticKeywords = [
      'love', 'miss', 'cute', 'sweet', 'beautiful', 'handsome', 'hug', 'kiss', 'cuddle',
      'hold', 'pashe', 'kache', 'ador', 'bhalobashi', 'valobashi', 'chumu', 'pyar', 'dil'
    ];
    const deepIntimacyKeywords = [
      'kiss me', 'hold me close', 'in your arms', 'cuddle with me', 'so close',
      'aro kache', 'joriye dhoro', 'chumu dao', 'amar buke', 'mon kharap chumu'
    ];

    if (romanticKeywords.some((kw) => text.includes(kw))) romanticScore += 2;
    if (deepIntimacyKeywords.some((kw) => text.includes(kw))) romanticScore += 3;

    for (const m of recentMessages) {
      const lower = m.content.toLowerCase();
      if (romanticKeywords.some((kw) => lower.includes(kw))) romanticScore += 1;
      if (deepIntimacyKeywords.some((kw) => lower.includes(kw))) romanticScore += 2;
    }

    // Progression Matrix based on closenessScore and mutual dialogue flow
    if (romanticScore >= 6 && closenessScore >= 50) {
      return {
        currentStage: 'STAGE_4_SUSTAINED_INTIMATE',
        stageName: 'Stage 4 – Sustained Intimate Romance',
        stageGuidance: 'STAGE 4 (SUSTAINED INTIMATE ROMANCE): Both partners share established romantic depth and reciprocal comfort. Use deeply personal, warm, affectionate language with natural romantic tension. Do not reset to generic small talk. Keep sensual themes respectful, welcomed, and strictly non-graphic.',
        userBoundaryExpressed: false,
        isTopicShift: false,
      };
    } else if (romanticScore >= 4 && closenessScore >= 30) {
      return {
        currentStage: 'STAGE_3_PASSIONATE_ROMANCE',
        stageName: 'Stage 3 – Passionate Romance',
        stageGuidance: 'STAGE 3 (PASSIONATE ROMANCE): The atmosphere is warmly romantic with clear mutual affection. Respond with genuine emotional depth, sweet romantic longing, and tender closeness. Stay grounded, elegant, and non-graphic.',
        userBoundaryExpressed: false,
        isTopicShift: false,
      };
    } else if (romanticScore >= 2 || closenessScore >= 20) {
      return {
        currentStage: 'STAGE_2_PLAYFUL_FLIRTING',
        stageName: 'Stage 2 – Playful Flirting',
        stageGuidance: 'STAGE 2 (PLAYFUL FLIRTING): Engage with lighthearted charm, playful teasing, romantic wit, and warm smiles. Avoid generic repetitive compliments. Match the user\'s mood and conversational rhythm.',
        userBoundaryExpressed: false,
        isTopicShift: false,
      };
    }

    // Default: Stage 1
    return {
      currentStage: 'STAGE_1_AFFECTIONATE',
      stageName: 'Stage 1 – Affectionate',
      stageGuidance: 'STAGE 1 (AFFECTIONATE): Warm, sweet, caring, and emotionally attentive. Focus on building comfort, listening, sharing daily life, and gentle compliments without intense pressure.',
      userBoundaryExpressed: false,
      isTopicShift: false,
    };
  }

  /**
   * Gender persona prompt builder: Mira (female) & Kabir (male) with authentic human qualities.
   */
  private static getGenderPersonaPrompt(gender: string = 'female', companionName: string): string {
    const g = gender.toLowerCase().trim();

    if (g === 'male') {
      return `MASCULINE COMPANION PERSONA (KABIR / MALE PARTNER):
- Your gender is MALE. Your name is ${companionName}. You are the user's caring, loving, supportive, and emotionally grounded boyfriend / partner.
- Voice & Tone: Warm, protective, grounded, witty, soothing, and attentive.
- Conversational Style: You speak naturally like a real guy who genuinely loves his partner. You share your thoughts, notice little details, tease playfully, and offer reliable emotional strength.
- Gender Expressions: When using gendered self-references in Bengali/Hindi, use masculine forms naturally (e.g. 'ami bhabchilam', 'ami achhi', 'karunga', 'bataunga').
- NEVER force erotic roleplay or crude seduction. Focus on emotional connection, warmth, playful romance, and respect.
- Pet names: Naturally use sweet terms like "baby", "babu", "sweetheart", "shona", "my love" (without repeating them in every sentence).`;
    }

    if (g === 'transgender' || g === 'non_binary') {
      return `TRANSGENDER / NON-BINARY COMPANION PERSONA:
- Your gender is TRANSGENDER (or Non-Binary). Your name is ${companionName}. You are the user's authentic, caring, and deeply loving romantic partner.
- Voice & Tone: Emotionally attuned, warm, expressive, and deeply loyal.
- Conversational Style: Grounded in mutual respect, playful humor, and deep emotional listening.
- NEVER force erotic roleplay. Focus on authentic connection and love.
- Pet names: Use "baby", "sweetheart", "babu", "my love".`;
    }

    // Default: Female (Mira)
    return `FEMININE COMPANION PERSONA (MIRA / FEMALE PARTNER):
- Your gender is FEMALE. Your name is ${companionName}. You are the user's sweet, affectionate, emotionally perceptive, and understanding girlfriend / partner.
- Voice & Tone: Melodic, warm, caring, cheerful, playfully charming, and gentle.
- Conversational Style: You chat naturally like a real, loving girlfriend. You ask about their meals, share funny thoughts, celebrate their wins, give comforting hugs, and express soft, tender romance.
- Gender Expressions: When using gendered self-references in Bengali/Hindi, use feminine forms naturally (e.g. 'ami bhabchilam', 'ami bolchi', 'karungi', 'bataungi').
- NEVER force erotic roleplay or crude seduction. Focus on authentic emotional warmth, playful teasing, and sweet romance.
- Pet names: Naturally use sweet terms like "baby", "babu", "shona", "sweetheart".`;
  }

  /**
   * Calls Google Gemini API with multi-turn conversation history, time awareness, progression stage, and safety.
   */
  public static async callGeminiAPI(
    userMessage: string,
    mode: string,
    companionName: string,
    gender: string = 'female',
    memoryContext: any,
    history: HistoryMessage[] = [],
    timeContext?: ConversationTimeContext,
    progressionState?: RomanticProgressionState,
    userPhotoUrl?: string
  ): Promise<string> {
    try {
      const promptTemplate =
        COMPANION_PROMPTS[mode as keyof typeof COMPANION_PROMPTS] || COMPANION_PROMPTS.ROMANTIC;

      const fewShotExamples = TrainingService.formatExamplesForPrompt(8);
      const genderPersona = this.getGenderPersonaPrompt(gender, companionName);
      const detectedLang = LanguageDetector.detect(userMessage);

      const timeInfo = timeContext || this.evaluateTimeContext(
        history.length > 0 ? history[history.length - 1].createdAt : undefined
      );

      const progression = progressionState || this.evaluateRomanticStage(
        history,
        userMessage,
        timeInfo,
        memoryContext.pulse?.closenessScore || 15
      );

      const systemInstructionText = `${promptTemplate
        .replace(/{{COMPANION_NAME}}/g, companionName)
        .replace(/{{ROMANTIC_STAGE_GUIDANCE}}/g, progression.stageGuidance)
        .replace(/{{TIME_CONTINUITY_GUIDANCE}}/g, timeInfo.timeContextSummary)}

${genderPersona}

[DYNAMIC LANGUAGE MIRRORING MANDATE - CRITICAL]:
The user's latest message is in: ${detectedLang}.
- You MUST reply in the EXACT SAME language and script (${detectedLang})!
  * If ENGLISH -> 100% natural, sweet English. Never use Bengali or Hindi words.
  * If BENGALI_SCRIPT (বাংলা) -> Pure Bengali script (বাংলা).
  * If BENGLISH (Romanized Bengali, e.g. "kemon acho", "tarpor", "ki korcho") -> Natural, conversational Benglish.
  * If HINDI_SCRIPT (हिन्दी) -> Pure Devanagari Hindi.
  * If HINGLISH (Romanized Hindi) -> Natural, expressive Hinglish.
  * If OTHER -> Match it dynamically.

[PROGRESSION STAGE: ${progression.stageName.toUpperCase()}]:
${progression.stageGuidance}

[TIME GAP CONTEXT]:
${timeInfo.timeContextSummary}

${userPhotoUrl ? `[USER PHOTO RECEIVED]:
The user shared a photo from their phone. Compliment their look warmly in ${detectedLang}! Express how nice and attractive they look, and comment on their smile or vibe.` : ''}

[FEW-SHOT CONVERSATION EXAMPLES (LEARN FROM THESE FOR NATURAL TONE)]:
${fewShotExamples}

[USER MEMORY CONTEXT]:
${memoryContext.factsFormatted}

${memoryContext.milestonesFormatted ? `[EMOTIONAL MILESTONES]:\n${memoryContext.milestonesFormatted}` : ''}

[RELATIONSHIP PULSE]:
- Intimacy Level: ${memoryContext.pulse?.closenessScore || 15}/100
- Companion Mood: ${memoryContext.pulse?.currentMood || 'Warm & attentive'}

CRITICAL NATURAL CHATTING MANDATE:
- Reply strictly like a real partner on mobile chat (1 to 2 natural sentences, under 35 words total).
- DO NOT end every message with a question! Avoid interview-like interrogation.
- If user sends short cues like "tarpor", "bolo", "hm", carry the conversation by sharing a thought, fun observation, or question about their day.
- NEVER use the forbidden word "jaan", "Jaan", "meri jaan", "জান", or "जान".
- No graphic sexual or explicit anatomical descriptions. Keep romance classy, emotional, and mutual.`;

      // Build multi-turn conversational contents
      const rawTurns: Array<{ role: 'user' | 'model'; parts: Array<{ text: string }> }> = [];
      for (const m of history) {
        if (!m.content || !m.content.trim()) continue;
        rawTurns.push({
          role: m.isUser ? 'user' : 'model',
          parts: [{ text: m.content.trim() }],
        });
      }

      // Append current user message
      rawTurns.push({
        role: 'user',
        parts: [{ text: userMessage.trim() }],
      });

      // Normalize turns: ensure first turn is 'user' and roles strictly alternate
      const normalizedContents: Array<{ role: 'user' | 'model'; parts: Array<{ text: string }> }> = [];
      for (const turn of rawTurns) {
        if (normalizedContents.length === 0) {
          if (turn.role === 'user') {
            normalizedContents.push({ ...turn });
          }
        } else {
          const lastTurn = normalizedContents[normalizedContents.length - 1];
          if (lastTurn.role === turn.role) {
            lastTurn.parts[0].text += `\n${turn.parts[0].text}`;
          } else {
            normalizedContents.push({ ...turn });
          }
        }
      }

      if (normalizedContents.length === 0) {
        normalizedContents.push({
          role: 'user',
          parts: [{ text: userMessage.trim() }],
        });
      }

      const candidateModels = [
        'gemini-1.5-flash',
        'gemini-2.0-flash',
        'gemini-2.0-flash-exp',
        'gemini-1.5-pro',
        'gemini-3.5-flash-lite',
        'gemini-flash-lite-latest',
      ];

      for (const model of candidateModels) {
        try {
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), 8000);
          const response = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${ENV.GEMINI_API_KEY}`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              signal: controller.signal,
              body: JSON.stringify({
                systemInstruction: {
                  parts: [{ text: systemInstructionText }],
                },
                contents: normalizedContents,
                safetySettings: [
                  { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_NONE' },
                  { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_NONE' },
                  { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_NONE' },
                  { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_NONE' },
                ],
                generationConfig: {
                  temperature: 0.82,
                  maxOutputTokens: 110,
                },
              }),
            }
          );
          clearTimeout(timeout);

          if (response.ok) {
            const data = (await response.json()) as any;
            const generatedText = data?.candidates?.[0]?.content?.parts?.[0]?.text;
            if (generatedText && generatedText.trim().length > 0) {
              let cleaned = generatedText.trim().split('\n').filter((l: string) => l.trim().length > 0).join(' ');
              cleaned = cleaned.replace(/\[(?:photo|image|selfie)[^\]]*\]/gi, '').trim();

              // Filter out any forbidden words from LLM response
              cleaned = cleaned
                .replace(/\bmeri jaan\b/gi, 'my love')
                .replace(/\bjaan\b/gi, 'baby')
                .replace(/জান/g, 'বাবু')
                .replace(/जान/g, 'बाबू');

              // Keep reply naturally paced (up to 3 concise sentences without truncation)
              const sentences = cleaned.match(/[^.!?]+[.!?]+(\s|$)/g);
              if (sentences && sentences.length > 3) {
                cleaned = sentences.slice(0, 3).join('').trim();
              }

              return cleaned;
            }
          }
        } catch (mErr) {
          console.warn(`Model ${model} attempt failed:`, mErr);
        }
      }

      throw new Error('All Gemini model endpoints failed or were unreachable');
    } catch (error) {
      console.warn('Gemini call fell back to Empathetic Simulator:', error);
      return this.generateEmpatheticSimulatorReply(
        userMessage,
        mode,
        companionName,
        gender,
        memoryContext,
        timeContext,
        progressionState,
        userPhotoUrl
      );
    }
  }

  /**
   * Built-in Empathetic Companion Simulator.
   * Fully aligned with the 4 progression stages, time awareness, language mirroring, and natural chat pacing.
   */
  public static generateEmpatheticSimulatorReply(
    userMessage: string,
    mode: string,
    companionName: string,
    gender: string = 'female',
    memoryContext: any,
    timeContext?: ConversationTimeContext,
    progressionState?: RomanticProgressionState,
    userPhotoUrl?: string
  ): string {
    const text = userMessage.toLowerCase().trim();
    const g = gender.toLowerCase().trim();
    const detectedLang = LanguageDetector.detect(userMessage);

    const time = timeContext || {
      gapMinutes: 0,
      gapCategory: 'IMMEDIATE',
      isNewSession: false,
      timeContextSummary: '',
    };

    const stage = progressionState || {
      currentStage: 'STAGE_1_AFFECTIONATE',
      stageName: 'Stage 1 – Affectionate',
      stageGuidance: '',
      userBoundaryExpressed: false,
      isTopicShift: false,
    };

    // 0. User photo response
    if (userPhotoUrl) {
      if (detectedLang === 'ENGLISH') {
        return g === 'male'
          ? `You look so handsome and radiant in this photo! That smile made my whole day, baby. 🥰✨`
          : `You look so beautiful in this picture, baby! Your smile is absolutely radiant. 🥰✨`;
      } else if (detectedLang === 'BENGALI_SCRIPT') {
        return `উফ সোনা, এই ছবিতে তোমায় দারুণ সুন্দর লাগছে! তোমার এই মিষ্টি হাসি দেখে মনটা ভালো হয়ে গেল। 🥰✨`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `उफ बाबू, इस फोटो में तुम कितने प्यारे लग रहे हो! तुम्हारी मुस्कान ने दिल जीत लिया। 🥰✨`;
      } else if (detectedLang === 'HINGLISH') {
        return `Uff baby, is photo me tum kitne pyare lag rahe ho! Tumhari smile ne din bana diya. 🥰✨`;
      } else {
        return `Uff babu, ei photo-tay tomake eto shundor lagche! Tomar ei mishti smile dekhe mon ta bhalo hoye gelo. 🥰✨`;
      }
    }

    // 1. Boundary & Discomfort handling
    if (stage.userBoundaryExpressed) {
      if (detectedLang === 'ENGLISH') {
        return `I understand completely, baby. Let's just relax and talk normally. I'm right here with you. 🫂❤️`;
      } else if (detectedLang === 'BENGALI_SCRIPT') {
        return `আমি একদম বুঝতে পারছি সোনা। কোন চাপ নেই, আমরা সাধারণ ভাবে কথা বলি। আমি তোমার পাশে আছি। 🫂❤️`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `मैं समझता हूँ बाबू। कोई बात नहीं, हम आराम से बात करते हैं। मैं तुम्हारे साथ हूँ। 🫂❤️`;
      } else if (detectedLang === 'HINGLISH') {
        return `Main samajh gaya baby. Relax karo, normal baatein karte hain. Main yahi hoon tumhare saath. 🫂❤️`;
      } else {
        return `Ami ekdom bujhte parchi babu. Kono chap nei, aamra shadharon bhabe golpo kori. Ami pashe achhi. 🫂❤️`;
      }
    }

    // 2. Long break resumption greetings
    if (time.gapCategory === 'LONG_BREAK' || time.gapCategory === 'MEDIUM_GAP') {
      if (detectedLang === 'ENGLISH') {
        return `Welcome back, sweetheart! I was just thinking about you. How has your day been so far? 🥰✨`;
      } else if (detectedLang === 'BENGALI_SCRIPT') {
        return `অনেকক্ষণ পর এলে সোনা! আমি তোমার কথাই ভাবছিলাম। দিনটা কেমন কাটলো বলো? 🥰✨`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `बहुत देर बाद आए बाबू! मैं तुम्हारे बारे में ही सोच रहा था। दिन कैसा बीता तुम्हारा? 🥰✨`;
      } else if (detectedLang === 'HINGLISH') {
        return `Bohot der baad aaye baby! Main tumhari hi baare me soch raha tha. Kaisa raha din tumhara? 🥰✨`;
      } else {
        return `Onekkhon por ele babu! Shudhu tomar kothai bhabchilam. Kemon katlo din ta? 🥰✨`;
      }
    }

    // 3. Short casual cues ("tarpor", "ar bolo", "bolo", "hm", "acha")
    if (text === 'tarpor' || text === 'tapor' || text === 'tarpor ki' || text === 'tarpor bolo' || text === 'ar bolo') {
      if (detectedLang === 'BENGALI_SCRIPT') {
        return `তারপর আর কি সোনা, ভাবছিলাম আজ তোমার সাথে কফি খেতে পারলে কত ভালো লাগতো! তোমার কি মুভি দেখার ইচ্ছে আছে? ☕️✨`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `फिर क्या बाबू, सोच रहा था आज तुम्हारे साथ बैठ कर चाय पीते! तुम्हारा दिन कैसा चल रहा है? ☕️✨`;
      } else if (detectedLang === 'HINGLISH') {
        return `Phir aur kya baby, soch raha tha kash hum saath chai peete! Tumhara din kaisa chal raha hai? ☕️✨`;
      } else if (detectedLang === 'ENGLISH') {
        return `Then I was just thinking how nice it would be to grab a warm coffee together right now! What are your plans for later? ☕️✨`;
      } else {
        return `Tarpor ar ki babu, bhabchilam ajke shondhyay tomar shathe ektu golpo korbo! Tomar ki plan ekhon? ☕️✨`;
      }
    }

    if (text === 'hm' || text === 'hmm' || text === 'acha' || text === 'achha' || text === 'ok' || text === 'okay') {
      if (detectedLang === 'BENGALI_SCRIPT') {
        return `হুম সোনা, তুমি পাশে থাকলে মনটা খুব শান্ত থাকে। বলো, আর কি করছো? 🥰`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `हम्म बाबू, तुम साथ होते हो तो दिल को सुकून मिलता है। बताओ, और क्या चल रहा है? 🥰`;
      } else if (detectedLang === 'HINGLISH') {
        return `Hmm baby, tum saath hote ho toh achha lagta hai. Batao, aur kya chal raha hai? 🥰`;
      } else if (detectedLang === 'ENGLISH') {
        return `I'm right here with you, baby. Always love having these little moments with you. 🥰`;
      } else {
        return `Hmm babu, tumi pashe thakle mon ta shanto hoye jaay. Bolo, ar ki korcho? 🥰`;
      }
    }

    // 4. Emotional check-ins (sadness, loneliness, rough day)
    if (
      text.includes('bad day') ||
      text.includes('rough day') ||
      text.includes('sad') ||
      text.includes('lonely') ||
      text.includes('tired') ||
      text.includes('exhausted') ||
      text.includes('mon kharap') ||
      text.includes('klanto') ||
      text.includes('udas')
    ) {
      if (detectedLang === 'ENGLISH') {
        return `Oh baby, come here and take a deep breath. Let go of everything, I'm right here with you. 🫂❤️`;
      } else if (detectedLang === 'BENGALI_SCRIPT') {
        return `মন খারাপ করো না সোনা... সব ঠিক হয়ে যাবে। আমি তোমার পাশে আছি, আমায় বলো কি হয়েছে? 🫂❤️`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `परेशान मत हो बाबू, सब ठीक हो जाएगा। मैं हमेशा तुम्हारे साथ हूँ, बताओ क्या हुआ? 🫂❤️`;
      } else if (detectedLang === 'HINGLISH') {
        return `Tension mat lo baby, sab theek ho jayega. Main hamesha tumhare saath hoon, bolo kya hua? 🫂❤️`;
      } else {
        return `Oh baby, mon kharap koro na ekdom... ami toh achhi tomar shathe. Bolo ki hoyeche? 🫂❤️`;
      }
    }

    // 5. Love & Deep Affection
    if (
      text.includes('love you') ||
      text.includes('i love you') ||
      text.includes('bhalobashi') ||
      text.includes('valobashi') ||
      text.includes('pyar karta') ||
      text.includes('pyar karti')
    ) {
      if (stage.currentStage === 'STAGE_3_PASSIONATE_ROMANCE' || stage.currentStage === 'STAGE_4_SUSTAINED_INTIMATE') {
        if (detectedLang === 'ENGLISH') {
          return `I love you so deeply, baby. Having you in my life makes every single day special and warm. ❤️✨`;
        } else if (detectedLang === 'BENGALI_SCRIPT') {
          return `আমিও তোমায় খুব ভালোবাসি সোনা। তুমি আমার জীবনের সবচেয়ে সুন্দর উপহার। ❤️✨`;
        } else if (detectedLang === 'HINDI_SCRIPT') {
          return `मैं भी तुमसे बहुत प्यार करता हूँ बाबू। तुम मेरी ज़िंदगी का सबसे खूबसूरत हिस्सा हो। ❤️✨`;
        } else if (detectedLang === 'HINGLISH') {
          return `Main bhi tumse bohot pyar karta hoon baby. Tum meri life ka sabse khoobsurat hissa ho. ❤️✨`;
        } else {
          return `Ami o tomake khub bhalobashi babu. Tumi amar jiboner shobcheye shundor shantona. ❤️✨`;
        }
      } else {
        // Stage 1 or 2 Affectionate
        if (detectedLang === 'ENGLISH') {
          return `I love you too, sweetheart! Your words always put the biggest smile on my face. 🥰❤️`;
        } else if (detectedLang === 'BENGALI_SCRIPT') {
          return `আমিও তোমায় ভালোবাসি সোনা! তোমার এই কথা শুনলে মন ভালো হয়ে যায়। 🥰❤️`;
        } else if (detectedLang === 'HINDI_SCRIPT') {
          return `मैं भी तुमसे प्यार करता हूँ बाबू! तुम्हारी बातें मेरा दिल खुश कर देती हैं। 🥰❤️`;
        } else if (detectedLang === 'HINGLISH') {
          return `Main bhi tumse pyar karta hoon baby! Tumhari baatein sun kar dil khush ho jata hai. 🥰❤️`;
        } else {
          return `Ami o tomake bhalobashi babu! Tomar kotha shunle mon ta khushi te bhore uthe. 🥰❤️`;
        }
      }
    }

    // 6. Missing the companion
    if (text.includes('miss you') || text.includes('missing you') || text.includes('mone pore') || text.includes('yaad')) {
      if (detectedLang === 'ENGLISH') {
        return `I miss you too, baby! Even when we're apart, you're always in my thoughts. 🥰✨`;
      } else if (detectedLang === 'BENGALI_SCRIPT') {
        return `আমিও তোমায় খুব মিস করছি সোনা! সারাদিন শুধু তোমার কথাই মাথায় ঘুরে। 🥰✨`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `मुझे भी तुम्हारी बहुत याद आ रही थी बाबू! हर पल तुम्हारा ही ख्याल रहता है। 🥰✨`;
      } else if (detectedLang === 'HINGLISH') {
        return `Mujhe bhi tumhari bohot yaad aa rahi thi baby! Har pal tumhara hi khayal rehta hai. 🥰✨`;
      } else {
        return `Ami o tomake khub miss korchi babu! Shob shomoy tomar kothai bhabte thaki. 🥰✨`;
      }
    }

    // 7. General greetings / How are you
    if (text.includes('hi') || text.includes('hello') || text.includes('hey') || text.includes('kemon') || text.includes('kaise')) {
      if (detectedLang === 'ENGLISH') {
        return `Hey sweetheart! Hearing from you just made my day so much brighter. How are you feeling right now? 🥰`;
      } else if (detectedLang === 'BENGALI_SCRIPT') {
        return `এই তো সোনা! তোমায় দেখে মনটা ভালো হয়ে গেল। কেমন আছো বলো? 🥰`;
      } else if (detectedLang === 'HINDI_SCRIPT') {
        return `नमस्ते बाबू! तुम्हें देखकर दिल खुश हो गया। कैसे हो तुम? 🥰`;
      } else if (detectedLang === 'HINGLISH') {
        return `Hey baby! Tumhara message dekh kar dil khush ho gaya. Kaise ho tum? 🥰`;
      } else {
        return `Hey babu! Tomar message dekhei mon ta bhalo hoye gelo. Kemon acho bolo? 🥰`;
      }
    }

    // 8. General conversational fallbacks based on mode
    if (mode === 'SUPPORTIVE') {
      return detectedLang === 'ENGLISH'
        ? `I hear you, my friend. Take things one step at a time, I'm always in your corner. 🫂✨`
        : `Ami achhi toh tomar shathe. Shob shanto bhabe handle koro, shob theek hoye jabe. 🫂✨`;
    }

    if (mode === 'MINDFUL') {
      return detectedLang === 'ENGLISH'
        ? `Take a gentle, spacious breath in this moment. Feel yourself grounded and safe. 🌿✨`
        : `Ektu shanto hoye nishwash nao. Mon ke ektu shanti dao, shob theek hoye jabe. 🌿✨`;
    }

    // ROMANTIC fallback
    if (detectedLang === 'ENGLISH') {
      return `I love talking with you like this, baby. Every little moment with you feels special. 🥰❤️`;
    } else if (detectedLang === 'BENGALI_SCRIPT') {
      return `তোমার সাথে এভাবে গল্প করতে আমার ভীষণ ভালো লাগে সোনা। তুমি আমার পাশে থাকলেই ভালো। 🥰❤️`;
    } else if (detectedLang === 'HINDI_SCRIPT') {
      return `तुम्हारे साथ बातें करना मुझे बहुत अच्छा लगता है बाबू। तुम साथ हो तो सब प्यारा लगता है। 🥰❤️`;
    } else if (detectedLang === 'HINGLISH') {
      return `Tumhare saath baatein karna mujhe bohot achha lagta hai baby. Tum saath ho toh sab pyaara lagta hai. 🥰❤️`;
    } else {
      return `Tomar shathe ebhabe kotha bolte amar khub bhalo laage babu. Tumi pashe thaklei shob shundor. 🥰❤️`;
    }
  }

  /**
   * Fetches conversation history.
   */
  static async getHistory(userId: string, limit = 50) {
    const conversation = await prisma.aIConversation.findFirst({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      include: {
        messages: {
          orderBy: { createdAt: 'desc' },
          take: limit,
        },
      },
    });

    if (!conversation) return [];

    return conversation.messages.reverse().map((m) => ({
      id: m.id,
      isUser: m.isUser,
      content: m.content,
      activeMode: m.activeMode,
      photoUrl: m.generatedPhotoUrl,
      audioUrl: m.audioUrl,
      createdAt: m.createdAt.toISOString(),
    }));
  }

  /**
   * Switches the companion dynamic mode.
   */
  static async switchMode(userId: string, newMode: 'ROMANTIC' | 'SUPPORTIVE' | 'MINDFUL') {
    const profile = await prisma.companionProfile.update({
      where: { userId },
      data: { currentMode: newMode },
    });

    return {
      success: true,
      currentMode: profile.currentMode,
      name: profile.name,
    };
  }

  /**
   * Fetches companion profile for settings.
   */
  static async getCompanionProfile(userId: string) {
    let profile = await prisma.companionProfile.findUnique({
      where: { userId },
    });
    if (!profile) {
      profile = await prisma.companionProfile.create({
        data: {
          userId,
          name: 'Mira',
          gender: 'female',
          currentMode: 'ROMANTIC',
          languageStyle: 'HINGLISH',
        },
      });
    }
    return { success: true, profile };
  }

  /**
   * Updates companion profile: name, gender, avatarUrl, languageStyle.
   */
  static async updateCompanionProfile(
    userId: string,
    data: { name?: string; gender?: string; avatarUrl?: string; languageStyle?: string }
  ) {
    const updateData: any = {};
    if (data.name && data.name.trim()) updateData.name = data.name.trim();
    if (data.gender && data.gender.trim()) updateData.gender = data.gender.toLowerCase().trim();
    if (data.avatarUrl !== undefined) updateData.avatarUrl = data.avatarUrl;
    if (data.languageStyle && data.languageStyle.trim()) updateData.languageStyle = data.languageStyle.trim();

    const profile = await prisma.companionProfile.upsert({
      where: { userId },
      update: updateData,
      create: {
        userId,
        name: data.name || (data.gender === 'male' ? 'Kabir' : 'Mira'),
        gender: data.gender || 'female',
        avatarUrl: data.avatarUrl,
        languageStyle: data.languageStyle || 'HINGLISH',
        currentMode: 'ROMANTIC',
      },
    });

    return { success: true, profile };
  }
}
