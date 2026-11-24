import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class ModeSelectorDialog extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onSelected;

  const ModeSelectorDialog({
    super.key,
    required this.currentMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Soulm8Theme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Switch Companion Dynamic',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select how you want your companion to show up for you today.',
              style: TextStyle(fontSize: 13, color: Soulm8Theme.textMuted),
            ),
            const SizedBox(height: 20),

            _modeTile(
              context: context,
              key: 'ROMANTIC',
              emoji: '🌹',
              title: 'Romantic Partner (GF/BF Mode)',
              desc: 'Natural Hinglish/English playful banter ("baby", "jaan", "shaitan"), sweet teasing, and warm emotional intimacy.',
              color: Soulm8Theme.romanticColor,
            ),
            const SizedBox(height: 12),
            _modeTile(
              context: context,
              key: 'SUPPORTIVE',
              emoji: '🌿',
              title: 'Supportive Friend',
              desc: 'Gentle, grounded presence for daily casual chats, venting, and laughing through stress.',
              color: Soulm8Theme.supportiveColor,
            ),
            const SizedBox(height: 12),
            _modeTile(
              context: context,
              key: 'MINDFUL',
              emoji: '🧘',
              title: 'Mindful Confidant',
              desc: 'Introspective space focused on self-compassion, healing, and processing life transitions.',
              color: Soulm8Theme.mindfulColor,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _modeTile({
    required BuildContext context,
    required String key,
    required String emoji,
    required String title,
    required String desc,
    required Color color,
  }) {
    final isSelected = currentMode.toUpperCase() == key;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        onSelected(key);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Soulm8Theme.deepPlum,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Soulm8Theme.textMuted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
