import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bgDark = Colors.black;
  static const Color cardDark = Colors.black;
  static const Color accentOrange = Color(0xFFFF6B00);
  static const Color accentYellow = Color(0xFFFFD600);
  static const Color accentGreen = Color(0xFFBFFF00);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8E8E93);

  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color secondaryOrange = Color(0xFFFF6B00);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    primaryColor: primaryPurple,
    cardColor: cardDark,
    dividerColor: Colors.white.withValues(alpha: 0.1),
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentYellow,
      surface: cardDark,
      onSurface: textWhite,
      onPrimary: textWhite,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textWhite),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textWhite),
        bodyLarge: TextStyle(fontSize: 16, color: textWhite),
        bodyMedium: TextStyle(fontSize: 14, color: textGrey),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    primaryColor: primaryPurple,
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: accentOrange,
      surface: Colors.white,
      onSurface: Color(0xFF0F172A),
      onPrimary: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF334155)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primaryPurple, Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient vibrantGradient = const LinearGradient(
    colors: [accentOrange, Color(0xFFFFB800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardGradient = const LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
