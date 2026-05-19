import 'package:flutter/material.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/segmentation/isolation_mode.dart';

enum ClipType { video, audio, title, image, adjustment, colorCard }

enum TextAnimationType {
  none,
  fadeIn,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  zoomIn,
  typewriter;

  String get displayName => switch (this) {
        TextAnimationType.none => 'None',
        TextAnimationType.fadeIn => 'Fade In',
        TextAnimationType.slideUp => 'Slide Up',
        TextAnimationType.slideDown => 'Slide Down',
        TextAnimationType.slideLeft => 'Slide Left',
        TextAnimationType.slideRight => 'Slide Right',
        TextAnimationType.zoomIn => 'Zoom In',
        TextAnimationType.typewriter => 'Typewriter',
      };

  static TextAnimationType fromId(String id) => TextAnimationType.values
      .firstWhere((e) => e.name == id, orElse: () => TextAnimationType.none);
}

enum BlendMode2 {
  normal,
  multiply,
  screen,
  overlay,
  add,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  hue,
  saturation,
  color,
  luminosity,
}

@immutable
class ClipModel {
  const ClipModel({
    required this.id,
    required this.trackId,
    required this.mediaId,
    required this.type,
    required this.startOnTimeline,
    required this.endOnTimeline,
    required this.mediaInPoint,
    required this.mediaOutPoint,
    this.speed = 1.0,
    this.opacity = 1.0,
    this.blendMode = BlendMode2.normal,
    this.labelColorIndex = 0,
    this.isVideoLinked = true,
    this.isAudioLinked = true,
    this.isMuted = false,
    this.isLocked = false,
    this.name = '',
    this.effectIds = const [],
    this.transitionInId,
    this.transitionOutId,
    this.transitionInDuration = Duration.zero,
    this.transitionOutDuration = Duration.zero,
    this.titleText,
    this.titleFontSize = AppConstants.defaultTitleFontSize,
    this.titleColorValue = AppConstants.defaultTitleColor,
    this.titleAlignment = 'center',
    this.cardColorValue = AppConstants.defaultCardColor,
    this.fontFamily = AppConstants.defaultFontFamily,
    this.textAnimationType = TextAnimationType.none,
    this.textAnimationDurationMs = AppConstants.textAnimationDurationMs,
    // Transform
    this.posX = 0.0,
    this.posY = 0.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.rotation = 0.0,
    this.anchorX = 0.5,
    this.anchorY = 0.5,
    // Crop (fraction 0.0–1.0 from each edge)
    this.cropLeft = 0.0,
    this.cropRight = 0.0,
    this.cropTop = 0.0,
    this.cropBottom = 0.0,
    // Clip flags
    this.isReversed = false,
    this.isFrozen = false,
    this.flipHorizontal = false,
    this.flipVertical = false,
    // Volume (per-clip audio level)
    this.volume = 1.0,
    // Subject isolation (background removal)
    this.isolationEnabled = false,
    this.isolationMode = IsolationMode.transparent,
    this.isolationColorValue = 0xFF00FF00,
    this.isolationBlurRadius = AppConstants.defaultIsolationBlurRadius,
    this.isolationEdgeFeather = AppConstants.defaultIsolationEdgeFeather,
    this.isolationMaskPath,
    this.isolationProcessing = false,
    this.isolationSelectionLeft,
    this.isolationSelectionTop,
    this.isolationSelectionRight,
    this.isolationSelectionBottom,
  });

  final String id;
  final String trackId;
  final String mediaId;
  final ClipType type;

  /// Position on the timeline (project time)
  final Duration startOnTimeline;
  final Duration endOnTimeline;

  /// Which part of the source media this clip uses
  final Duration mediaInPoint;
  final Duration mediaOutPoint;

  final double speed;
  final double opacity;
  final BlendMode2 blendMode;
  final int labelColorIndex;
  final bool isVideoLinked;
  final bool isAudioLinked;
  final bool isMuted;
  final bool isLocked;
  final String name;
  final List<String> effectIds;
  final String? transitionInId;
  final String? transitionOutId;
  final Duration transitionInDuration;
  final Duration transitionOutDuration;

  // Title clip fields
  final String? titleText;
  final double titleFontSize;
  final int titleColorValue;
  final String titleAlignment; // 'left' | 'center' | 'right'

  // Color-card clip field
  final int cardColorValue;

  // Font & animation (title, colorCard, and image clips)
  final String fontFamily;
  final TextAnimationType textAnimationType;
  final int textAnimationDurationMs;

  // Transform (position in pixels relative to comp center, scale 1.0=100%)
  final double posX;
  final double posY;
  final double scaleX;
  final double scaleY;
  final double rotation; // degrees
  final double anchorX; // 0.0–1.0 (fraction of clip width)
  final double anchorY; // 0.0–1.0 (fraction of clip height)

  // Crop (fraction 0.0–1.0 removed from each edge)
  final double cropLeft;
  final double cropRight;
  final double cropTop;
  final double cropBottom;

  // Clip flags
  final bool isReversed;
  final bool isFrozen; // freeze frame at playhead
  final bool flipHorizontal;
  final bool flipVertical;

  // Per-clip audio volume
  final double volume;

  // Subject isolation (background removal)
  final bool isolationEnabled;
  final IsolationMode isolationMode;
  final int isolationColorValue;
  final double isolationBlurRadius;
  final double isolationEdgeFeather;
  final String? isolationMaskPath;
  final bool isolationProcessing;
  final double? isolationSelectionLeft;
  final double? isolationSelectionTop;
  final double? isolationSelectionRight;
  final double? isolationSelectionBottom;

  Duration get duration => endOnTimeline - startOnTimeline;
  Duration get mediaDuration => mediaOutPoint - mediaInPoint;

  Color get labelColor =>
      ColorTokens.clipLabels[labelColorIndex % ColorTokens.clipLabels.length];

  // Sentinel used by copyWith to distinguish "omitted" from "explicitly null"
  // for nullable String fields (transitionInId, transitionOutId).
  static const Object _omit = Object();

  ClipModel copyWith({
    String? id,
    String? trackId,
    String? mediaId,
    ClipType? type,
    Duration? startOnTimeline,
    Duration? endOnTimeline,
    Duration? mediaInPoint,
    Duration? mediaOutPoint,
    double? speed,
    double? opacity,
    BlendMode2? blendMode,
    int? labelColorIndex,
    bool? isVideoLinked,
    bool? isAudioLinked,
    bool? isMuted,
    bool? isLocked,
    String? name,
    List<String>? effectIds,
    Object? transitionInId = _omit,
    Object? transitionOutId = _omit,
    Duration? transitionInDuration,
    Duration? transitionOutDuration,
    Object? titleText = _omit,
    double? titleFontSize,
    int? titleColorValue,
    String? titleAlignment,
    int? cardColorValue,
    String? fontFamily,
    TextAnimationType? textAnimationType,
    int? textAnimationDurationMs,
    double? posX,
    double? posY,
    double? scaleX,
    double? scaleY,
    double? rotation,
    double? anchorX,
    double? anchorY,
    double? cropLeft,
    double? cropRight,
    double? cropTop,
    double? cropBottom,
    bool? isReversed,
    bool? isFrozen,
    bool? flipHorizontal,
    bool? flipVertical,
    double? volume,
    bool? isolationEnabled,
    IsolationMode? isolationMode,
    int? isolationColorValue,
    double? isolationBlurRadius,
    double? isolationEdgeFeather,
    Object? isolationMaskPath = _omit,
    bool? isolationProcessing,
    Object? isolationSelectionLeft = _omit,
    Object? isolationSelectionTop = _omit,
    Object? isolationSelectionRight = _omit,
    Object? isolationSelectionBottom = _omit,
  }) {
    return ClipModel(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      mediaId: mediaId ?? this.mediaId,
      type: type ?? this.type,
      startOnTimeline: startOnTimeline ?? this.startOnTimeline,
      endOnTimeline: endOnTimeline ?? this.endOnTimeline,
      mediaInPoint: mediaInPoint ?? this.mediaInPoint,
      mediaOutPoint: mediaOutPoint ?? this.mediaOutPoint,
      speed: speed ?? this.speed,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      labelColorIndex: labelColorIndex ?? this.labelColorIndex,
      isVideoLinked: isVideoLinked ?? this.isVideoLinked,
      isAudioLinked: isAudioLinked ?? this.isAudioLinked,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      name: name ?? this.name,
      effectIds: effectIds ?? this.effectIds,
      transitionInId: transitionInId == _omit
          ? this.transitionInId
          : transitionInId as String?,
      transitionOutId: transitionOutId == _omit
          ? this.transitionOutId
          : transitionOutId as String?,
      transitionInDuration: transitionInDuration ?? this.transitionInDuration,
      transitionOutDuration:
          transitionOutDuration ?? this.transitionOutDuration,
      titleText: titleText == _omit ? this.titleText : titleText as String?,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      titleColorValue: titleColorValue ?? this.titleColorValue,
      titleAlignment: titleAlignment ?? this.titleAlignment,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      textAnimationType: textAnimationType ?? this.textAnimationType,
      textAnimationDurationMs:
          textAnimationDurationMs ?? this.textAnimationDurationMs,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      rotation: rotation ?? this.rotation,
      anchorX: anchorX ?? this.anchorX,
      anchorY: anchorY ?? this.anchorY,
      cropLeft: cropLeft ?? this.cropLeft,
      cropRight: cropRight ?? this.cropRight,
      cropTop: cropTop ?? this.cropTop,
      cropBottom: cropBottom ?? this.cropBottom,
      isReversed: isReversed ?? this.isReversed,
      isFrozen: isFrozen ?? this.isFrozen,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      volume: volume ?? this.volume,
      isolationEnabled: isolationEnabled ?? this.isolationEnabled,
      isolationMode: isolationMode ?? this.isolationMode,
      isolationColorValue: isolationColorValue ?? this.isolationColorValue,
      isolationBlurRadius: isolationBlurRadius ?? this.isolationBlurRadius,
      isolationEdgeFeather: isolationEdgeFeather ?? this.isolationEdgeFeather,
      isolationMaskPath: isolationMaskPath == _omit
          ? this.isolationMaskPath
          : isolationMaskPath as String?,
      isolationProcessing: isolationProcessing ?? this.isolationProcessing,
      isolationSelectionLeft: isolationSelectionLeft == _omit
          ? this.isolationSelectionLeft
          : isolationSelectionLeft as double?,
      isolationSelectionTop: isolationSelectionTop == _omit
          ? this.isolationSelectionTop
          : isolationSelectionTop as double?,
      isolationSelectionRight: isolationSelectionRight == _omit
          ? this.isolationSelectionRight
          : isolationSelectionRight as double?,
      isolationSelectionBottom: isolationSelectionBottom == _omit
          ? this.isolationSelectionBottom
          : isolationSelectionBottom as double?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClipModel(id: $id, type: $type, start: $startOnTimeline, '
      'end: $endOnTimeline)';
}
