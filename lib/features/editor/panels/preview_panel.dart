import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_type.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:video_player/video_player.dart';

/// The clip currently under the playhead (first video track, reversed priority).
final _activeClipProvider = Provider.autoDispose<ClipModel?>((ref) {
  final state = ref.watch(timelineStateProvider);
  for (final track in state.videoTracks.reversed) {
    final clip = state.clipAt(track.id, state.playhead);
    if (clip != null) return clip;
  }
  return null;
});

final _currentClipPathProvider = Provider.autoDispose<String?>((ref) {
  final clip = ref.watch(_activeClipProvider);
  return clip?.mediaId;
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

  /// Wraps [child] with Flutter filter widgets mirroring the active effects.
  /// This gives a real-time visual preview without running FFmpeg.
  Widget _applyEffectFilters(Widget child, List<EffectInstance> effects) {
    Widget result = child;
    for (final effect in effects.where((e) => e.isEnabled)) {
      switch (effect.type) {
        case EffectType.colorCorrection:
          final matrix = _buildColorMatrix(effect.parameters);
          result = ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix),
            child: result,
          );
        case EffectType.blur:
          final sigma =
              (effect.parameters['radius'] ?? 4.0).clamp(0.0, 40.0);
          if (sigma > 0) {
            result = ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: result,
            );
          }
        case EffectType.vignette:
          final angle = (effect.parameters['angle'] ?? 1.5708)
              .clamp(0.0, 3.14159);
          final strength = (angle / math.pi).clamp(0.0, 1.0);
          result = Stack(
            children: [
              result,
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          Colors.black
                              .withValues(alpha: strength * 0.85),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        case EffectType.grain:
        case EffectType.lut:
          // Not representable with Flutter filters; skip for preview.
          break;
      }
    }
    return result;
  }

  /// Computes a 20-element RGBA color matrix combining brightness, contrast,
  /// and saturation so a single [ColorFilter.matrix] covers all three.
  ///
  /// Input/output values are in [0,1]. The offset column uses [0,1] as well.
  List<double> _buildColorMatrix(Map<String, double> params) {
    final brightness = (params['brightness'] ?? 0.0).clamp(-1.0, 1.0);
    final contrast = (params['contrast'] ?? 1.0).clamp(0.0, 3.0);
    final saturation = (params['saturation'] ?? 1.0).clamp(0.0, 3.0);

    // ITU-R BT.709 luminance weights
    const rLum = 0.2126;
    const gLum = 0.7152;
    const bLum = 0.0722;

    // Saturation: interpolate between grayscale and full colour
    final sr = rLum * (1.0 - saturation);
    final sg = gLum * (1.0 - saturation);
    final sb = bLum * (1.0 - saturation);

    // Contrast: scale and offset to keep midpoint at 0.5
    final offset = (1.0 - contrast) / 2.0 + brightness;

    // Combined S then C then B in one matrix:
    //   out_R = contrast * (sr+sat)*R + contrast*sg*G + contrast*sb*B + offset
    return [
      contrast * (sr + saturation), contrast * sg, contrast * sb, 0, offset,
      contrast * sr, contrast * (sg + saturation), contrast * sb, 0, offset,
      contrast * sr, contrast * sg, contrast * (sb + saturation), 0, offset,
      0, 0, 0, 1, 0,
    ];
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

    final activeClip = ref.watch(_activeClipProvider);
    final effects = activeClip != null
        ? ref.watch(timelineStateProvider).effectsForClip(activeClip.id)
        : <EffectInstance>[];

    Widget videoWidget = _initialized && _controller != null
        ? AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          )
        : _EmptyPreview(
            width: widget.project.composition.width,
            height: widget.project.composition.height,
          );

    // Apply active effects as Flutter visual filters for real-time preview.
    videoWidget = _applyEffectFilters(videoWidget, effects);

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(child: Center(child: videoWidget)),
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
