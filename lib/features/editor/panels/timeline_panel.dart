import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/history/history_manager.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/clip_thumbnail_cache.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/timeline/timeline_tool.dart';
import 'package:fluxedit/core/timeline/track_model.dart';
import 'package:fluxedit/widgets/timeline/timeline_canvas.dart';

final _timelineAssetsProvider = FutureProvider.family<List<MediaAsset>, String>(
  (ref, projectId) =>
      ref.watch(projectRepositoryProvider).getMediaAssets(projectId),
);

class TimelinePanel extends ConsumerWidget {
  const TimelinePanel({super.key, required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final tracksH =
        state.tracks.fold(0.0, (sum, t) => sum + t.height);
    final canvasH = AppConstants.timelineRulerHeight + tracksH;

    return Container(
      color: ColorTokens.backgroundBase,
      child: Column(
        children: [
          _TimelineToolbar(project: project),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                height: canvasH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TrackHeaders(),
                    Expanded(
                      child: _TimelineScrollArea(projectId: project.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineToolbar extends ConsumerWidget {
  const _TimelineToolbar({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final tool = ref.watch(timelineToolProvider);
    final history = ref.watch(historyManagerProvider);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
      ),
      child: Row(
        children: [
          // Undo / Redo
          IconButton(
            icon: const Icon(Icons.undo, size: 16),
            tooltip: history.nextUndoDescription != null
                ? 'Undo: ${history.nextUndoDescription}'
                : 'Nothing to Undo',
            onPressed: history.canUndo
                ? () => ref.read(timelineControllerProvider).undo()
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 16),
            tooltip: history.nextRedoDescription != null
                ? 'Redo: ${history.nextRedoDescription}'
                : 'Nothing to Redo',
            onPressed: history.canRedo
                ? () => ref.read(timelineControllerProvider).redo()
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const VerticalDivider(width: 16),
          // Select tool
          _ToolButton(
            icon: Icons.near_me,
            tooltip: 'Select (V)',
            isActive: tool == TimelineTool.select,
            onPressed: () => ref
                .read(timelineToolProvider.notifier)
                .state = TimelineTool.select,
          ),
          // Blade tool
          _ToolButton(
            icon: Icons.content_cut,
            tooltip: 'Blade / Cut (B)',
            isActive: tool == TimelineTool.blade,
            onPressed: () => ref
                .read(timelineToolProvider.notifier)
                .state = TimelineTool.blade,
          ),
          const VerticalDivider(width: 16),
          // Add video / audio tracks
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            tooltip: 'Add Video Track',
            onPressed: () => ref.read(timelineControllerProvider).addTrack(
              projectId: project.id,
              type: TrackType.video,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: const Icon(Icons.music_note, size: 16),
            tooltip: 'Add Audio Track',
            onPressed: () => ref.read(timelineControllerProvider).addTrack(
              projectId: project.id,
              type: TrackType.audio,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const VerticalDivider(width: 16),
          // Add synthetic clips
          _AddSyntheticButton(project: project),
          const SizedBox(width: 8),
          const VerticalDivider(width: 8),
          const SizedBox(width: 8),
          // Zoom
          const Icon(
            Icons.zoom_out,
            size: 14,
            color: ColorTokens.textSecondary,
          ),
          SizedBox(
            width: 80,
            child: Slider(
              value: state.zoom,
              min: AppConstants.minTimelineZoom,
              max: AppConstants.maxTimelineZoom,
              onChanged: (v) =>
                  ref.read(timelineStateProvider).setZoom(v),
            ),
          ),
          const Icon(
            Icons.zoom_in,
            size: 14,
            color: ColorTokens.textSecondary,
          ),
          const SizedBox(width: 8),
          const VerticalDivider(width: 8),
          const SizedBox(width: 8),
          // Snap toggle
          IconButton(
            icon: Icon(
              state.snapEnabled ? Icons.grid_on : Icons.grid_off,
              size: 16,
            ),
            tooltip: state.snapEnabled ? 'Snap On' : 'Snap Off',
            onPressed: () => ref
                .read(timelineStateProvider)
                .setSnapEnabled(!state.snapEnabled),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const Spacer(),
          Text(
            '${(state.zoom).toStringAsFixed(0)} px/s',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Popup menu for adding a Title or Color Card clip to the first video track.
class _AddSyntheticButton extends ConsumerWidget {
  const _AddSyntheticButton({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_SyntheticClipType>(
      tooltip: 'Add Title / Color Card',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      icon: const Icon(Icons.text_fields, size: 16),
      onSelected: (type) {
        final state = ref.read(timelineStateProvider);
        final controller = ref.read(timelineControllerProvider);
        final firstVideoTrack =
            state.videoTracks.isNotEmpty ? state.videoTracks.first : null;
        if (firstVideoTrack == null) return;

        switch (type) {
          case _SyntheticClipType.title:
            controller.addTitleClip(
              projectId: project.id,
              trackId: firstVideoTrack.id,
            );
          case _SyntheticClipType.colorCard:
            controller.addColorCardClip(
              projectId: project.id,
              trackId: firstVideoTrack.id,
            );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _SyntheticClipType.title,
          child: Row(
            children: [
              Icon(Icons.title, size: 16),
              SizedBox(width: 8),
              Text('Add Title'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _SyntheticClipType.colorCard,
          child: Row(
            children: [
              Icon(Icons.rectangle, size: 16),
              SizedBox(width: 8),
              Text('Add Color Card'),
            ],
          ),
        ),
      ],
    );
  }
}

enum _SyntheticClipType { title, colorCard }

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? ColorTokens.accentPrimary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isActive
                ? Border.all(color: ColorTokens.accentPrimary, width: 1)
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive
                ? ColorTokens.accentPrimary
                : ColorTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TrackHeaders extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final tracks = state.tracks;

    return Container(
      width: AppConstants.trackHeaderWidth,
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(
          right: BorderSide(color: ColorTokens.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          ...tracks.map((track) => _TrackHeader(track: track)),
        ],
      ),
    );
  }
}

class _TrackHeader extends ConsumerWidget {
  const _TrackHeader({required this.track});

  final TrackModel track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected =
        ref.watch(timelineStateProvider).selectedTrackId == track.id;

    return GestureDetector(
      onTap: () =>
          ref.read(timelineStateProvider).selectTrack(track.id),
      child: Container(
        height: track.height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorTokens.backgroundHover
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: ColorTokens.trackDivider),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                track.displayName,
                style: AppTypography.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _MuteButton(track: track),
            _LockButton(track: track),
          ],
        ),
      ),
    );
  }
}

class _MuteButton extends ConsumerWidget {
  const _MuteButton({required this.track});

  final TrackModel track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          track.isMuted ? Icons.volume_off : Icons.volume_up,
          size: 12,
          color: track.isMuted
              ? ColorTokens.warning
              : ColorTokens.textSecondary,
        ),
        onPressed: () {
          final updated = track.copyWith(isMuted: !track.isMuted);
          ref.read(timelineStateProvider).updateTrack(updated);
        },
      ),
    );
  }
}

class _LockButton extends ConsumerWidget {
  const _LockButton({required this.track});

  final TrackModel track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          track.isLocked ? Icons.lock : Icons.lock_open,
          size: 12,
          color: track.isLocked
              ? ColorTokens.accentPrimary
              : ColorTokens.textSecondary,
        ),
        onPressed: () {
          final updated = track.copyWith(isLocked: !track.isLocked);
          ref.read(timelineStateProvider).updateTrack(updated);
        },
      ),
    );
  }
}

class _TimelineScrollArea extends ConsumerWidget {
  const _TimelineScrollArea({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final tool = ref.watch(timelineToolProvider);
    final thumbCache = ref.watch(clipThumbnailCacheProvider);
    final assetsAsync = ref.watch(_timelineAssetsProvider(projectId));

    // Trigger thumbnail loading after the current frame to avoid calling
    // notifyListeners() during the build phase.
    assetsAsync.whenData((assets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final assetMap = {for (final a in assets) a.id: a};
        for (final clip in state.clips) {
          if (clip.type != ClipType.video) continue;
          final asset = assetMap[clip.mediaId];
          if (asset == null) continue;
          thumbCache.ensureLoaded(
            clip: clip,
            filePath: asset.filePath,
            mediaDuration: asset.duration,
          );
        }
      });
    });

    return GestureDetector(
      onTapDown: (details) {
        if (tool == TimelineTool.select) {
          final time = state.pixelToTime(details.localPosition.dx);
          ref.read(timelineStateProvider).setPlayhead(time);
          ref.read(timelineStateProvider).clearSelection();
        }
      },
      child: ClipRect(
        child: TimelineCanvas(
          timelineState: state,
          tool: tool,
          onClipTap: (clipId) {
            if (tool == TimelineTool.select) {
              ref.read(timelineStateProvider).selectClip(clipId);
            }
          },
          onClipBladeAt: (clipId, time) {
            ref.read(timelineControllerProvider).splitClip(clipId, time);
          },
          onClipDragStart: (clipId) {},
          onClipDrag: (clipId, delta) {
            final clips = state.clips;
            ClipModel? found;
            for (final c in clips) {
              if (c.id == clipId) {
                found = c;
                break;
              }
            }
            if (found == null) return;
            final deltaDuration = Duration(
              microseconds: (delta / state.zoom * 1000000).round(),
            );
            ref.read(timelineControllerProvider).moveClip(
              clipId,
              found.startOnTimeline + deltaDuration,
            );
          },
          onClipTrimStart: (clipId, dx) {
            final newTime = state.pixelToTime(dx);
            ref
                .read(timelineControllerProvider)
                .trimClipStart(clipId, newTime);
          },
          onClipTrimEnd: (clipId, dx) {
            final newTime = state.pixelToTime(dx);
            ref
                .read(timelineControllerProvider)
                .trimClipEnd(clipId, newTime);
          },
          onClipContextMenu: (clipId, position) =>
              _showClipContextMenu(context, ref, clipId, position),
          thumbnails: {
            for (final entry in state.clips)
              if (thumbCache.thumbnailsForClip(entry.id) != null)
                entry.id: thumbCache.thumbnailsForClip(entry.id)!,
          },
          loadingClipIds: {
            for (final entry in state.clips)
              if (thumbCache.isLoading(entry.id)) entry.id,
          },
        ),
      ),
    );
  }

  Future<void> _showClipContextMenu(
    BuildContext context,
    WidgetRef ref,
    String clipId,
    Offset position,
  ) async {
    final controller = ref.read(timelineControllerProvider);
    final timelineState = ref.read(timelineStateProvider);

    final result = await showMenu<_ClipAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: const [
        PopupMenuItem(
          value: _ClipAction.edit,
          child: _ContextMenuItem(icon: Icons.tune, label: 'Edit Clip'),
        ),
        PopupMenuItem(
          value: _ClipAction.splitAtPlayhead,
          child: _ContextMenuItem(
              icon: Icons.content_cut, label: 'Split at Playhead'),
        ),
        PopupMenuItem(
          value: _ClipAction.duplicate,
          child: _ContextMenuItem(icon: Icons.copy, label: 'Duplicate'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _ClipAction.delete,
          child: _ContextMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete',
            isDestructive: true,
          ),
        ),
      ],
    );

    if (result == null) return;
    timelineState.selectClip(clipId);

    switch (result) {
      case _ClipAction.edit:
        break;
      case _ClipAction.splitAtPlayhead:
        await controller.splitAtPlayhead();
      case _ClipAction.duplicate:
        await controller.duplicateClip(clipId);
      case _ClipAction.delete:
        await controller.rippleDelete(clipId);
        timelineState.clearSelection();
    }
  }
}

enum _ClipAction { edit, splitAtPlayhead, duplicate, delete }

class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : null;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
