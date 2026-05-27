import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/app/theme/typography.dart';
import 'package:prepstation/core/audio/waveform_generator.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/history/history_manager.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/clip_thumbnail_cache.dart';
import 'package:prepstation/core/timeline/timeline_controller.dart';
import 'package:prepstation/core/timeline/timeline_tool.dart';
import 'package:prepstation/core/timeline/track_model.dart';
import 'package:prepstation/widgets/timeline/timeline_canvas.dart';

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
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(bottom: BorderSide(color: ColorTokens.borderSubtle)),
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
          // Tracker tool
          _ToolButton(
            icon: Icons.pin_drop_outlined,
            tooltip: 'Track Point (T)',
            isActive: tool == TimelineTool.tracker,
            onPressed: () => ref
                .read(timelineToolProvider.notifier)
                .state = TimelineTool.tracker,
          ),
          const VerticalDivider(width: 16),
          _UnifiedAddButton(project: project),
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

/// Unified add button — single "+" that lets the user add any type of track or
/// synthetic clip from one popup menu.
class _UnifiedAddButton extends ConsumerWidget {
  const _UnifiedAddButton({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_AddAction>(
      tooltip: 'Add',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      icon: const Icon(Icons.add, size: 16),
      onSelected: (action) {
        final state = ref.read(timelineStateProvider);
        final controller = ref.read(timelineControllerProvider);

        switch (action) {
          case _AddAction.videoTrack:
            controller.addTrack(
              projectId: project.id,
              type: TrackType.video,
            );
          case _AddAction.audioTrack:
            controller.addTrack(
              projectId: project.id,
              type: TrackType.audio,
            );
          case _AddAction.title:
            final track = state.videoTracks.isNotEmpty
                ? state.videoTracks.first
                : null;
            if (track == null) return;
            controller.addTitleClip(
              projectId: project.id,
              trackId: track.id,
            );
          case _AddAction.colorCard:
            final track = state.videoTracks.isNotEmpty
                ? state.videoTracks.first
                : null;
            if (track == null) return;
            controller.addColorCardClip(
              projectId: project.id,
              trackId: track.id,
            );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _AddAction.videoTrack,
          child: Row(
            children: [
              Icon(Icons.videocam_outlined, size: 16),
              SizedBox(width: 8),
              Text('Video Track'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _AddAction.audioTrack,
          child: Row(
            children: [
              Icon(Icons.music_note_outlined, size: 16),
              SizedBox(width: 8),
              Text('Audio Track'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _AddAction.title,
          child: Row(
            children: [
              Icon(Icons.title, size: 16),
              SizedBox(width: 8),
              Text('Title'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _AddAction.colorCard,
          child: Row(
            children: [
              Icon(Icons.rectangle_outlined, size: 16),
              SizedBox(width: 8),
              Text('Color Card'),
            ],
          ),
        ),
      ],
    );
  }
}

enum _AddAction { videoTrack, audioTrack, title, colorCard }

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
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? ColorTokens.accentPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
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
      onSecondaryTapDown: (d) =>
          _showTrackContextMenu(context, ref, d.globalPosition),
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
            _DeleteTrackButton(track: track),
          ],
        ),
      ),
    );
  }

  Future<void> _showTrackContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final result = await showMenu<_TrackAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: _TrackAction.toggleMute,
          child: Row(
            children: [
              Icon(track.isMuted ? Icons.volume_up : Icons.volume_off, size: 16),
              const SizedBox(width: 8),
              Text(track.isMuted ? 'Unmute' : 'Mute'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _TrackAction.toggleLock,
          child: Row(
            children: [
              Icon(track.isLocked ? Icons.lock_open : Icons.lock, size: 16),
              const SizedBox(width: 8),
              Text(track.isLocked ? 'Unlock' : 'Lock'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _TrackAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Delete Track', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );

    if (result == null) return;
    switch (result) {
      case _TrackAction.toggleMute:
        final updated = track.copyWith(isMuted: !track.isMuted);
        ref.read(timelineStateProvider).updateTrack(updated);
      case _TrackAction.toggleLock:
        final updated = track.copyWith(isLocked: !track.isLocked);
        ref.read(timelineStateProvider).updateTrack(updated);
      case _TrackAction.delete:
        unawaited(ref.read(timelineControllerProvider).removeTrack(track.id));
    }
  }
}

enum _TrackAction { toggleMute, toggleLock, delete }

class _DeleteTrackButton extends ConsumerWidget {
  const _DeleteTrackButton({required this.track});

  final TrackModel track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.close,
          size: 12,
          color: ColorTokens.textSecondary,
        ),
        tooltip: 'Delete Track',
        onPressed: () =>
            unawaited(ref.read(timelineControllerProvider).removeTrack(track.id)),
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

class _TimelineScrollArea extends ConsumerStatefulWidget {
  const _TimelineScrollArea({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_TimelineScrollArea> createState() =>
      _TimelineScrollAreaState();
}

class _TimelineScrollAreaState extends ConsumerState<_TimelineScrollArea> {
  /// Clip IDs for which thumbnail loading has already been requested.


  /// Media asset IDs for which waveform loading has already been requested.
  final Set<String> _waveformsRequested = {};

  String? _trackIdAtDragY(double globalY, BuildContext context) {
    final state = ref.read(timelineStateProvider);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final localY = box.globalToLocal(Offset(0, globalY)).dy;
    const rulerH = AppConstants.timelineRulerHeight;
    double yOffset = rulerH;
    for (final track in state.tracks) {
      if (localY >= yOffset && localY < yOffset + track.height) {
        return track.id;
      }
      yOffset += track.height;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineStateProvider);
    final tool = ref.watch(timelineToolProvider);
    final thumbCache = ref.watch(clipThumbnailCacheProvider);
    final waveformCache = ref.watch(waveformCacheProvider);

    // Trigger thumbnail loading for video/image clips.
    // The cache internally skips clips that are already cached, loading,
    // or have exceeded the retry limit.
    final thumbClips = state.clips
        .where(
          (c) => c.type == ClipType.video || c.type == ClipType.image,
        )
        .toList();

    if (thumbClips.isNotEmpty) {
      Future.microtask(() {
        if (!mounted) return;
        for (final clip in thumbClips) {
          thumbCache.ensureLoaded(clip: clip);
        }
      });
    }

    // Trigger waveform loading for audio/video clips with audio.
    final needsWave = state.clips
        .where(
          (c) =>
              (c.type == ClipType.audio || c.type == ClipType.video) &&
              !_waveformsRequested.contains(c.mediaId) &&
              !waveformCache.containsKey(c.mediaId),
        )
        .toList();

    if (needsWave.isNotEmpty) {
      Future.microtask(() {
        if (!mounted) return;
        final generator = ref.read(waveformGeneratorProvider);
        final repo = ref.read(projectRepositoryProvider);
        final cache = ref.read(waveformCacheProvider.notifier);
        for (final clip in needsWave) {
          _waveformsRequested.add(clip.mediaId);
          repo.getMediaAsset(clip.mediaId).then((asset) async {
            if (asset == null || !asset.hasAudio) return;
            final data = await generator.generateWaveform(
              sourceFilePath: asset.filePath,
              assetId: asset.id,
            );
            if (data != null) cache.put(asset.id, data);
          });
        }
      });
    }

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
          onClipDrag: (clipId, delta, {double? globalY}) {
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
            String? targetTrackId;
            if (globalY != null) {
              targetTrackId = _trackIdAtDragY(globalY, context);
            }
            ref.read(timelineControllerProvider).moveClip(
              clipId,
              found.startOnTimeline + deltaDuration,
              newTrackId: targetTrackId,
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
              _showClipContextMenu(clipId, position),
          waveforms: waveformCache,
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

  Future<void> _showClipContextMenu(String clipId, Offset position) async {
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
