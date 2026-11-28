import 'package:flutter/material.dart';

/// Apple Modern Minimalist Design System for Vocap
class AppTheme {
  // Apple Dark Mode Palette
  static const Color backgroundDark = Color(0xFF000000); // True Apple OLED Black
  static const Color surfaceDark = Color(0xFF1C1C1E);    // Apple Secondary Grouped Background
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);// Apple Tertiary Grouped Background
  
  // Apple System Tint Colors
  static const Color primary = Color(0xFF0A84FF);        // Apple System Blue
  static const Color primaryDark = Color(0xFF0071E3);
  static const Color accent = Color(0xFF5E5CE6);         // Apple System Indigo
  static const Color mint = Color(0xFF30D158);           // Apple System Green / Mint
  static const Color orange = Color(0xFFFF9F0A);         // Apple System Orange
  static const Color red = Color(0xFFFF453A);            // Apple System Red

  // Apple Typography Colors
  static const Color textLight = Color(0xFFFFFFFF);      // Primary Label
  static const Color textSecondary = Color(0xFFEBEBF5);  // Secondary Label
  static const Color textMuted = Color(0xFF8E8E93);      // Apple System Gray

  // Apple Hairline Border & Dividers
  static const Color borderSubtle = Color(0x1FFFFFFF);   // 12% White Hairline
  static const Color dividerColor = Color(0x28545458);

  // IELTS Band Color Coding (Apple Vibrant System Palette)
  static Color getBandColor(String band) {
    if (band.contains('8.5') || band.contains('9.0') || band.contains('C2')) {
      return const Color(0xFFBF5AF2); // Apple System Purple (C2: 8.5 - 9.0)
    } else if (band.contains('7.0') || band.contains('8.0') || band.contains('C1')) {
      return const Color(0xFF0A84FF); // Apple System Blue (C1: 7.0 - 8.0)
    } else if (band.contains('5.5') || band.contains('6.5') || band.contains('B2')) {
      return const Color(0xFF30D158); // Apple System Green (B2: 5.5 - 6.5)
    } else if (band.contains('4.0') || band.contains('5.0') || band.contains('B1')) {
      return const Color(0xFFFF9F0A); // Apple System Orange (B1: 4.0 - 5.0)
    } else if (band.contains('3.0') || band.contains('3.5') || band.contains('A2')) {
      return const Color(0xFFFF375F); // Apple System Pink (A2: 3.0 - 3.5)
    } else {
      return const Color(0xFF8E8E93); // Apple System Gray (A1: 1.0 - 2.5)
    }
  }

  // SM-2 Review Quality Colors (Apple Vibrant Badges)
  static const Color qualityAgain = Color(0xFFFF453A); // Apple Red
  static const Color qualityHard = Color(0xFFFF9F0A);  // Apple Orange
  static const Color qualityGood = Color(0xFF0A84FF);  // Apple Blue
  static const Color qualityEasy = Color(0xFF30D158);  // Apple Green

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: null, // Default system sans-serif (San Francisco on Apple, clean system on others)
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 0.8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: -0.4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceElevated,
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderSubtle, width: 0.8),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textLight,
        ),
      ),
    );
  }
}
