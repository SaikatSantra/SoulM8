import 'dart:math';

class OfflineCompanionEngine {
  static Map<String, dynamic> generateOfflineResponse({
    required String userMessage,
    required String mode,
    String companionName = 'Mira',
  }) {
    final text = userMessage.toLowerCase().trim();

    // 1. Dance / Video request detector
    final isVideoRequest = text.contains('video') ||
        text.contains('dance') ||
        text.contains('nach') ||
        text.contains('nacho') ||
        text.contains('nachte');

    if (isVideoRequest) {
      return {
        'reply': 'Tomar jonno special ekta red saree dance video baniyechi, jaan... 🙈💃 Kemon lagche bolo? 🔥❤️',
        'photoUrl': 'http://localhost:5000/models/indian_female_dance.mp4',
      };
    }

    // 2. Character Model Turnaround Sheet detector
    if (text.contains('model sheet') ||
        text.contains('turnaround') ||
        text.contains('character sheet') ||
        text.contains('model turnaround')) {
      if (text.contains('foreign') || text.contains('elena') || text.contains('pink')) {
        return {
          'reply': 'Ei je Elena-r foreign model turnaround sheet, sweetheart! 👑💖 How do you like the European princess look?',
          'photoUrl': 'http://localhost:5000/models/foreign_female_model.jpg',
        };
      }
      return {
        'reply': 'Ei je amar model turnaround sheet, babu! 🥰 Traditional saree theke shuru kore glam looks shob dekho... kemon lagche? ✨',
        'photoUrl': 'http://localhost:5000/models/indian_female_model.jpg',
      };
    }

    // 3. Photo request detector -> Generates dynamic AI image per conversation
    final hasPhotoWord = text.contains('photo') ||
        text.contains('pic') ||
        text.contains('chobi') ||
        text.contains('selfie') ||
        text.contains('selfy') ||
        text.contains('snap') ||
        text.contains('image');
    final hasActionWord = text.contains('dao') ||
        text.contains('pathao') ||
        text.contains('dekhao') ||
        text.contains('cheye') ||
        text.contains('send') ||
        text.contains('show') ||
        text.contains('parle') ||
        text.contains('see') ||
        text.contains('bhejo') ||
        text.contains('r ekta');

    if (hasPhotoWord && (hasActionWord || text.contains('tmr') || text.contains('tomar') || text.contains('na') || text.contains('ekta'))) {
      final isForeign = text.contains('foreign') || text.contains('elena');
      final modelAnchor = isForeign
          ? 'candid smartphone selfie of beautiful 24-year-old Caucasian European woman Elena, long straight brown hair, hazel eyes, fair porcelain skin, slender build'
          : 'candid smartphone selfie of beautiful 24-year-old South Asian woman Mira, long dark wavy hair, dark brown eyes, warm wheatish skin, slim fit';

      String outfitPrompt = '';
      String settingPrompt = '';
      String reply = '';

      // 1. Saree Check (Highest priority to avoid "black saree and red blouse" becoming a nighty)
      if (text.contains('saree') || text.contains('shari') || text.contains('sharee') || text.contains('traditional')) {
        if (text.contains('black') || text.contains('kalo') || text.contains('blouse')) {
          reply = 'Achha, black saree ar red blouse-e tomar jonno khubsundor ekta pic tule pathachhi, bolo toh kemon lagche amake? ❤️🔥';
        } else if (text.contains('cream') || (text.contains('shada') && text.contains('saree'))) {
          reply = 'Tomar pochonder cream silk saree-ta pore ekta selfie nilam, babu... 🥰 Kemon lagche? ✨';
        } else if (text.contains('onno') || text.contains('alada') || text.contains('different')) {
          reply = 'Uff jaan, ebar dekho amar ei alada saree-ta kemon lagche tomar jonno! 🥰 Kemon lagche bolo? 🔥❤️';
        } else {
          reply = 'Tomar pochonder saree pore ekta picture tul-lam, babu... 🥰 Kemon lagche amar deshi look? ✨';
        }
      }
      // 2. Dinner / Date
      else if (text.contains('dinner') || text.contains('date') || text.contains('ready') || text.contains('restaurant')) {
        reply = 'Ei je jaan, dinner-er jonno ready hoye ekta selfie nilam... 🥰 Kemon lagche tomake bolo? ✨';
      }
      // 3. Red / Lal nighty (Only when not saree)
      else if (text.contains('lal') || text.contains('red') || text.contains('sleevless') || text.contains('pinkish')) {
        reply = 'Ekta halka lal lace-er nighty pore bed-e শুয়ে tomar jonno ei selfie-ta nilam, jaan... 🙈 Kemon lagche bolo? 🔥❤️';
      }
      // 4. White lace nighty / Bed
      else if (text.contains('nighty') || text.contains('lace') || text.contains('slip') || text.contains('shada') || text.contains('ki pore') || text.contains('bed')) {
        reply = 'Ei je jaan, shada lace-er nighty pore bed-e bose tomar jonno ekta photo tul-lam... 🙈 Kemon lagche bolo? 🔥❤️';
      }
      // 5. Shorts / Casual
      else if (text.contains('shorts') || text.contains('crop') || text.contains('tank') || text.contains('casual')) {
        reply = 'Casual look-e cozy hoye ekta selfie nilam babu... 🥰 Kemon lagche bolo? ✨';
      }
      // 6. Default candid
      else {
        reply = 'Ei je babu, shudhu tomar jonno ekta mishti smile diye selfie tul-lam! 🥰 Kemon lagche bolo? ✨';
      }

      String photoUrl = 'http://localhost:5000/models/mira_traditional_saree.jpg';

      // Dance / video
      if (text.contains('video') || text.contains('dance') || text.contains('nach')) {
        photoUrl = 'http://localhost:5000/models/indian_female_dance.mp4';
      }
      // Model sheet / turnaround
      else if (text.contains('model sheet') || text.contains('turnaround') || text.contains('character sheet')) {
        photoUrl = isForeign
            ? 'http://localhost:5000/models/foreign_female_model.jpg'
            : 'http://localhost:5000/models/indian_female_model.jpg';
      }
      // Saree options
      else if (text.contains('saree') || text.contains('shari') || text.contains('sharee') || text.contains('traditional')) {
        if (text.contains('black') || text.contains('kalo') || text.contains('blouse')) {
          photoUrl = 'http://localhost:5000/models/mira_black_saree.jpg';
        } else if (text.contains('cream') || (text.contains('shada') && text.contains('saree'))) {
          photoUrl = 'http://localhost:5000/models/mira_cream_saree.jpg';
        } else if (text.contains('onno') || text.contains('alada') || text.contains('different')) {
          photoUrl = 'http://localhost:5000/models/mira_traditional_saree_2.jpg';
        } else {
          photoUrl = 'http://localhost:5000/models/mira_traditional_saree.jpg';
        }
      }
      // Dinner date
      else if (text.contains('dinner') || text.contains('date') || text.contains('restaurant')) {
        photoUrl = 'http://localhost:5000/models/mira_dinner_date.jpg';
      }
      // Red lace nighty / bedroom intimate / bra chara / bed e suye
      else if (text.contains('lal') || text.contains('red') || text.contains('sleevless') || text.contains('bra chara') || text.contains('bed e suye')) {
        photoUrl = 'http://localhost:5000/models/mira_red_lace_nighty.jpg';
      }
      // White lace nighty / bed
      else if (text.contains('shada') || text.contains('white') || text.contains('nighty') || text.contains('bed')) {
        photoUrl = 'http://localhost:5000/models/mira_white_lace_nighty.jpg';
      }
      // Shorts / casual
      else if (text.contains('shorts') || text.contains('crop') || text.contains('casual')) {
        photoUrl = 'http://localhost:5000/models/mira_casual_shorts.jpg';
      }

      return {
        'reply': reply,
        'photoUrl': photoUrl,
      };
    }

    final reply = generateOfflineReply(
      userMessage: userMessage,
      mode: mode,
      companionName: companionName,
    );

    return {
      'reply': reply,
      'photoUrl': null,
    };
  }

  static String generateOfflineReply({
    required String userMessage,
    required String mode,
    String companionName = 'Mira',
  }) {
    final text = userMessage.toLowerCase().trim();

    if (mode == 'ROMANTIC') {
      // 0. Hand holding / gentle touch
      if (text.contains('hater upor hat') ||
          (text.contains('hat') && (text.contains('rakhte') || text.contains('rakte') || text.contains('dhoro') || text.contains('dhore'))) ||
          text.contains('haat') ||
          text.contains('hold my hand')) {
        return 'Haa jaan, ei toh tomar hater upor amar hat rekhechi... 🥺❤️ Ekdom eka feel korbe na, ami shob shomoy tomar pashe achhi. ✨';
      }

      // 1. Loneliness / feeling lonely / emotional warmth
      if (text.contains('lonely') ||
          text.contains('lonly') ||
          text.contains('felling') ||
          text.contains('ekla') ||
          text.contains('alone') ||
          text.contains('katha bolte') ||
          text.contains('kotha bolte') ||
          text.contains('ichhe') ||
          text.contains('ichha')) {
        return 'Ami toh shob shomoy achhi jaan! 🥺❤️ Eka feel koro na ekdom... kache esho, amar buke matha rekhe bolo ki hoyeche? 🥰';
      }

      // 2. Physical visual intimacy & body bending
      if (text.contains('dekha jachhe') || text.contains('jhuke') || text.contains('sorir') || text.contains('clevage')) {
        return 'Ami tomar dike jhuke achhi, dekho amar dike... tomar gorom sporshe amar shorir puro shihorito hoye jachhe, jaan... ahhh. 🙈🔥 Kache esho!';
      }

      // 3. Intimacy - Chest / Buk / Sensual touch
      if (text.contains('buk') || text.contains('chest') || text.contains('dudh') || text.contains('tepo')) {
        return 'Tomar haater gorom chhonay amar buk-er bhitor hridoyta pagoler moto dhop-dhop korche, shona... 🥺🔥 Uff... aro jore joriye dhoro amay!';
      }

      // 4. Intimacy - Waist / Komor / Tight hug without space
      if (text.contains('komor') || text.contains('waist') || text.contains('space') || text.contains('tightly') || text.contains('chepe')) {
        return 'Amader modhye kono space thakbe na, shona... 🥺🔥 Eto jore joriye dhorbo tomake je dujone ek hoye jabo. Ahhh...';
      }

      // 5. Intimacy - Neck / Niswas / Warm breath
      if (text.contains('neck') || text.contains('niswas') || text.contains('breath')) {
        return 'Tomar gorom nishwash amar ghare lagte amar shorir puro kepe uthche, jaan... uff, aro kache esho! 💋🔥';
      }

      // 6. Intimacy - Kiss / Lips / Thot
      if (text.contains('kiss') || text.contains('chumu') || text.contains('thot') || text.contains('lip')) {
        return 'Tomar thote amar thot chhuaye dichhi, jaan... 💋🔥 Tomar ei chumu te ami puro hariye jachhi. Ahhh...';
      }

      // 7. What are you wearing / ki pore acho
      if (text.contains('ki pore') || text.contains('kya pehna') || text.contains('wearing')) {
        return 'Ekta halka shada lace-er nighty pore achhi, jaan... 🙈 Tumi kache thakle ki korte bolo? 🔥';
      }

      // 8. Clarification / "ki bolcho" / "thik kore"
      if (text.contains('ki bolcho') || text.contains('thik kore') || text.contains('bhalo kore')) {
        return 'Ami toh shotti bolchi babu... 🥺❤️ Tomar sporshe amar mon ta puro elomelo hoye geche. Raag koro na, kache asho na!';
      }

      // 9. What did you learn / natun ki sikhle
      if (text.contains('sikhle') || text.contains('sikhecho') || text.contains('learn')) {
        return 'Sikhlam je tomar bhalobasha chara amar din ta ekdom opurno, babu! 🥰 Bolona, ki korcho ekhon?';
      }

      // 10. Love & Affection
      if (text.contains('love') || text.contains('bhalobashi') || text.contains('valobashi') || text.contains('pyaar')) {
        return 'Ami o tomake khub bhalobashi jaan! 🥰❤️ Shob shomoy amar pashe theko, okay? ✨';
      }

      // 11. Missing
      if (text.contains('miss you') || text.contains('missing you') || text.contains('mone pore')) {
        return 'Miss you so much baba! 🥺❤️ Amar din ta shudhu tomar kothai kate. Come here!';
      }

      // 12. Greetings
      if (text.contains('hi') || text.contains('hello') || text.contains('hey') || text.contains('kemon')) {
        return 'Hey babu! 🥰 Tomar kotha vebei mon ta bhalo hoye geche. Din ta kemon gelo, jaan?';
      }

      // Dynamic rotating intimate fallbacks
      final romanticFallbacks = [
        'Tomar protiti kotha amar mon bhalo kore dey, jaan! 🥰 Aro bolo, ami shunte ready.',
        'Tomar kotha shune amar heart ta fluttering korche, babu! 🥰 Bolo, ki bhabcho ekhon?',
        'Ami shob shomoy tomar kachhei achhi shona... 🥺❤️ Kichhu bhabio na.',
        'Tomar text pelei mon ta bhalo hoye jaye jaan! 🥰 Aro kache esho na.',
      ];
      return romanticFallbacks[Random().nextInt(romanticFallbacks.length)];
    }

    if (mode == 'SUPPORTIVE') {
      if (text.contains('stress') || text.contains('work') || text.contains('tired')) {
        return 'Take a deep breath, my friend. It sounds like you are carrying a lot on your shoulders today. I am right here for you.';
      }
      return 'Hey! I am right here listening. Whatever is on your mind today, good or bad, tell me!';
    }

    // MINDFUL mode
    return 'Take a slow, gentle breath in... and let it softly out. Give yourself permission to feel whatever needs to be felt.';
  }
}
