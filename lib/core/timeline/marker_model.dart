import 'package:flutter/foundation.dart';

enum MarkerColor {
  red,
  orange,
  yellow,
  green,
  cyan,
  blue,
  purple,
  pink;

  int get colorValue => switch (this) {
        MarkerColor.red => 0xFFFF453A,
        MarkerColor.orange => 0xFFFF9F0A,
        MarkerColor.yellow => 0xFFFFD60A,
        MarkerColor.green => 0xFF30D158,
        MarkerColor.cyan => 0xFF64D2FF,
        MarkerColor.blue => 0xFF0A84FF,
        MarkerColor.purple => 0xFFBF5AF2,
        MarkerColor.pink => 0xFFFF375F,
      };

  static MarkerColor fromName(String name) =>
      MarkerColor.values.firstWhere((e) => e.name == name,
          orElse: () => MarkerColor.blue);
}

@immutable
class MarkerModel {
  const MarkerModel({
    required this.id,
    required this.projectId,
    required this.time,
    this.name = '',
    this.note = '',
    this.color = MarkerColor.blue,
    this.durationUs = 0,
  });

  final String id;
  final String projectId;
  final Duration time;
  final String name;
  final String note;
  final MarkerColor color;
  final int durationUs; // 0 = point marker, >0 = range marker

  Duration get markerDuration => Duration(microseconds: durationUs);

  MarkerModel copyWith({
    String? id,
    String? projectId,
    Duration? time,
    String? name,
    String? note,
    MarkerColor? color,
    int? durationUs,
  }) {
    return MarkerModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      time: time ?? this.time,
      name: name ?? this.name,
      note: note ?? this.note,
      color: color ?? this.color,
      durationUs: durationUs ?? this.durationUs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MarkerModel(id: $id, time: $time, name: $name)';
}
