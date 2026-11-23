import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF10B981); // Emerald / Forest Green
  static const Color primaryDark = Color(0xFF059669);
  static const Color accent = Color(0xFF6366F1); // Indigo
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // IELTS Band Color Coding
  // IELTS Band Color Coding (6-tier CEFR scale)
  static Color getBandColor(String band) {
    if (band.contains('8.5') || band.contains('9.0') || band.contains('C2')) {
      return const Color(0xFF8B5CF6); // Purple (Expert C2: 8.5 - 9.0)
    } else if (band.contains('7.0') || band.contains('8.0') || band.contains('C1')) {
      return const Color(0xFF3B82F6); // Blue (Advanced C1: 7.0 - 8.0)
    } else if (band.contains('5.5') || band.contains('6.5') || band.contains('B2')) {
      return const Color(0xFF10B981); // Emerald (Upper-Intermediate B2: 5.5 - 6.5)
    } else if (band.contains('4.0') || band.contains('5.0') || band.contains('B1')) {
      return const Color(0xFFF59E0B); // Amber (Intermediate B1: 4.0 - 5.0)
    } else if (band.contains('3.0') || band.contains('3.5') || band.contains('A2')) {
      return const Color(0xFFEC4899); // Pink (Elementary A2: 3.0 - 3.5)
    } else {
      return const Color(0xFF64748B); // Slate (Beginner A1: 1.0 - 2.5)
    }
  }

  // SM-2 Review Quality Colors
  static const Color qualityAgain = Color(0xFFEF4444); // Red - Again (0-1)
  static const Color qualityHard = Color(0xFFF97316);  // Orange - Hard (2-3)
  static const Color qualityGood = Color(0xFF3B82F6);  // Blue - Good (4)
  static const Color qualityEasy = Color(0xFF10B981);  // Green - Easy (5)

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surfaceDark,
        onSurface: textLight,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
      ),
    );
  }
}
