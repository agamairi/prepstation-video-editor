import 'package:flutter/material.dart';

abstract final class ColorTokens {
  // ── Background hierarchy ──────────────────────────────────────────────────
  static const Color backgroundDeep = Color(0xFF0A0A0C);
  static const Color backgroundBase = Color(0xFF141416);
  static const Color backgroundPanel = Color(0xFF1C1C1F);
  static const Color backgroundSurface = Color(0xFF242428);
  static const Color backgroundElevated = Color(0xFF2C2C30);
  static const Color backgroundHover = Color(0xFF343438);

  // ── Panel / border lines ──────────────────────────────────────────────────
  static const Color borderSubtle = Color(0x0FFFFFFF);
  static const Color borderDefault = Color(0x1AFFFFFF);
  static const Color borderStrong = Color(0x30FFFFFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8A8A8E);
  static const Color textDisabled = Color(0xFF48484A);
  static const Color textInverse = Color(0xFF0A0A0C);

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accentPrimary = Color(0xFF0A84FF);
  static const Color accentPrimaryHover = Color(0xFF389AFF);
  static const Color accentPrimaryPressed = Color(0xFF0070E0);
  static const Color accentSecondary = Color(0xFFBF5AF2);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);

  // ── Timeline specific ─────────────────────────────────────────────────────
  static const Color playhead = Color(0xFFFF453A);
  static const Color clipVideo = Color(0xFF1A3D70);
  static const Color clipVideoHover = Color(0xFF214E8A);
  static const Color clipVideoSelected = Color(0xFF0A84FF);
  static const Color clipAudio = Color(0xFF0C3621);
  static const Color clipAudioHover = Color(0xFF0F4428);
  static const Color clipAudioSelected = Color(0xFF30D158);
  static const Color clipTitle = Color(0xFF3D1E5E);
  static const Color clipThumbnailOverlay = Color(0x66000000);
  static const Color waveformColor = Color(0xFF30D158);
  static const Color waveformBackground = Color(0xFF061B10);
  static const Color renderCacheBar = Color(0xFF30D158);
  static const Color markerDefault = Color(0xFFFF9F0A);
  static const Color trackDivider = Color(0x0FFFFFFF);
  static const Color timeRuler = Color(0xFF141416);
  static const Color timeRulerTick = Color(0xFF48484A);
  static const Color timeRulerText = Color(0xFF8A8A8E);
  static const Color snapIndicator = Color(0xFFFF9F0A);
  static const Color inOutRange = Color(0x200A84FF);

  // ── Clip label colors ─────────────────────────────────────────────────────
  static const List<Color> clipLabels = [
    Color(0xFF0A84FF),
    Color(0xFF30D158),
    Color(0xFFFF9F0A),
    Color(0xFFFF453A),
    Color(0xFFBF5AF2),
    Color(0xFFFF375F),
    Color(0xFF5AC8FA),
    Color(0xFF8A8A8E),
  ];

  // ── Inspector / Effects panel ─────────────────────────────────────────────
  static const Color inspectorBackground = Color(0xFF141416);
  static const Color inspectorSection = Color(0xFF1C1C1F);
  static const Color sliderTrack = Color(0xFF2C2C30);
  static const Color sliderThumb = Color(0xFF0A84FF);
  static const Color keyframeDot = Color(0xFFFF9F0A);
  static const Color keyframeDiamond = Color(0xFFFF9F0A);
  static const Color transitionStripe = Color(0xFFBF5AF2);

  // ── Scopes ────────────────────────────────────────────────────────────────
  static const Color scopeBackground = Color(0xFF080808);
  static const Color scopeGridLine = Color(0x1AFFFFFF);
  static const Color scopeRed = Color(0xFFFF453A);
  static const Color scopeGreen = Color(0xFF30D158);
  static const Color scopeBlue = Color(0xFF0A84FF);
  static const Color scopeLuma = Color(0xFFF5F5F7);

  // ── Project card gradients ────────────────────────────────────────────────
  static const List<List<Color>> projectGradients = [
    [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
    [Color(0xFF30D158), Color(0xFF0A84FF)],
    [Color(0xFFFF9F0A), Color(0xFFFF375F)],
    [Color(0xFFBF5AF2), Color(0xFF0A84FF)],
    [Color(0xFF5AC8FA), Color(0xFF30D158)],
    [Color(0xFFFF375F), Color(0xFFBF5AF2)],
    [Color(0xFF30D158), Color(0xFF5AC8FA)],
    [Color(0xFF0A84FF), Color(0xFF30D158)],
  ];
}
