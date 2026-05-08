import 'package:flutter/foundation.dart';

@immutable
class WaveformData {
  const WaveformData({
    required this.assetId,
    required this.peaks,
    required this.sampleRate,
  });

  final String assetId;

  /// Normalized amplitude values in [0, 1], sampled at [sampleRate] per second.
  final List<double> peaks;

  /// Samples per second of the peaks list.
  final int sampleRate;

  Duration get totalDuration => Duration(
        microseconds: peaks.isEmpty
            ? 0
            : (peaks.length / sampleRate * 1000000).round(),
      );

  /// Returns [pixelCount] peak values representing [start]..[end] of the media.
  List<double> peaksForRange(Duration start, Duration end, int pixelCount) {
    if (peaks.isEmpty || pixelCount <= 0) return List.filled(pixelCount, 0.0);

    final startIdx = (start.inMicroseconds / 1000000.0 * sampleRate)
        .round()
        .clamp(0, peaks.length - 1);
    final endIdx = (end.inMicroseconds / 1000000.0 * sampleRate)
        .round()
        .clamp(startIdx, peaks.length);

    final rangeLen = endIdx - startIdx;
    if (rangeLen <= 0) return List.filled(pixelCount, 0.0);

    return List.generate(pixelCount, (i) {
      final from = startIdx + (i / pixelCount * rangeLen).floor();
      final to = (startIdx + ((i + 1) / pixelCount * rangeLen).floor())
          .clamp(from + 1, peaks.length);
      double max = 0;
      for (var j = from; j < to; j++) {
        if (peaks[j] > max) max = peaks[j];
      }
      return max;
    });
  }
}
