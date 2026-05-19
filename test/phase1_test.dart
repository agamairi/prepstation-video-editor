import 'package:flutter_test/flutter_test.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/ffmpeg/codec_registry.dart';
import 'package:prepstation/core/ffmpeg/filtergraph_builder.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/composition_model.dart';
import 'package:prepstation/core/timeline/keyframe_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';
import 'package:prepstation/core/timeline/track_model.dart';

void main() {
  // ── Project Model ──────────────────────────────────────────────────────────

  group('ProjectModel', () {
    test('create() factory sets sensible defaults', () {
      final project = ProjectModel.create(
        name: 'Test Project',
        filePath: '/tmp/test.prepstation',
      );

      expect(project.name, 'Test Project');
      expect(project.filePath, '/tmp/test.prepstation');
      expect(project.id, startsWith('proj_'));
      expect(project.version, '0.1.0');
      expect(project.composition.width, AppConstants.defaultWidth);
      expect(project.composition.height, AppConstants.defaultHeight);
      expect(project.composition.frameRate, AppConstants.defaultFrameRate);
    });

    test('copyWith preserves unchanged fields', () {
      final original = ProjectModel.create(
        name: 'Original',
        filePath: '/tmp/original.prepstation',
      );
      final copy = original.copyWith(name: 'Renamed');

      expect(copy.id, original.id);
      expect(copy.name, 'Renamed');
      expect(copy.filePath, original.filePath);
      expect(copy.composition, original.composition);
    });

    test('equality is id-based', () {
      final p1 = ProjectModel.create(name: 'A', filePath: '/a');
      final p2 = p1.copyWith(name: 'B');
      // Same id → equal even though name differs
      expect(p1, equals(p2));
      // Explicit different-id project is not equal
      final p3 = p1.copyWith(id: '${p1.id}_other');
      expect(p1, isNot(equals(p3)));
    });
  });

  // ── CompositionModel ────────────────────────────────────────────────────────

  group('CompositionModel', () {
    const comp = CompositionModel(
      id: 'comp_1',
      name: 'Main',
      width: 1920,
      height: 1080,
      frameRate: 30.0,
      duration: Duration(seconds: 10),
    );

    test('frameDuration is correct for 30 fps', () {
      // 1s / 30 = 33333 µs
      expect(comp.frameDuration.inMicroseconds, closeTo(33333, 1));
    });

    test('totalFrames is correct', () {
      // At 30fps, frameDuration rounds to 33333µs (not exact 33333.3̄).
      // 10s / 33333µs = 300.003, which ceiling() gives 301.
      expect(comp.totalFrames, 301);
    });

    test('frameToTime round-trips with timeToFrame', () {
      for (final frame in [0, 1, 15, 29, 150, 299]) {
        final time = comp.frameToTime(frame);
        final back = comp.timeToFrame(time);
        expect(back, frame, reason: 'frame=$frame');
      }
    });

    test('frameRateDisplay returns clean strings', () {
      const pairs = [
        [23.976, '23.976'],
        [24.0, '24'],
        [25.0, '25'],
        [29.97, '29.97'],
        [30.0, '30'],
        [60.0, '60'],
      ];
      for (final pair in pairs) {
        final c = CompositionModel(
          id: 'c',
          name: 'c',
          frameRate: pair[0] as double,
        );
        expect(c.frameRateDisplay, pair[1], reason: 'fps=${pair[0]}');
      }
    });
  });

  // ── MediaAsset ─────────────────────────────────────────────────────────────

  group('MediaAsset', () {
    final asset = MediaAsset(
      id: 'asset_1',
      projectId: 'proj_1',
      filePath: '/videos/test.mp4',
      name: 'test.mp4',
      type: 'video',
      duration: const Duration(minutes: 2, seconds: 30),
      width: 1920,
      height: 1080,
      frameRate: 29.97,
      sampleRate: 48000,
      channels: 2,
      videoCodec: 'h264',
      audioCodec: 'aac',
      bitRate: 8000,
      fileSize: 150000000,
      colorSpace: 'bt709',
      dateAdded: DateTime(2026, 1, 1),
    );

    test('hasVideo is true when dimensions are set', () {
      expect(asset.hasVideo, isTrue);
    });

    test('hasAudio is true when channels > 0', () {
      expect(asset.hasAudio, isTrue);
    });

    test('resolution getter formats correctly', () {
      expect(asset.resolution, '1920x1080');
    });

    test('frameRateDisplay for 29.97', () {
      expect(asset.frameRateDisplay, '29.97');
    });

    test('copyWith changes only specified fields', () {
      final copy = asset.copyWith(name: 'renamed.mp4');
      expect(copy.id, asset.id);
      expect(copy.name, 'renamed.mp4');
      expect(copy.duration, asset.duration);
    });

    test('audio-only asset hasVideo is false', () {
      final audio = asset.copyWith(width: 0, height: 0);
      expect(audio.hasVideo, isFalse);
      expect(audio.hasAudio, isTrue);
    });
  });

  // ── TrackModel ─────────────────────────────────────────────────────────────

  group('TrackModel', () {
    const videoTrack = TrackModel(
      id: 'track_v1',
      projectId: 'proj_1',
      type: TrackType.video,
      index: 0,
    );

    const audioTrack = TrackModel(
      id: 'track_a1',
      projectId: 'proj_1',
      type: TrackType.audio,
      index: 0,
    );

    test('isVideo is true for video tracks', () {
      expect(videoTrack.isVideo, isTrue);
      expect(videoTrack.isAudio, isFalse);
    });

    test('isAudio is true for audio tracks', () {
      expect(audioTrack.isAudio, isTrue);
      expect(audioTrack.isVideo, isFalse);
    });

    test('displayName uses type prefix when name is empty', () {
      expect(videoTrack.displayName, 'V1');
      expect(audioTrack.displayName, 'A1');
    });

    test('displayName returns custom name when set', () {
      final named = videoTrack.copyWith(name: 'Talking Head');
      expect(named.displayName, 'Talking Head');
    });

    test('copyWith toggles mute independently', () {
      final muted = videoTrack.copyWith(isMuted: true);
      expect(muted.isMuted, isTrue);
      expect(muted.isLocked, isFalse);
    });

    test('equality is id-based', () {
      final copy = videoTrack.copyWith(isMuted: true);
      expect(videoTrack, equals(copy));
    });
  });

  // ── ClipModel ──────────────────────────────────────────────────────────────

  group('ClipModel', () {
    const clip = ClipModel(
      id: 'clip_1',
      trackId: 'track_v1',
      mediaId: 'asset_1',
      type: ClipType.video,
      startOnTimeline: Duration(seconds: 5),
      endOnTimeline: Duration(seconds: 15),
      mediaInPoint: Duration.zero,
      mediaOutPoint: Duration(seconds: 10),
    );

    test('duration is end minus start', () {
      expect(clip.duration, const Duration(seconds: 10));
    });

    test('mediaDuration is outPoint minus inPoint', () {
      expect(clip.mediaDuration, const Duration(seconds: 10));
    });

    test('copyWith updates position correctly', () {
      final moved = clip.copyWith(
        startOnTimeline: const Duration(seconds: 10),
        endOnTimeline: const Duration(seconds: 20),
      );
      expect(moved.duration, const Duration(seconds: 10));
      expect(moved.startOnTimeline, const Duration(seconds: 10));
    });

    test('copyWith can change id (split operation)', () {
      final right = clip.copyWith(
        id: 'clip_2',
        startOnTimeline: const Duration(seconds: 10),
        mediaInPoint: const Duration(seconds: 5),
      );
      expect(right.id, 'clip_2');
      expect(right.trackId, clip.trackId);
    });

    test('equality is id-based', () {
      final copy = clip.copyWith(opacity: 0.5);
      expect(clip, equals(copy)); // same id
    });

    test('speed defaults to 1.0', () {
      expect(clip.speed, 1.0);
    });

    test('opacity defaults to 1.0', () {
      expect(clip.opacity, 1.0);
    });
  });

  // ── TimelineState ──────────────────────────────────────────────────────────

  group('TimelineState', () {
    late TimelineState state;

    setUp(() {
      state = TimelineState();
    });

    tearDown(() {
      state.dispose();
    });

    const track = TrackModel(
      id: 'track_v1',
      projectId: 'proj_1',
      type: TrackType.video,
      index: 0,
    );

    const clip1 = ClipModel(
      id: 'clip_1',
      trackId: 'track_v1',
      mediaId: 'asset_1',
      type: ClipType.video,
      startOnTimeline: Duration(seconds: 0),
      endOnTimeline: Duration(seconds: 5),
      mediaInPoint: Duration.zero,
      mediaOutPoint: Duration(seconds: 5),
    );

    const clip2 = ClipModel(
      id: 'clip_2',
      trackId: 'track_v1',
      mediaId: 'asset_2',
      type: ClipType.video,
      startOnTimeline: Duration(seconds: 5),
      endOnTimeline: Duration(seconds: 12),
      mediaInPoint: Duration.zero,
      mediaOutPoint: Duration(seconds: 7),
    );

    test('initial state is empty', () {
      expect(state.tracks, isEmpty);
      expect(state.clips, isEmpty);
      expect(state.duration, Duration.zero);
      expect(state.isPlaying, isFalse);
    });

    test('addTrack appends track and notifies', () {
      var notified = false;
      state.addListener(() => notified = true);
      state.addTrack(track);
      expect(state.tracks.length, 1);
      expect(state.tracks.first.id, 'track_v1');
      expect(notified, isTrue);
    });

    test('addClip appends clip and recalculates duration', () {
      state.addClip(clip1);
      expect(state.clips.length, 1);
      expect(state.duration, const Duration(seconds: 5));
    });

    test('duration is max endOnTimeline across all clips', () {
      state.addClip(clip1);
      state.addClip(clip2);
      expect(state.duration, const Duration(seconds: 12));
    });

    test('removeClip removes by id and recalculates duration', () {
      state.addClip(clip1);
      state.addClip(clip2);
      state.removeClip('clip_2');
      expect(state.clips.length, 1);
      expect(state.duration, const Duration(seconds: 5));
    });

    test('updateClip replaces clip in-place', () {
      state.addClip(clip1);
      final updated = clip1.copyWith(
        endOnTimeline: const Duration(seconds: 8),
        mediaOutPoint: const Duration(seconds: 8),
      );
      state.updateClip(updated);
      expect(state.clips.first.duration, const Duration(seconds: 8));
    });

    test('selectClip sets selected ids', () {
      state.selectClip('clip_1');
      expect(state.selectedClipIds, contains('clip_1'));
    });

    test('selectClip with addToSelection accumulates', () {
      state.selectClip('clip_1');
      state.selectClip('clip_2', addToSelection: true);
      expect(state.selectedClipIds.length, 2);
    });

    test('clearSelection empties selection set', () {
      state.selectClip('clip_1');
      state.clearSelection();
      expect(state.selectedClipIds, isEmpty);
    });

    test('setPlayhead clamps to timeline duration', () {
      state.addClip(clip1); // duration = 5s
      state.setPlayhead(const Duration(seconds: 10));
      expect(state.playhead, const Duration(seconds: 5));
    });

    test('setPlayhead below zero clamps to zero', () {
      state.setPlayhead(const Duration(seconds: -1));
      expect(state.playhead, Duration.zero);
    });

    test('setZoom clamps to allowed range', () {
      state.setZoom(AppConstants.maxTimelineZoom * 2);
      expect(state.zoom, AppConstants.maxTimelineZoom);
      state.setZoom(0);
      expect(state.zoom, AppConstants.minTimelineZoom);
    });

    test('timeToPixel / pixelToTime round-trip', () {
      state.setZoom(100); // 100 px/s
      const time = Duration(seconds: 3);
      final px = state.timeToPixel(time);
      expect(px, closeTo(300.0, 0.001));
      final back = state.pixelToTime(px);
      expect(back.inMicroseconds, closeTo(time.inMicroseconds, 1000));
    });

    test('clipsForTrack returns clips sorted by start time', () {
      state.addClip(clip2);
      state.addClip(clip1);
      final sorted = state.clipsForTrack('track_v1');
      expect(sorted.first.id, 'clip_1');
      expect(sorted.last.id, 'clip_2');
    });

    test('clipAt returns clip at given time', () {
      state.addClip(clip1);
      final found = state.clipAt('track_v1', const Duration(seconds: 2));
      expect(found?.id, 'clip_1');
    });

    test('clipAt returns null when no clip at time', () {
      state.addClip(clip1);
      final notFound = state.clipAt('track_v1', const Duration(seconds: 6));
      expect(notFound, isNull);
    });

    test('removeTrack removes track and its clips', () {
      state.addTrack(track);
      state.addClip(clip1);
      state.removeTrack('track_v1');
      expect(state.tracks, isEmpty);
      expect(state.clips, isEmpty);
    });

    test('snapEnabled defaults to true', () {
      expect(state.snapEnabled, isTrue);
    });

    test('snapToNearestPoint returns null when snap disabled', () {
      state.setSnapEnabled(false);
      state.addClip(clip1);
      final result = state.snapToNearestPoint(
        const Duration(seconds: 5),
        null,
      );
      expect(result, isNull);
    });

    test('inPoint and outPoint can be set independently', () {
      state.setInPoint(const Duration(seconds: 2));
      state.setOutPoint(const Duration(seconds: 8));
      expect(state.inPoint, const Duration(seconds: 2));
      expect(state.outPoint, const Duration(seconds: 8));
    });
  });

  // ── FiltergraphBuilder ─────────────────────────────────────────────────────

  group('FiltergraphBuilder', () {
    const builder = FiltergraphBuilder();

    const clips = [
      ClipModel(
        id: 'clip_1',
        trackId: 't1',
        mediaId: 'a1',
        type: ClipType.video,
        startOnTimeline: Duration.zero,
        endOnTimeline: Duration(seconds: 5),
        mediaInPoint: Duration.zero,
        mediaOutPoint: Duration(seconds: 5),
      ),
      ClipModel(
        id: 'clip_2',
        trackId: 't1',
        mediaId: 'a2',
        type: ClipType.video,
        startOnTimeline: Duration(seconds: 5),
        endOnTimeline: Duration(seconds: 10),
        mediaInPoint: Duration.zero,
        mediaOutPoint: Duration(seconds: 5),
      ),
    ];

    test('buildConcatGraph returns empty string for no clips', () {
      expect(builder.buildConcatGraph([]), '');
    });

    test('buildConcatGraph includes all input references', () {
      final graph = builder.buildConcatGraph(clips);
      expect(graph, contains('[0:v][0:a]'));
      expect(graph, contains('[1:v][1:a]'));
      expect(graph, contains('concat=n=2:v=1:a=1'));
    });

    test('validate returns false for empty string', () {
      expect(builder.validate(''), isFalse);
    });

    test('validate returns true for balanced brackets', () {
      final graph = builder.buildConcatGraph(clips);
      expect(builder.validate(graph), isTrue);
    });

    test('buildInputArgs emits -ss -t -i per clip', () {
      final args = builder.buildInputArgs(clips, ['/a.mp4', '/b.mp4']);
      expect(args, contains('-ss 0.0'));
      expect(args, contains('-t 5.0'));
      expect(args, contains('"/a.mp4"'));
      expect(args, contains('"/b.mp4"'));
    });
  });

  // ── CodecRegistry ──────────────────────────────────────────────────────────

  group('CodecRegistry', () {
    test('presets list has exactly 6 items', () {
      expect(CodecRegistry.presets.length, 6);
    });

    test('preset ids are unique', () {
      final ids = CodecRegistry.presets.map((p) => p.id).toSet();
      expect(ids.length, CodecRegistry.presets.length);
    });

    test('buildVideoCodecArgs contains codec name for h264', () {
      final preset = CodecRegistry.presets
          .firstWhere((p) => p.id == 'youtube_1080p');
      expect(CodecRegistry.buildVideoCodecArgs(preset), contains('libx264'));
    });

    test('buildVideoCodecArgs contains codec name for h265', () {
      final preset = CodecRegistry.presets
          .firstWhere((p) => p.id == 'h265_1080p');
      expect(CodecRegistry.buildVideoCodecArgs(preset), contains('libx265'));
    });

    test('buildAudioCodecArgs for aac includes bitrate', () {
      final preset = CodecRegistry.presets
          .firstWhere((p) => p.id == 'youtube_1080p');
      final args = CodecRegistry.buildAudioCodecArgs(preset);
      expect(args, contains('aac'));
      expect(args, contains('192k'));
    });

    test('containerExtension is correct for each format', () {
      final byContainer = {
        for (final p in CodecRegistry.presets) p.container: p,
      };
      if (byContainer.containsKey(ContainerFormat.mp4)) {
        expect(
          byContainer[ContainerFormat.mp4]!.containerExtension,
          'mp4',
        );
      }
      if (byContainer.containsKey(ContainerFormat.webm)) {
        expect(
          byContainer[ContainerFormat.webm]!.containerExtension,
          'webm',
        );
      }
    });
  });

  // ── KeyframeModel / ParameterCurve ─────────────────────────────────────────

  group('ParameterCurve', () {
    test('linear interpolation between two keyframes', () {
      const kf1 = KeyframeModel(
        id: 'kf1',
        parameterId: 'opacity',
        time: Duration.zero,
        value: 0.0,
        interpolation: KeyframeInterpolation.linear,
      );
      const kf2 = KeyframeModel(
        id: 'kf2',
        parameterId: 'opacity',
        time: Duration(seconds: 2),
        value: 1.0,
        interpolation: KeyframeInterpolation.linear,
      );

      const curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [kf1, kf2],
        defaultValue: 0.0,
      );
      expect(curve.evaluate(const Duration(seconds: 1)), closeTo(0.5, 0.001));
    });

    test('hold interpolation stays at start value', () {
      const kf1 = KeyframeModel(
        id: 'kf1',
        parameterId: 'opacity',
        time: Duration.zero,
        value: 0.0,
        interpolation: KeyframeInterpolation.hold,
      );
      const kf2 = KeyframeModel(
        id: 'kf2',
        parameterId: 'opacity',
        time: Duration(seconds: 2),
        value: 1.0,
        interpolation: KeyframeInterpolation.hold,
      );

      const curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [kf1, kf2],
        defaultValue: 0.0,
      );
      expect(curve.evaluate(const Duration(seconds: 1)), closeTo(0.0, 0.001));
    });

    test('evaluate clamps before first keyframe to first value', () {
      const kf = KeyframeModel(
        id: 'kf1',
        parameterId: 'opacity',
        time: Duration(seconds: 5),
        value: 0.75,
        interpolation: KeyframeInterpolation.linear,
      );
      const curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [kf],
        defaultValue: 0.0,
      );
      expect(curve.evaluate(Duration.zero), closeTo(0.75, 0.001));
    });

    test('evaluate clamps after last keyframe to last value', () {
      const kf = KeyframeModel(
        id: 'kf1',
        parameterId: 'opacity',
        time: Duration(seconds: 2),
        value: 0.3,
        interpolation: KeyframeInterpolation.linear,
      );
      const curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [kf],
        defaultValue: 0.0,
      );
      expect(
        curve.evaluate(const Duration(seconds: 10)),
        closeTo(0.3, 0.001),
      );
    });

    test('empty curve returns defaultValue', () {
      const curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [],
        defaultValue: 0.0,
      );
      expect(curve.evaluate(const Duration(seconds: 5)), 0.0);
    });
  });

  // ── AppConstants ───────────────────────────────────────────────────────────

  group('AppConstants', () {
    test('zoom range is valid', () {
      expect(AppConstants.minTimelineZoom, lessThan(AppConstants.defaultTimelineZoom));
      expect(AppConstants.defaultTimelineZoom, lessThan(AppConstants.maxTimelineZoom));
    });

    test('default composition is 1920x1080 at 30fps', () {
      expect(AppConstants.defaultWidth, 1920);
      expect(AppConstants.defaultHeight, 1080);
      expect(AppConstants.defaultFrameRate, 30.0);
    });

    test('snap threshold is positive', () {
      expect(AppConstants.snapThreshold, greaterThan(0));
    });
  });
}
