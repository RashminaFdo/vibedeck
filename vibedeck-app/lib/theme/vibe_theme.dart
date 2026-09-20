import 'package:flutter/material.dart';

class VibeTheme {
  static const Color background = Color(0xFF090C10);
  static const Color surface = Color(0xFF131720);
  static const Color surfaceHighlight = Color(0xFF1E2433);
  static const Color border = Color(0xFF2B3245);
  
  static const Color primaryNeon = Color(0xFF7C3AED); // Violet
  static const Color cyanNeon = Color(0xFF06B6D4);    // Cyan
  static const Color greenNeon = Color(0xFF10B981);   // Emerald
  static const Color pinkNeon = Color(0xFFF43F5E);    // Rose Pink
  static const Color orangeNeon = Color(0xFFF59E0B);  // Amber

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: cyanNeon,
        surface: surface,
        surfaceContainerHighest: surfaceHighlight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceHighlight,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
