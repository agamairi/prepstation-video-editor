import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/core/audio/waveform_generator.dart';
import 'package:fluxedit/core/ffmpeg/ffmpeg_engine.dart';
import 'package:fluxedit/core/ffmpeg/thumbnail_generator.dart';
import 'package:fluxedit/core/history/clip_commands.dart';
import 'package:fluxedit/core/history/edit_command.dart';
import 'package:fluxedit/core/history/history_manager.dart';
import 'package:fluxedit/core/project/project_model.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/core/timeline/track_model.dart';
import 'package:uuid/uuid.dart';

final timelineStateProvider = ChangeNotifierProvider.autoDispose<TimelineState>(
  (ref) => TimelineState(),
);

final timelineControllerProvider =
    Provider.autoDispose<TimelineController>((ref) {
  return TimelineController(
    state: ref.watch(timelineStateProvider.notifier),
    repository: ref.watch(projectRepositoryProvider),
    ffmpegEngine: ref.watch(ffmpegEngineProvider),
    thumbnailGenerator: ref.watch(thumbnailGeneratorProvider),
    waveformGenerator: ref.watch(waveformGeneratorProvider),
    history: ref.watch(historyManagerProvider.notifier),
  );
});

class TimelineController {
  TimelineController({
    required this.state,
    required this.repository,
    required this.ffmpegEngine,
    required this.thumbnailGenerator,
    required this.waveformGenerator,
    required this.history,
  });

  final TimelineState state;
  final ProjectRepository repository;
  final FfmpegEngine ffmpegEngine;
  final ThumbnailGenerator thumbnailGenerator;
  final WaveformGenerator waveformGenerator;
  final HistoryManager history;

  static const _uuid = Uuid();

  Future<void> loadProject(String projectId) async {
    final tracks = await repository.getTracks(projectId);
    final clips = await repository.getClipsForProject(projectId);
    state.setTracks(tracks);
    state.setClips(clips);
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
    final clipDuration = asset.duration;
    if (clipDuration == Duration.zero) return null;

    final clip = ClipModel(
      id: 'clip_${_uuid.v4()}',
      trackId: trackId,
      mediaId: asset.id,
      type: asset.hasVideo ? ClipType.video : ClipType.audio,
      startOnTimeline: actualStart,
      endOnTimeline: actualStart + clipDuration,
      mediaInPoint: Duration.zero,
      mediaOutPoint: clipDuration,
    );
    await execute(AddClipCommand(clip));
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
