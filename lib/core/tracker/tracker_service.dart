import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:prepstation/core/ffmpeg/ffmpeg_engine.dart';
import 'package:prepstation/core/tracker/tracker_model.dart';

final trackerServiceProvider = Provider<TrackerService>((ref) {
  return TrackerService(ffmpeg: ref.watch(ffmpegEngineProvider));
});

class TrackerService {
  TrackerService({required this.ffmpeg});

  final FfmpegEngine ffmpeg;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  /// Tracks a point through a video clip by extracting frames and performing
  /// template matching around the initial pin position.
  ///
  /// [videoPath] – source video file
  /// [pinX], [pinY] – normalized 0..1 coordinates of the initial pin
  /// [pinTime] – the media time where the pin was placed
  /// [inPoint], [outPoint] – the range to track within
  /// [videoWidth], [videoHeight] – actual resolution of the source
  /// [searchRadius] – pixel radius to search in each frame
  /// [frameStep] – analyze every N-th frame (1 = every frame)
  Future<List<TrackPoint>> trackPoint({
    required String videoPath,
    required double pinX,
    required double pinY,
    required Duration pinTime,
    required Duration inPoint,
    required Duration outPoint,
    required int videoWidth,
    required int videoHeight,
    int searchRadius = 60,
    int templateSize = 32,
    int frameStep = 1,
    void Function(double progress)? onProgress,
  }) async {
    _cancelled = false;

    final tempDir = await getTemporaryDirectory();
    final sessionDir = Directory(
      '${tempDir.path}/tracker_${DateTime.now().millisecondsSinceEpoch}',
    );
    await sessionDir.create(recursive: true);

    try {
      final fps = await _detectFrameRate(videoPath);
      final frameDuration = Duration(
        microseconds: (1000000.0 / fps * frameStep).round(),
      );

      final totalFrames = (outPoint - inPoint).inMicroseconds ~/
          frameDuration.inMicroseconds;
      if (totalFrames <= 0) return [];

      // Extract frames as PNG images
      final framesDir = '${sessionDir.path}/frames';
      await Directory(framesDir).create();

      await ffmpeg.execute(
        '-ss ${_formatTime(inPoint)} '
        '-to ${_formatTime(outPoint)} '
        '-i "$videoPath" '
        '-vf "fps=${fps / frameStep}" '
        '-vsync vfr '
        '"$framesDir/frame_%06d.png"',
      );

      if (_cancelled) return [];

      final frameFiles = Directory(framesDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      if (frameFiles.isEmpty) return [];

      // Find the reference frame (closest to pinTime)
      final pinFrameIdx = ((pinTime - inPoint).inMicroseconds /
              frameDuration.inMicroseconds)
          .round()
          .clamp(0, frameFiles.length - 1);

      // Load reference frame and extract template
      final refImage = await _loadImage(frameFiles[pinFrameIdx].path);
      if (refImage == null) return [];

      final pinPxX = (pinX * refImage.width).round();
      final pinPxY = (pinY * refImage.height).round();

      final halfTpl = templateSize ~/ 2;
      final tplLeft = (pinPxX - halfTpl).clamp(0, refImage.width - templateSize);
      final tplTop = (pinPxY - halfTpl).clamp(0, refImage.height - templateSize);

      final template = img.copyCrop(
        refImage,
        x: tplLeft,
        y: tplTop,
        width: templateSize,
        height: templateSize,
      );

      final points = <TrackPoint>[];

      // Track forward from pin frame
      var currentX = pinPxX;
      var currentY = pinPxY;
      var currentTemplate = template;

      // Add pin frame itself
      points.add(TrackPoint(
        time: inPoint + frameDuration * pinFrameIdx,
        x: pinX,
        y: pinY,
        confidence: 1.0,
      ));

      // Track forward
      for (var i = pinFrameIdx + 1; i < frameFiles.length; i++) {
        if (_cancelled) return [];

        final frame = await _loadImage(frameFiles[i].path);
        if (frame == null) continue;

        final result = await _templateMatch(
          frame, currentTemplate, currentX, currentY,
          searchRadius, templateSize,
        );

        currentX = result.x;
        currentY = result.y;

        points.add(TrackPoint(
          time: inPoint + frameDuration * i,
          x: currentX / frame.width,
          y: currentY / frame.height,
          confidence: result.confidence,
        ));

        // Update template for drift adaptation
        if (result.confidence > 0.6) {
          final newTplLeft = (currentX - halfTpl).clamp(0, frame.width - templateSize);
          final newTplTop = (currentY - halfTpl).clamp(0, frame.height - templateSize);
          currentTemplate = img.copyCrop(
            frame,
            x: newTplLeft,
            y: newTplTop,
            width: templateSize,
            height: templateSize,
          );
        }

        onProgress?.call((i - pinFrameIdx) / (frameFiles.length - 1));
      }

      // Track backward from pin frame
      currentX = pinPxX;
      currentY = pinPxY;
      currentTemplate = template;

      final backwardPoints = <TrackPoint>[];
      for (var i = pinFrameIdx - 1; i >= 0; i--) {
        if (_cancelled) return [];

        final frame = await _loadImage(frameFiles[i].path);
        if (frame == null) continue;

        final result = await _templateMatch(
          frame, currentTemplate, currentX, currentY,
          searchRadius, templateSize,
        );

        currentX = result.x;
        currentY = result.y;

        backwardPoints.add(TrackPoint(
          time: inPoint + frameDuration * i,
          x: currentX / frame.width,
          y: currentY / frame.height,
          confidence: result.confidence,
        ));

        if (result.confidence > 0.6) {
          final newTplLeft = (currentX - halfTpl).clamp(0, frame.width - templateSize);
          final newTplTop = (currentY - halfTpl).clamp(0, frame.height - templateSize);
          currentTemplate = img.copyCrop(
            frame,
            x: newTplLeft,
            y: newTplTop,
            width: templateSize,
            height: templateSize,
          );
        }

        final totalDone = (pinFrameIdx - i) + (frameFiles.length - pinFrameIdx);
        onProgress?.call(totalDone / (frameFiles.length - 1));
      }

      // Merge backward (reversed) + forward
      final allPoints = [
        ...backwardPoints.reversed,
        ...points,
      ];

      allPoints.sort((a, b) => a.time.compareTo(b.time));
      return allPoints;
    } finally {
      try {
        await sessionDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<double> _detectFrameRate(String videoPath) async {
    try {
      final probe = await ffmpeg.probe(videoPath);
      return probe.videoStream?.frameRate ?? 30.0;
    } catch (_) {
      return 30.0;
    }
  }

  Future<img.Image?> _loadImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      return await FfmpegEngine.runInIsolate(() => img.decodePng(bytes));
    } catch (e) {
      debugPrint('[TrackerService] Failed to load frame: $e');
      return null;
    }
  }

  Future<_MatchResult> _templateMatch(
    img.Image frame,
    img.Image template,
    int centerX,
    int centerY,
    int searchRadius,
    int templateSize,
  ) async {
    return FfmpegEngine.runInIsolate(() {
      return _doTemplateMatch(
        frame, template, centerX, centerY, searchRadius, templateSize,
      );
    });
  }

  static _MatchResult _doTemplateMatch(
    img.Image frame,
    img.Image template,
    int centerX,
    int centerY,
    int searchRadius,
    int templateSize,
  ) {
    final halfTpl = templateSize ~/ 2;
    final searchLeft = (centerX - searchRadius).clamp(0, frame.width - templateSize);
    final searchTop = (centerY - searchRadius).clamp(0, frame.height - templateSize);
    final searchRight = (centerX + searchRadius).clamp(templateSize, frame.width) - templateSize;
    final searchBottom = (centerY + searchRadius).clamp(templateSize, frame.height) - templateSize;

    var bestX = centerX;
    var bestY = centerY;
    var bestScore = double.infinity;
    const step = 2;

    // Coarse pass
    for (var sy = searchTop; sy <= searchBottom; sy += step) {
      for (var sx = searchLeft; sx <= searchRight; sx += step) {
        final score = _sadScore(frame, template, sx, sy, templateSize);
        if (score < bestScore) {
          bestScore = score;
          bestX = sx + halfTpl;
          bestY = sy + halfTpl;
        }
      }
    }

    // Fine pass around best coarse match
    final fineLeft = (bestX - halfTpl - step).clamp(0, frame.width - templateSize);
    final fineTop = (bestY - halfTpl - step).clamp(0, frame.height - templateSize);
    final fineRight = (bestX - halfTpl + step).clamp(0, frame.width - templateSize);
    final fineBottom = (bestY - halfTpl + step).clamp(0, frame.height - templateSize);

    for (var sy = fineTop; sy <= fineBottom; sy++) {
      for (var sx = fineLeft; sx <= fineRight; sx++) {
        final score = _sadScore(frame, template, sx, sy, templateSize);
        if (score < bestScore) {
          bestScore = score;
          bestX = sx + halfTpl;
          bestY = sy + halfTpl;
        }
      }
    }

    // Normalize confidence: lower SAD = higher confidence
    final maxSad = templateSize * templateSize * 255.0 * 3.0;
    final confidence = (1.0 - bestScore / maxSad).clamp(0.0, 1.0);

    return _MatchResult(bestX, bestY, confidence);
  }

  /// Sum of Absolute Differences — fast metric for template matching.
  static double _sadScore(
    img.Image frame,
    img.Image template,
    int offsetX,
    int offsetY,
    int size,
  ) {
    var sum = 0.0;
    // Sample every other pixel for speed
    for (var ty = 0; ty < size; ty += 2) {
      for (var tx = 0; tx < size; tx += 2) {
        final fp = frame.getPixel(offsetX + tx, offsetY + ty);
        final tp = template.getPixel(tx, ty);
        sum += (fp.r - tp.r).abs() +
            (fp.g - tp.g).abs() +
            (fp.b - tp.b).abs();
      }
    }
    return sum;
  }

  String _formatTime(Duration d) {
    final seconds = d.inMicroseconds / 1000000.0;
    return seconds.toStringAsFixed(6);
  }
}

class _MatchResult {
  const _MatchResult(this.x, this.y, this.confidence);
  final int x;
  final int y;
  final double confidence;
}
