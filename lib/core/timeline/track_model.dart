import 'package:flutter/foundation.dart';
import 'package:prepstation/core/constants/app_constants.dart';

enum TrackType { video, audio, title, adjustment, null_ }

@immutable
class TrackModel {
  const TrackModel({
    required this.id,
    required this.projectId,
    required this.type,
    required this.index,
    this.name = '',
    this.height = AppConstants.defaultTrackHeight,
    this.isMuted = false,
    this.isSoloed = false,
    this.isLocked = false,
    this.isVisible = true,
    this.volume = 1.0,
    this.pan = 0.0,
  });

  final String id;
  final String projectId;
  final TrackType type;
  final int index;
  final String name;
  final double height;
  final bool isMuted;
  final bool isSoloed;
  final bool isLocked;
  final bool isVisible;
  final double volume;
  final double pan;

  bool get isVideo =>
      type == TrackType.video || type == TrackType.adjustment;
  bool get isAudio => type == TrackType.audio;

  String get displayName {
    if (name.isNotEmpty) return name;
    return switch (type) {
      TrackType.video => 'V${index + 1}',
      TrackType.audio => 'A${index + 1}',
      TrackType.title => 'T${index + 1}',
      TrackType.adjustment => 'Adj${index + 1}',
      TrackType.null_ => 'Null${index + 1}',
    };
  }

  TrackModel copyWith({
    String? id,
    String? projectId,
    TrackType? type,
    int? index,
    String? name,
    double? height,
    bool? isMuted,
    bool? isSoloed,
    bool? isLocked,
    bool? isVisible,
    double? volume,
    double? pan,
  }) {
    return TrackModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      index: index ?? this.index,
      name: name ?? this.name,
      height: height ?? this.height,
      isMuted: isMuted ?? this.isMuted,
      isSoloed: isSoloed ?? this.isSoloed,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
