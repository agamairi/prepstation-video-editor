import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/ffmpeg/thumbnail_generator.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';

/// Non-autoDispose so thumbnails survive navigation between screens.
final clipThumbnailCacheProvider =
    ChangeNotifierProvider<ClipThumbnailCache>(
  (ref) => ClipThumbnailCache(
    ref.watch(thumbnailGeneratorProvider),
    ref.watch(projectRepositoryProvider),
  ),
);

class ClipThumbnailCache extends ChangeNotifier {
  ClipThumbnailCache(this._generator, this._repository);

  final ThumbnailGenerator _generator;
  final ProjectRepository _repository;

  final Map<String, List<ui.Image>> _cache = {};
  final Set<String> _loading = {};
  final Map<String, int> _failCount = {};

  static const int _maxRetries = 3;

  List<ui.Image>? thumbnailsForClip(String clipId) => _cache[clipId];

  bool isLoading(String clipId) => _loading.contains(clipId);

  void clearFailures() {
    _failCount.clear();
    notifyListeners();
  }

  /// Triggers thumbnail loading for [clip] if not already cached/loading.
  ///
  /// Fetches the asset from the repository itself, so it always reads
  /// fresh data even for clips imported after the editor opened.
  Future<void> ensureLoaded({
    required ClipModel clip,
    int videoCount = 6,
  }) async {
    if (clip.type != ClipType.video && clip.type != ClipType.image) return;
    if (_cache.containsKey(clip.id)) return;
    if (_loading.contains(clip.id)) return;
    if ((_failCount[clip.id] ?? 0) >= _maxRetries) return;

    _loading.add(clip.id);
    // Defer notifyListeners() so it never fires during a build phase.
    unawaited(Future.microtask(notifyListeners));

    try {
      final asset = await _repository.getMediaAsset(clip.mediaId);
      if (asset == null) {
        _failCount[clip.id] = (_failCount[clip.id] ?? 0) + 1;
        return;
      }

      final List<String> paths;

      if (clip.type == ClipType.image) {
        // Images are single-frame — one thumbnail suffices.
        final path = await _generator.generateThumbnail(
          sourceFilePath: asset.filePath,
          assetId: '${asset.id}_img',
          timestamp: Duration.zero,
          width: AppConstants.timelineThumbnailWidth,
          height: AppConstants.timelineThumbnailHeight,
        );
        paths = path != null ? [path] : [];
      } else {
        if (asset.duration == Duration.zero) {
          _failCount[clip.id] = (_failCount[clip.id] ?? 0) + 1;
          return;
        }
        paths = await _generator.generateTimelineThumbnails(
          sourceFilePath: asset.filePath,
          assetId: clip.mediaId,
          mediaDuration: asset.duration,
          count: videoCount,
        );
      }

      if (paths.isEmpty) {
        debugPrint(
          '[ClipThumbnailCache] No thumbnails for clip=${clip.id}',
        );
        _failCount[clip.id] = (_failCount[clip.id] ?? 0) + 1;
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
        _failCount[clip.id] = (_failCount[clip.id] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('[ClipThumbnailCache] Error for clip=${clip.id}: $e');
      _failCount[clip.id] = (_failCount[clip.id] ?? 0) + 1;
    } finally {
      _loading.remove(clip.id);
      notifyListeners();
    }
  }
}
