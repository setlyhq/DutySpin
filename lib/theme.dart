import 'package:flutter/material.dart';

class AppTheme {
  // Base background matches the lighter, airy dashboard look.
  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFE7EDF7);
  static const Color border = Color(0xFFE2E8F0);
  static const Color text = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  // Brand primary (used for primary CTA button & selected tab).
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryMuted = Color(0xFFE0EDFF);

  // Welcome screen CTA/button color (kept aligned with primary).
  static const Color welcomeCta = Color(0xFF2563EB);
  static const Color warningBg = Color(0xFFFEF9C3);
  static const Color warningText = Color(0xFF92400E);

  // Accent colors (used in Welcome hero cards)
  static const Color success = Color(0xFF22C55E);
  static const Color successMuted = Color(0xFFEAFBF1);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentOrangeMuted = Color(0xFFFFF5E6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleMuted = Color(0xFFF2EEFF);

  // Welcome background gradient endpoints
  static const Color welcomeBgTop = Color(0xFFF1EEFF);
  static const Color welcomeBgBottom = Color(0xFFFFF5EA);

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: text,
        outline: border,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w900, color: text),
        titleMedium: const TextStyle(fontWeight: FontWeight.w800, color: text),
        bodyMedium: const TextStyle(color: text),
        bodySmall: const TextStyle(color: textMuted),
      ),
    );
  }
}
