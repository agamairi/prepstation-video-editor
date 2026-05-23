import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/app/theme/typography.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/effects/effect_model.dart';
import 'package:prepstation/core/effects/effect_type.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/segmentation/isolation_mode.dart';
import 'package:prepstation/core/segmentation/segmentation_service.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_controller.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';
import 'package:prepstation/core/timeline/timeline_tool.dart';
import 'package:prepstation/core/timeline/track_model.dart';
import 'package:prepstation/core/transitions/transition_type.dart';
import 'package:prepstation/features/editor/panels/tracker_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';

class _TransitionInfo {
  const _TransitionInfo({
    required this.type,
    required this.progress,
    required this.outgoingClip,
    this.incomingClip,
  });
  final TransitionType type;
  final double progress;
  final ClipModel outgoingClip;
  final ClipModel? incomingClip;
}

final _transitionInfoProvider = Provider.autoDispose<_TransitionInfo?>((ref) {
  final state = ref.watch(timelineStateProvider);
  final playhead = state.playhead;

  for (final track in state.videoTracks.reversed) {
    final trackClips = state.clipsForTrack(track.id);
    for (var i = 0; i < trackClips.length; i++) {
      final clip = trackClips[i];
      if (clip.transitionOutId == null ||
          clip.transitionOutDuration == Duration.zero) {
        continue;
      }

      final transType = TransitionType.fromId(clip.transitionOutId!);
      if (transType == null) continue;

      final transStart =
          clip.endOnTimeline - clip.transitionOutDuration;
      final transEnd = clip.endOnTimeline;

      if (playhead >= transStart && playhead < transEnd) {
        final elapsed =
            (playhead - transStart).inMicroseconds.toDouble();
        final total =
            clip.transitionOutDuration.inMicroseconds.toDouble();
        final nextClip =
            i + 1 < trackClips.length ? trackClips[i + 1] : null;
        return _TransitionInfo(
          type: transType,
          progress: (elapsed / total).clamp(0.0, 1.0),
          outgoingClip: clip,
          incomingClip: nextClip,
        );
      }
    }
  }
  return null;
});

/// The clip currently under the playhead (top video track wins) — used for
/// inspector selection and isolation gestures.
final _activeClipProvider = Provider.autoDispose<ClipModel?>((ref) {
  final state = ref.watch(timelineStateProvider);
  for (final track in state.videoTracks.reversed) {
    final clip = state.clipAt(track.id, state.playhead);
    if (clip != null) return clip;
  }
  return null;
});

/// All clips visible at the current playhead across every visible video track,
/// ordered bottom-to-top (lowest track index first → painted first → behind).
final _visibleLayersProvider = Provider.autoDispose<List<ClipModel>>((ref) {
  final state = ref.watch(timelineStateProvider);
  final layers = <ClipModel>[];
  final sortedTracks = state.videoTracks.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  for (final track in sortedTracks) {
    if (!track.isVisible) continue;
    final clip = state.clipAt(track.id, state.playhead);
    if (clip != null) layers.add(clip);
  }
  return layers;
});


/// Derived bool provider so ref.listen sees value changes (not same-object
/// ChangeNotifier ticks).
final _isPlayingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(timelineStateProvider).isPlaying;
});


class PreviewPanel extends ConsumerStatefulWidget {
  const PreviewPanel({super.key, required this.project});

  final ProjectModel project;

  @override
  ConsumerState<PreviewPanel> createState() => _PreviewPanelState();
}

class _LayerEntry {
  VideoPlayerController? videoController;
  String? mediaId;
  bool initialized = false;
  bool _disposed = false;

  VideoPlayerController? maskController;
  String? maskPath;
  bool maskInitialized = false;

  bool get isDisposed => _disposed;

  Future<void> dispose() async {
    _disposed = true;
    await videoController?.dispose();
    await maskController?.dispose();
    videoController = null;
    maskController = null;
    initialized = false;
    maskInitialized = false;
  }
}

class _PreviewPanelState extends ConsumerState<PreviewPanel> {
  final Map<String, _LayerEntry> _layers = {};

  VideoPlayerController? _transitionController;
  String? _transitionMediaId;
  bool _transitionInitialized = false;

  Offset? _selectionRectStart;
  Offset? _selectionRectEnd;
  bool _isDrawingSelection = false;

  final Map<String, ja.AudioPlayer> _audioPlayers = {};
  final Set<String> _activeAudioClipIds = {};
  final Set<String> _audioLoading = {};
  bool _audioSyncing = false;

  Timer? _playbackTimer;
  DateTime? _wallClockAtPlayStart;
  Duration _playheadAtPlayStart = Duration.zero;

  final Map<String, String?> _imagePathCache = {};

  @override
  void dispose() {
    _playbackTimer?.cancel();
    for (final layer in _layers.values) {
      layer.dispose();
    }
    _layers.clear();
    _transitionController?.dispose();
    for (final player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  // ── Playback control ────────────────────────────────────────────────────────

  void _startPlayback(TimelineState state) {
    _playbackTimer?.cancel();

    Duration seekTo = state.playhead;

    // Capture selected clip to scope playback to it.
    ClipModel? boundaryClip;
    if (state.selectedClipIds.isNotEmpty) {
      final selectedId = state.selectedClipIds.first;
      try {
        boundaryClip = state.clips.firstWhere((c) => c.id == selectedId);
      } catch (_) {}
    }

    if (boundaryClip != null) {
      // Clamp to selected clip range
      if (seekTo < boundaryClip.startOnTimeline ||
          seekTo >= boundaryClip.endOnTimeline) {
        seekTo = boundaryClip.startOnTimeline;
        state.setPlayhead(seekTo);
      }
    } else if (state.duration > Duration.zero && seekTo >= state.duration) {
      seekTo = Duration.zero;
      state.setPlayhead(seekTo);
    }

    _playheadAtPlayStart = seekTo;
    _wallClockAtPlayStart = DateTime.now();

    _syncLayerControllers(state, seekTo, startPlaying: true);
    _syncAudioPlayback(state, seekTo);

    // Track which clips had playing controllers last tick so we can detect
    // when the playhead crosses into a new clip and start its controller.
    Set<String> lastVisibleClipIds = {};

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      final s = ref.read(timelineStateProvider);
      if (!s.isPlaying) return;

      final elapsed = DateTime.now().difference(_wallClockAtPlayStart!);
      final newPlayhead = _playheadAtPlayStart + elapsed;

      // Stop at selected clip boundary
      if (boundaryClip != null &&
          newPlayhead >= boundaryClip.endOnTimeline) {
        s.setPlayhead(boundaryClip.startOnTimeline);
        s.setPlaying(false);
        for (final layer in _layers.values) {
          if (!layer.isDisposed) layer.videoController?.pause();
        }
        _stopAllAudio();
        return;
      }

      if (s.duration > Duration.zero && newPlayhead >= s.duration) {
        s.setPlayhead(Duration.zero);
        s.setPlaying(false);
        for (final layer in _layers.values) {
          if (!layer.isDisposed) {
            layer.videoController?.seekTo(Duration.zero);
            layer.videoController?.pause();
          }
        }
        _stopAllAudio();
        return;
      }

      s.setPlayhead(newPlayhead);

      // Sync video controllers for clips currently under the playhead.
      // This ensures that when the playhead moves from one clip to the
      // next, the new clip's video controller gets seeked and played.
      final nowVisible = <String>{};
      for (final track in s.videoTracks) {
        if (!track.isVisible) continue;
        final clip = s.clipAt(track.id, newPlayhead);
        if (clip != null && clip.type == ClipType.video) {
          nowVisible.add(clip.id);
          final layer = _layers[clip.id];
          if (layer != null &&
              layer.initialized &&
              !layer.isDisposed &&
              layer.videoController != null) {
            if (!lastVisibleClipIds.contains(clip.id)) {
              final offsetInClip = newPlayhead - clip.startOnTimeline;
              final videoPos = clip.mediaInPoint + offsetInClip;
              layer.videoController!.seekTo(videoPos);
              layer.videoController!.play();
            }
          }
        }
      }

      for (final oldId in lastVisibleClipIds) {
        if (!nowVisible.contains(oldId)) {
          final old = _layers[oldId];
          if (old != null && !old.isDisposed) {
            old.videoController?.pause();
          }
        }
      }
      lastVisibleClipIds = nowVisible;

      _syncAudioPlayback(s, newPlayhead);
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _wallClockAtPlayStart = null;
    for (final layer in _layers.values) {
      layer.videoController?.pause();
    }
    _stopAllAudio();
  }

  void _syncLayerControllers(TimelineState state, Duration playhead,
      {bool startPlaying = false}) {
    final visibleClips = <ClipModel>[];
    final sortedTracks = state.videoTracks.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    for (final track in sortedTracks) {
      if (!track.isVisible) continue;
      final clip = state.clipAt(track.id, playhead);
      if (clip != null && clip.type == ClipType.video) {
        visibleClips.add(clip);
      }
    }

    for (final clip in visibleClips) {
      final layer = _layers[clip.id];
      if (layer == null || !layer.initialized || layer.videoController == null) {
        if (layer?.mediaId != clip.mediaId) {
          _loadLayerVideo(clip.id, clip.mediaId).then((_) {
            if (!mounted) return;
            final l = _layers[clip.id];
            if (l == null || !l.initialized || l.videoController == null) return;
            final offsetInClip = playhead - clip.startOnTimeline;
            final videoPos = clip.mediaInPoint + offsetInClip;
            l.videoController!.seekTo(videoPos);
            if (startPlaying) l.videoController!.play();
          });
        }
        continue;
      }
      final offsetInClip = playhead - clip.startOnTimeline;
      final videoPos = clip.mediaInPoint + offsetInClip;
      layer.videoController!.seekTo(videoPos);
      if (startPlaying) layer.videoController!.play();
    }
  }

  // ── Audio playback ─────────────────────────────────────────────────────────

  Future<void> _syncAudioPlayback(TimelineState state, Duration playhead) async {
    if (_audioSyncing) return;
    _audioSyncing = true;
    try {
      final audioClips = <ClipModel>[];
      for (final track in state.tracks.where((t) => t.type == TrackType.audio)) {
        final clip = state.clipAt(track.id, playhead);
        if (clip != null && !clip.isMuted) {
          audioClips.add(clip);
        }
      }

      final activeIds = audioClips.map((c) => c.id).toSet();

      for (final id in _activeAudioClipIds.toList()) {
        if (!activeIds.contains(id)) {
          await _audioPlayers[id]?.pause();
          _activeAudioClipIds.remove(id);
        }
      }

      for (final clip in audioClips) {
        if (_activeAudioClipIds.contains(clip.id)) continue;
        if (_audioLoading.contains(clip.id)) continue;

        final player = await _getAudioPlayer(clip);
        if (player == null) continue;
        if (!mounted) return;

        final offsetInClip = playhead - clip.startOnTimeline;
        final mediaPos = clip.mediaInPoint + offsetInClip;
        await player.setVolume(clip.volume);
        await player.seek(mediaPos);
        unawaited(player.play());
        _activeAudioClipIds.add(clip.id);
      }
    } finally {
      _audioSyncing = false;
    }
  }

  Future<ja.AudioPlayer?> _getAudioPlayer(ClipModel clip) async {
    if (_audioPlayers.containsKey(clip.id)) return _audioPlayers[clip.id];
    if (_audioLoading.contains(clip.id)) return null;

    _audioLoading.add(clip.id);
    try {
      final asset = await ref.read(projectRepositoryProvider).getMediaAsset(clip.mediaId);
      if (asset == null) return null;

      final player = ja.AudioPlayer();
      try {
        await player.setFilePath(asset.filePath);
        _audioPlayers[clip.id] = player;
        return player;
      } catch (e) {
        debugPrint('[PreviewPanel] Failed to load audio for ${clip.id}: $e');
        await player.dispose();
        return null;
      }
    } finally {
      _audioLoading.remove(clip.id);
    }
  }

  void _stopAllAudio() {
    for (final player in _audioPlayers.values) {
      player.stop();
    }
    _activeAudioClipIds.clear();
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
    final controller = ref.read(timelineControllerProvider);

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
    final scaleX = controller.evaluatedParameter(clip.id, 'scaleX', clip.scaleX);
    final scaleY = controller.evaluatedParameter(clip.id, 'scaleY', clip.scaleY);
    if (scaleX != 1.0 || scaleY != 1.0) {
      result = Transform(
        alignment: Alignment(
          -1.0 + 2.0 * clip.anchorX,
          -1.0 + 2.0 * clip.anchorY,
        ),
        transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
        child: result,
      );
    }

    // Rotation (in degrees)
    final rotation = controller.evaluatedParameter(clip.id, 'rotation', clip.rotation);
    if (rotation != 0.0) {
      final radians = rotation * math.pi / 180.0;
      result = Transform.rotate(
        angle: radians,
        alignment: Alignment(
          -1.0 + 2.0 * clip.anchorX,
          -1.0 + 2.0 * clip.anchorY,
        ),
        child: result,
      );
    }

    // Position offset (in pixels) — evaluate keyframes for animated tracking
    final posX = controller.evaluatedParameter(clip.id, 'posX', clip.posX);
    final posY = controller.evaluatedParameter(clip.id, 'posY', clip.posY);
    if (posX != 0.0 || posY != 0.0) {
      result = Transform.translate(
        offset: Offset(posX, posY),
        child: result,
      );
    }

    // Opacity
    final opacity = controller.evaluatedParameter(clip.id, 'opacity', clip.opacity);
    if (opacity < 1.0) {
      result = Opacity(opacity: opacity.clamp(0.0, 1.0), child: result);
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

  Future<void> _loadLayerVideo(String clipId, String mediaId) async {
    var layer = _layers[clipId];
    if (layer != null && layer.mediaId == mediaId && layer.initialized) return;

    if (layer != null) {
      await layer.videoController?.dispose();
      layer.videoController = null;
      layer.initialized = false;
    } else {
      layer = _LayerEntry();
      _layers[clipId] = layer;
    }
    layer.mediaId = mediaId;

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

    final currentLayer = _layers[clipId];
    if (currentLayer == null || currentLayer.mediaId != mediaId) {
      await controller.dispose();
      return;
    }

    final state = ref.read(timelineStateProvider);
    final hasLinkedAudio = state.clips.any(
      (c) => c.mediaId == mediaId && c.type == ClipType.audio && c.isVideoLinked,
    );
    if (hasLinkedAudio) {
      await controller.setVolume(0.0);
    }

    setState(() {
      currentLayer.videoController = controller;
      currentLayer.initialized = true;
    });
  }

  void _pruneUnusedLayers(List<ClipModel> visibleClips) {
    final visibleIds = visibleClips.map((c) => c.id).toSet();
    final staleIds = _layers.keys.where((id) => !visibleIds.contains(id)).toList();
    for (final id in staleIds) {
      _layers[id]?.dispose();
      _layers.remove(id);
    }
  }

  Future<void> _loadTransitionVideo(String mediaId) async {
    if (_transitionMediaId == mediaId) return;
    _transitionMediaId = mediaId;

    final old = _transitionController;
    _transitionController = null;
    _transitionInitialized = false;
    await old?.dispose();

    if (!mounted) return;

    final asset =
        await ref.read(projectRepositoryProvider).getMediaAsset(mediaId);
    if (asset == null || !mounted || !asset.hasVideo) return;

    final controller = VideoPlayerController.file(
      File(asset.proxyPath ?? asset.filePath),
    );

    await controller.initialize();
    if (!mounted || _transitionMediaId != mediaId) {
      await controller.dispose();
      return;
    }

    setState(() {
      _transitionController = controller;
      _transitionInitialized = true;
    });
  }

  void _clearTransitionVideo() {
    if (_transitionController == null) return;
    final old = _transitionController;
    _transitionMediaId = null;
    _transitionController = null;
    _transitionInitialized = false;
    old?.dispose();
  }

  // ── Isolation mask video ─────────────────────────────────────────────────────

  Future<void> _loadLayerMaskVideo(String clipId, String path) async {
    final layer = _layers[clipId];
    if (layer == null) return;
    if (layer.maskPath == path && layer.maskInitialized) return;
    layer.maskPath = path;

    final old = layer.maskController;
    layer.maskController = null;
    layer.maskInitialized = false;
    await old?.dispose();

    if (!mounted) return;

    final file = File(path);
    if (!file.existsSync()) return;

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    final currentLayer = _layers[clipId];
    if (currentLayer == null || currentLayer.maskPath != path) {
      await controller.dispose();
      return;
    }

    await controller.setVolume(0.0);

    setState(() {
      currentLayer.maskController = controller;
      currentLayer.maskInitialized = true;
    });
  }

  void _clearLayerMaskVideo(String clipId) {
    final layer = _layers[clipId];
    if (layer == null || layer.maskController == null) return;
    final old = layer.maskController;
    layer.maskPath = null;
    layer.maskController = null;
    layer.maskInitialized = false;
    old?.dispose();
  }

  // ── Isolation selection rectangle gestures ────────────────────────────────────

  void _onSelectionPanStart(DragStartDetails details, BoxConstraints constraints) {
    setState(() {
      _isDrawingSelection = true;
      _selectionRectStart = Offset(
        (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
        (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
      );
      _selectionRectEnd = _selectionRectStart;
    });
  }

  void _onSelectionPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _selectionRectEnd = Offset(
        (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
        (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
      );
    });
  }

  Future<void> _onSelectionPanEnd(ClipModel clip) async {
    if (_selectionRectStart == null || _selectionRectEnd == null) return;

    final left = math.min(_selectionRectStart!.dx, _selectionRectEnd!.dx);
    final top = math.min(_selectionRectStart!.dy, _selectionRectEnd!.dy);
    final right = math.max(_selectionRectStart!.dx, _selectionRectEnd!.dx);
    final bottom = math.max(_selectionRectStart!.dy, _selectionRectEnd!.dy);

    setState(() {
      _isDrawingSelection = false;
      _selectionRectStart = null;
      _selectionRectEnd = null;
    });

    if ((right - left) < AppConstants.isolationRectMinSize ||
        (bottom - top) < AppConstants.isolationRectMinSize) {
      return;
    }

    final controller = ref.read(timelineControllerProvider);
    await controller.setIsolationSelectionRect(clip.id, left, top, right, bottom);

    unawaited(_autoGenerateMask(clip.id, Rect.fromLTRB(left, top, right, bottom)));
  }

  Future<void> _autoGenerateMask(String clipId, Rect selectionRect) async {
    final controller = ref.read(timelineControllerProvider);
    final segService = ref.read(segmentationServiceProvider);
    final repo = ref.read(projectRepositoryProvider);

    final clip = ref.read(timelineStateProvider).clips.firstWhere(
      (c) => c.id == clipId,
      orElse: () => throw StateError('Clip not found'),
    );

    final asset = await repo.getMediaAsset(clip.mediaId);
    if (asset == null) return;

    controller.setIsolationProcessing(clipId, true);

    final dir = File(asset.filePath).parent.path;
    final outputPath = '$dir/mask_${clip.id}.mp4';

    final result = await segService.generateMaskVideo(
      videoPath: asset.filePath,
      outputPath: outputPath,
      inPoint: clip.mediaInPoint,
      outPoint: clip.mediaOutPoint,
      selectionRect: selectionRect,
    );

    if (!mounted) return;

    if (result != null) {
      await controller.setIsolationMaskPath(clipId, result);
    } else {
      controller.setIsolationProcessing(clipId, false);
    }
  }

  Widget _applyIsolationPreview(Widget child, ClipModel clip) {
    if (!clip.isolationEnabled || clip.isolationMaskPath == null) return child;

    final layer = _layers[clip.id];
    if (layer == null || !layer.maskInitialized || layer.maskController == null) {
      return child;
    }

    final maskAr = layer.maskController!.value.aspectRatio;
    Widget maskWidget = AspectRatio(
      aspectRatio: maskAr > 0 ? maskAr : 16.0 / 9.0,
      child: VideoPlayer(layer.maskController!),
    );

    // Apply edge feathering as a blur on the mask
    if (clip.isolationEdgeFeather > 0) {
      final featherSigma = clip.isolationEdgeFeather * 0.8;
      maskWidget = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: featherSigma,
          sigmaY: featherSigma,
        ),
        child: maskWidget,
      );
    }

    switch (clip.isolationMode) {
      case IsolationMode.transparent:
        return ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Colors.white, Colors.white],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: Stack(
            alignment: Alignment.center,
            children: [
              child,
              Positioned.fill(
                child: Opacity(opacity: 0.0, child: maskWidget),
              ),
            ],
          ),
        );

      case IsolationMode.blur:
        final sigma = clip.isolationBlurRadius * 0.5;
        return Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
              ),
              child: child,
            ),
            _IsolationMaskComposite(
              subject: child,
              mask: maskWidget,
            ),
          ],
        );

      case IsolationMode.solidColor:
        final bgColor = Color(clip.isolationColorValue);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(color: bgColor),
            _IsolationMaskComposite(
              subject: child,
              mask: maskWidget,
            ),
          ],
        );
    }
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

  Widget _buildLayerWidget(ClipModel clip, TimelineState timelineState) {
    final animT = _animT(clip, timelineState.playhead);

    Widget layerWidget;
    if (clip.type == ClipType.title) {
      layerWidget = _TextOverlayPreview(
        clip: clip,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
        background: Color(clip.titleBgColorValue),
        animT: animT,
      );
    } else if (clip.type == ClipType.colorCard) {
      layerWidget = _TextOverlayPreview(
        clip: clip,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
        background: Color(clip.cardColorValue),
        animT: animT,
      );
    } else if (clip.type == ClipType.image) {
      layerWidget = _TextOverlayPreview(
        clip: clip,
        compositionWidth: widget.project.composition.width,
        compositionHeight: widget.project.composition.height,
        imagePath: _imagePathCache[clip.id],
        animT: animT,
      );
    } else if (clip.type == ClipType.video) {
      final layer = _layers[clip.id];
      if (layer != null &&
          layer.initialized &&
          layer.videoController != null &&
          layer.videoController!.value.isInitialized) {
        final ar = layer.videoController!.value.aspectRatio;
        layerWidget = AspectRatio(
          aspectRatio: ar > 0 ? ar : 16.0 / 9.0,
          child: VideoPlayer(layer.videoController!),
        );
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }

    final effects = timelineState.effectsForClip(clip.id);
    layerWidget = _applyEffectFilters(layerWidget, effects);
    layerWidget = _applyClipTransforms(layerWidget, clip);

    if (clip.isolationEnabled && clip.isolationMaskPath != null) {
      final layer = _layers[clip.id];
      if (layer != null && layer.maskInitialized && layer.maskController != null) {
        final offsetInClip = timelineState.playhead - clip.startOnTimeline;
        final maskPos = clip.mediaInPoint + offsetInClip;
        layer.maskController!.seekTo(maskPos);
      }
      layerWidget = _applyIsolationPreview(layerWidget, clip);
    }

    return layerWidget;
  }

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

    final activeClip = ref.watch(_activeClipProvider);
    final visibleLayers = ref.watch(_visibleLayersProvider);
    final timelineState = ref.watch(timelineStateProvider);
    final transitionInfo = ref.watch(_transitionInfoProvider);

    // Ensure layer controllers are loaded for all visible clips.
    // During playback, load ALL video clips so controllers are ready
    // when the playhead reaches them; only prune when paused.
    final clipsToLoad = timelineState.isPlaying
        ? timelineState.clips
            .where((c) => c.type == ClipType.video || c.type == ClipType.image)
            .toList()
        : visibleLayers;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!timelineState.isPlaying) {
        _pruneUnusedLayers(visibleLayers);
      }

      for (final clip in clipsToLoad) {
        if (clip.type == ClipType.video) {
          final layer = _layers[clip.id];
          if (layer == null || layer.mediaId != clip.mediaId) {
            _loadLayerVideo(clip.id, clip.mediaId).then((_) {
              if (!mounted) return;
              final l = _layers[clip.id];
              if (l == null || !l.initialized || l.videoController == null) return;
              final ts = ref.read(timelineStateProvider);
              final offsetInClip = ts.playhead - clip.startOnTimeline;
              final videoPos = clip.mediaInPoint + offsetInClip;
              l.videoController!.seekTo(videoPos);
            });
          } else if (layer.initialized &&
              layer.videoController != null &&
              !timelineState.isPlaying) {
            final offsetInClip = timelineState.playhead - clip.startOnTimeline;
            final videoPos = clip.mediaInPoint + offsetInClip;
            layer.videoController!.seekTo(videoPos);
          }
        }

        if (clip.type == ClipType.image && !_imagePathCache.containsKey(clip.id)) {
          ref.read(projectRepositoryProvider).getMediaAsset(clip.mediaId).then((asset) {
            if (mounted && asset != null) {
              setState(() {
                _imagePathCache[clip.id] = asset.proxyPath ?? asset.filePath;
              });
            }
          });
        }

        if (clip.isolationEnabled && clip.isolationMaskPath != null) {
          _layers.putIfAbsent(clip.id, () => _LayerEntry());
          final layer = _layers[clip.id]!;
          if (layer.maskPath != clip.isolationMaskPath) {
            _loadLayerMaskVideo(clip.id, clip.isolationMaskPath!);
          }
        } else {
          final layer = _layers[clip.id];
          if (layer != null && layer.maskController != null) {
            _clearLayerMaskVideo(clip.id);
          }
        }
      }
    });

    // Load or clear the incoming clip's video for transition preview.
    if (transitionInfo != null &&
        transitionInfo.incomingClip != null &&
        transitionInfo.incomingClip!.type == ClipType.video) {
      final inMediaId = transitionInfo.incomingClip!.mediaId;
      if (_transitionMediaId != inMediaId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadTransitionVideo(inMediaId);
        });
      }
      if (_transitionInitialized &&
          _transitionController != null &&
          _transitionController!.value.isInitialized) {
        final inClip = transitionInfo.incomingClip!;
        final offsetInClip =
            timelineState.playhead - inClip.startOnTimeline;
        final videoPos = inClip.mediaInPoint + offsetInClip;
        _transitionController!.seekTo(videoPos);
      }
    } else if ((transitionInfo == null ||
            transitionInfo.incomingClip == null) &&
        _transitionController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _clearTransitionVideo();
      });
    }

    // Build the composited layer stack.
    Widget contentWidget;
    if (visibleLayers.isEmpty) {
      contentWidget = _EmptyPreview(
        width: widget.project.composition.width,
        height: widget.project.composition.height,
      );
    } else if (visibleLayers.length == 1) {
      contentWidget = _buildLayerWidget(visibleLayers.first, timelineState);
    } else {
      contentWidget = Stack(
        alignment: Alignment.center,
        children: [
          for (final clip in visibleLayers)
            Positioned.fill(
              child: Center(child: _buildLayerWidget(clip, timelineState)),
            ),
        ],
      );
    }

    // Apply transition effect when in a transition zone (topmost layer only).
    if (transitionInfo != null) {
      Widget incomingWidget;
      if (_transitionInitialized &&
          _transitionController != null &&
          _transitionController!.value.isInitialized) {
        final ar = _transitionController!.value.aspectRatio;
        incomingWidget = AspectRatio(
          aspectRatio: ar > 0 ? ar : 16.0 / 9.0,
          child: VideoPlayer(_transitionController!),
        );
      } else {
        incomingWidget = const ColoredBox(color: Colors.black);
      }

      contentWidget = _TransitionComposite(
        type: transitionInfo.type,
        progress: transitionInfo.progress,
        outgoing: contentWidget,
        incoming: incomingWidget,
      );
    }

    final inSelectionMode = activeClip != null &&
        activeClip.type == ClipType.video &&
        activeClip.isolationEnabled &&
        activeClip.isolationMaskPath == null &&
        activeClip.isolationSelectionLeft == null;

    final tool = ref.watch(timelineToolProvider);
    final inTrackerMode = tool == TimelineTool.tracker &&
        activeClip != null &&
        activeClip.type == ClipType.video;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: inSelectionMode || _isDrawingSelection
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanStart: (d) =>
                              _onSelectionPanStart(d, constraints),
                          onPanUpdate: (d) =>
                              _onSelectionPanUpdate(d, constraints),
                          onPanEnd: (d) =>
                              _onSelectionPanEnd(activeClip!),
                          child: Stack(
                            children: [
                              contentWidget,
                              if (_selectionRectStart != null &&
                                  _selectionRectEnd != null)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _SelectionRectPainter(
                                      start: _selectionRectStart!,
                                      end: _selectionRectEnd!,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : inTrackerMode
                      ? Stack(
                          children: [
                            contentWidget,
                            Positioned.fill(
                              child: TrackerOverlay(
                                activeClip: activeClip,
                              ),
                            ),
                          ],
                        )
                      : contentWidget,
            ),
          ),
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

// ── Isolation mask composite ─────────────────────────────────────────────────

class _IsolationMaskComposite extends StatelessWidget {
  const _IsolationMaskComposite({
    required this.subject,
    required this.mask,
  });

  final Widget subject;
  final Widget mask;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.dst,
          ),
          child: mask,
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Colors.white, Colors.white],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: subject,
        ),
      ],
    );
  }
}

// ── Transition composite ─────────────────────────────────────────────────────

class _TransitionComposite extends StatelessWidget {
  const _TransitionComposite({
    required this.type,
    required this.progress,
    required this.outgoing,
    required this.incoming,
  });

  final TransitionType type;
  final double progress;
  final Widget outgoing;
  final Widget incoming;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: switch (type) {
        TransitionType.crossDissolve => _crossDissolve(),
        TransitionType.fadeBlack => _fadeViaColor(Colors.black),
        TransitionType.fadeWhite => _fadeViaColor(Colors.white),
        TransitionType.wipeLeft => _wipe(const Alignment(1, 0), Axis.horizontal),
        TransitionType.wipeRight => _wipe(const Alignment(-1, 0), Axis.horizontal),
        TransitionType.wipeUp => _wipe(const Alignment(0, 1), Axis.vertical),
        TransitionType.wipeDown => _wipe(const Alignment(0, -1), Axis.vertical),
        TransitionType.slide ||
        TransitionType.slideRight ||
        TransitionType.slideUp ||
        TransitionType.slideDown => _slide(),
        _ => _crossDissolve(),
      },
    );
  }

  Widget _centered(Widget child) {
    return Positioned.fill(child: Center(child: child));
  }

  Widget _crossDissolve() {
    return Stack(
      children: [
        _centered(Opacity(opacity: (1.0 - progress).clamp(0.0, 1.0), child: outgoing)),
        _centered(Opacity(opacity: progress.clamp(0.0, 1.0), child: incoming)),
      ],
    );
  }

  Widget _fadeViaColor(Color color) {
    final fadeOut = (progress * 2.0).clamp(0.0, 1.0);
    final fadeIn = ((progress - 0.5) * 2.0).clamp(0.0, 1.0);
    return Stack(
      children: [
        if (fadeIn > 0) _centered(Opacity(opacity: fadeIn, child: incoming)),
        if (fadeOut < 1) _centered(Opacity(opacity: 1.0 - fadeOut, child: outgoing)),
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: color.withValues(
                alpha: fadeOut < 1.0 ? fadeOut : 1.0 - fadeIn,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wipe(Alignment direction, Axis axis) {
    return Stack(
      children: [
        _centered(incoming),
        _centered(
          ClipRect(
            child: Align(
              alignment: direction,
              widthFactor: axis == Axis.horizontal ? 1.0 - progress : null,
              heightFactor: axis == Axis.vertical ? 1.0 - progress : null,
              child: outgoing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _slide() {
    final Offset outOffset;
    final Offset inOffset;

    switch (type) {
      case TransitionType.slide:
        outOffset = Offset(-progress, 0);
        inOffset = Offset(1.0 - progress, 0);
      case TransitionType.slideRight:
        outOffset = Offset(progress, 0);
        inOffset = Offset(-1.0 + progress, 0);
      case TransitionType.slideUp:
        outOffset = Offset(0, -progress);
        inOffset = Offset(0, 1.0 - progress);
      case TransitionType.slideDown:
        outOffset = Offset(0, progress);
        inOffset = Offset(0, -1.0 + progress);
      default:
        outOffset = Offset(-progress, 0);
        inOffset = Offset(1.0 - progress, 0);
    }

    return Stack(
      children: [
        _centered(FractionalTranslation(translation: inOffset, child: incoming)),
        _centered(FractionalTranslation(translation: outOffset, child: outgoing)),
      ],
    );
  }
}

class _SelectionRectPainter extends CustomPainter {
  _SelectionRectPainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(
      Offset(start.dx * size.width, start.dy * size.height),
      Offset(end.dx * size.width, end.dy * size.height),
    );

    final paint = Paint()
      ..color = ColorTokens.isolationRect
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppConstants.isolationRectStrokeWidth;

    canvas.drawRect(rect, paint);

    final fillPaint = Paint()
      ..color = ColorTokens.isolationRect.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);
  }

  @override
  bool shouldRepaint(_SelectionRectPainter oldDelegate) =>
      start != oldDelegate.start || end != oldDelegate.end;
}
