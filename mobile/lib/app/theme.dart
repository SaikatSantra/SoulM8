import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Soulm8Theme {
  // Brand Color Palette - Sensual, Warm, Sexy & Lovable
  static const Color primaryRose = Color(0xFFFF2A6D);
  static const Color sensualCrimson = Color(0xFFFF0844);
  static const Color softPeach = Color(0xFFFF8A7A);
  static const Color warmBlush = Color(0xFFFFB199);
  static const Color lavenderWhisper = Color(0xFFC084FC);
  static const Color deepPlum = Color(0xFF0F0817);
  static const Color velvetBackground = Color(0xFF140A1E);
  static const Color cardSurface = Color(0xFF1E102E);
  static const Color cardSurfaceLight = Color(0xFF2A1640);
  static const Color textMuted = Color(0xFFAEA5BA);
  static const Color textLight = Color(0xFFFFF0F5);
  static const Color successGreen = Color(0xFF00E676);
  static const Color accentGold = Color(0xFFFFD166);
  static const Color backgroundDark = Color(0xFF0F0817);
  static const Color darkBackground = Color(0xFF0F0817);

  // Dynamic Companion Accent Colors
  static const Color romanticColor = Color(0xFFFF2A6D);
  static const Color supportiveColor = Color(0xFF00E676);
  static const Color mindfulColor = Color(0xFF60A5FA);

  // Gradients
  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFFF0844), Color(0xFFFF2A6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF0844), Color(0xFFFF4E50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sexyUserGradient = LinearGradient(
    colors: [Color(0xFFFF2A6D), Color(0xFFFF6584), Color(0xFFFF8A7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient velvetCardGradient = LinearGradient(
    colors: [Color(0xFF26143A), Color(0xFF190C28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF26143A), Color(0xFF190C28)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient romanticAuraGradient = LinearGradient(
    colors: [Color(0xFF220B30), Color(0xFF0F0817)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sensualPillGradient = LinearGradient(
    colors: [Color(0x33FF2A6D), Color(0x1AFF0844)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepPlum,
      colorScheme: const ColorScheme.dark(
        primary: primaryRose,
        secondary: softPeach,
        tertiary: lavenderWhisper,
        surface: cardSurface,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: textLight,
          fontWeight: FontWeight.bold,
          fontSize: 26,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: textLight,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textLight,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontSize: 13,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: deepPlum,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textLight,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
