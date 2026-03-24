import 'package:flutter/material.dart';

import 'colors.dart';

class AppTheme {
  AppTheme._(); // Prevent instantiation

  static const double _baseBody = 16.0;
  static const double _baseTitle = 16.0;
  static const double _baseHeadline = 24.0;

  static double _scale(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide / 360.0).clamp(0.85, 1.40);
  }

  static TextStyle _ts({
    required BuildContext context,
    required double baseSize,
    FontWeight weight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: baseSize * _scale(context),
      fontWeight: weight,
      color: color,
      height: 1.5,
      letterSpacing: 0.15,
    );
  }

  //  Light Theme
  static ThemeData light(BuildContext context) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // ── Color Scheme ────────────────────────────
    colorScheme: const ColorScheme.light(
      surface: bgLight,
      onSurface: darkIconBackgroundColor,
      primary: fontLight,
      onPrimary: subFontLight,
      primaryContainer: containerLight,
      onPrimaryContainer: forGroundLight,
      outline: outlineLight,
      outlineVariant: forGroundOutlineLight,
      error: red,
    ),

    scaffoldBackgroundColor: bgLight,

    // ── Icons ────────────────────────────────────
    iconTheme: const IconThemeData(color: fontLight, size: 24),

    // ── Divider ──────────────────────────────────
    dividerColor: outlineLight,
    dividerTheme: const DividerThemeData(
      color: outlineLight,
      thickness: 1.5,
      space: 1,
    ),

    // ── Text Theme ───────────────────────────────
    textTheme: TextTheme(
      // -- Display --
      displayLarge: _ts(
        context: context,
        baseSize: 36,
        weight: FontWeight.bold,
        color: fontLight,
      ),
      displayMedium: _ts(
        context: context,
        baseSize: _baseTitle - 6,
        color: subFontLight,
      ),
      displaySmall: _ts(
        context: context,
        baseSize: _baseHeadline - 4,
        weight: FontWeight.w700,
        color: fontLight,
      ),
      // -- Headline --
      headlineLarge: _ts(
        context: context,
        baseSize: _baseHeadline + 8,
        weight: FontWeight.bold,
        color: fontLight,
      ),
      headlineMedium: _ts(
        context: context,
        baseSize: _baseHeadline + 2,
        weight: FontWeight.w600,
        color: fontLight,
      ),
      headlineSmall: _ts(
        context: context,
        baseSize: _baseHeadline - 2,
        weight: FontWeight.w600,
        color: fontLight,
      ),
      // -- Title --
      titleLarge: _ts(
        context: context,
        baseSize: _baseTitle + 2,
        weight: FontWeight.w600,
        color: fontLight,
      ),
      titleMedium: _ts(
        context: context,
        baseSize: _baseTitle,
        weight: FontWeight.w600,
        color: fontLight,
      ),
      titleSmall: _ts(
        context: context,
        baseSize: _baseTitle - 3,
        color: fontLight,
      ),
      // -- Body --
      bodyLarge: _ts(context: context, baseSize: _baseBody, color: fontLight),
      bodyMedium: _ts(
        context: context,
        baseSize: _baseBody - 3,
        color: subFontLight,
      ),
      bodySmall: _ts(
        context: context,
        baseSize: _baseBody - 4,
        color: subFontLight,
      ),
      // -- Label --
      labelLarge: _ts(
        context: context,
        baseSize: _baseBody - 2,
        weight: FontWeight.w500,
        color: fontLight,
      ),
      labelMedium: _ts(
        context: context,
        baseSize: _baseBody - 6,
        color: fontLight,
      ),
      labelSmall: _ts(
        context: context,
        baseSize: _baseBody - 8,
        color: fontLight,
      ),
    ),
  );


  //  Dark Theme
  static ThemeData dark(BuildContext context) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,

    // ── Color Scheme ────────────────────────────
    colorScheme: const ColorScheme.dark(
      surface: bgDark,
      onSurface: lightIconBackgroundColor,
      primary: fontDark,
      onPrimary: subFontDark,
      primaryContainer: containerDark,
      onPrimaryContainer: forGroundDark,
      outline: outlineDark,
      outlineVariant: forGroundOutlineDark,
      error: redDark,
    ),

    scaffoldBackgroundColor: bgDark,

    // ── Icons ────────────────────────────────────
    iconTheme: const IconThemeData(color: fontDark, size: 24),

    // ── Divider ──────────────────────────────────
    dividerColor: outlineDark,
    dividerTheme: const DividerThemeData(
      color: outlineDark,
      thickness: 1,
      space: 1,
    ),

    // ── Text Theme ───────────────────────────────
    textTheme: TextTheme(
      // -- Display --
      displayLarge: _ts(
        context: context,
        baseSize: 36,
        weight: FontWeight.bold,
        color: fontDark,
      ),
      displayMedium: _ts(
        context: context,
        baseSize: _baseTitle - 6,
        color: subFontDark,
      ),
      displaySmall: _ts(
        context: context,
        baseSize: _baseHeadline - 4,
        weight: FontWeight.w600,
        color: fontDark,
      ),
      // -- Headline --
      headlineLarge: _ts(
        context: context,
        baseSize: _baseHeadline + 8,
        weight: FontWeight.bold,
        color: fontDark,
      ),
      headlineMedium: _ts(
        context: context,
        baseSize: _baseHeadline + 2,
        weight: FontWeight.w600,
        color: fontDark,
      ),
      headlineSmall: _ts(
        context: context,
        baseSize: _baseHeadline - 2,
        weight: FontWeight.w600,
        color: fontDark,
      ),
      // -- Title --
      titleLarge: _ts(
        context: context,
        baseSize: _baseTitle + 2,
        weight: FontWeight.w600,
        color: fontDark,
      ),
      titleMedium: _ts(
        context: context,
        baseSize: _baseTitle,
        weight: FontWeight.w600,
        color: fontDark,
      ),
      titleSmall: _ts(
        context: context,
        baseSize: _baseTitle - 4,
        color: fontDark,
      ),
      // -- Body --
      bodyLarge: _ts(context: context, baseSize: _baseBody, color: fontDark),
      bodyMedium: _ts(
        context: context,
        baseSize: _baseBody - 3,
        color: subFontDark,
      ),
      bodySmall: _ts(
        context: context,
        baseSize: _baseBody - 4,
        color: subFontDark,
      ),
      // -- Label --
      labelLarge: _ts(
        context: context,
        baseSize: _baseBody - 2,
        weight: FontWeight.w500,
        color: fontDark,
      ),
      labelMedium: _ts(
        context: context,
        baseSize: _baseBody - 6,
        color: fontDark,
      ),
      labelSmall: _ts(
        context: context,
        baseSize: _baseBody - 8,
        color: fontDark,
      ),
    ),
  );
}
