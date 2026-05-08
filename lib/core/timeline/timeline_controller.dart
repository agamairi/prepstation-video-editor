import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/core/ffmpeg/ffmpeg_engine.dart';
import 'package:fluxedit/core/ffmpeg/thumbnail_generator.dart';
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
  );
});

class TimelineController {
  TimelineController({
    required this.state,
    required this.repository,
    required this.ffmpegEngine,
    required this.thumbnailGenerator,
  });

  final TimelineState state;
  final ProjectRepository repository;
  final FfmpegEngine ffmpegEngine;
  final ThumbnailGenerator thumbnailGenerator;

  static const _uuid = Uuid();

  Future<void> loadProject(String projectId) async {
    final tracks = await repository.getTracks(projectId);
    final clips = await repository.getClipsForProject(projectId);
    state.setTracks(tracks);
    state.setClips(clips);
  }

  /// Adds a new track to the project.
  Future<TrackModel> addTrack({
    required String projectId,
    required TrackType type,
    String name = '',
  }) async {
    final videoTracks = state.videoTracks;
    final audioTracks = state.audioTracks;
    final index = type.name == 'audio'
        ? audioTracks.length
        : videoTracks.length;

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

  /// Removes a track and all its clips.
  Future<void> removeTrack(String trackId) async {
    final clips = state.clipsForTrack(trackId);
    for (final clip in clips) {
      await repository.deleteClip(clip.id);
    }
    state.removeTrack(trackId);
    await repository.deleteTrack(trackId);
  }

  /// Adds a media asset as a clip on [trackId] at [startTime].
  /// Probes the file if [asset] is not yet probed.
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
    state.addClip(clip);
    await repository.saveClip(clip);
    return clip;
  }

  /// Removes a clip.
  Future<void> removeClip(String clipId) async {
    state.removeClip(clipId);
    await repository.deleteClip(clipId);
  }

  /// Moves a clip to a new start position.
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
    state.updateClip(updated);
    await repository.saveClip(updated);
  }

  /// Trims the in-point of a clip (drag left edge).
  Future<void> trimClipStart(String clipId, Duration newStart) async {
    final clip = _findClip(clipId);
    if (clip == null) return;

    if (newStart >= clip.endOnTimeline) return;
    final delta = newStart - clip.startOnTimeline;
    final newMediaIn = clip.mediaInPoint + delta;
    if (newMediaIn < Duration.zero || newMediaIn >= clip.mediaOutPoint) {
      return;
    }

    final updated = clip.copyWith(
      startOnTimeline: newStart,
      mediaInPoint: newMediaIn,
    );
    state.updateClip(updated);
    await repository.saveClip(updated);
  }

  /// Trims the out-point of a clip (drag right edge).
  Future<void> trimClipEnd(String clipId, Duration newEnd) async {
    final clip = _findClip(clipId);
    if (clip == null) return;

    if (newEnd <= clip.startOnTimeline) return;
    final delta = newEnd - clip.endOnTimeline;
    final newMediaOut = clip.mediaOutPoint + delta;
    if (newMediaOut <= clip.mediaInPoint) return;

    final minMediaOut = clip.mediaInPoint + const Duration(milliseconds: 33);
    final clampedMediaOut = newMediaOut < minMediaOut ? minMediaOut : newMediaOut;

    final updated = clip.copyWith(
      endOnTimeline: newEnd,
      mediaOutPoint: clampedMediaOut,
    );
    state.updateClip(updated);
    await repository.saveClip(updated);
  }

  /// Splits a clip at [time], producing two clips.
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

    state.removeClip(clipId);
    state.addClip(left);
    state.addClip(right);

    await repository.deleteClip(clipId);
    await repository.saveClip(left);
    await repository.saveClip(right);

    return [left, right];
  }

  /// Imports a media file, probes it, saves it, generates thumbnail.
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
    return asset;
  }

  Duration _nextAvailableTime(String trackId) {
    final clips = state.clipsForTrack(trackId);
    if (clips.isEmpty) return Duration.zero;
    return clips.map((c) => c.endOnTimeline).reduce(
      (a, b) => a > b ? a : b,
    );
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
