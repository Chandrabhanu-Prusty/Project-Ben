import 'package:flutter/material.dart';

/// Central design system tokens and theme definition for Ben.
/// Based strictly on the UI/UX Design Brief.
class AppColors {
  AppColors._();

  static const Color deepBlack = Color(0xFF050706);
  static const Color darkCharcoal = Color(0xFF0C100D);
  static const Color forestCharcoal = Color(0xFF111813);
  static const Color darkSlateGreen = Color(0xFF18221A);
  static const Color neonGreen = Color(0xFF39FF67);
  static const Color softGreen = Color(0xFFA5FFB6);
  static const Color alertRed = Color(0xFFFF5A5F);
  static const Color softWhite = Color(0xFFF4F7F4);
  static const Color mutedGrey = Color(0xFFADB8AF);
  static const Color disabledText = Color(0xFF758078);
  static const Color subtleGreenGrey = Color(0xFF28352B);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepBlack,
      primaryColor: AppColors.neonGreen,
      canvasColor: AppColors.darkCharcoal,
      cardColor: AppColors.forestCharcoal,
      dividerColor: AppColors.subtleGreenGrey,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonGreen,
        secondary: AppColors.softGreen,
        surface: AppColors.forestCharcoal,
        error: AppColors.alertRed,
        onPrimary: AppColors.deepBlack,
        onSecondary: AppColors.deepBlack,
        onSurface: AppColors.softWhite,
        onError: AppColors.softWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepBlack,
        foregroundColor: AppColors.softWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.softWhite,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCharcoal,
        selectedItemColor: AppColors.neonGreen,
        unselectedItemColor: AppColors.mutedGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.forestCharcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.subtleGreenGrey, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSlateGreen,
        hintStyle: const TextStyle(color: AppColors.mutedGrey, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.softWhite, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.subtleGreenGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.subtleGreenGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.alertRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.alertRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.deepBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.softWhite,
          side: const BorderSide(color: AppColors.subtleGreenGrey),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.neonGreen,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.softWhite,
        ),
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.softWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.softWhite,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.softWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.softWhite,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.mutedGrey,
          height: 1.4,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedGrey,
        ),
      ),
    );
  }
}
