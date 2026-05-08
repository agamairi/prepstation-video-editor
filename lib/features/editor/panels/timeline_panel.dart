import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/history/history_manager.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/timeline/timeline_tool.dart';
import 'package:fluxedit/core/timeline/track_model.dart';
import 'package:fluxedit/widgets/timeline/timeline_canvas.dart';

class TimelinePanel extends ConsumerWidget {
  const TimelinePanel({super.key, required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: ColorTokens.backgroundBase,
      child: Column(
        children: [
          _TimelineToolbar(project: project),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                _TrackHeaders(),
                Expanded(child: _TimelineScrollArea()),
              ],
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
          // Add tracks
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
          // Snap
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final tool = ref.watch(timelineToolProvider);

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
        ),
      ),
    );
  }
}
