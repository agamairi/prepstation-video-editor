import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:video_player/video_player.dart';

final _currentClipPathProvider = Provider.autoDispose<String?>((ref) {
  final timelineState = ref.watch(timelineStateProvider);
  final tracks = timelineState.videoTracks;
  if (tracks.isEmpty) return null;

  for (final track in tracks.reversed) {
    final clip = timelineState.clipAt(track.id, timelineState.playhead);
    if (clip != null) {
      // We need the media file path — return the mediaId and resolve async
      return clip.mediaId;
    }
  }
  return null;
});

class PreviewPanel extends ConsumerStatefulWidget {
  const PreviewPanel({super.key, required this.project});

  final ProjectModel project;

  @override
  ConsumerState<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends ConsumerState<PreviewPanel> {
  VideoPlayerController? _controller;
  String? _currentMediaId;
  bool _initialized = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(String mediaId) async {
    if (_currentMediaId == mediaId) return;
    _currentMediaId = mediaId;

    final asset =
        await ref.read(projectRepositoryProvider).getMediaAsset(mediaId);
    if (asset == null || !mounted) return;

    await _controller?.dispose();
    final controller = VideoPlayerController.file(
      File(asset.proxyPath ?? asset.filePath),
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaId = ref.watch(_currentClipPathProvider);
    final timelineState = ref.watch(timelineStateProvider);

    if (mediaId != null && mediaId != _currentMediaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVideo(mediaId);
      });
    }

    if (mediaId == null && _controller != null) {
      _controller?.pause();
    }

    if (_controller != null) {
      if (timelineState.isPlaying &&
          !(_controller?.value.isPlaying ?? false)) {
        _controller?.play();
      } else if (!timelineState.isPlaying &&
          (_controller?.value.isPlaying ?? false)) {
        _controller?.pause();
      }
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _initialized && _controller != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : _EmptyPreview(
                      width: widget.project.composition.width,
                      height: widget.project.composition.height,
                    ),
            ),
          ),
          _PreviewToolbar(project: widget.project),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.width, required this.height});

  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 64,
              color: ColorTokens.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              '$width×$height',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewToolbar extends ConsumerWidget {
  const _PreviewToolbar({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: ColorTokens.backgroundPanel,
        border: Border(
          top: BorderSide(color: ColorTokens.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${project.composition.width}×${project.composition.height}',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(width: 8),
          Text(
            '${project.composition.frameRateDisplay} fps',
            style: AppTypography.labelSmall,
          ),
          const Spacer(),
          _ZoomSelector(),
        ],
      ),
    );
  }
}

class _ZoomSelector extends StatefulWidget {
  @override
  State<_ZoomSelector> createState() => _ZoomSelectorState();
}

class _ZoomSelectorState extends State<_ZoomSelector> {
  String _zoom = 'Fit';

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _zoom,
      underline: const SizedBox(),
      style: AppTypography.labelSmall,
      dropdownColor: ColorTokens.backgroundElevated,
      isDense: true,
      items: ['Fit', '25%', '50%', '100%', '200%']
          .map(
            (z) => DropdownMenuItem(value: z, child: Text(z)),
          )
          .toList(),
      onChanged: (v) => setState(() => _zoom = v ?? 'Fit'),
    );
  }
}
