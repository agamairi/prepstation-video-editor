import 'package:flutter_test/flutter_test.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/constants/media_constants.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';
import 'package:prepstation/core/timeline/track_model.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

ClipModel _makeClip({
  String id = 'clip_1',
  String trackId = 'track_v1',
  ClipType type = ClipType.video,
  Duration start = Duration.zero,
  Duration end = const Duration(seconds: 5),
}) =>
    ClipModel(
      id: id,
      trackId: trackId,
      mediaId: 'asset_1',
      type: type,
      startOnTimeline: start,
      endOnTimeline: end,
      mediaInPoint: Duration.zero,
      mediaOutPoint: end - start,
    );

ClipModel _makeImageClip({
  String id = 'img_1',
  String trackId = 'track_v1',
  Duration start = Duration.zero,
  Duration end = const Duration(seconds: 5),
}) =>
    ClipModel(
      id: id,
      trackId: trackId,
      mediaId: 'img_asset_1',
      type: ClipType.image,
      startOnTimeline: start,
      endOnTimeline: end,
      mediaInPoint: Duration.zero,
      mediaOutPoint: end - start,
    );

ClipModel _makeTitleClip({
  String id = 'title_1',
  String trackId = 'track_v1',
  Duration start = Duration.zero,
  Duration end = const Duration(seconds: 5),
  String titleText = 'Hello',
}) =>
    ClipModel(
      id: id,
      trackId: trackId,
      mediaId: 'title_asset',
      type: ClipType.title,
      startOnTimeline: start,
      endOnTimeline: end,
      mediaInPoint: Duration.zero,
      mediaOutPoint: end - start,
      titleText: titleText,
    );

// ── TextAnimationType ──────────────────────────────────────────────────────

void main() {
  group('TextAnimationType enum', () {
    test('has exactly 8 values', () {
      expect(TextAnimationType.values.length, 8);
    });

    test('all values have non-empty displayName', () {
      for (final t in TextAnimationType.values) {
        expect(t.displayName, isNotEmpty, reason: '${t.name} has empty displayName');
      }
    });

    test('displayName for none is None', () {
      expect(TextAnimationType.none.displayName, 'None');
    });

    test('displayName for fadeIn is Fade In', () {
      expect(TextAnimationType.fadeIn.displayName, 'Fade In');
    });

    test('displayName for slideUp is Slide Up', () {
      expect(TextAnimationType.slideUp.displayName, 'Slide Up');
    });

    test('displayName for slideDown is Slide Down', () {
      expect(TextAnimationType.slideDown.displayName, 'Slide Down');
    });

    test('displayName for slideLeft is Slide Left', () {
      expect(TextAnimationType.slideLeft.displayName, 'Slide Left');
    });

    test('displayName for slideRight is Slide Right', () {
      expect(TextAnimationType.slideRight.displayName, 'Slide Right');
    });

    test('displayName for zoomIn is Zoom In', () {
      expect(TextAnimationType.zoomIn.displayName, 'Zoom In');
    });

    test('displayName for typewriter is Typewriter', () {
      expect(TextAnimationType.typewriter.displayName, 'Typewriter');
    });

    test('all displayNames are distinct', () {
      final names = TextAnimationType.values.map((t) => t.displayName).toList();
      expect(names.toSet().length, names.length);
    });

    test('fromId roundtrip for every value', () {
      for (final t in TextAnimationType.values) {
        expect(TextAnimationType.fromId(t.name), t);
      }
    });

    test('fromId with unknown id returns none', () {
      expect(TextAnimationType.fromId('bogus'), TextAnimationType.none);
    });

    test('fromId with empty string returns none', () {
      expect(TextAnimationType.fromId(''), TextAnimationType.none);
    });
  });

  // ── AppConstants — new phase-7 fields ─────────────────────────────────────

  group('AppConstants phase-7', () {
    test('autoSaveInterval is 30 seconds', () {
      expect(AppConstants.autoSaveInterval, const Duration(seconds: 30));
    });

    test('defaultFontFamily is Roboto', () {
      expect(AppConstants.defaultFontFamily, 'Roboto');
    });

    test('textAnimationDurationMs is 600', () {
      expect(AppConstants.textAnimationDurationMs, 600);
    });
  });

  // ── MediaConstants — image extensions ─────────────────────────────────────

  group('MediaConstants image extensions', () {
    test('imageExtensions is non-empty', () {
      expect(MediaConstants.imageExtensions, isNotEmpty);
    });

    test('jpg is an image extension', () {
      expect(MediaConstants.imageExtensions, contains('jpg'));
    });

    test('jpeg is an image extension', () {
      expect(MediaConstants.imageExtensions, contains('jpeg'));
    });

    test('png is an image extension', () {
      expect(MediaConstants.imageExtensions, contains('png'));
    });

    test('webp is an image extension', () {
      expect(MediaConstants.imageExtensions, contains('webp'));
    });

    test('mp4 is NOT an image extension', () {
      expect(MediaConstants.imageExtensions, isNot(contains('mp4')));
    });

    test('mp3 is NOT an image extension', () {
      expect(MediaConstants.imageExtensions, isNot(contains('mp3')));
    });

    test('allExtensions includes image extensions', () {
      for (final ext in MediaConstants.imageExtensions) {
        expect(MediaConstants.allExtensions, contains(ext),
            reason: '$ext missing from allExtensions');
      }
    });

    test('image extensions are distinct from video extensions', () {
      final overlap = MediaConstants.imageExtensions
          .toSet()
          .intersection(MediaConstants.videoExtensions.toSet());
      expect(overlap, isEmpty);
    });

    test('image extensions are distinct from audio extensions', () {
      final overlap = MediaConstants.imageExtensions
          .toSet()
          .intersection(MediaConstants.audioExtensions.toSet());
      expect(overlap, isEmpty);
    });
  });

  // ── ClipModel — new fields and defaults ────────────────────────────────────

  group('ClipModel new fields — defaults', () {
    late ClipModel clip;

    setUp(() => clip = _makeClip());

    test('fontFamily defaults to Roboto', () {
      expect(clip.fontFamily, 'Roboto');
    });

    test('textAnimationType defaults to none', () {
      expect(clip.textAnimationType, TextAnimationType.none);
    });

    test('textAnimationDurationMs defaults to 600', () {
      expect(clip.textAnimationDurationMs, 600);
    });
  });

  group('ClipModel copyWith — animation fields', () {
    test('copyWith updates fontFamily', () {
      final clip = _makeClip();
      final updated = clip.copyWith(fontFamily: 'Montserrat');
      expect(updated.fontFamily, 'Montserrat');
      expect(updated.id, clip.id);
    });

    test('copyWith updates textAnimationType', () {
      final clip = _makeClip();
      final updated = clip.copyWith(textAnimationType: TextAnimationType.fadeIn);
      expect(updated.textAnimationType, TextAnimationType.fadeIn);
    });

    test('copyWith updates textAnimationDurationMs', () {
      final clip = _makeClip();
      final updated = clip.copyWith(textAnimationDurationMs: 1200);
      expect(updated.textAnimationDurationMs, 1200);
    });

    test('copyWith without animation args preserves defaults', () {
      final clip = _makeClip();
      final updated = clip.copyWith(name: 'renamed');
      expect(updated.fontFamily, clip.fontFamily);
      expect(updated.textAnimationType, clip.textAnimationType);
      expect(updated.textAnimationDurationMs, clip.textAnimationDurationMs);
    });

    test('copyWith can chain multiple animation field changes', () {
      final clip = _makeClip();
      final updated = clip.copyWith(
        fontFamily: 'Lato',
        textAnimationType: TextAnimationType.zoomIn,
        textAnimationDurationMs: 800,
      );
      expect(updated.fontFamily, 'Lato');
      expect(updated.textAnimationType, TextAnimationType.zoomIn);
      expect(updated.textAnimationDurationMs, 800);
    });
  });

  // ── ClipType.image ────────────────────────────────────────────────────────

  group('ClipType.image', () {
    test('image clip has type image', () {
      final clip = _makeImageClip();
      expect(clip.type, ClipType.image);
    });

    test('image clip 5-second default duration is preserved', () {
      final clip = _makeImageClip(
        start: Duration.zero,
        end: const Duration(seconds: 5),
      );
      expect(clip.duration, const Duration(seconds: 5));
    });

    test('image clip can carry fontFamily', () {
      final clip = _makeImageClip().copyWith(fontFamily: 'Oswald');
      expect(clip.fontFamily, 'Oswald');
    });

    test('image clip can carry text animation', () {
      final clip =
          _makeImageClip().copyWith(textAnimationType: TextAnimationType.slideUp);
      expect(clip.textAnimationType, TextAnimationType.slideUp);
    });

    test('image clip can carry animation duration', () {
      final clip = _makeImageClip().copyWith(textAnimationDurationMs: 900);
      expect(clip.textAnimationDurationMs, 900);
    });

    test('image clip can carry titleText for overlay', () {
      const clip = ClipModel(
        id: 'img_text',
        trackId: 'track_v1',
        mediaId: 'img_asset',
        type: ClipType.image,
        startOnTimeline: Duration.zero,
        endOnTimeline: Duration(seconds: 5),
        mediaInPoint: Duration.zero,
        mediaOutPoint: Duration(seconds: 5),
        titleText: 'Caption',
      );
      expect(clip.titleText, 'Caption');
    });
  });

  // ── Title clip animation fields ────────────────────────────────────────────

  group('Title clip animation fields', () {
    test('title clip defaults to no animation', () {
      final clip = _makeTitleClip();
      expect(clip.textAnimationType, TextAnimationType.none);
    });

    test('title clip animation can be set to typewriter', () {
      final clip = _makeTitleClip()
          .copyWith(textAnimationType: TextAnimationType.typewriter);
      expect(clip.textAnimationType, TextAnimationType.typewriter);
    });

    test('title clip animation duration can be updated', () {
      final clip =
          _makeTitleClip().copyWith(textAnimationDurationMs: 1500);
      expect(clip.textAnimationDurationMs, 1500);
    });

    test('title clip preserves text when animation fields change', () {
      final clip = _makeTitleClip(titleText: 'My Title').copyWith(
        textAnimationType: TextAnimationType.fadeIn,
        textAnimationDurationMs: 400,
      );
      expect(clip.titleText, 'My Title');
    });
  });

  // ── TimelineState with image clips ────────────────────────────────────────

  group('TimelineState with image clips', () {
    late TimelineState state;

    setUp(() {
      state = TimelineState();
      state.addTrack(
        const TrackModel(
          id: 'track_v1',
          projectId: 'proj',
          type: TrackType.video,
          index: 0,
        ),
      );
    });
    tearDown(() => state.dispose());

    test('can add an image clip', () {
      state.addClip(_makeImageClip());
      expect(state.clips.length, 1);
      expect(state.clips.first.type, ClipType.image);
    });

    test('image clip is included in state duration', () {
      state.addClip(_makeImageClip(
        start: const Duration(seconds: 2),
        end: const Duration(seconds: 7),
      ));
      expect(state.duration, const Duration(seconds: 7));
    });

    test('image clip can be selected', () {
      final clip = _makeImageClip();
      state.addClip(clip);
      state.selectClip(clip.id);
      expect(state.selectedClipIds, contains(clip.id));
    });

    test('can mix video and image clips', () {
      state.addClip(_makeClip(id: 'v1', start: Duration.zero, end: const Duration(seconds: 5)));
      state.addClip(_makeImageClip(
        id: 'img1',
        start: const Duration(seconds: 5),
        end: const Duration(seconds: 10),
      ));
      expect(state.clips.length, 2);
      expect(
        state.clips.map((c) => c.type).toSet(),
        containsAll([ClipType.video, ClipType.image]),
      );
    });

    test('image clip can be updated with animation via updateClip', () {
      final clip = _makeImageClip();
      state.addClip(clip);
      final updated = clip.copyWith(
        textAnimationType: TextAnimationType.slideLeft,
        textAnimationDurationMs: 700,
      );
      state.updateClip(updated);
      final fromState = state.clips.firstWhere((c) => c.id == clip.id);
      expect(fromState.textAnimationType, TextAnimationType.slideLeft);
      expect(fromState.textAnimationDurationMs, 700);
    });

    test('image clip can be removed', () {
      final clip = _makeImageClip();
      state.addClip(clip);
      state.removeClip(clip.id);
      expect(state.clips, isEmpty);
    });
  });

  // ── Animation duration range invariants ───────────────────────────────────

  group('Animation duration range', () {
    test('default 600ms is within the controller clamp range 100–5000', () {
      const def = AppConstants.textAnimationDurationMs;
      expect(def, greaterThanOrEqualTo(100));
      expect(def, lessThanOrEqualTo(5000));
    });

    test('clamping logic: value below min is raised to 100', () {
      const raw = 50;
      final clamped = raw.clamp(100, 5000);
      expect(clamped, 100);
    });

    test('clamping logic: value above max is lowered to 5000', () {
      const raw = 9999;
      final clamped = raw.clamp(100, 5000);
      expect(clamped, 5000);
    });

    test('clamping logic: value within range is unchanged', () {
      const raw = 1200;
      final clamped = raw.clamp(100, 5000);
      expect(clamped, 1200);
    });
  });
}
