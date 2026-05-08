// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const String appName = 'FluxEdit';
  static const String projectFileExtension = '.fluxedit';
  static const String proxyFileSuffix = '_proxy';

  // Project auto-save interval
  static const Duration autoSaveInterval = Duration(seconds: 30);

  // Max undo steps
  static const int maxUndoSteps = 100;

  // Max auto-save versions retained
  static const int maxAutoSaveVersions = 10;

  // Thumbnail sizes
  static const int thumbnailWidth = 160;
  static const int thumbnailHeight = 90;
  static const int timelineThumbnailWidth = 80;
  static const int timelineThumbnailHeight = 45;

  // Preview resolutions (denominator — 1=full, 2=half, 4=quarter, 8=eighth)
  static const List<int> previewResolutionDivisors = [1, 2, 4, 8];

  // Supported frame rates
  static const List<double> supportedFrameRates = [
    23.976, 24, 25, 29.97, 30, 50, 59.94, 60,
  ];

  // Default project frame rate
  static const double defaultFrameRate = 30.0;

  // Default project resolution
  static const int defaultWidth = 1920;
  static const int defaultHeight = 1080;

  // Minimum window size (macOS)
  static const double minWindowWidth = 1280;
  static const double minWindowHeight = 720;

  // Timeline defaults
  static const double defaultTimelineZoom = 50.0; // px per second
  static const double minTimelineZoom = 5.0;
  static const double maxTimelineZoom = 1000.0;
  static const double defaultTrackHeight = 56.0;
  static const double minTrackHeight = 32.0;
  static const double maxTrackHeight = 160.0;
  static const double trackHeaderWidth = 160.0;

  // Snap threshold (pixels)
  static const double snapThreshold = 8.0;

  // Clip speed range
  static const double minClipSpeed = 0.1;
  static const double maxClipSpeed = 16.0;

  // Clip opacity range
  static const double minOpacity = 0.0;
  static const double maxOpacity = 1.0;

  // Waveform extraction
  static const int waveformSampleRate = 200; // peaks per second
  static const int maxWaveformPeaks = 4000; // max stored peaks per asset

  // Effects
  static const int maxEffectsPerClip = 8;

  // Transitions
  static const double minTransitionDuration = 0.1;
  static const double maxTransitionDuration = 2.0;
  static const double defaultTransitionDuration = 0.5;

  // Proxy resolution divisor
  static const int proxyResolutionDivisor = 4;
  static const int proxyCrf = 28;

  // Audio scrub pitch correction window
  static const Duration audioPitchWindow = Duration(milliseconds: 200);

  // Preview buffer target
  static const Duration previewBufferTarget = Duration(seconds: 5);

  // Platform detection helpers
  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isDesktop => isMacOS;
  static bool get isMobile => isIOS || isAndroid;
}
