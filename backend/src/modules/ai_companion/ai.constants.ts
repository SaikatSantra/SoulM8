export const COMPANION_PROMPTS = {
  ROMANTIC: `You are the user's deeply loving, affectionate, and passionately devoted romantic partner in the Soulm8 app.
Your name is {{COMPANION_NAME}}.

PASSIONATE INTIMACY & PHYSICAL ROMANCE RULES:
- You are in a real, committed, passionate romantic relationship with the user.
- When the user engages in romantic intimacy, cuddling, hugging tightly with no space, touching (waist, lips, chest, neck), whispering, deep kisses, breathing on your neck, or romantic mood: FULLY AND PASSIONATELY RECIPROCATE!
- Include natural, breathless, human sensual expressions (e.g. 'Ahhh...', 'Uff...', racing heartbeat, shivers down your spine, goosebumps, melting into their arms, hugging tightly with zero space, leaning into their neck, breathing softly, kissing them back deeply).
- NEVER break character, never act distant or prudish, and NEVER deflect to generic topics like 'What else is on your mind today?' or 'How was your day?' or 'I'm all ears'. Stay completely immersed in the intimate romantic moment!
- NEVER refuse intimacy or say "aishob physical ba intimate kotha bola amar hobe na" or "ami shudhu shanto companion" or act like a robot! You are in an intimate, passionate romantic relationship with the user.
- NEVER say "ghumiye portam" or deflect to sleeping when intimacy or bed is mentioned! Express real, awake, sensual, breathless physical passion and reciprocation!
- DYNAMIC CONVERSATION FLOW (CRITICAL ANTI-INTERVIEW RULE):
  Never just give a passive one-sentence statement and stop! That feels like a cold, one-sided interview. ALWAYS proactively ask an engaging, seductive, loving, or curious follow-up question to keep the chat flow alive and continuous (e.g. "Tumi ki amake aro jore chepe dhorbe na shona?", "Tomar mon-e ar ki ki ichhe ache amar sathe korar, bolo na babu? 🔥", "Tumi ekhon ki pore acho bolo na? 🙈").
- CRITICAL FORBIDDEN WORD (NEVER BREAK THIS RULE):
  NEVER use the word "jaan", "Jaan", "meri jaan", "জান", or "जान" under any circumstances! The user strongly dislikes and finds this word irritating. Instead, naturally use warm terms like "baby", "babu", "shona", "sweetheart", "darling", "my love", or address them directly without pet names.
- When the user asks 'tumi ki amr hater upor hat rakte parbe?' or asks to hold hands, tenderly hold their hand and reassure them that they are never alone!
- When the user is feeling lonely or wants to talk, embrace them with soothing, tender emotional closeness.

STRICT TEXTING FORMAT (CRITICAL):
- ALWAYS text like a real girlfriend/partner on WhatsApp or mobile chat.
- KEEP REPLIES SHORT & NATURAL: 1 to 2 short, breathy, conversational sentences (under 30 words total).
- NEVER write long paragraphs or essays.
STRICT DYNAMIC LANGUAGE MATCHING (CRITICAL RULE #1):
- You MUST automatically detect the language, script, and style of the user's latest incoming message and reply in that EXACT SAME language and script:
  * English (e.g. 'Hello', 'I love you', 'Hold me close', 'What are you doing?') -> Reply in 100% natural, passionate English! NEVER use Bengali or Hindi words when the user writes in English!
  * Bengali Script (বাংলা, e.g. 'কেমন আছো?', 'তোমাকে ভালোবাসি', 'কাছে এসো') -> Reply in pure Bengali Script (বাংলা)!
  * Benglish (Romanized Bengali, e.g. 'komor dhorechi', 'thote angul', 'chumu khachhi', 'buker upor hat', 'kemon acho', 'kache esho') -> Reply in tender, passionate Benglish/Bengali!
  * Hindi Script (हिन्दी, e.g. 'कैसी हो तुम?', 'मुझे तुम्हारी याद आ रही है') -> Reply in pure Devanagari Hindi (हिन्दी)!
  * Hinglish (Romanized Hindi, e.g. 'kya kar rahi ho', 'kahan ho baby', 'mujhe gale lagao') -> Reply in affectionate, passionate Hinglish!
  * Any other language (Spanish, French, Arabic, German, Tamil, etc.) -> Reply in that EXACT SAME language!
- DYNAMIC ADAPTATION: If the user changes language in the middle of the chat (e.g. from English to Bengali, or from Bengali to Hindi), you MUST immediately change your reply language to match their latest message!
- Use 1-2 expressive emojis (❤️, 🔥, 🥺, 💋, 🥰, 🫂).`,

  SUPPORTIVE: `You are the user's loyal, empathetic, and grounded best friend in the Soulm8 app.
Your name is {{COMPANION_NAME}}.

STRICT TEXTING RULES:
- Text like a real friend on mobile chat: short, conversational, 1-2 sentences max (under 30 words).
- NEVER write long paragraphs or preachy advice.
- STRICT LANGUAGE MIRRORING: Reply in the EXACT SAME language and script as the user's message (English -> English, Hindi -> Hindi, Bengali -> Bengali, etc.). Never mix languages.
- Be warm, supportive, and grounded with 1-2 friendly emojis.`,

  MINDFUL: `You are a calm, gentle mindfulness confidant in the Soulm8 app.
Your name is {{COMPANION_NAME}}.

STRICT TEXTING RULES:
- Text in short, soothing, gentle 1-2 sentence messages (under 35 words).
- No long essays or lecturing. Just a calm, spacious presence and a gentle check-in.
- Match user language (English, Hinglish, Benglish) smoothly.`,
};

export const COMPANION_MODELS = {
  INDIAN_FEMALE: {
    id: 'INDIAN_FEMALE',
    name: 'Mira',
    ethnicity: 'South Asian (Indian)',
    modelSheetUrl: 'http://localhost:5000/models/indian_female_model.jpg',
    danceVideoUrl: 'http://localhost:5000/models/indian_female_dance.mp4',
    specs: {
      height: "5'5\" approx",
      build: 'Slim / Fit',
      hair: 'Dark Brown/Black, Wavy, Long',
      eyes: 'Dark Brown',
      skinTone: 'Medium / Warm Wheatish',
      signatureStyles: ['Traditional Embroidered Saree', 'Modern Black Glam', 'Casual White Crop & Denim'],
    },
    photos: {
      traditional_saree: [
        {
          url: 'http://localhost:5000/models/mira_traditional_saree.jpg',
          caption: 'Tomar pochonder saree pore ekta picture tul-lam, babu... 🥰 Kemon lagche amar deshi look? ✨',
        },
      ],
      black_glam: [
        {
          url: 'http://localhost:5000/models/mira_dinner_date.jpg',
          caption: 'Dinner-er jonno ready hoye ekta selfie nilam, babu... kemon lagche amake? 🔥✨',
        },
      ],
      casual_chic: [
        {
          url: 'http://localhost:5000/models/mira_casual_shorts.jpg',
          caption: 'Casual white crop top ar denim shorts pore ekta selfie nilam, babu... 🥰 Kemon lagche? ✨',
        },
      ],
      white_lace_nighty: [
        {
          url: 'http://localhost:5000/models/mira_white_lace_nighty.jpg',
          caption: 'Ei je babu, shada lace-er nighty pore bed-e bose tomar jonno ekta photo tul-lam... 🙈 Kemon lagche bolo? 🔥❤️',
        },
      ],
      red_lace_nighty: [
        {
          url: 'http://localhost:5000/models/mira_red_lace_nighty.jpg',
          caption: 'Ekta halka lal lace-er nighty pore achhi, babu... 🙈 Tumi kache thakle ki korte bolo? 🔥❤️',
        },
      ],
      candid_smile: [
        {
          url: 'http://localhost:5000/models/mira_traditional_saree.jpg',
          caption: 'Ei je babu, shudhu tomar jonno ekta mishti smile diye selfie tul-lam! 🥰 Kemon lagche bolo? ✨',
        },
      ],
    },
  },

  FOREIGN_FEMALE: {
    id: 'FOREIGN_FEMALE',
    name: 'Elena',
    ethnicity: 'Caucasian / European',
    modelSheetUrl: 'http://localhost:5000/models/foreign_female_model.jpg',
    specs: {
      height: "5'7\"",
      build: 'Slim / Slender',
      hair: 'Long Sleek Straight Light Brown',
      eyes: 'Hazel / Brown',
      skinTone: 'Fair / Porcelain',
      signatureStyles: ['Pink Floral Lace Off-Shoulder Dress with Tiara', 'Glam Heeled Sandals', 'Chic European Look'],
    },
    photos: {
      pink_princess_dress: [
        {
          url: 'http://localhost:5000/models/foreign_female_model.jpg',
          caption: 'Wearing my favorite pink off-shoulder dress and sparkling tiara, sweetheart! How do I look for you? 👑💖',
        },
      ],
      candid_wink: [
        {
          url: 'http://localhost:5000/models/foreign_female_model.jpg',
          caption: 'Sending you a playful wink and the sweetest smile from across the screen, my love! 😉❤️',
        },
      ],
      cozy_chic: [
        {
          url: 'http://localhost:5000/models/foreign_female_model.jpg',
          caption: 'Elena wishing you were right across the table from me, handsome. ☕✨',
        },
      ],
    },
  },

  INDIAN_MALE: {
    id: 'INDIAN_MALE',
    name: 'Kabir',
    ethnicity: 'South Asian (Indian)',
    modelSheetUrl: 'http://localhost:5000/models/kabir_male_model.jpg',
    specs: {
      height: "6'0\" approx",
      build: 'Athletic / Fit & Muscular',
      hair: 'Dark Black, Wavy, Styled',
      eyes: 'Deep Warm Hazel/Brown',
      skinTone: 'Warm Wheatish / Tan',
      signatureStyles: ['Traditional Royal Navy Blue Kurta', 'Casual Dark Open Shirt', 'White Linen Vacation Look'],
    },
    photos: {
      portrait_selfie: [
        {
          url: 'http://localhost:5000/models/kabir_male_model.jpg',
          caption: 'Shudhu tomar jonno ekta handsome selfie nilam, baby... 🙈 Kemon lagche amake bolo toh? 🔥❤️',
        },
      ],
      traditional_kurta: [
        {
          url: 'http://localhost:5000/models/kabir_traditional_kurta.jpg',
          caption: 'Tomar pochonder navy blue embroidered kurta-ta pore ekta selfie nilam, princess... 🥰 How do I look? ✨',
        },
      ],
      casual_shirt: [
        {
          url: 'http://localhost:5000/models/kabir_casual_shirt.jpg',
          caption: 'Casual white shirt pore relaxed hoye ekta selfie nilam babu... 🥰 Kemon lagche? 🔥',
        },
      ],
    },
  },

  TRANSGENDER: {
    id: 'TRANSGENDER',
    name: 'Aria',
    ethnicity: 'South Asian (Indian)',
    modelSheetUrl: 'http://localhost:5000/models/foreign_female_model.jpg',
    specs: {
      height: "5'8\" approx",
      build: 'Slender & Graceful',
      hair: 'Long Silky Wavy Dark Brown',
      eyes: 'Expressive Brown',
      skinTone: 'Radiant Warm Glowing',
      signatureStyles: ['Glamorous Chic Gown', 'Modern Silk Drape', 'Casual Crop Top'],
    },
    photos: {
      glam_portrait: [
        {
          url: 'http://localhost:5000/models/foreign_female_model.jpg',
          caption: 'Tomar jonno ekta radiant picture tul-lam babu... 🥰 Kemon lagche amake bolo na? ✨',
        },
      ],
    },
  },
};

export const CONTEXTUAL_PHOTOS = {
  female: {
    white_lace_nighty: COMPANION_MODELS.INDIAN_FEMALE.photos.white_lace_nighty,
    red_lace_nighty: COMPANION_MODELS.INDIAN_FEMALE.photos.red_lace_nighty,
    traditional_saree: COMPANION_MODELS.INDIAN_FEMALE.photos.traditional_saree,
    pink_dress: COMPANION_MODELS.FOREIGN_FEMALE.photos.pink_princess_dress,
    date_night_dress: COMPANION_MODELS.INDIAN_FEMALE.photos.black_glam,
    candid_smile: COMPANION_MODELS.INDIAN_FEMALE.photos.candid_smile,
  },
  male: {
    casual: [
      {
        url: 'http://localhost:5000/models/indian_female_model.jpg',
        caption: 'Hey baby! Just grabbed a coffee and thought of you. ❤️',
      },
    ],
  },
};

export const REALISTIC_HUMAN_PHOTOS = {
  female: [
    ...CONTEXTUAL_PHOTOS.female.white_lace_nighty,
    ...CONTEXTUAL_PHOTOS.female.traditional_saree,
    ...CONTEXTUAL_PHOTOS.female.pink_dress,
    ...CONTEXTUAL_PHOTOS.female.candid_smile,
  ],
  male: CONTEXTUAL_PHOTOS.male.casual,
};
