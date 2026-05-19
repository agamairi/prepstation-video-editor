import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/core/audio/waveform_generator.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/constants/media_constants.dart';
import 'package:prepstation/core/effects/effect_model.dart';
import 'package:prepstation/core/effects/effect_registry.dart';
import 'package:prepstation/core/effects/effect_type.dart';
import 'package:prepstation/core/ffmpeg/ffmpeg_engine.dart';
import 'package:prepstation/core/ffmpeg/thumbnail_generator.dart';
import 'package:prepstation/core/history/clip_commands.dart';
import 'package:prepstation/core/history/edit_command.dart';
import 'package:prepstation/core/history/effect_commands.dart';
import 'package:prepstation/core/history/history_manager.dart';
import 'package:prepstation/core/history/keyframe_commands.dart';
import 'package:prepstation/core/keyframes/keyframe_repository.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/segmentation/isolation_mode.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/keyframe_model.dart';
import 'package:prepstation/core/timeline/marker_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';
import 'package:prepstation/core/timeline/track_model.dart';
import 'package:prepstation/core/transitions/transition_type.dart';
import 'package:uuid/uuid.dart';

final timelineStateProvider = ChangeNotifierProvider<TimelineState>(
  (ref) => TimelineState(),
);

final timelineControllerProvider = Provider<TimelineController>((ref) {
  final controller = TimelineController(
    state: ref.watch(timelineStateProvider.notifier),
    repository: ref.watch(projectRepositoryProvider),
    ffmpegEngine: ref.watch(ffmpegEngineProvider),
    thumbnailGenerator: ref.watch(thumbnailGeneratorProvider),
    waveformGenerator: ref.watch(waveformGeneratorProvider),
    history: ref.watch(historyManagerProvider.notifier),
    keyframeRepo: ref.watch(keyframeRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class TimelineController {
  TimelineController({
    required this.state,
    required this.repository,
    required this.ffmpegEngine,
    required this.thumbnailGenerator,
    required this.waveformGenerator,
    required this.history,
    required this.keyframeRepo,
  });

  final TimelineState state;
  final ProjectRepository repository;
  final FfmpegEngine ffmpegEngine;
  final ThumbnailGenerator thumbnailGenerator;
  final WaveformGenerator waveformGenerator;
  final HistoryManager history;
  final KeyframeRepository keyframeRepo;

  static const _uuid = Uuid();

  bool _active = true;

  void dispose() => _active = false;

  Future<void> loadProject(String projectId) async {
    final tracks = await repository.getTracks(projectId);
    if (!_active) return;
    final clips = await repository.getClipsForProject(projectId);
    if (!_active) return;
    state.setTracks(tracks);
    state.setClips(clips);

    final markers = await repository.getMarkers(projectId);
    if (!_active) return;
    state.setMarkers(markers);

    for (final clip in clips) {
      final effects = await repository.getEffectsForClip(clip.id);
      if (!_active) return;
      if (effects.isNotEmpty) {
        state.setEffectsForClip(clip.id, effects);
      }
      final keyframes = await keyframeRepo.getKeyframesForClip(clip.id);
      if (!_active) return;
      if (keyframes.isNotEmpty) {
        final byParam = <String, List<KeyframeModel>>{};
        for (final kf in keyframes) {
          (byParam[kf.parameterId] ??= []).add(kf);
        }
        state.setKeyframesForClip(clip.id, byParam);
      }
    }
  }

  Future<TrackModel> addTrack({
    required String projectId,
    required TrackType type,
    String name = '',
  }) async {
    final index = type.name == 'audio'
        ? state.audioTracks.length
        : state.videoTracks.length;

    final track = TrackModel(
      id: 'track_${_uuid.v4()}',
      projectId: projectId,
      type: type,
      index: index,
      name: name,
    );
    state.addTrack(track);
    await repository.saveTrack(track);
    return track;
  }

  Future<void> removeTrack(String trackId) async {
    final clips = state.clipsForTrack(trackId);
    for (final clip in clips) {
      await repository.deleteClip(clip.id);
    }
    state.removeTrack(trackId);
    await repository.deleteTrack(trackId);
  }

  // ── History-aware operations ───────────────────────────────────────────────

  Future<void> execute(EditCommand command) =>
      history.execute(command, state, repository);

  Future<void> undo() => history.undo(state, repository);

  Future<void> redo() => history.redo(state, repository);

  // ── Clip mutations (all undoable) ──────────────────────────────────────────

  Future<ClipModel?> addClipFromAsset({
    required String trackId,
    required MediaAsset asset,
    Duration? startTime,
  }) async {
    final actualStart = startTime ?? _nextAvailableTime(trackId);

    // Still images report 0 duration from FFprobe — use a sensible default.
    var clipDuration = asset.duration;
    if (clipDuration == Duration.zero) {
      clipDuration = const Duration(seconds: 5);
    }

    final isImage = _isImagePath(asset.filePath);
    final ClipType type;
    if (isImage) {
      type = ClipType.image;
    } else if (asset.hasVideo) {
      type = ClipType.video;
    } else {
      type = ClipType.audio;
    }

    final videoClipId = 'clip_${_uuid.v4()}';
    final clip = ClipModel(
      id: videoClipId,
      trackId: trackId,
      mediaId: asset.id,
      type: type,
      startOnTimeline: actualStart,
      endOnTimeline: actualStart + clipDuration,
      mediaInPoint: Duration.zero,
      mediaOutPoint: clipDuration,
    );
    await execute(AddClipCommand(clip));

    // Auto-create a linked audio clip on the first audio track.
    if (type == ClipType.video && asset.hasAudio) {
      final audioTrack = state.audioTracks.isNotEmpty
          ? state.audioTracks.first
          : null;
      if (audioTrack != null) {
        final audioClip = ClipModel(
          id: 'clip_${_uuid.v4()}',
          trackId: audioTrack.id,
          mediaId: asset.id,
          type: ClipType.audio,
          startOnTimeline: actualStart,
          endOnTimeline: actualStart + clipDuration,
          mediaInPoint: Duration.zero,
          mediaOutPoint: clipDuration,
          isVideoLinked: true,
        );
        await execute(AddClipCommand(audioClip));
      }
    }

    return clip;
  }

  Future<void> removeClip(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(RemoveClipCommand(clip));
  }

  /// Removes [clipId] and shifts all subsequent clips on the same track left.
  Future<void> rippleDelete(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;

    final originals = state
        .clipsForTrack(clip.trackId)
        .where((c) => c.startOnTimeline >= clip.endOnTimeline)
        .toList();

    final shifted = originals
        .map(
          (c) => c.copyWith(
            startOnTimeline: c.startOnTimeline - clip.duration,
            endOnTimeline: c.endOnTimeline - clip.duration,
          ),
        )
        .toList();

    await execute(
      RippleDeleteCommand(
        deletedClip: clip,
        originalSubsequentClips: originals,
        shiftedSubsequentClips: shifted,
      ),
    );
  }

  Future<void> moveClip(
    String clipId,
    Duration newStart, {
    String? newTrackId,
  }) async {
    final clip = _findClip(clipId);
    if (clip == null) return;

    final snapped = state.snapToNearestPoint(newStart, clipId) ?? newStart;
    final duration = clip.duration;
    final updated = clip.copyWith(
      startOnTimeline: snapped,
      endOnTimeline: snapped + duration,
      trackId: newTrackId,
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Move Clip',
    ));
  }

  Future<void> trimClipStart(String clipId, Duration newStart) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    if (newStart >= clip.endOnTimeline) return;

    final delta = newStart - clip.startOnTimeline;
    final newMediaIn = clip.mediaInPoint + delta;
    if (newMediaIn < Duration.zero || newMediaIn >= clip.mediaOutPoint) return;

    final updated = clip.copyWith(
      startOnTimeline: newStart,
      mediaInPoint: newMediaIn,
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Trim Start',
    ));
  }

  Future<void> trimClipEnd(String clipId, Duration newEnd) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    if (newEnd <= clip.startOnTimeline) return;

    final delta = newEnd - clip.endOnTimeline;
    final newMediaOut = clip.mediaOutPoint + delta;
    if (newMediaOut <= clip.mediaInPoint) return;

    final minMediaOut = clip.mediaInPoint + const Duration(milliseconds: 33);
    final clampedMediaOut =
        newMediaOut < minMediaOut ? minMediaOut : newMediaOut;

    final updated = clip.copyWith(
      endOnTimeline: newEnd,
      mediaOutPoint: clampedMediaOut,
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Trim End',
    ));
  }

  Future<List<ClipModel>> splitClip(String clipId, Duration time) async {
    final clip = _findClip(clipId);
    if (clip == null) return [];
    if (time <= clip.startOnTimeline || time >= clip.endOnTimeline) return [];

    final delta = time - clip.startOnTimeline;
    final splitMediaPoint = clip.mediaInPoint + delta;

    final left = clip.copyWith(
      endOnTimeline: time,
      mediaOutPoint: splitMediaPoint,
    );
    final right = clip.copyWith(
      id: 'clip_${_uuid.v4()}',
      startOnTimeline: time,
      mediaInPoint: splitMediaPoint,
    );

    await execute(SplitClipCommand(
      originalClip: clip,
      leftClip: left,
      rightClip: right,
    ));
    return [left, right];
  }

  /// Splits the clip at the current playhead position on its track.
  Future<List<ClipModel>> splitAtPlayhead() async {
    final playhead = state.playhead;
    for (final track in state.tracks) {
      final clip = state.clipAt(track.id, playhead);
      if (clip != null) {
        return splitClip(clip.id, playhead);
      }
    }
    return [];
  }

  Future<void> updateClipOpacity(String clipId, double opacity) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final updated = clip.copyWith(opacity: opacity.clamp(0.0, 1.0));
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Set Opacity',
    ));
  }

  Future<void> updateClipSpeed(String clipId, double speed) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final clamped = speed.clamp(0.1, 16.0);
    final updated = clip.copyWith(speed: clamped);
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Set Speed',
    ));
  }

  Future<void> updateClipName(String clipId, String name) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final updated = clip.copyWith(name: name);
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Rename Clip',
    ));
  }

  // ── Transition operations (all undoable) ──────────────────────────────────

  Future<void> setTransition(
    String clipId,
    TransitionType type,
    Duration duration,
  ) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    const minDur = Duration(milliseconds: 100);
    const maxDur = Duration(seconds: 2);
    final clamped = duration < minDur
        ? minDur
        : (duration > maxDur ? maxDur : duration);
    final updated = clip.copyWith(
      transitionOutId: type.name,
      transitionOutDuration: clamped,
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Set Transition',
    ));
  }

  Future<void> clearTransition(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final updated = clip.copyWith(
      transitionOutId: null,
      transitionOutDuration: Duration.zero,
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Remove Transition',
    ));
  }

  // ── Effect operations (all undoable) ──────────────────────────────────────

  Future<EffectInstance?> addEffect(String clipId, EffectType type) async {
    final current = state.effectsForClip(clipId);
    if (current.length >= AppConstants.maxEffectsPerClip) return null;

    final effect = EffectInstance(
      id: 'effect_${_uuid.v4()}',
      clipId: clipId,
      type: type,
      stackIndex: current.length,
      parameters: EffectRegistry.defaultParameters(type),
    );
    await execute(AddEffectCommand(effect));
    return effect;
  }

  Future<void> removeEffect(EffectInstance effect) async {
    await execute(RemoveEffectCommand(effect));
  }

  Future<void> updateEffectParameters(
    EffectInstance effect,
    Map<String, double> parameters,
  ) async {
    final updated = effect.copyWith(parameters: parameters);
    await execute(UpdateEffectCommand(before: effect, after: updated));
  }

  Future<void> toggleEffect(EffectInstance effect) async {
    final updated = effect.copyWith(isEnabled: !effect.isEnabled);
    await execute(UpdateEffectCommand(before: effect, after: updated));
  }

  // ── Keyframe operations (all undoable) ────────────────────────────────────

  /// Sets a keyframe at the current playhead for [parameterId] on [clipId].
  /// If a keyframe already exists at that time it is updated; otherwise a new
  /// one is added.
  Future<void> setKeyframe(
    String clipId,
    String parameterId,
    double value, {
    KeyframeInterpolation interpolation = KeyframeInterpolation.linear,
  }) async {
    final time = state.playhead;
    final existing = state.keyframeAt(clipId, parameterId, time);
    if (existing != null) {
      final updated = existing.copyWith(value: value, interpolation: interpolation);
      await execute(UpdateKeyframeCommand(
        clipId: clipId,
        before: existing,
        after: updated,
        keyframeRepo: keyframeRepo,
      ));
    } else {
      final kf = KeyframeModel(
        id: 'kf_${_uuid.v4()}',
        parameterId: parameterId,
        time: time,
        value: value,
        interpolation: interpolation,
      );
      await execute(AddKeyframeCommand(
        clipId: clipId,
        keyframe: kf,
        keyframeRepo: keyframeRepo,
      ));
    }
  }

  /// Removes the keyframe at the current playhead for [parameterId] on
  /// [clipId], if one exists.
  Future<void> removeKeyframeAtPlayhead(
    String clipId,
    String parameterId,
  ) async {
    final existing = state.keyframeAt(clipId, parameterId, state.playhead);
    if (existing == null) return;
    await execute(RemoveKeyframeCommand(
      clipId: clipId,
      keyframe: existing,
      keyframeRepo: keyframeRepo,
    ));
  }

  /// Returns the evaluated (animated) value for a clip parameter at the
  /// current playhead. Falls back to [staticValue] when no keyframes exist.
  double evaluatedParameter(
    String clipId,
    String parameterId,
    double staticValue,
  ) =>
      state.evaluateParameter(
        clipId,
        parameterId,
        state.playhead,
        staticValue,
      );

  /// Creates a title-text clip on [trackId]. A synthetic media asset is
  /// created to satisfy the FK constraint (width=0 → hasVideo=false).
  Future<ClipModel> addTitleClip({
    required String projectId,
    required String trackId,
    String text = 'Title',
    Duration duration = const Duration(seconds: 5),
    Duration? startTime,
  }) async {
    final assetId = 'asset_${_uuid.v4()}';
    final now = DateTime.now();
    final asset = MediaAsset(
      id: assetId,
      projectId: projectId,
      filePath: '__synthetic__',
      name: 'Title',
      type: 'synthetic_title',
      duration: duration,
      width: 0,
      height: 0,
      frameRate: 0,
      sampleRate: 0,
      channels: 0,
      videoCodec: '',
      audioCodec: '',
      bitRate: 0,
      fileSize: 0,
      colorSpace: '',
      dateAdded: now,
    );
    await repository.saveMediaAsset(asset);

    final actualStart = startTime ?? _nextAvailableTime(trackId);
    final clip = ClipModel(
      id: 'clip_${_uuid.v4()}',
      trackId: trackId,
      mediaId: assetId,
      type: ClipType.title,
      startOnTimeline: actualStart,
      endOnTimeline: actualStart + duration,
      mediaInPoint: Duration.zero,
      mediaOutPoint: duration,
      name: text,
      titleText: text,
    );
    await execute(AddClipCommand(clip));
    return clip;
  }

  /// Creates a solid-color card clip on [trackId].
  Future<ClipModel> addColorCardClip({
    required String projectId,
    required String trackId,
    int color = AppConstants.defaultCardColor,
    Duration duration = const Duration(seconds: 5),
    Duration? startTime,
  }) async {
    final assetId = 'asset_${_uuid.v4()}';
    final now = DateTime.now();
    final asset = MediaAsset(
      id: assetId,
      projectId: projectId,
      filePath: '__synthetic__',
      name: 'Color Card',
      type: 'synthetic_colorcard',
      duration: duration,
      width: 0,
      height: 0,
      frameRate: 0,
      sampleRate: 0,
      channels: 0,
      videoCodec: '',
      audioCodec: '',
      bitRate: 0,
      fileSize: 0,
      colorSpace: '',
      dateAdded: now,
    );
    await repository.saveMediaAsset(asset);

    final actualStart = startTime ?? _nextAvailableTime(trackId);
    final clip = ClipModel(
      id: 'clip_${_uuid.v4()}',
      trackId: trackId,
      mediaId: assetId,
      type: ClipType.colorCard,
      startOnTimeline: actualStart,
      endOnTimeline: actualStart + duration,
      mediaInPoint: Duration.zero,
      mediaOutPoint: duration,
      name: 'Color Card',
      cardColorValue: color,
    );
    await execute(AddClipCommand(clip));
    return clip;
  }

  // ── Title / color-card mutations (all undoable) ───────────────────────────

  Future<void> updateTitleText(String clipId, String text) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(titleText: text, name: text),
      description: 'Edit Title Text',
    ));
  }

  Future<void> updateTitleFontSize(String clipId, double size) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(titleFontSize: size.clamp(8.0, 200.0)),
      description: 'Title Font Size',
    ));
  }

  Future<void> updateTitleColor(String clipId, int colorValue) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(titleColorValue: colorValue),
      description: 'Title Color',
    ));
  }

  Future<void> updateTitleAlignment(String clipId, String alignment) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(titleAlignment: alignment),
      description: 'Title Alignment',
    ));
  }

  Future<void> updateCardColor(String clipId, int colorValue) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(cardColorValue: colorValue),
      description: 'Card Color',
    ));
  }

  Future<void> updateFontFamily(String clipId, String fontFamily) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(fontFamily: fontFamily),
      description: 'Font Family',
    ));
  }

  Future<void> updateTextAnimation(
    String clipId,
    TextAnimationType animation,
  ) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(textAnimationType: animation),
      description: 'Text Animation',
    ));
  }

  Future<void> updateAnimationDuration(String clipId, int durationMs) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(
          textAnimationDurationMs: durationMs.clamp(100, 5000)),
      description: 'Animation Duration',
    ));
  }

  // ── Transform operations (all undoable) ────────────────────────────────

  Future<void> updateClipTransform(
    String clipId, {
    double? posX,
    double? posY,
    double? scaleX,
    double? scaleY,
    double? rotation,
    double? anchorX,
    double? anchorY,
  }) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final updated = clip.copyWith(
      posX: posX,
      posY: posY,
      scaleX: scaleX?.clamp(AppConstants.minScale, AppConstants.maxScale),
      scaleY: scaleY?.clamp(AppConstants.minScale, AppConstants.maxScale),
      rotation: rotation,
      anchorX: anchorX?.clamp(0.0, 1.0),
      anchorY: anchorY?.clamp(0.0, 1.0),
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Transform',
    ));
  }

  // ── Crop operations (all undoable) ─────────────────────────────────────

  Future<void> updateClipCrop(
    String clipId, {
    double? cropLeft,
    double? cropRight,
    double? cropTop,
    double? cropBottom,
  }) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final updated = clip.copyWith(
      cropLeft: cropLeft?.clamp(AppConstants.minCrop, AppConstants.maxCrop),
      cropRight: cropRight?.clamp(AppConstants.minCrop, AppConstants.maxCrop),
      cropTop: cropTop?.clamp(AppConstants.minCrop, AppConstants.maxCrop),
      cropBottom: cropBottom?.clamp(AppConstants.minCrop, AppConstants.maxCrop),
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: updated,
      description: 'Crop',
    ));
  }

  // ── Flip/Reverse/Freeze operations (all undoable) ─────────────────────

  Future<void> toggleFlipHorizontal(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(flipHorizontal: !clip.flipHorizontal),
      description: 'Flip Horizontal',
    ));
  }

  Future<void> toggleFlipVertical(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(flipVertical: !clip.flipVertical),
      description: 'Flip Vertical',
    ));
  }

  Future<void> toggleReverse(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(isReversed: !clip.isReversed),
      description: 'Reverse Clip',
    ));
  }

  Future<void> toggleFreezeFrame(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(isFrozen: !clip.isFrozen),
      description: 'Freeze Frame',
    ));
  }

  // ── Subject isolation operations (all undoable) ───────────────────────

  Future<void> toggleIsolation(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null || clip.type != ClipType.video) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(isolationEnabled: !clip.isolationEnabled),
      description: clip.isolationEnabled
          ? 'Disable Subject Isolation'
          : 'Enable Subject Isolation',
    ));
  }

  Future<void> updateIsolationMode(
    String clipId,
    IsolationMode mode,
  ) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(isolationMode: mode),
      description: 'Isolation Mode',
    ));
  }

  Future<void> updateIsolationColor(String clipId, int colorValue) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(isolationColorValue: colorValue),
      description: 'Isolation Color',
    ));
  }

  Future<void> updateIsolationBlurRadius(
    String clipId,
    double radius,
  ) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final clamped = radius.clamp(
      AppConstants.minIsolationBlurRadius,
      AppConstants.maxIsolationBlurRadius,
    );
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(isolationBlurRadius: clamped),
      description: 'Isolation Blur',
    ));
  }

  Future<void> setIsolationMaskPath(
    String clipId,
    String? maskPath,
  ) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final updated = clip.copyWith(
      isolationMaskPath: maskPath,
      isolationProcessing: false,
    );
    state.updateClip(updated);
    await repository.saveClip(updated);
  }

  void setIsolationProcessing(String clipId, bool processing) {
    final clip = _findClip(clipId);
    if (clip == null) return;
    state.updateClip(clip.copyWith(isolationProcessing: processing));
  }

  Future<void> setIsolationSelectionRect(
    String clipId,
    double left,
    double top,
    double right,
    double bottom,
  ) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(
        isolationSelectionLeft: left,
        isolationSelectionTop: top,
        isolationSelectionRight: right,
        isolationSelectionBottom: bottom,
      ),
      description: 'Set Isolation Selection',
    ));
  }

  Future<void> clearIsolationSelectionRect(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(
        isolationSelectionLeft: null,
        isolationSelectionTop: null,
        isolationSelectionRight: null,
        isolationSelectionBottom: null,
        isolationMaskPath: null,
      ),
      description: 'Clear Isolation Selection',
    ));
  }

  // ── Volume operations (all undoable) ──────────────────────────────────

  Future<void> updateClipVolume(String clipId, double volume) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final clamped = volume.clamp(AppConstants.minVolume, AppConstants.maxVolume);
    await execute(UpdateClipCommand(
      before: clip,
      after: clip.copyWith(volume: clamped),
      description: 'Set Volume',
    ));
  }

  // ── Marker operations ────────────────────────────────────────────────

  Future<MarkerModel> addMarker({
    required String projectId,
    String name = '',
    MarkerColor color = MarkerColor.blue,
    Duration? time,
  }) async {
    final marker = MarkerModel(
      id: 'marker_${_uuid.v4()}',
      projectId: projectId,
      time: time ?? state.playhead,
      name: name,
      color: color,
    );
    state.addMarker(marker);
    await repository.saveMarker(marker);
    return marker;
  }

  Future<void> removeMarker(String markerId) async {
    state.removeMarker(markerId);
    await repository.deleteMarker(markerId);
  }

  Future<void> updateMarker(MarkerModel marker) async {
    state.updateMarker(marker);
    await repository.saveMarker(marker);
  }

  /// Seeks playhead to the next marker after current position.
  void seekToNextMarker() {
    final markers = state.markers;
    if (markers.isEmpty) return;
    for (final m in markers) {
      if (m.time > state.playhead) {
        state.setPlayhead(m.time);
        return;
      }
    }
  }

  /// Seeks playhead to the previous marker before current position.
  void seekToPreviousMarker() {
    final markers = state.markers;
    if (markers.isEmpty) return;
    for (var i = markers.length - 1; i >= 0; i--) {
      if (markers[i].time < state.playhead) {
        state.setPlayhead(markers[i].time);
        return;
      }
    }
  }

  // ── Frame navigation ─────────────────────────────────────────────────

  /// Steps the playhead by [frames] frames. Positive = forward, negative = back.
  void stepFrames(int frames, {double frameRate = AppConstants.defaultFrameRate}) {
    final frameDurationUs = (1000000.0 / frameRate).round();
    final newTime = state.playhead + Duration(microseconds: frameDurationUs * frames);
    state.setPlayhead(newTime);
  }

  /// Moves playhead to the start of the timeline.
  void goToStart() => state.setPlayhead(Duration.zero);

  /// Moves playhead to the end of the timeline.
  void goToEnd() => state.setPlayhead(state.duration);

  /// Seeks playhead to the next clip boundary (start or end).
  void seekToNextEdit() {
    final playhead = state.playhead;
    Duration? nearest;
    for (final clip in state.clips) {
      for (final edge in [clip.startOnTimeline, clip.endOnTimeline]) {
        if (edge > playhead) {
          if (nearest == null || edge < nearest) nearest = edge;
        }
      }
    }
    if (nearest != null) state.setPlayhead(nearest);
  }

  /// Seeks playhead to the previous clip boundary.
  void seekToPreviousEdit() {
    final playhead = state.playhead;
    Duration? nearest;
    for (final clip in state.clips) {
      for (final edge in [clip.startOnTimeline, clip.endOnTimeline]) {
        if (edge < playhead) {
          if (nearest == null || edge > nearest) nearest = edge;
        }
      }
    }
    if (nearest != null) state.setPlayhead(nearest);
  }

  // ── Track controls ───────────────────────────────────────────────────

  Future<void> toggleTrackVisibility(String trackId) async {
    final track = state.tracks.firstWhere((t) => t.id == trackId);
    final updated = track.copyWith(isVisible: !track.isVisible);
    state.updateTrack(updated);
    await repository.saveTrack(updated);
  }

  Future<void> updateTrackHeight(String trackId, double height) async {
    final track = state.tracks.firstWhere((t) => t.id == trackId);
    final clamped = height.clamp(
      AppConstants.minTrackHeight,
      AppConstants.maxTrackHeight,
    );
    final updated = track.copyWith(height: clamped);
    state.updateTrack(updated);
    await repository.saveTrack(updated);
  }

  Future<void> updateTrackVolume(String trackId, double volume) async {
    final track = state.tracks.firstWhere((t) => t.id == trackId);
    final updated = track.copyWith(
      volume: volume.clamp(AppConstants.minVolume, AppConstants.maxVolume),
    );
    state.updateTrack(updated);
    await repository.saveTrack(updated);
  }

  Future<void> updateTrackPan(String trackId, double pan) async {
    final track = state.tracks.firstWhere((t) => t.id == trackId);
    final updated = track.copyWith(pan: pan.clamp(-1.0, 1.0));
    state.updateTrack(updated);
    await repository.saveTrack(updated);
  }

  Future<void> duplicateClip(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final duplicate = clip.copyWith(
      id: 'clip_${_uuid.v4()}',
      startOnTimeline: clip.endOnTimeline,
      endOnTimeline: clip.endOnTimeline + clip.duration,
    );
    await execute(AddClipCommand(duplicate));
  }

  // ── Media import ───────────────────────────────────────────────────────────

  Future<MediaAsset> importMediaFile({
    required String projectId,
    required String filePath,
  }) async {
    final probeResult = await ffmpegEngine.probe(filePath);
    final assetId = 'asset_${_uuid.v4()}';

    final thumbPath = await thumbnailGenerator.generateThumbnail(
      sourceFilePath: filePath,
      assetId: assetId,
      timestamp: const Duration(seconds: 1),
    );

    final asset = probeResult.toMediaAsset(
      id: assetId,
      projectId: projectId,
      filePath: filePath,
      thumbnailPath: thumbPath,
    );

    await repository.saveMediaAsset(asset);

    // Kick off waveform generation in background for audio-bearing assets
    if (asset.hasAudio) {
      unawaited(waveformGenerator.generateWaveform(
        sourceFilePath: filePath,
        assetId: assetId,
      ));
    }

    return asset;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _isImagePath(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return MediaConstants.imageExtensions.contains(ext);
  }

  Duration _nextAvailableTime(String trackId) {
    final clips = state.clipsForTrack(trackId);
    if (clips.isEmpty) return Duration.zero;
    return clips.map((c) => c.endOnTimeline).reduce((a, b) => a > b ? a : b);
  }

  ClipModel? _findClip(String clipId) {
    try {
      return state.clips.firstWhere((c) => c.id == clipId);
    } catch (_) {
      return null;
    }
  }

  void ensureDefaultTracks(String projectId) {
    if (state.videoTracks.isEmpty) {
      final v1 = TrackModel(
        id: 'track_v1_$projectId',
        projectId: projectId,
        type: TrackType.video,
        index: 0,
        name: 'V1',
      );
      state.addTrack(v1);
      repository.saveTrack(v1);
    }
    if (state.audioTracks.isEmpty) {
      final a1 = TrackModel(
        id: 'track_a1_$projectId',
        projectId: projectId,
        type: TrackType.audio,
        index: 0,
        name: 'A1',
      );
      state.addTrack(a1);
      repository.saveTrack(a1);
    }
  }
}
