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

/// Resolves the file path for an image clip's asset (null when not an image).
final _activeImagePathProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final clip = ref.watch(_activeClipProvider);
  if (clip?.type != ClipType.image) return null;
  final asset = await ref
      .read(projectRepositoryProvider)
      .getMediaAsset(clip!.mediaId);
  return asset?.proxyPath ?? asset?.filePath;
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
          final strength =
              (effect.parameters['strength'] ?? 20.0).clamp(0.0, 100.0);
          if (strength > 0) {
            result = _GrainOverlay(strength: strength, child: result);
          }
        case EffectType.sharpen:
          final amount =
              (effect.parameters['amount'] ?? 1.0).clamp(0.0, 5.0);
          if (amount > 0) {
            final sigma = 0.5 + amount * 0.3;
            result = Stack(
              children: [
                result,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.compose(
                        outer: ui.ImageFilter.dilate(radiusX: sigma * 0.15, radiusY: sigma * 0.15),
                        inner: ui.ImageFilter.blur(sigmaX: sigma * 0.2, sigmaY: sigma * 0.2),
                      ),
                      child: Opacity(
                        opacity: (amount / 5.0).clamp(0.0, 0.5),
                        child: result,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        case EffectType.colorWheels:
          final matrix = _buildColorWheelsMatrix(effect.parameters);
          result = ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix),
            child: result,
          );
        case EffectType.curves:
          final matrix = _buildCurvesMatrix(effect.parameters);
          result = ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix),
            child: result,
          );
        case EffectType.denoise:
          final strength =
              (effect.parameters['strength'] ?? 4.0).clamp(1.0, 20.0);
          final sigma = (strength - 1) * 0.15;
          if (sigma > 0.1) {
            result = ImageFiltered(
              imageFilter:
                  ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: result,
            );
          }
        case EffectType.chromaKey:
        case EffectType.lut:
        case EffectType.stabilize:
        case EffectType.audioEq:
        case EffectType.audioCompressor:
        case EffectType.audioNoiseReduction:
        case EffectType.audioReverb:
          break;
      }
    }
    return result;
  }

  Widget _applyClipTransforms(Widget child, ClipModel clip) {
    Widget result = child;

    // Crop: clip the visible area by the fractional insets
    final hasCrop = clip.cropLeft > 0 ||
        clip.cropRight > 0 ||
        clip.cropTop > 0 ||
        clip.cropBottom > 0;
    if (hasCrop) {
      final visibleW = 1.0 - clip.cropLeft - clip.cropRight;
      final visibleH = 1.0 - clip.cropTop - clip.cropBottom;
      if (visibleW > 0 && visibleH > 0) {
        result = ClipRect(
          child: Align(
            alignment: Alignment(
              -1.0 + 2.0 * (clip.cropLeft / (1.0 - visibleW)).clamp(0.0, 1.0),
              -1.0 + 2.0 * (clip.cropTop / (1.0 - visibleH)).clamp(0.0, 1.0),
            ),
            widthFactor: visibleW,
            heightFactor: visibleH,
            child: result,
          ),
        );
      }
    }

    // Flip
    if (clip.flipHorizontal || clip.flipVertical) {
      result = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          clip.flipHorizontal ? -1.0 : 1.0,
          clip.flipVertical ? -1.0 : 1.0,
          1.0,
        ),
        child: result,
      );
    }

    // Scale
    if (clip.scaleX != 1.0 || clip.scaleY != 1.0) {
      result = Transform(
        alignment: Alignment(
          -1.0 + 2.0 * clip.anchorX,
          -1.0 + 2.0 * clip.anchorY,
        ),
        transform: Matrix4.diagonal3Values(clip.scaleX, clip.scaleY, 1.0),
        child: result,
      );
    }

    // Rotation (in degrees)
    if (clip.rotation != 0.0) {
      final radians = clip.rotation * math.pi / 180.0;
      result = Transform.rotate(
        angle: radians,
        alignment: Alignment(
          -1.0 + 2.0 * clip.anchorX,
          -1.0 + 2.0 * clip.anchorY,
        ),
        child: result,
      );
    }

    // Position offset (in pixels)
    if (clip.posX != 0.0 || clip.posY != 0.0) {
      result = Transform.translate(
        offset: Offset(clip.posX, clip.posY),
        child: result,
      );
    }

    // Opacity
    if (clip.opacity < 1.0) {
      result = Opacity(opacity: clip.opacity.clamp(0.0, 1.0), child: result);
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

  List<double> _buildColorWheelsMatrix(Map<String, double> params) {
    final lr = params['liftR'] ?? 1.0;
    final lg = params['liftG'] ?? 1.0;
    final lb = params['liftB'] ?? 1.0;
    final gr = params['gammaR'] ?? 1.0;
    final gg = params['gammaG'] ?? 1.0;
    final gb = params['gammaB'] ?? 1.0;
    final gnr = params['gainR'] ?? 1.0;
    final gng = params['gainG'] ?? 1.0;
    final gnb = params['gainB'] ?? 1.0;
    final temp = params['temperature'] ?? 0.0;
    final tint = params['tint'] ?? 0.0;

    final rScale = gnr * gr * lr + temp * 0.1;
    final gScale = gng * gg * lg + tint * 0.05;
    final bScale = gnb * gb * lb - temp * 0.1;

    return [
      rScale, 0, 0, 0, 0,
      0, gScale, 0, 0, 0,
      0, 0, bScale, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  List<double> _buildCurvesMatrix(Map<String, double> params) {
    final mg = params['masterGamma'] ?? 1.0;
    final mb = params['masterBlack'] ?? 0.0;
    final mw = params['masterWhite'] ?? 1.0;
    final rg = params['redGamma'] ?? 1.0;
    final gg = params['greenGamma'] ?? 1.0;
    final bg = params['blueGamma'] ?? 1.0;

    final range = (mw - mb).clamp(0.01, 1.0);
    final rScale = (rg * mg * range).clamp(0.01, 4.0);
    final gScale = (gg * mg * range).clamp(0.01, 4.0);
    final bScale = (bg * mg * range).clamp(0.01, 4.0);
    final offset = mb * 255.0;

    return [
      rScale, 0, 0, 0, offset,
      0, gScale, 0, 0, offset,
      0, 0, bScale, 0, offset,
      0, 0, 0, 1, 0,
    ];
  }

  // ── Video loading ───────────────────────────────────────────────────────────

  Future<void> _loadVideo(String mediaId) async {
    if (_currentMediaId == mediaId) return;
    _currentMediaId = mediaId;

    final old = _controller;
    setState(() {
      _controller = null;
      _initialized = false;
    });
    await old?.dispose();

    if (!mounted) return;

    final asset =
        await ref.read(projectRepositoryProvider).getMediaAsset(mediaId);
    if (asset == null || !mounted) return;

    if (!asset.hasVideo) return;

    final controller = VideoPlayerController.file(
      File(asset.proxyPath ?? asset.filePath),
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    if (_currentMediaId != mediaId) {
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
    final durMs = clip.textAnimationDurationMs.toDouble();
    return (offsetMs / durMs).clamp(0.0, 1.0);
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
    final imagePathAsync = ref.watch(_activeImagePathProvider);

    if (mediaId != null && mediaId != _currentMediaId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadVideo(mediaId);
      });
    }

    if (mediaId == null && _currentMediaId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final old = _controller;
        _currentMediaId = null;
        setState(() {
          _controller = null;
          _initialized = false;
        });
        old?.dispose();
      });
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
    } else if (activeClip?.type == ClipType.image) {
      contentWidget = _TextOverlayPreview(
        clip: activeClip!,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
        imagePath: imagePathAsync.value,
        animT: animT,
      );
    } else if (activeClip?.type == ClipType.video &&
        _initialized &&
        _controller != null &&
        _controller!.value.isInitialized) {
      final ar = _controller!.value.aspectRatio;
      contentWidget = AspectRatio(
        aspectRatio: ar > 0 ? ar : 16.0 / 9.0,
        child: VideoPlayer(_controller!),
      );
    } else {
      contentWidget = _EmptyPreview(
        width: widget.project.composition.width,
        height: widget.project.composition.height,
      );
    }

    contentWidget = _applyEffectFilters(contentWidget, effects);

    if (activeClip != null) {
      contentWidget = _applyClipTransforms(contentWidget, activeClip);
    }

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
    this.background,
    this.imagePath,
    required this.animT,
  });

  final ClipModel clip;
  final int compositionWidth;
  final int compositionHeight;
  /// Solid background colour — used for title and colorCard clips.
  final Color? background;
  /// File path of an image — used for image clips (overrides [background]).
  final String? imagePath;
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

    Widget bgWidget;
    if (imagePath != null) {
      bgWidget = Image.file(
        File(imagePath!),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            ColoredBox(color: background ?? Colors.black),
      );
    } else {
      bgWidget = ColoredBox(color: background ?? Colors.black);
    }

    return AspectRatio(
      aspectRatio: compositionWidth / compositionHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          bgWidget,
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: textWidget),
            ),
        ],
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

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay({required this.strength, required this.child});

  final double strength;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final opacity = (strength / 100.0).clamp(0.0, 0.6);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GrainPainter(opacity: opacity),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();
    const step = 3.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final lum = rng.nextDouble();
        paint.color = Color.fromRGBO(
          (lum * 255).round(),
          (lum * 255).round(),
          (lum * 255).round(),
          opacity * (0.3 + rng.nextDouble() * 0.7),
        );
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.opacity != opacity;
}
