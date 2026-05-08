import 'package:flutter/material.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';

abstract final class AppTypography {
  static const String _fontFamily = 'SF Pro Display';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ColorTokens.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: ColorTokens.textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textDisabled,
    letterSpacing: 0.3,
  );

  static const TextStyle monoMedium = TextStyle(
    fontFamily: 'SF Mono',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textPrimary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: 'SF Mono',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: ColorTokens.textSecondary,
  );

  static const TextStyle timecode = TextStyle(
    fontFamily: 'SF Mono',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorTokens.textPrimary,
    letterSpacing: 1.0,
  );
}
