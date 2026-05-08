import 'package:flutter/foundation.dart';

enum KeyframeInterpolation { linear, easeIn, easeOut, easeInOut, hold }

@immutable
class KeyframeModel {
  const KeyframeModel({
    required this.id,
    required this.parameterId,
    required this.time,
    required this.value,
    this.interpolation = KeyframeInterpolation.linear,
    this.inTangentX = 0.0,
    this.inTangentY = 0.0,
    this.outTangentX = 0.0,
    this.outTangentY = 0.0,
  });

  final String id;
  final String parameterId;
  final Duration time;
  final double value;
  final KeyframeInterpolation interpolation;

  // Bezier handle positions (normalized, relative to keyframe position)
  final double inTangentX;
  final double inTangentY;
  final double outTangentX;
  final double outTangentY;

  KeyframeModel copyWith({
    String? id,
    String? parameterId,
    Duration? time,
    double? value,
    KeyframeInterpolation? interpolation,
    double? inTangentX,
    double? inTangentY,
    double? outTangentX,
    double? outTangentY,
  }) {
    return KeyframeModel(
      id: id ?? this.id,
      parameterId: parameterId ?? this.parameterId,
      time: time ?? this.time,
      value: value ?? this.value,
      interpolation: interpolation ?? this.interpolation,
      inTangentX: inTangentX ?? this.inTangentX,
      inTangentY: inTangentY ?? this.inTangentY,
      outTangentX: outTangentX ?? this.outTangentX,
      outTangentY: outTangentY ?? this.outTangentY,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyframeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A sequence of keyframes for a single parameter.
@immutable
class ParameterCurve {
  const ParameterCurve({
    required this.parameterId,
    required this.keyframes,
    required this.defaultValue,
  });

  final String parameterId;
  final List<KeyframeModel> keyframes;
  final double defaultValue;

  List<KeyframeModel> get sorted =>
      List<KeyframeModel>.from(keyframes)
        ..sort((a, b) => a.time.compareTo(b.time));

  /// Evaluate the curve at [time] using the interpolation type of the
  /// preceding keyframe. Returns [defaultValue] if no keyframes exist.
  double evaluate(Duration time) {
    if (keyframes.isEmpty) return defaultValue;
    final kfs = sorted;
    if (time <= kfs.first.time) return kfs.first.value;
    if (time >= kfs.last.time) return kfs.last.value;

    KeyframeModel? prev;
    KeyframeModel? next;
    for (final kf in kfs) {
      if (kf.time <= time) {
        prev = kf;
      } else {
        next = kf;
        break;
      }
    }

    if (prev == null || next == null) return defaultValue;
    if (prev.interpolation == KeyframeInterpolation.hold) return prev.value;

    final t =
        (time - prev.time).inMicroseconds /
        (next.time - prev.time).inMicroseconds;

    return switch (prev.interpolation) {
      KeyframeInterpolation.linear => _lerp(prev.value, next.value, t),
      KeyframeInterpolation.easeIn => _lerp(
        prev.value,
        next.value,
        _easeIn(t),
      ),
      KeyframeInterpolation.easeOut => _lerp(
        prev.value,
        next.value,
        _easeOut(t),
      ),
      KeyframeInterpolation.easeInOut => _lerp(
        prev.value,
        next.value,
        _easeInOut(t),
      ),
      KeyframeInterpolation.hold => prev.value,
    };
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _easeIn(double t) => t * t;
  static double _easeOut(double t) => t * (2 - t);
  static double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

  ParameterCurve copyWith({
    String? parameterId,
    List<KeyframeModel>? keyframes,
    double? defaultValue,
  }) {
    return ParameterCurve(
      parameterId: parameterId ?? this.parameterId,
      keyframes: keyframes ?? this.keyframes,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }
}
