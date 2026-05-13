import 'dart:async';
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
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:video_player/video_player.dart';

/// The clip currently under the playhead (top video track wins).
final _activeClipProvider = Provider.autoDispose<ClipModel?>((ref) {
  final state = ref.watch(timelineStateProvider);
  for (final track in state.videoTracks.reversed) {
    final clip = state.clipAt(track.id, state.playhead);
    if (clip != null) return clip;
  }
  return null;
});

/// Derived bool provider so ref.listen sees value changes (not same-object
/// ChangeNotifier ticks).
final _isPlayingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(timelineStateProvider).isPlaying;
});

final _currentClipPathProvider = Provider.autoDispose<String?>((ref) {
  final clip = ref.watch(_activeClipProvider);
  if (clip == null) return null;
  // Synthetic clips (title, colorCard) have no real video file.
  if (clip.type == ClipType.title || clip.type == ClipType.colorCard) {
    return null;
  }
  return clip.mediaId;
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

  Timer? _playbackTimer;
  DateTime? _wallClockAtPlayStart;
  Duration _playheadAtPlayStart = Duration.zero;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ── Playback control ────────────────────────────────────────────────────────

  void _startPlayback(TimelineState state) {
    _playbackTimer?.cancel();

    // If a clip is selected and the playhead is outside it, jump to its start.
    Duration seekTo = state.playhead;
    if (state.selectedClipIds.isNotEmpty) {
      final selectedId = state.selectedClipIds.first;
      try {
        final selected =
            state.clips.firstWhere((c) => c.id == selectedId);
        if (state.playhead < selected.startOnTimeline ||
            state.playhead >= selected.endOnTimeline) {
          seekTo = selected.startOnTimeline;
          state.setPlayhead(seekTo);
        }
      } catch (_) {}
    }

    _playheadAtPlayStart = seekTo;
    _wallClockAtPlayStart = DateTime.now();

    // Seek video to the correct position within the active clip.
    if (_controller != null && _initialized) {
      ClipModel? videoClip;
      for (final track in state.videoTracks.reversed) {
        final c = state.clipAt(track.id, seekTo);
        if (c != null && c.type == ClipType.video) {
          videoClip = c;
          break;
        }
      }
      if (videoClip != null) {
        final offsetInClip = seekTo - videoClip.startOnTimeline;
        final videoPos = videoClip.mediaInPoint + offsetInClip;
        _controller!.seekTo(videoPos);
        _controller!.play();
      }
    }

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      final s = ref.read(timelineStateProvider);
      if (!s.isPlaying) return;

      final elapsed = DateTime.now().difference(_wallClockAtPlayStart!);
      final newPlayhead = _playheadAtPlayStart + elapsed;

      if (s.duration > Duration.zero && newPlayhead >= s.duration) {
        s.setPlayhead(Duration.zero);
        s.setPlaying(false);
        return;
      }
      s.setPlayhead(newPlayhead);
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _wallClockAtPlayStart = null;
    _controller?.pause();
  }

  // ── Effect filters ──────────────────────────────────────────────────────────

  /// Wraps [child] with Flutter filter widgets mirroring the active effects.
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
              imageFilter:
                  ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: result,
            );
          }
        case EffectType.vignette:
          final angle =
              (effect.parameters['angle'] ?? 1.5708).clamp(0.0, 3.14159);
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
          break;
      }
    }
    return result;
  }

  /// 20-element RGBA color matrix combining brightness, contrast, saturation.
  ///
  /// Flutter's [ColorFilter.matrix] expects offset values in the [0, 255]
  /// range (same as Android ColorMatrix).
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

    // Contrast: scale and shift to keep midpoint at 0.5; brightness shifts on
    // top. Offset column must be in [0, 255] for ColorFilter.matrix.
    final offset = ((1.0 - contrast) / 2.0 + brightness) * 255.0;

    return [
      contrast * (sr + saturation), contrast * sg, contrast * sb, 0, offset,
      contrast * sr, contrast * (sg + saturation), contrast * sb, 0, offset,
      contrast * sr, contrast * sg, contrast * (sb + saturation), 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  // ── Video loading ───────────────────────────────────────────────────────────

  Future<void> _loadVideo(String mediaId) async {
    if (_currentMediaId == mediaId) return;
    _currentMediaId = mediaId;

    final asset =
        await ref.read(projectRepositoryProvider).getMediaAsset(mediaId);
    if (asset == null || !mounted) return;

    // Synthetic assets (title, colorCard) carry no video file.
    if (!asset.hasVideo) {
      await _controller?.dispose();
      if (mounted) {
        setState(() {
          _controller = null;
          _initialized = false;
        });
      }
      return;
    }

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

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // React to play/pause transitions via a derived bool provider so that
    // the same-object ChangeNotifier issue doesn't prevent detection.
    ref.listen<bool>(_isPlayingProvider, (prev, isPlaying) {
      final state = ref.read(timelineStateProvider);
      if (isPlaying) {
        _startPlayback(state);
      } else {
        _stopPlayback();
      }
    });

    final mediaId = ref.watch(_currentClipPathProvider);
    final activeClip = ref.watch(_activeClipProvider);
    final timelineState = ref.watch(timelineStateProvider);

    if (mediaId != null && mediaId != _currentMediaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadVideo(mediaId);
      });
    }

    // Reset video controller when no video clip is under the playhead.
    if (mediaId == null && _initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _controller?.dispose();
          _controller = null;
          _initialized = false;
          _currentMediaId = null;
        });
      });
    }

    final effects = activeClip != null
        ? timelineState.effectsForClip(activeClip.id)
        : <EffectInstance>[];

    // Choose the content widget based on the active clip type.
    Widget contentWidget;
    if (activeClip?.type == ClipType.title) {
      contentWidget = _TitlePreview(
        clip: activeClip!,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
      );
    } else if (activeClip?.type == ClipType.colorCard) {
      contentWidget = _ColorCardPreview(
        clip: activeClip!,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
      );
    } else if (_initialized && _controller != null) {
      contentWidget = AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    } else {
      contentWidget = _EmptyPreview(
        width: widget.project.composition.width,
        height: widget.project.composition.height,
      );
    }

    contentWidget = _applyEffectFilters(contentWidget, effects);

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(child: Center(child: contentWidget)),
          _PreviewToolbar(project: widget.project),
        ],
      ),
    );
  }
}

// ── Synthetic clip preview widgets ───────────────────────────────────────────

class _TitlePreview extends StatelessWidget {
  const _TitlePreview({
    required this.clip,
    required this.compositionWidth,
    required this.compositionHeight,
  });

  final ClipModel clip;
  final int compositionWidth;
  final int compositionHeight;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (clip.titleAlignment) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };
    return AspectRatio(
      aspectRatio: compositionWidth / compositionHeight,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            clip.titleText ?? '',
            textAlign: alignment,
            style: TextStyle(
              color: Color(clip.titleColorValue),
              fontSize: clip.titleFontSize,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(blurRadius: 4, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorCardPreview extends StatelessWidget {
  const _ColorCardPreview({
    required this.clip,
    required this.compositionWidth,
    required this.compositionHeight,
  });

  final ClipModel clip;
  final int compositionWidth;
  final int compositionHeight;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: compositionWidth / compositionHeight,
      child: ColoredBox(color: Color(clip.cardColorValue)),
    );
  }
}

// ── Shared preview widgets ────────────────────────────────────────────────────

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
