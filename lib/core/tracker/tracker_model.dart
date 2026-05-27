import 'package:flutter/foundation.dart';

enum TrackerStatus { idle, tracking, completed, failed }

@immutable
class TrackPoint {
  const TrackPoint({
    required this.time,
    required this.x,
    required this.y,
    this.confidence = 1.0,
  });

  final Duration time;
  final double x;
  final double y;
  final double confidence;

  TrackPoint copyWith({
    Duration? time,
    double? x,
    double? y,
    double? confidence,
  }) {
    return TrackPoint(
      time: time ?? this.time,
      x: x ?? this.x,
      y: y ?? this.y,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'timeUs': time.inMicroseconds,
        'x': x,
        'y': y,
        'confidence': confidence,
      };

  factory TrackPoint.fromJson(Map<String, dynamic> json) => TrackPoint(
        time: Duration(microseconds: json['timeUs'] as int),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      );
}

@immutable
class TrackerSession {
  const TrackerSession({
    required this.id,
    required this.clipId,
    required this.name,
    required this.pinX,
    required this.pinY,
    required this.pinTime,
    this.status = TrackerStatus.idle,
    this.points = const [],
    this.searchRadius = 60,
    this.colorHex = 0xFFFF6B00,
  });

  final String id;
  final String clipId;
  final String name;

  /// Normalized (0..1) position where the user dropped the pin on the preview.
  final double pinX;
  final double pinY;

  /// The media time at which the pin was placed.
  final Duration pinTime;

  final TrackerStatus status;
  final List<TrackPoint> points;

  /// Search window radius in pixels for the FFmpeg-based tracker.
  final int searchRadius;

  final int colorHex;

  TrackerSession copyWith({
    String? id,
    String? clipId,
    String? name,
    double? pinX,
    double? pinY,
    Duration? pinTime,
    TrackerStatus? status,
    List<TrackPoint>? points,
    int? searchRadius,
    int? colorHex,
  }) {
    return TrackerSession(
      id: id ?? this.id,
      clipId: clipId ?? this.clipId,
      name: name ?? this.name,
      pinX: pinX ?? this.pinX,
      pinY: pinY ?? this.pinY,
      pinTime: pinTime ?? this.pinTime,
      status: status ?? this.status,
      points: points ?? this.points,
      searchRadius: searchRadius ?? this.searchRadius,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  TrackPoint? pointAtTime(Duration time, {Duration tolerance = const Duration(milliseconds: 17)}) {
    for (final p in points) {
      if ((p.time - time).abs() <= tolerance) return p;
    }
    return null;
  }

  TrackPoint? interpolatedAt(Duration time) {
    if (points.isEmpty) return null;
    if (points.length == 1) return points.first;

    if (time <= points.first.time) return points.first;
    if (time >= points.last.time) return points.last;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (time >= a.time && time <= b.time) {
        final range = (b.time - a.time).inMicroseconds.toDouble();
        final t = range > 0
            ? (time - a.time).inMicroseconds / range
            : 0.0;
        return TrackPoint(
          time: time,
          x: a.x + (b.x - a.x) * t,
          y: a.y + (b.y - a.y) * t,
          confidence: a.confidence + (b.confidence - a.confidence) * t,
        );
      }
    }
    return points.last;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clipId': clipId,
        'name': name,
        'pinX': pinX,
        'pinY': pinY,
        'pinTimeUs': pinTime.inMicroseconds,
        'status': status.name,
        'searchRadius': searchRadius,
        'colorHex': colorHex,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory TrackerSession.fromJson(Map<String, dynamic> json) => TrackerSession(
        id: json['id'] as String,
        clipId: json['clipId'] as String,
        name: json['name'] as String,
        pinX: (json['pinX'] as num).toDouble(),
        pinY: (json['pinY'] as num).toDouble(),
        pinTime: Duration(microseconds: json['pinTimeUs'] as int),
        status: TrackerStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TrackerStatus.idle,
        ),
        searchRadius: json['searchRadius'] as int? ?? 60,
        colorHex: json['colorHex'] as int? ?? 0xFFFF6B00,
        points: (json['points'] as List<dynamic>?)
                ?.map((e) => TrackPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
