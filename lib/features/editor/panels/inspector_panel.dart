import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';

class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);
    final selectedIds = timelineState.selectedClipIds;

    return Container(
      color: ColorTokens.inspectorBackground,
      child: Column(
        children: [
          const _PanelHeader(),
          Expanded(
            child: selectedIds.isEmpty
                ? _NoSelectionPlaceholder()
                : _ClipInspector(
                    clipId: selectedIds.first,
                    projectId: projectId,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(
          bottom: BorderSide(color: ColorTokens.borderSubtle),
        ),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text('Inspector', style: AppTypography.labelLarge),
      ),
    );
  }
}

class _NoSelectionPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select a clip to inspect',
        style: AppTypography.bodySmall,
      ),
    );
  }
}

class _ClipInspector extends ConsumerWidget {
  const _ClipInspector({
    required this.clipId,
    required this.projectId,
  });

  final String clipId;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineStateProvider);
    final ClipModel? clip = timelineState.clips
        .cast<ClipModel?>()
        .firstWhere(
          (ClipModel? c) => c?.id == clipId,
          orElse: () => null,
        );

    if (clip == null) return const SizedBox();

    return FutureBuilder<MediaAsset?>(
      future: ref.read(projectRepositoryProvider).getMediaAsset(clip.mediaId),
      builder: (context, snap) {
        final asset = snap.data;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const _SectionHeader(title: 'Clip'),
            _PropertyRow(
              label: 'Name',
              value: asset?.name ?? clip.mediaId,
            ),
            _PropertyRow(
              label: 'Duration',
              value: _formatDuration(clip.duration),
            ),
            _PropertyRow(
              label: 'Start',
              value: _formatDuration(clip.startOnTimeline),
            ),
            _PropertyRow(
              label: 'End',
              value: _formatDuration(clip.endOnTimeline),
            ),
            _PropertyRow(
              label: 'Speed',
              value: '${clip.speed}x',
            ),
            _PropertyRow(
              label: 'Opacity',
              value: '${(clip.opacity * 100).toStringAsFixed(0)}%',
            ),
            if (asset != null) ...[
              const SizedBox(height: 12),
              const _SectionHeader(title: 'Source'),
              _PropertyRow(
                label: 'Resolution',
                value: asset.resolution,
              ),
              _PropertyRow(
                label: 'Frame Rate',
                value: '${asset.frameRateDisplay} fps',
              ),
              _PropertyRow(
                label: 'Video Codec',
                value: asset.videoCodec,
              ),
              _PropertyRow(
                label: 'Audio Codec',
                value: asset.audioCodec,
              ),
              _PropertyRow(
                label: 'Color Space',
                value: asset.colorSpace,
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final ms = d.inMilliseconds.remainder(1000);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: ColorTokens.accentPrimary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTypography.labelMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
