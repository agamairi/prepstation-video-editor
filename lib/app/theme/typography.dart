import 'package:flutter/material.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';

abstract final class AppTypography {
  static const String _fontFamily = 'SF Pro Display';
  static const String _fontFamilyMono = 'SF Mono';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.8,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ColorTokens.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: ColorTokens.textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textDisabled,
    letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static const TextStyle monoMedium = TextStyle(
    fontFamily: _fontFamilyMono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: _fontFamilyMono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
  );

  static const TextStyle timecode = TextStyle(
    fontFamily: _fontFamilyMono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorTokens.textPrimary,
    letterSpacing: 0.8,
  );
}
