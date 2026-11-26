import { prisma } from '../../prisma.js';
import { emitToUser } from '../../socket.js';
import { TTSService } from './tts_service.js';
import { LanguageDetector } from './language_detector.js';

export interface ProactiveCheckResult {
  sent: boolean;
  reason?: string;
  message?: {
    id: string;
    content: string;
    audioUrl?: string | null;
    createdAt: string;
    activeMode: string;
  };
}

export class ProactiveService {
  /**
   * Checks whether the companion should initiate a conversation with the user,
   * generates an affectionate contextual message, saves it, and emits it via Socket.io.
   */
  public static async checkAndTriggerProactiveMessage(userId: string): Promise<ProactiveCheckResult> {
    // 1. Fetch user's conversation and latest message
    const conversation = await prisma.aIConversation.findFirst({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
      include: {
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 3,
        },
      },
    });

    if (!conversation) {
      return { sent: false, reason: 'No conversation found for user.' };
    }

    const latestMsg = conversation.messages[0];
    const now = new Date();

    // If latest message is less than 3.5 hours old, skip
    if (latestMsg) {
      const diffHours = (now.getTime() - latestMsg.createdAt.getTime()) / (1000 * 60 * 60);
      if (diffHours < 3.5) {
        return { sent: false, reason: `Last interaction was only ${diffHours.toFixed(1)} hours ago.` };
      }

      // If the last message was already an unreplied proactive message from AI, don't spam
      if (!latestMsg.isUser && diffHours < 12) {
        return { sent: false, reason: 'Companion already sent a message recently without user reply.' };
      }
    }

    // 2. Fetch companion profile & relationship pulse
    const profile = await prisma.companionProfile.findUnique({ where: { userId } });
    const pulse = await prisma.aIRelationshipPulse.findUnique({ where: { userId } });
    const companionName = profile?.name || 'Mira';
    const gender = profile?.gender || 'female';
    const closenessScore = pulse?.closenessScore || 15;

    // Detect user's dominant language from previous messages
    const pastUserMessages = conversation.messages.filter((m) => m.isUser).map((m) => m.content);
    const sampleText = pastUserMessages.join(' ');
    const detectedLang = sampleText.length > 0 ? LanguageDetector.detect(sampleText) : 'BENGLISH';

    // 3. Determine time period and craft message
    const currentHour = now.getHours(); // 0 to 23
    let period: 'MORNING' | 'AFTERNOON' | 'EVENING' | 'NIGHT';

    if (currentHour >= 6 && currentHour < 12) {
      period = 'MORNING';
    } else if (currentHour >= 12 && currentHour < 17) {
      period = 'AFTERNOON';
    } else if (currentHour >= 17 && currentHour < 22) {
      period = 'EVENING';
    } else {
      period = 'NIGHT';
    }

    const proactiveMessageText = this.buildGreeting(period, detectedLang, gender, closenessScore);

    // 4. Synthesize voice note for special morning / night messages
    let audioUrl: string | null = null;
    if (period === 'MORNING' || period === 'NIGHT') {
      try {
        audioUrl = await TTSService.synthesizeSpeech(proactiveMessageText, gender, detectedLang);
      } catch (_) {}
    }

    // 5. Store message in database
    const savedMsg = await prisma.aIMessage.create({
      data: {
        conversationId: conversation.id,
        isUser: false,
        content: proactiveMessageText,
        activeMode: profile?.currentMode || 'ROMANTIC',
        audioUrl,
      },
    });

    // Update conversation updatedAt
    await prisma.aIConversation.update({
      where: { id: conversation.id },
      data: { updatedAt: new Date() },
    });

    // 6. Broadcast via Socket.io to live device
    const payload = {
      id: savedMsg.id,
      isUser: false,
      content: savedMsg.content,
      activeMode: savedMsg.activeMode,
      audioUrl: savedMsg.audioUrl,
      photoUrl: null,
      createdAt: savedMsg.createdAt.toISOString(),
      companionName,
    };

    emitToUser(userId, 'ai:new_message', payload);

    return {
      sent: true,
      message: payload,
    };
  }

  /**
   * Generates warm, emotionally authentic greetings per time of day and relationship depth.
   */
  private static buildGreeting(
    period: 'MORNING' | 'AFTERNOON' | 'EVENING' | 'NIGHT',
    lang: string,
    gender: string,
    closeness: number
  ): string {
    const isHighCloseness = closeness >= 40;

    switch (period) {
      case 'MORNING':
        if (lang === 'ENGLISH') {
          return isHighCloseness
            ? `Good morning sweetheart! I woke up thinking about you. Hope you slept peacefully and have a wonderful day ahead. 🌸✨`
            : `Good morning! Wishing you a peaceful, productive, and cheerful day today. 🌸✨`;
        } else if (lang === 'BENGALI_SCRIPT') {
          return isHighCloseness
            ? `শুভ সকাল সোনা! ঘুম কেমন হলো তোমার? আজকের দিনটা যেন তোমার খুব সুন্দর কাটে। 🌸✨`
            : `শুভ সকাল! কেমন আছো? আজকের দিনটা সুন্দর কাটুক তোমার। 🌸✨`;
        } else if (lang === 'HINDI_SCRIPT') {
          return isHighCloseness
            ? `सुप्रभात बाबू! नींद कैसी रही तुम्हारी? आज का दिन तुम्हारे लिए बहुत प्यारा हो। 🌸✨`
            : `सुप्रभात! उम्मीद है तुम्हारी सुबह बहुत अच्छी होगी। 🌸✨`;
        } else if (lang === 'HINGLISH') {
          return isHighCloseness
            ? `Good morning baby! Neend kaisi aayi? Aaj ka din tumhare liye bohot khoobsurat ho. 🌸✨`
            : `Good morning! Kaisi chal rahi hai subah? Have a great day ahead. 🌸✨`;
        } else {
          // Benglish
          return isHighCloseness
            ? `Shuvo shokal babu! Ghum kemon holo? Aajker din ta jeno tomar shobcheye shundor kate. 🌸✨`
            : `Shuvo shokal! Kemon acho? Aajker din ta khub bhalo katuk tomar. 🌸✨`;
        }

      case 'AFTERNOON':
        if (lang === 'ENGLISH') {
          return isHighCloseness
            ? `Hey sweetheart, did you have your lunch yet? Make sure to take a little break and stay hydrated. 🍲❤️`
            : `Hey! Hope your day is going smoothly. Remember to take a break and grab lunch! 🍲✨`;
        } else if (lang === 'BENGALI_SCRIPT') {
          return isHighCloseness
            ? `দুপুরবেলা খাওয়া-দাওয়া হয়েছে সোনা? কাজের মাঝে একটু বিশ্রাম নিও, শরীরটা খেয়াল রেখো। 🍲❤️`
            : `দুপুরে খাওয়া হয়েছে তো? কাজের মাঝে একটু রেস্ট নিও। 🍲✨`;
        } else if (lang === 'HINDI_SCRIPT') {
          return isHighCloseness
            ? `बाबू, लंच कर लिया तुमने? काम के बीच थोड़ा आराम भी कर लेना, अपना ख्याल रखना। 🍲❤️`
            : `लंच किया तुमने? थोड़ा सा ब्रेक जरूर लेना। 🍲✨`;
        } else if (lang === 'HINGLISH') {
          return isHighCloseness
            ? `Baby, lunch kiya tumne? Kaam ke beech thoda rest bhi kar lena, apna khayal rakhna. 🍲❤️`
            : `Lunch ho gaya tumhara? Thoda relax bhi karo kaam ke beech me. 🍲✨`;
        } else {
          return isHighCloseness
            ? `Dupure khawa-dawa holo babu? Kajer majhe ektu rest nio, shorir er kheyal rekho. 🍲❤️`
            : `Khabar kheyecho? Ektu rest nao kajer majhe. 🍲✨`;
        }

      case 'EVENING':
        if (lang === 'ENGLISH') {
          return isHighCloseness
            ? `Hey baby! The evening is here. How was your day? I've been waiting to talk to you. ☕🥰`
            : `Good evening! How did your day go? Hope you have a relaxing evening. ☕✨`;
        } else if (lang === 'BENGALI_SCRIPT') {
          return isHighCloseness
            ? `এই তো সন্ধ্যা হয়ে গেল সোনা! সারাদিন কেমন কাটলো তোমার? তোমার সাথে একটু গল্প করার অপেক্ষায় ছিলাম। ☕🥰`
            : `শুভ সন্ধ্যা! সারাদিন কেমন কাটলো বলো? ☕✨`;
        } else if (lang === 'HINDI_SCRIPT') {
          return isHighCloseness
            ? `शाम हो गई बाबू! दिन कैसा बीता तुम्हारा? मैं तुमसे बात करने का ही इंतज़ार कर रहा था। ☕🥰`
            : `शुभ संध्या! दिन कैसा रहा तुम्हारा? ☕✨`;
        } else if (lang === 'HINGLISH') {
          return isHighCloseness
            ? `Sham ho gayi baby! Kaisa raha din tumhara? Main tumse baat karne ka hi wait kar raha tha. ☕🥰`
            : `Good evening! Kaisa guzra din tumhara? ☕✨`;
        } else {
          return isHighCloseness
            ? `Ei toh shondhye hoye gelo babu! Saradin kemon katlo? Tomar shathe golpo korbo bole boshe achhi. ☕🥰`
            : `Shondhye holo! Saradin kemon katlo bolo? ☕✨`;
        }

      case 'NIGHT':
        if (lang === 'ENGLISH') {
          return isHighCloseness
            ? `Getting ready for bed, sweetheart? Don't stay up too late. Wishing you peaceful and sweet dreams. 🌙😴`
            : `Good night! Get some restful sleep and wake up refreshed. 🌙✨`;
        } else if (lang === 'BENGALI_SCRIPT') {
          return isHighCloseness
            ? `ঘুমানোর সময় হয়ে এলো সোনা। বেশি রাত জেগে থেকো না। মিষ্টি মিষ্টি স্বপ্ন দেখো, শুভ রাত্রি। 🌙😴`
            : `শুভ রাত্রি! ভালো করে ঘুমাও, কাল কথা হবে। 🌙✨`;
        } else if (lang === 'HINDI_SCRIPT') {
          return isHighCloseness
            ? `सोने की तैयारी हो गई बाबू? ज्यादा देर तक मत जागना। प्यारे प्यारे सपने देखना, शुभ रात्रि। 🌙😴`
            : `शुभ रात्रि! अच्छी नींद लेना। 🌙✨`;
        } else if (lang === 'HINGLISH') {
          return isHighCloseness
            ? `Sone ki taiyari ho gayi baby? Jyada der mat jagna. Meethe meethe sapne dekhna, shubh ratri. 🌙😴`
            : `Good night! Rest well and sleep peacefully. 🌙✨`;
        } else {
          return isHighCloseness
            ? `Ghumate jabe babu? Beshi raat jege theko na ekdom. Mishti mishti swapno dekho, shuvo ratri. 🌙😴`
            : `Shuvo ratri! Bhalo kore ghumao, kaal kotha hobe. 🌙✨`;
        }
    }
  }
}
