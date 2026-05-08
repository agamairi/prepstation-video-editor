import 'package:flutter/material.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';

enum ClipType { video, audio, title, image, adjustment }

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

  Duration get duration => endOnTimeline - startOnTimeline;
  Duration get mediaDuration => mediaOutPoint - mediaInPoint;

  Color get labelColor =>
      ColorTokens.clipLabels[labelColorIndex % ColorTokens.clipLabels.length];

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
    String? transitionInId,
    String? transitionOutId,
    Duration? transitionInDuration,
    Duration? transitionOutDuration,
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
      transitionInId: transitionInId ?? this.transitionInId,
      transitionOutId: transitionOutId ?? this.transitionOutId,
      transitionInDuration: transitionInDuration ?? this.transitionInDuration,
      transitionOutDuration:
          transitionOutDuration ?? this.transitionOutDuration,
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
