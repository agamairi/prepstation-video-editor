import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';

final thumbnailGeneratorProvider = Provider<ThumbnailGenerator>(
  (ref) => ThumbnailGenerator(),
);

class ThumbnailGenerator {
  /// Generates a JPEG thumbnail at [timestamp] from [sourceFilePath].
  /// Returns the path to the generated thumbnail, or null on failure.
  Future<String?> generateThumbnail({
    required String sourceFilePath,
    required String assetId,
    Duration timestamp = const Duration(seconds: 1),
    int width = AppConstants.thumbnailWidth,
    int height = AppConstants.thumbnailHeight,
  }) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final thumbDir = Directory('${cacheDir.path}/thumbnails');
      await thumbDir.create(recursive: true);

      final outputPath = '${thumbDir.path}/$assetId.jpg';

      // Skip if already exists
      if (File(outputPath).existsSync()) return outputPath;

      final ts = _formatTimestamp(timestamp);
      final command =
          '-y -ss $ts -i "$sourceFilePath" '
          '-vframes 1 -vf "scale=$width:$height:force_original_aspect_ratio='
          'decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2" '
          '-q:v 3 "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) && File(outputPath).existsSync()) {
        return outputPath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Generates multiple thumbnails at evenly spaced intervals (for timeline).
  Future<List<String>> generateTimelineThumbnails({
    required String sourceFilePath,
    required String assetId,
    required Duration mediaDuration,
    int count = 10,
    int width = AppConstants.timelineThumbnailWidth,
    int height = AppConstants.timelineThumbnailHeight,
  }) async {
    if (mediaDuration == Duration.zero) return [];

    final results = <String>[];
    for (var i = 0; i < count; i++) {
      final fraction = i / (count - 1).clamp(1, count - 1);
      final ts = Duration(
        microseconds:
            (mediaDuration.inMicroseconds * fraction).round(),
      );
      final path = await generateThumbnail(
        sourceFilePath: sourceFilePath,
        assetId: '${assetId}_t$i',
        timestamp: ts,
        width: width,
        height: height,
      );
      if (path != null) results.add(path);
    }
    return results;
  }

  String _formatTimestamp(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ms = d.inMilliseconds.remainder(1000);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
  }
}
