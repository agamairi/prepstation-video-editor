import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/media_constants.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/timeline/track_model.dart';

final mediaAssetsProvider = FutureProvider.family<List<MediaAsset>, String>(
  (ref, projectId) =>
      ref.watch(projectRepositoryProvider).getMediaAssets(projectId),
);

class MediaPanel extends ConsumerStatefulWidget {
  const MediaPanel({super.key, required this.projectId, this.onClipAdded});

  final String projectId;
  final VoidCallback? onClipAdded;

  @override
  ConsumerState<MediaPanel> createState() => _MediaPanelState();
}

class _MediaPanelState extends ConsumerState<MediaPanel> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(mediaAssetsProvider(widget.projectId));

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        _importDroppedFiles(details.files.map((f) => f.path).toList());
      },
      child: Column(
        children: [
          _PanelHeader(
            title: 'Media',
            onImport: () => _importMedia(context),
          ),
          Expanded(
            child: Stack(
              children: [
                assetsAsync.when(
                  data: (assets) => assets.isEmpty
                      ? _EmptyMediaState(
                          onImport: () => _importMedia(context))
                      : _MediaGrid(
                          assets: assets,
                          projectId: widget.projectId,
                          onClipAdded: widget.onClipAdded,
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ),
                if (_isDragging)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorTokens.accentPrimary.withValues(alpha: 0.15),
                        border: Border.all(
                          color: ColorTokens.accentPrimary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.file_download_outlined,
                              size: 32,
                              color: ColorTokens.accentPrimary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Drop to import',
                              style: TextStyle(
                                color: ColorTokens.accentPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importMedia(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: MediaConstants.allExtensions,
    );

    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (file.path == null) continue;
      await _importFile(file.path!);
    }
  }

  Future<void> _importDroppedFiles(List<String> paths) async {
    final supportedExts = MediaConstants.allExtensions
        .map((e) => e.toLowerCase())
        .toSet();

    for (final path in paths) {
      final ext = path.split('.').last.toLowerCase();
      if (!supportedExts.contains(ext)) continue;
      await _importFile(path);
    }
  }

  Future<void> _importFile(String path) async {
    try {
      await ref.read(timelineControllerProvider).importMediaFile(
        projectId: widget.projectId,
        filePath: path,
      );
      ref.invalidate(mediaAssetsProvider(widget.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.onImport});

  final String title;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(
          bottom: BorderSide(color: ColorTokens.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.perm_media_outlined,
            size: 13,
            color: ColorTokens.textDisabled,
          ),
          const SizedBox(width: 6),
          Text(title, style: AppTypography.labelLarge),
          const Spacer(),
          Tooltip(
            message: 'Import Media',
            child: GestureDetector(
              onTap: onImport,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ColorTokens.backgroundSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ColorTokens.borderDefault),
                ),
                child: const Icon(
                  Icons.add,
                  size: 14,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMediaState extends StatelessWidget {
  const _EmptyMediaState({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: ColorTokens.textDisabled,
          ),
          const SizedBox(height: 12),
          const Text('No media', style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Import', style: AppTypography.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _MediaGrid extends ConsumerWidget {
  const _MediaGrid({
    required this.assets,
    required this.projectId,
    this.onClipAdded,
  });

  final List<MediaAsset> assets;
  final String projectId;
  final VoidCallback? onClipAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 16 / 9,
      ),
      itemCount: assets.length,
      itemBuilder: (context, i) => _MediaTile(
        asset: assets[i],
        projectId: projectId,
        onClipAdded: onClipAdded,
      ),
    );
  }
}

class _MediaTile extends ConsumerWidget {
  const _MediaTile({
    required this.asset,
    required this.projectId,
    this.onClipAdded,
  });

  final MediaAsset asset;
  final String projectId;
  final VoidCallback? onClipAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: '${asset.name}\n${asset.resolution} · '
          '${asset.frameRateDisplay} fps · '
          '${_formatDuration(asset.duration)}',
      child: GestureDetector(
        onTap: () => _addToTimeline(ref, context),
        onDoubleTap: () => _addToTimeline(ref, context),
        child: Container(
          decoration: BoxDecoration(
            color: ColorTokens.backgroundSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ColorTokens.borderSubtle),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: asset.thumbnailPath != null
                    ? Image.file(
                        File(asset.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, trace) =>
                            const _DefaultThumbnail(),
                      )
                    : const _DefaultThumbnail(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(3),
                    ),
                  ),
                  child: Text(
                    asset.name,
                    style: AppTypography.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (asset.hasVideo)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.videocam, size: 12, color: Colors.white70),
                ),
              // Visible "+" button so add-to-timeline is discoverable on mobile
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _addToTimeline(ref, context),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: ColorTokens.accentPrimary,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToTimeline(WidgetRef ref, BuildContext context) async {
    final controller = ref.read(timelineControllerProvider);
    final state = ref.read(timelineStateProvider);

    String trackId;
    final videoTracks = state.videoTracks;
    if (videoTracks.isNotEmpty) {
      trackId = videoTracks.first.id;
    } else {
      final track = await controller.addTrack(
        projectId: projectId,
        type: TrackType.video,
        name: 'V1',
      );
      trackId = track.id;
    }

    await controller.addClipFromAsset(
      trackId: trackId,
      asset: asset,
    );

    onClipAdded?.call();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${asset.name} added to timeline',
            style: AppTypography.bodySmall,
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: ColorTokens.backgroundElevated,
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m}m ${s}s';
  }
}

class _DefaultThumbnail extends StatelessWidget {
  const _DefaultThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.backgroundElevated,
      child: const Icon(
        Icons.movie,
        color: ColorTokens.textDisabled,
        size: 24,
      ),
    );
  }
}
