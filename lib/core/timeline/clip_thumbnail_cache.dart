import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/core/ffmpeg/thumbnail_generator.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';

final clipThumbnailCacheProvider =
    ChangeNotifierProvider.autoDispose<ClipThumbnailCache>(
  (ref) => ClipThumbnailCache(ref.watch(thumbnailGeneratorProvider)),
);

class ClipThumbnailCache extends ChangeNotifier {
  ClipThumbnailCache(this._generator);

  final ThumbnailGenerator _generator;

  final Map<String, List<ui.Image>> _cache = {};
  final Set<String> _loading = {};
  // Tracks clips that failed to generate — won't retry until cache is cleared.
  final Set<String> _failed = {};

  List<ui.Image>? thumbnailsForClip(String clipId) => _cache[clipId];

  bool isLoading(String clipId) => _loading.contains(clipId);

  void clearFailures() {
    _failed.clear();
    notifyListeners();
  }

  Future<void> ensureLoaded({
    required ClipModel clip,
    required String filePath,
    required Duration mediaDuration,
    int count = 6,
  }) async {
    if (_cache.containsKey(clip.id)) return;
    if (_loading.contains(clip.id)) return;
    if (_failed.contains(clip.id)) return;

    _loading.add(clip.id);
    notifyListeners(); // trigger loading-state repaint

    try {
      final paths = await _generator.generateTimelineThumbnails(
        sourceFilePath: filePath,
        assetId: clip.mediaId,
        mediaDuration: mediaDuration,
        count: count,
      );

      if (paths.isEmpty) {
        debugPrint(
          '[ClipThumbnailCache] FFmpeg returned no thumbnails for '
          'clip=${clip.id} asset=${clip.mediaId} path=$filePath',
        );
        _failed.add(clip.id);
        return;
      }

      final images = <ui.Image>[];
      for (final path in paths) {
        try {
          final bytes = await File(path).readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          images.add(frame.image);
        } catch (e) {
          debugPrint('[ClipThumbnailCache] Failed to decode $path: $e');
        }
      }

      if (images.isNotEmpty) {
        _cache[clip.id] = images;
      } else {
        _failed.add(clip.id);
      }
    } catch (e) {
      debugPrint('[ClipThumbnailCache] Error loading clip=${clip.id}: $e');
      _failed.add(clip.id);
    } finally {
      _loading.remove(clip.id);
      notifyListeners();
    }
  }
}
