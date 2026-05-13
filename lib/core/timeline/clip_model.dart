import 'package:flutter/material.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/core/constants/app_constants.dart';

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

  // Font & animation (title and colorCard clips)
  final String fontFamily;
  final TextAnimationType textAnimationType;

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
