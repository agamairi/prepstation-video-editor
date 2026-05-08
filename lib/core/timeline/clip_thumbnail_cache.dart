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

  List<ui.Image>? thumbnailsForClip(String clipId) => _cache[clipId];

  Future<void> ensureLoaded({
    required ClipModel clip,
    required String filePath,
    required Duration mediaDuration,
    int count = 8,
  }) async {
    if (_cache.containsKey(clip.id) || _loading.contains(clip.id)) return;
    _loading.add(clip.id);

    try {
      final paths = await _generator.generateTimelineThumbnails(
        sourceFilePath: filePath,
        assetId: clip.mediaId,
        mediaDuration: mediaDuration,
        count: count,
      );

      final images = <ui.Image>[];
      for (final path in paths) {
        final bytes = await File(path).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        images.add(frame.image);
      }

      _cache[clip.id] = images;
      notifyListeners();
    } catch (_) {
      // silently skip — clip body will render without thumbnails
    } finally {
      _loading.remove(clip.id);
    }
  }
}
