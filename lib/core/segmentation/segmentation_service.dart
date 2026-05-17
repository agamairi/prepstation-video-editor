import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final segmentationServiceProvider = Provider<SegmentationService>(
  (ref) => SegmentationService(),
);

enum SegmentationQuality { fast, balanced, accurate }

class SegmentationService {
  static const _channel = MethodChannel('com.fluxedit/segmentation');

  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> segmentFrame({
    required String videoPath,
    required Duration timestamp,
    SegmentationQuality quality = SegmentationQuality.balanced,
  }) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>(
        'segmentFrame',
        {
          'videoPath': videoPath,
          'timestampUs': timestamp.inMicroseconds,
          'quality': quality.name,
        },
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<String?> generateMaskVideo({
    required String videoPath,
    required String outputPath,
    required Duration inPoint,
    required Duration outPoint,
    SegmentationQuality quality = SegmentationQuality.balanced,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (onProgress != null) {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'onMaskProgress') {
            final progress = call.arguments as double;
            onProgress(progress);
          }
        });
      }

      final result = await _channel.invokeMethod<String>(
        'generateMaskVideo',
        {
          'videoPath': videoPath,
          'outputPath': outputPath,
          'inPointUs': inPoint.inMicroseconds,
          'outPointUs': outPoint.inMicroseconds,
          'quality': quality.name,
        },
      );

      _channel.setMethodCallHandler(null);
      return result;
    } catch (_) {
      _channel.setMethodCallHandler(null);
      return null;
    }
  }

  Future<void> cancelProcessing() async {
    try {
      await _channel.invokeMethod<void>('cancelProcessing');
    } catch (_) {
      // ignore
    }
  }
}
