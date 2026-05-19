import 'package:flutter/foundation.dart';
import 'package:prepstation/core/constants/app_constants.dart';

@immutable
class CompositionModel {
  const CompositionModel({
    required this.id,
    required this.name,
    this.width = AppConstants.defaultWidth,
    this.height = AppConstants.defaultHeight,
    this.frameRate = AppConstants.defaultFrameRate,
    this.duration = Duration.zero,
    this.backgroundColor = 0xFF000000,
    this.pixelAspectRatio = 1.0,
  });

  final String id;
  final String name;
  final int width;
  final int height;
  final double frameRate;
  final Duration duration;
  final int backgroundColor;
  final double pixelAspectRatio;

  Duration get frameDuration =>
      Duration(microseconds: (1000000 / frameRate).round());

  int get totalFrames => (duration.inMicroseconds / frameDuration.inMicroseconds).ceil();

  Duration frameToTime(int frame) =>
      Duration(microseconds: (frame * frameDuration.inMicroseconds).round());

  int timeToFrame(Duration time) =>
      (time.inMicroseconds / frameDuration.inMicroseconds).floor();

  String get frameRateDisplay {
    const pairs = [
      [23.976, '23.976'], [24.0, '24'], [25.0, '25'],
      [29.97, '29.97'], [30.0, '30'], [50.0, '50'],
      [59.94, '59.94'], [60.0, '60'],
    ];
    for (final pair in pairs) {
      if ((frameRate - (pair[0] as double)).abs() < 0.01) {
        return pair[1] as String;
      }
    }
    return frameRate.toStringAsFixed(2);
  }

  CompositionModel copyWith({
    String? id,
    String? name,
    int? width,
    int? height,
    double? frameRate,
    Duration? duration,
    int? backgroundColor,
    double? pixelAspectRatio,
  }) {
    return CompositionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      duration: duration ?? this.duration,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      pixelAspectRatio: pixelAspectRatio ?? this.pixelAspectRatio,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompositionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
