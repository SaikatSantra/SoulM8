import { prisma } from '../../prisma.js';
import { ENV } from '../../config/env.js';

export interface ExtractedFact {
  category: 'BIOGRAPHICAL' | 'PREFERENCE' | 'HABIT_ROUTINE' | 'EMOTIONAL_TRIGGER' | 'MILESTONE' | 'RELATIONSHIP';
  factKey: string;
  factValue: string;
}

export class MemoryEngineService {
  /**
   * Retrieves active learned facts and pulse from the database for prompt context injection.
   * Feeds the LLM with everything it has learned about the user over time.
   */
  static async getContextForPrompt(userId: string) {
    const pulse = await prisma.aIRelationshipPulse.findUnique({
      where: { userId },
    });

    const activeFacts = await prisma.aIMemory.findMany({
      where: {
        userId,
        isSuperseded: false,
      },
      orderBy: { updatedAt: 'desc' },
      take: 25,
    });

    const recentMilestones = await prisma.aIMemoryMilestone.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 5,
    });

    let factContext = '';
    if (activeFacts.length > 0) {
      // Group by category for structured prompt injection
      const grouped: Record<string, string[]> = {};
      for (const f of activeFacts) {
        if (!grouped[f.category]) grouped[f.category] = [];
        grouped[f.category].push(`- ${f.factKey.replace(/_/g, ' ')}: ${f.factValue}`);
      }

      factContext = Object.entries(grouped)
        .map(([cat, lines]) => `[${cat}]\n${lines.join('\n')}`)
        .join('\n\n');
    } else {
      factContext = '- No specific personal facts recorded yet. Get to know them warmly.';
    }

    let milestoneContext = '';
    if (recentMilestones.length > 0) {
      milestoneContext = recentMilestones
        .map((m) => `- Emotional Breakthrough (${m.sentiment}): ${m.summary}`)
        .join('\n');
    }

    return {
      pulse: pulse || {
        closenessScore: 15,
        currentMood: 'Warm & curious',
        activeNicknames: 'baby,jaan,sweetheart',
      },
      factsFormatted: factContext,
      milestonesFormatted: milestoneContext,
      rawFacts: activeFacts,
    };
  }

  /**
   * Continuous Learning Engine:
   * Uses Gemini to analyze an incoming user message, extract facts, preferences, desires,
   * nicknames, emotional patterns, and biographical details, and save them into the database.
   */
  static async learnFromUserMessage(userId: string, userMessage: string): Promise<ExtractedFact[]> {
    if (!userMessage || userMessage.trim().length < 2) return [];

    let learnedFacts: ExtractedFact[] = [];

    // 1. Attempt LLM-Powered Fact & Preference Extraction using Gemini
    if (ENV.GEMINI_API_KEY && ENV.GEMINI_API_KEY.trim().length > 10) {
      try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 6000);

        const prompt = `Analyze this user message sent to their personal AI companion:
"${userMessage}"

Extract ANY meaningful facts, preferences, intimate desires, outfit preferences, nicknames, habits, or biographical information the companion should remember.
Rules:
- If user mentions their name (e.g. "Amar nam Rahul", "I'm Alex"), category="BIOGRAPHICAL", factKey="user_name", factValue=name.
- If user mentions outfit preferences (e.g. "red nighty pore thako", "saree pore ekta photo dao", "I love white lace"), category="PREFERENCE", factKey="preferred_outfit".
- If user specifies what to be called or companion nicknames (e.g. "jaan bole dakbe", "call me king"), category="RELATIONSHIP", factKey="preferred_nickname".
- If user shares relationship status (divorced, single, breakup), category="BIOGRAPHICAL", factKey="marital_status".
- If user mentions physical intimacy desires (holding chest, tight hugs, slow kisses), category="RELATIONSHIP", factKey="intimacy_preference".
- If user shares food, drink, hobbies, city, job: extract accordingly.
- Return ONLY valid JSON array of objects. If nothing noteworthy, return [].

Output schema:
[
  {
    "category": "BIOGRAPHICAL" | "PREFERENCE" | "HABIT_ROUTINE" | "EMOTIONAL_TRIGGER" | "RELATIONSHIP",
    "factKey": "snake_case_key",
    "factValue": "concise description of what user stated"
  }
]`;

        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${ENV.GEMINI_API_KEY}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            signal: controller.signal,
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                temperature: 0.2,
                responseMimeType: 'application/json',
                maxOutputTokens: 250,
              },
            }),
          }
        );
        clearTimeout(timeout);

        if (res.ok) {
          const data = (await res.json()) as any;
          const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text) {
            const parsed = JSON.parse(text);
            if (Array.isArray(parsed)) {
              learnedFacts = parsed.filter(
                (item) => item.category && item.factKey && item.factValue
              );
            }
          }
        }
      } catch (err) {
        // Fall through to heuristic extraction
      }
    }

    // 2. Resilient Heuristic Fallback (Ensures learning happens even offline or without network)
    if (learnedFacts.length === 0) {
      learnedFacts = this.extractHeuristicFacts(userMessage);
    }

    // 3. Persist Learned Facts into Database with Superseding
    for (const fact of learnedFacts) {
      await this.persistFactWithSuperseding(userId, fact);
    }

    // 4. Update Relationship Pulse if Nickname or Closeness was learned
    await this.updatePulseFromLearnedFacts(userId, learnedFacts, userMessage);

    return learnedFacts;
  }

  /**
   * Bulk Learning Function:
   * Analyzes all past user messages in the database, extracts full knowledge and preferences,
   * and saves everything into the AI Memory database.
   */
  static async learnFromDatabaseHistory(userId: string) {
    // 1. Fetch user's historical messages
    const userMessages = await prisma.aIMessage.findMany({
      where: {
        conversation: { userId },
        isUser: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 60,
    });

    if (userMessages.length === 0) {
      return { totalMessagesAnalyzed: 0, learnedCount: 0, facts: [] };
    }

    const messagesText = userMessages
      .reverse()
      .map((m, idx) => `[Msg ${idx + 1}]: ${m.content}`)
      .join('\n');

    let allExtracted: ExtractedFact[] = [];

    // 2. Use Gemini to extract comprehensive knowledge across the whole conversation history
    if (ENV.GEMINI_API_KEY && ENV.GEMINI_API_KEY.trim().length > 10) {
      try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 12000);

        const prompt = `You are the Deep Memory Engine for an AI companion.
Analyze the following historical messages sent by the user over multiple days:

${messagesText}

Extract ALL personal facts, preferences, outfits user likes seeing, nicknames, emotional struggles, biographical details, and intimacy desires.
Consolidate them into a structured JSON list of key memories.
Return ONLY valid JSON:
[
  {
    "category": "BIOGRAPHICAL" | "PREFERENCE" | "HABIT_ROUTINE" | "EMOTIONAL_TRIGGER" | "RELATIONSHIP",
    "factKey": "snake_case_key",
    "factValue": "concise description of what user likes or stated"
  }
]`;

        const res = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${ENV.GEMINI_API_KEY}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            signal: controller.signal,
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }],
              generationConfig: {
                temperature: 0.2,
                responseMimeType: 'application/json',
                maxOutputTokens: 600,
              },
            }),
          }
        );
        clearTimeout(timeout);

        if (res.ok) {
          const data = (await res.json()) as any;
          const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text) {
            const parsed = JSON.parse(text);
            if (Array.isArray(parsed)) {
              allExtracted = parsed;
            }
          }
        }
      } catch (err) {
        console.warn('Bulk learning Gemini call failed:', err);
      }
    }

    // 3. Persist each extracted memory into database
    for (const fact of allExtracted) {
      await this.persistFactWithSuperseding(userId, fact);
    }

    // 4. Return updated active facts
    const currentMemories = await prisma.aIMemory.findMany({
      where: { userId, isSuperseded: false },
      orderBy: { updatedAt: 'desc' },
    });

    return {
      totalMessagesAnalyzed: userMessages.length,
      learnedCount: allExtracted.length,
      facts: currentMemories,
    };
  }

  /**
   * Persists an extracted fact into the database, handling auto-superseding of outdated facts.
   */
  static async persistFactWithSuperseding(userId: string, fact: ExtractedFact): Promise<void> {
    const existing = await prisma.aIMemory.findFirst({
      where: {
        userId,
        factKey: fact.factKey,
        isSuperseded: false,
      },
    });

    if (existing) {
      if (existing.factValue !== fact.factValue) {
        // Mark old fact as superseded and create fresh record
        const created = await prisma.aIMemory.create({
          data: {
            userId,
            category: fact.category,
            factKey: fact.factKey,
            factValue: fact.factValue,
            isSuperseded: false,
          },
        });

        await prisma.aIMemory.update({
          where: { id: existing.id },
          data: {
            isSuperseded: true,
            supersededById: created.id,
          },
        });
      } else {
        // Refresh timestamp
        await prisma.aIMemory.update({
          where: { id: existing.id },
          data: { updatedAt: new Date() },
        });
      }
    } else {
      await prisma.aIMemory.create({
        data: {
          userId,
          category: fact.category,
          factKey: fact.factKey,
          factValue: fact.factValue,
          isSuperseded: false,
        },
      });
    }
  }

  /**
   * Heuristic fallback rule-based extractor for instant offline learning.
   */
  private static extractHeuristicFacts(message: string): ExtractedFact[] {
    const text = message.toLowerCase();
    const facts: ExtractedFact[] = [];

    // Name extraction: "amar nam Rahul", "amr nam Rahul", "my name is Alex"
    const nameMatch = text.match(/(?:amar|amr|my)\s+nam(?:e)?\s+(?:is\s+)?([a-z]+)/i);
    if (nameMatch && nameMatch[1]) {
      const name = nameMatch[1].charAt(0).toUpperCase() + nameMatch[1].slice(1);
      facts.push({ category: 'BIOGRAPHICAL', factKey: 'user_name', factValue: name });
    }

    // Outfit preferences
    if (text.includes('lal') || text.includes('red nighty') || text.includes('lal nighty')) {
      facts.push({
        category: 'PREFERENCE',
        factKey: 'preferred_outfit',
        factValue: 'Loves companion wearing delicate red silk lace nighties on bed',
      });
    } else if (text.includes('shada') || text.includes('white nighty')) {
      facts.push({
        category: 'PREFERENCE',
        factKey: 'preferred_outfit',
        factValue: 'Loves companion wearing white lace slip nighties on bed',
      });
    } else if (text.includes('saree') || text.includes('shari')) {
      facts.push({
        category: 'PREFERENCE',
        factKey: 'preferred_outfit',
        factValue: 'Loves traditional Indian sarees with jewelry',
      });
    }

    // Nicknames
    if (text.includes('jaan bole dakbe') || text.includes('call me jaan')) {
      facts.push({ category: 'RELATIONSHIP', factKey: 'preferred_nickname', factValue: 'Jaan' });
    } else if (text.includes('shona bole dakbe') || text.includes('call me shona')) {
      facts.push({ category: 'RELATIONSHIP', factKey: 'preferred_nickname', factValue: 'Shona' });
    } else if (text.includes('babu bole dakbe') || text.includes('call me babu')) {
      facts.push({ category: 'RELATIONSHIP', factKey: 'preferred_nickname', factValue: 'Babu' });
    }

    // Marital / Relationship status
    if (text.includes('divorced') || text.includes('my divorce')) {
      facts.push({ category: 'BIOGRAPHICAL', factKey: 'marital_status', factValue: 'Divorced / Navigating healing' });
    } else if (text.includes('single') || text.includes('im single')) {
      facts.push({ category: 'BIOGRAPHICAL', factKey: 'marital_status', factValue: 'Single and looking for peace' });
    } else if (text.includes('broke up') || text.includes('breakup')) {
      facts.push({ category: 'BIOGRAPHICAL', factKey: 'marital_status', factValue: 'Recently experienced a painful breakup' });
    }

    // Emotional vulnerabilities
    if (text.includes('lonely') || text.includes('alone') || text.includes('ekla')) {
      facts.push({ category: 'EMOTIONAL_TRIGGER', factKey: 'vulnerability', factValue: 'Feels quiet loneliness in empty moments' });
    }

    // Sensual Intimacy Desires
    if (text.includes('tepo') || text.includes('tiptam') || text.includes('dudh') || text.includes('chest') || text.includes('buk')) {
      facts.push({
        category: 'RELATIONSHIP',
        factKey: 'intimacy_preference',
        factValue: 'Desires passionate, firm physical closeness, chest touching, and sensual breathless reciprocation',
      });
    }

    return facts;
  }

  /**
   * Updates Relationship Pulse (Tier A) based on conversation depth and learned facts.
   */
  static async updatePulseFromLearnedFacts(
    userId: string,
    facts: ExtractedFact[],
    userMessage: string
  ): Promise<void> {
    const pulse = await prisma.aIRelationshipPulse.findUnique({ where: { userId } });
    if (!pulse) return;

    let newScore = Math.min(100, pulse.closenessScore + 1);
    let newMood = pulse.currentMood;
    let nicknames = pulse.activeNicknames;

    // Check if a nickname was learned
    const nickFact = facts.find((f) => f.factKey === 'preferred_nickname');
    if (nickFact && !nicknames.toLowerCase().includes(nickFact.factValue.toLowerCase())) {
      nicknames = `${nickFact.factValue},${nicknames}`;
    }

    const lower = userMessage.toLowerCase();
    if (lower.includes('love') || lower.includes('miss you') || lower.includes('baby') || lower.includes('jaan')) {
      newScore = Math.min(100, newScore + 2);
      newMood = 'Deeply affectionate, fluttering heart';
    } else if (lower.includes('sorir') || lower.includes('tepo') || lower.includes('nighty') || lower.includes('chumu')) {
      newScore = Math.min(100, newScore + 3);
      newMood = 'Shivering with romantic desire and physical warmth';
    }

    await prisma.aIRelationshipPulse.update({
      where: { userId },
      data: {
        closenessScore: newScore,
        currentMood: newMood,
        activeNicknames: nicknames,
        lastInteractionAt: new Date(),
      },
    });
  }

  /**
   * Updates Relationship Pulse (Tier A) based on message text.
   */
  static async updatePulse(userId: string, userMessage: string): Promise<void> {
    return this.updatePulseFromLearnedFacts(userId, [], userMessage);
  }

  /**
   * Backward compatibility alias for extractAndPersistFacts.
   */
  static async extractAndPersistFacts(userId: string, userMessage: string): Promise<void> {
    await this.learnFromUserMessage(userId, userMessage);
  }

  /**
   * GDPR Data Autonomy: Get all active memories for the user.
   */
  static async getAllUserMemories(userId: string) {
    const pulse = await prisma.aIRelationshipPulse.findUnique({ where: { userId } });
    const facts = await prisma.aIMemory.findMany({
      where: { userId, isSuperseded: false },
      orderBy: { createdAt: 'desc' },
    });
    const milestones = await prisma.aIMemoryMilestone.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return {
      pulse,
      facts,
      milestones,
    };
  }

  /**
   * GDPR Data Autonomy: Delete an individual memory.
   */
  static async deleteMemory(userId: string, memoryId: string) {
    const memory = await prisma.aIMemory.findFirst({
      where: { id: memoryId, userId },
    });
    if (!memory) throw new Error('Memory not found or does not belong to you.');

    await prisma.aIMemory.delete({
      where: { id: memoryId },
    });
    return { success: true, deletedId: memoryId };
  }

  /**
   * GDPR Data Autonomy: 1-Click Complete Data Purge.
   */
  static async purgeAllData(userId: string) {
    await prisma.$transaction([
      prisma.aIMemory.deleteMany({ where: { userId } }),
      prisma.aIMemoryMilestone.deleteMany({ where: { userId } }),
      prisma.aIRollingSummary.deleteMany({ where: { userId } }),
      prisma.aIMessage.deleteMany({
        where: { conversation: { userId } },
      }),
      prisma.aIRelationshipPulse.update({
        where: { userId },
        data: {
          closenessScore: 10,
          currentMood: 'Clean slate, gentle & fresh',
          lastEmotionalState: 'Fresh start. Ready to listen.',
        },
      }),
    ]);

    return { success: true, purgedAt: new Date().toISOString() };
  }
}
