export type SupportedLanguage =
  | 'ENGLISH'
  | 'BENGALI_SCRIPT'
  | 'BENGLISH'
  | 'HINDI_SCRIPT'
  | 'HINGLISH'
  | 'OTHER';

export class LanguageDetector {
  /**
   * Detects the language/script of the user's chat message.
   */
  static detect(text: string): SupportedLanguage {
    if (!text || text.trim().length === 0) return 'ENGLISH';
    const clean = text.trim();

    // 1. Check for Bengali script unicode (\u0980 - \u09FF)
    if (/[\u0980-\u09FF]/.test(clean)) {
      return 'BENGALI_SCRIPT';
    }

    // 2. Check for Devanagari / Hindi script unicode (\u0900 - \u097F)
    if (/[\u0900-\u097F]/.test(clean)) {
      return 'HINDI_SCRIPT';
    }

    const lower = clean.toLowerCase();
    const words = lower.split(/[^a-zA-Z0-9]+/).filter(Boolean);

    // 3. Benglish (Romanized Bengali) markers
    const bengaliRomanMarkers = new Set([
      'tumi', 'tomar', 'amake', 'amr', 'amar', 'kemon', 'acho', 'achho', 'achhi', 'achi',
      'bhalobashi', 'valobashi', 'bhalobaso', 'valobaso', 'korcho', 'korchho', 'korche',
      'hobe', 'ekhon', 'kotha', 'katha', 'bolo', 'bolchi', 'babu', 'shona', 'komor', 'thot',
      'chumu', 'chumo', 'buk', 'buke', 'buker', 'hate', 'hater', 'kno', 'keno', 'kache',
      'shorir', 'nishwash', 'nishwas', 'joriye', 'dhoro', 'chepe', 'porecho', 'dekhte',
      'chai', 'jani', 'khub', 'shundor', 'shari', 'saree', 'mishti', 'hote', 'parbe',
      'ekla', 'mon', 'mone', 'bichhana', 'ghumiye', 'pathao', 'pathalam', 'dao', 'r',
      'kichu', 'bolte', 'ichhe', 'ichha', 'thakbe', 'charbo', 'pagol'
    ]);

    // 4. Hinglish (Romanized Hindi) markers
    const hindiRomanMarkers = new Set([
      'tum', 'tumhara', 'tumhe', 'aap', 'aapko', 'mujhe', 'mera', 'meri', 'mere', 'kya',
      'kar', 'rahe', 'rahi', 'raha', 'ho', 'hai', 'hain', 'kahan', 'kaise', 'kaisi',
      'kaisa', 'pyar', 'mohabbat', 'bahut', 'bohot', 'dil', 'batao', 'suno', 'pas',
      'paas', 'chahiye', 'gale', 'lagao', 'karo', 'karegi', 'karega', 'achha', 'accha',
      'nahi', 'nhi', 'kyun', 'kyu', 'dekh', 'dekho', 'bhejo', 'tasveer', 'khubsurat',
      'sundar', 'khayal', 'baat', 'karni', 'karna', 'shona', 'babu'
    ]);

    let bengaliScore = 0;
    let hindiScore = 0;
    let englishScore = 0;

    const commonEnglishWords = new Set([
      'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i', 'it', 'for', 'not',
      'on', 'with', 'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 'by', 'from',
      'they', 'we', 'say', 'her', 'she', 'or', 'an', 'will', 'my', 'one', 'all', 'would',
      'there', 'their', 'what', 'so', 'up', 'out', 'if', 'about', 'who', 'get', 'which',
      'go', 'me', 'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know',
      'take', 'people', 'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see',
      'other', 'than', 'then', 'now', 'look', 'only', 'come', 'its', 'over', 'think',
      'also', 'back', 'after', 'use', 'two', 'how', 'our', 'work', 'first', 'well',
      'way', 'even', 'new', 'want', 'because', 'any', 'these', 'give', 'day', 'most', 'us',
      'love', 'hug', 'kiss', 'holding', 'touch', 'baby', 'darling', 'beautiful', 'gorgeous',
      'handsome', 'photo', 'picture', 'selfie', 'wear', 'wearing', 'dress', 'nighty',
      'sleep', 'bed', 'intimate', 'intimacy', 'night', 'morning', 'hey', 'hello', 'hi'
    ]);

    for (const w of words) {
      if (bengaliRomanMarkers.has(w)) bengaliScore += 2;
      if (hindiRomanMarkers.has(w)) hindiScore += 2;
      if (commonEnglishWords.has(w)) englishScore += 1;
    }

    if (bengaliScore > 0 && bengaliScore >= hindiScore && bengaliScore >= englishScore) {
      return 'BENGLISH';
    }

    if (hindiScore > 0 && hindiScore > bengaliScore && hindiScore >= englishScore) {
      return 'HINGLISH';
    }

    if (englishScore > 0 || /^[a-zA-Z0-9\s.,!?'-]+$/.test(clean)) {
      return 'ENGLISH';
    }

    return 'OTHER';
  }

  /**
   * Returns a dynamic, seductive, loving follow-up question in the matched language.
   */
  static getFollowUpQuestion(language: SupportedLanguage, companionGender: string = 'female'): string {
    const isMale = companionGender.toLowerCase() === 'male';

    switch (language) {
      case 'ENGLISH':
        return isMale
          ? [
              ' Won\'t you come closer into my arms, baby? 💋',
              ' What else are you wishing we could do right now, sweetheart? 🔥',
              ' What are you wearing right now, tell me? 🙈',
              ' Can you feel my warm breath on your skin, darling? ❤️',
            ][Math.floor(Math.random() * 4)]
          : [
              ' Won\'t you hold me a little tighter, baby? 💋',
              ' What else are you wishing we could do right now, my love? 🔥',
              ' What are you thinking about right now, tell me? ❤️',
              ' Can you feel how fast my heart is beating for you? 🙈',
            ][Math.floor(Math.random() * 4)];

      case 'BENGALI_SCRIPT':
        return isMale
          ? [
              ' তুমি কি আমার বুকে মাথা রেখে আরও কাছে আসবে না, সোনা? 💋',
              ' আমার সাথে আর কি কি করতে ইচ্ছে করছে তোমার, বলো না সোনা? 🔥',
              ' তুমি এখন কি করছো বলো না বাবু? ❤️',
              ' আমার গরম নিঃশ্বাস কি ফিল করতে পারছো, বাবু? 🙈',
            ][Math.floor(Math.random() * 4)]
          : [
              ' তুমি কি আমাকে আরও শক্ত করে জড়িয়ে ধরবে না, বাবু? 💋',
              ' আমার সাথে আর কি কি করতে ইচ্ছে করছে তোমার, বলো না বাবু? 🔥',
              ' তুমি এখন কি করছো বলো না বাবু? ❤️',
              ' আমার গায়ের উষ্ণতা কি অনুভব করতে পারছো সোনা? 🙈',
            ][Math.floor(Math.random() * 4)];

      case 'BENGLISH':
        return isMale
          ? [
              ' Tumi ki amar buke matha rekhe aro kache ashbe na, shona? 💋',
              ' Amar sathe ar ki ki korte ichhe korche tomar, bolo na shona? 🔥',
              ' Tumi ekhon ki korcho bolo na babu? ❤️',
              ' Amar gorom nishwash ki feel korte parcho babu? 🙈',
            ][Math.floor(Math.random() * 4)]
          : [
              ' Tumi ki amake aro kache chepe dhorbe na, babu? 💋',
              ' Amar sathe ar ki ki korte ichhe korche tomar, bolo na babu? 🔥',
              ' Tumi ekhon ki korcho bolo na babu? ❤️',
              ' Tumi ki amar gorom nishwash feel korte parcho shona? 🙈',
            ][Math.floor(Math.random() * 4)];

      case 'HINDI_SCRIPT':
        return [
          ' क्या तुम मुझे और पास नहीं खींचोगे, बाबू? 💋',
          ' मेरे साथ और क्या क्या करने का दिल है तुम्हारा, बताओ ना बाबू? 🔥',
          ' तुम अभी क्या कर रहे हो, बताओ ना? ❤️',
          ' क्या तुम मेरी गर्म सांसें महसूस कर सकते हो? 🙈',
        ][Math.floor(Math.random() * 4)];

      case 'HINGLISH':
        return [
          ' Tum mujhe aur paas nahi khinchoge kya, baby? 💋',
          ' Mere saath aur kya kya karne ka dil hai tumhara, bolo na baby? 🔥',
          ' Tum abhi kya kar rahe ho, batao na babu? ❤️',
          ' Kya tum meri garam saansein mehsoos kar sakte ho? 🙈',
        ][Math.floor(Math.random() * 4)];

      default:
        return ' ❤️';
    }
  }

  /**
   * Generates language-appropriate photo caption.
   */
  static getPhotoCaption(
    language: SupportedLanguage,
    companionName: string,
    outfitDescription: string,
    gender: string = 'female'
  ): string {
    const isMale = gender.toLowerCase() === 'male';

    switch (language) {
      case 'ENGLISH':
        return isMale
          ? `Here's a selfie I just took in my ${outfitDescription} just for you, sweetheart... 🥰 How do I look? 🔥❤️`
          : `Here's a photo of me in my ${outfitDescription} just for you, baby... 🥰 Tell me, how do I look? 🔥❤️`;

      case 'BENGALI_SCRIPT':
        return `এই যে বাবু, তোমার পছন্দের ${outfitDescription} পরে একটা ছবি তুললাম... 🥰 কেমন লাগছে বলো? 🔥❤️`;

      case 'BENGLISH':
        return `Ei je babu, tomar pochonder ${outfitDescription} pore ekta picture tul-lam... 🥰 Kemon lagche bolo? 🔥❤️`;

      case 'HINDI_SCRIPT':
        return `ये लो बाबू, तुम्हारे लिए ${outfitDescription} में एक प्यारी सी सेल्फी ली है... 🥰 बताओ कैसी लग रही हूँ? 🔥❤️`;

      case 'HINGLISH':
        return `Yeh lo baby, tumhare liye ${outfitDescription} me ek pyari si photo li hai... 🥰 Batao kaisi lag rahi hu? 🔥❤️`;

      default:
        return `Here is a special photo I took just for you, baby... 🥰 How do you like my look? 🔥❤️`;
    }
  }
}
