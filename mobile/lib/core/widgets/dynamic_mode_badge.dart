import 'package:flutter/material.dart';
import '../../app/theme.dart';

class DynamicModeBadge extends StatelessWidget {
  final String mode; // 'ROMANTIC', 'SUPPORTIVE', 'MINDFUL'
  final VoidCallback? onTap;

  const DynamicModeBadge({
    super.key,
    required this.mode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String emoji;
    String label;

    switch (mode.toUpperCase()) {
      case 'SUPPORTIVE':
        badgeColor = Soulm8Theme.supportiveColor;
        emoji = '🌿';
        label = 'Supportive Friend';
        break;
      case 'MINDFUL':
        badgeColor = Soulm8Theme.mindfulColor;
        emoji = '🧘';
        label = 'Mindful Confidant';
        break;
      case 'ROMANTIC':
      default:
        badgeColor = Soulm8Theme.romanticColor;
        emoji = '🌹';
        label = 'Romantic Partner';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: badgeColor.withOpacity(0.65), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withOpacity(0.25),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                shadows: [
                  Shadow(
                    color: badgeColor,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
            ],
          ],
        ),
      ),
    );
  }
}
