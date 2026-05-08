import 'package:flutter/material.dart';

abstract final class ColorTokens {
  // ── Background hierarchy ──────────────────────────────────────────────────
  static const Color backgroundDeep = Color(0xFF0E0E0F);
  static const Color backgroundBase = Color(0xFF1A1A1B);
  static const Color backgroundPanel = Color(0xFF222224);
  static const Color backgroundSurface = Color(0xFF2A2A2D);
  static const Color backgroundElevated = Color(0xFF333337);
  static const Color backgroundHover = Color(0xFF3A3A3F);

  // ── Panel / border lines ──────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF2E2E32);
  static const Color borderDefault = Color(0xFF3C3C42);
  static const Color borderStrong = Color(0xFF505057);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEAEAEE);
  static const Color textSecondary = Color(0xFFA0A0AA);
  static const Color textDisabled = Color(0xFF606068);
  static const Color textInverse = Color(0xFF0E0E0F);

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accentPrimary = Color(0xFF4D9CFF);
  static const Color accentPrimaryHover = Color(0xFF6EB1FF);
  static const Color accentPrimaryPressed = Color(0xFF2E7BE0);
  static const Color accentSecondary = Color(0xFF9B6DFF);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C47A);
  static const Color warning = Color(0xFFFFB340);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF4D9CFF);

  // ── Timeline specific ─────────────────────────────────────────────────────
  static const Color playhead = Color(0xFFFF5252);
  static const Color clipVideo = Color(0xFF1E4D8C);
  static const Color clipVideoHover = Color(0xFF265FA8);
  static const Color clipVideoSelected = Color(0xFF4D9CFF);
  static const Color clipAudio = Color(0xFF1A5C3A);
  static const Color clipAudioHover = Color(0xFF1E6E45);
  static const Color clipAudioSelected = Color(0xFF34C47A);
  static const Color clipTitle = Color(0xFF5C3A7A);
  static const Color clipThumbnailOverlay = Color(0x88000000);
  static const Color waveformColor = Color(0xFF34C47A);
  static const Color waveformBackground = Color(0xFF0E2A1A);
  static const Color renderCacheBar = Color(0xFF34C47A);
  static const Color markerDefault = Color(0xFFFFB340);
  static const Color trackDivider = Color(0xFF2E2E32);
  static const Color timeRuler = Color(0xFF1A1A1B);
  static const Color timeRulerTick = Color(0xFF505057);
  static const Color timeRulerText = Color(0xFFA0A0AA);
  static const Color snapIndicator = Color(0xFFFFB340);
  static const Color inOutRange = Color(0x334D9CFF);

  // ── Clip label colors ─────────────────────────────────────────────────────
  static const List<Color> clipLabels = [
    Color(0xFF4D9CFF),
    Color(0xFF34C47A),
    Color(0xFFFFB340),
    Color(0xFFFF5252),
    Color(0xFF9B6DFF),
    Color(0xFFFF6B9D),
    Color(0xFF40D9F3),
    Color(0xFFBBBBBB),
  ];

  // ── Inspector / Effects panel ─────────────────────────────────────────────
  static const Color inspectorBackground = Color(0xFF1E1E21);
  static const Color inspectorSection = Color(0xFF252528);
  static const Color sliderTrack = Color(0xFF3C3C42);
  static const Color sliderThumb = Color(0xFF4D9CFF);
  static const Color keyframeDot = Color(0xFFFFB340);
  static const Color keyframeDiamond = Color(0xFFFFB340);
  static const Color transitionStripe = Color(0xFF9B6DFF);

  // ── Scopes ────────────────────────────────────────────────────────────────
  static const Color scopeBackground = Color(0xFF0A0A0C);
  static const Color scopeGridLine = Color(0x33FFFFFF);
  static const Color scopeRed = Color(0xFFFF4444);
  static const Color scopeGreen = Color(0xFF44FF44);
  static const Color scopeBlue = Color(0xFF4488FF);
  static const Color scopeLuma = Color(0xFFFFFFFF);
}
