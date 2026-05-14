import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/media_constants.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';

final _mediaAssetsProvider = FutureProvider.family<List<MediaAsset>, String>(
  (ref, projectId) =>
      ref.watch(projectRepositoryProvider).getMediaAssets(projectId),
);

class MediaPanel extends ConsumerWidget {
  const MediaPanel({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(_mediaAssetsProvider(projectId));

    return Column(
      children: [
        _PanelHeader(
          title: 'Media',
          onImport: () => _importMedia(context, ref),
        ),
        Expanded(
          child: assetsAsync.when(
            data: (assets) => assets.isEmpty
                ? _EmptyMediaState(onImport: () => _importMedia(context, ref))
                : _MediaGrid(assets: assets, projectId: projectId),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: AppTypography.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _importMedia(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: MediaConstants.allExtensions,
    );

    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (file.path == null) continue;
      try {
        await ref.read(timelineControllerProvider).importMediaFile(
          projectId: projectId,
          filePath: file.path!,
        );
        ref.invalidate(_mediaAssetsProvider(projectId));
      } catch (e) {
        if (context.mounted) {
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
  const _MediaGrid({required this.assets, required this.projectId});

  final List<MediaAsset> assets;
  final String projectId;

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
      ),
    );
  }
}

class _MediaTile extends ConsumerWidget {
  const _MediaTile({required this.asset, required this.projectId});

  final MediaAsset asset;
  final String projectId;

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
    final videoTracks = state.videoTracks;
    if (videoTracks.isEmpty) return;

    await controller.addClipFromAsset(
      trackId: videoTracks.first.id,
      asset: asset,
    );

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
