import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_type.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_controller.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:google_fonts/google_fonts.dart';
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
        final selected = state.clips.firstWhere((c) => c.id == selectedId);
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
                          Colors.black.withValues(alpha: strength * 0.85),
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

  List<double> _buildColorMatrix(Map<String, double> params) {
    final brightness = (params['brightness'] ?? 0.0).clamp(-1.0, 1.0);
    final contrast = (params['contrast'] ?? 1.0).clamp(0.0, 3.0);
    final saturation = (params['saturation'] ?? 1.0).clamp(0.0, 3.0);

    const rLum = 0.2126;
    const gLum = 0.7152;
    const bLum = 0.0722;

    final sr = rLum * (1.0 - saturation);
    final sg = gLum * (1.0 - saturation);
    final sb = bLum * (1.0 - saturation);

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

  // ── Animation helpers ───────────────────────────────────────────────────────

  /// 0→1 progress of the clip's text-in animation at the current playhead.
  double _animT(ClipModel clip, Duration playhead) {
    final offsetMs =
        (playhead - clip.startOnTimeline).inMilliseconds.toDouble();
    return (offsetMs / AppConstants.textAnimationDurationMs).clamp(0.0, 1.0);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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

    // When moving to a non-video clip/gap, just pause (don't dispose).
    if (mediaId == null && _controller != null) {
      _controller!.pause();
    }

    final effects = activeClip != null
        ? timelineState.effectsForClip(activeClip.id)
        : <EffectInstance>[];

    // Compute animation progress for synthetic clips.
    final animT = activeClip != null
        ? _animT(activeClip, timelineState.playhead)
        : 1.0;

    // Choose the content widget based on the active clip type.
    Widget contentWidget;
    if (activeClip?.type == ClipType.title) {
      contentWidget = _TextOverlayPreview(
        clip: activeClip!,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
        background: Colors.black,
        animT: animT,
      );
    } else if (activeClip?.type == ClipType.colorCard) {
      contentWidget = _TextOverlayPreview(
        clip: activeClip!,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
        background: Color(activeClip.cardColorValue),
        animT: animT,
      );
    } else if (activeClip?.type == ClipType.video &&
        _initialized &&
        _controller != null) {
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

// ── Text overlay preview (title and colorCard) ───────────────────────────────

class _TextOverlayPreview extends StatelessWidget {
  const _TextOverlayPreview({
    required this.clip,
    required this.compositionWidth,
    required this.compositionHeight,
    required this.background,
    required this.animT,
  });

  final ClipModel clip;
  final int compositionWidth;
  final int compositionHeight;
  final Color background;
  final double animT;

  TextStyle _resolvedStyle() {
    final base = TextStyle(
      color: Color(clip.titleColorValue),
      fontSize: clip.titleFontSize,
      fontWeight: FontWeight.bold,
      shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
    );
    try {
      return GoogleFonts.getFont(clip.fontFamily, textStyle: base);
    } catch (_) {
      return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alignment = switch (clip.titleAlignment) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };

    final text = clip.titleText ?? '';

    Widget textWidget = text.isEmpty
        ? const SizedBox.shrink()
        : Text(text, textAlign: alignment, style: _resolvedStyle());

    // Apply text animation based on animT (0=start, 1=fully in).
    textWidget = _applyAnimation(textWidget, text);

    return AspectRatio(
      aspectRatio: compositionWidth / compositionHeight,
      child: Container(
        color: background,
        padding: const EdgeInsets.all(32),
        child: Center(child: textWidget),
      ),
    );
  }

  Widget _applyAnimation(Widget child, String fullText) {
    final t = animT;
    switch (clip.textAnimationType) {
      case TextAnimationType.none:
        return child;
      case TextAnimationType.fadeIn:
        return Opacity(opacity: t, child: child);
      case TextAnimationType.slideUp:
        return Transform.translate(
          offset: Offset(0, (1 - t) * 40),
          child: Opacity(opacity: t, child: child),
        );
      case TextAnimationType.slideDown:
        return Transform.translate(
          offset: Offset(0, -(1 - t) * 40),
          child: Opacity(opacity: t, child: child),
        );
      case TextAnimationType.slideLeft:
        return Transform.translate(
          offset: Offset((1 - t) * 60, 0),
          child: Opacity(opacity: t, child: child),
        );
      case TextAnimationType.slideRight:
        return Transform.translate(
          offset: Offset(-(1 - t) * 60, 0),
          child: Opacity(opacity: t, child: child),
        );
      case TextAnimationType.zoomIn:
        return Transform.scale(
          scale: 0.3 + 0.7 * t,
          child: Opacity(opacity: t, child: child),
        );
      case TextAnimationType.typewriter:
        if (fullText.isEmpty) return child;
        final visible =
            (fullText.length * t).round().clamp(0, fullText.length);
        return Text(
          fullText.substring(0, visible),
          textAlign: switch (clip.titleAlignment) {
            'left' => TextAlign.left,
            'right' => TextAlign.right,
            _ => TextAlign.center,
          },
          style: _resolvedStyle(),
        );
    }
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
            Text('$width×$height', style: AppTypography.bodySmall),
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
          .map((z) => DropdownMenuItem(value: z, child: Text(z)))
          .toList(),
      onChanged: (v) => setState(() => _zoom = v ?? 'Fit'),
    );
  }
}
