import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
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

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
      ),
      child: Row(
        children: [
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
          const VerticalDivider(width: 20),
          const SizedBox(width: 8),
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
          const VerticalDivider(width: 20),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              state.snapEnabled
                  ? Icons.grid_on
                  : Icons.grid_off,
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
          // Time ruler spacer
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
    final isSelected = ref.watch(timelineStateProvider).selectedTrackId ==
        track.id;

    return Container(
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
          _TrackControlButtons(track: track),
        ],
      ),
    );
  }
}

class _TrackControlButtons extends ConsumerWidget {
  const _TrackControlButtons({required this.track});

  final TrackModel track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MuteButton(track: track),
        _LockButton(track: track),
      ],
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

    return GestureDetector(
      onTapDown: (details) {
        final time = state.pixelToTime(details.localPosition.dx);
        ref.read(timelineStateProvider).setPlayhead(time);
        ref.read(timelineStateProvider).clearSelection();
      },
      child: ClipRect(
        child: TimelineCanvas(
          timelineState: state,
          onClipTap: (clipId) {
            ref.read(timelineStateProvider).selectClip(clipId);
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
            ref.read(timelineControllerProvider).trimClipStart(
              clipId,
              newTime,
            );
          },
          onClipTrimEnd: (clipId, dx) {
            final newTime = state.pixelToTime(dx);
            ref.read(timelineControllerProvider).trimClipEnd(
              clipId,
              newTime,
            );
          },
        ),
      ),
    );
  }
}
