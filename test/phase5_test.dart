import 'package:flutter_test/flutter_test.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/effects/effect_model.dart';
import 'package:prepstation/core/effects/effect_type.dart';
import 'package:prepstation/core/ffmpeg/filtergraph_builder.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';
import 'package:prepstation/core/timeline/track_model.dart';
import 'package:prepstation/core/transitions/transition_type.dart';

// ── Fixtures ───────────────────────────────────────────────────────────────

ClipModel _makeClip({
  String id = 'clip_1',
  String trackId = 'track_v1',
  Duration start = Duration.zero,
  Duration end = const Duration(seconds: 10),
  String? transitionOutId,
  Duration transitionOutDuration = Duration.zero,
}) =>
    ClipModel(
      id: id,
      trackId: trackId,
      mediaId: 'asset_1',
      type: ClipType.video,
      startOnTimeline: start,
      endOnTimeline: end,
      mediaInPoint: Duration.zero,
      mediaOutPoint: end - start,
      transitionOutId: transitionOutId,
      transitionOutDuration: transitionOutDuration,
    );

const _transition1s = Duration(seconds: 1);
const _transition500ms = Duration(milliseconds: 500);

const _graphBuilder = FiltergraphBuilder();

// ── TransitionType ─────────────────────────────────────────────────────────

void main() {
  group('TransitionType', () {
    test('all values have distinct xfadeParams', () {
      final params = TransitionType.values.map((t) => t.xfadeParam).toSet();
      expect(params.length, TransitionType.values.length);
    });

    test('all values have non-empty displayNames', () {
      for (final t in TransitionType.values) {
        expect(t.displayName, isNotEmpty);
      }
    });

    test('crossDissolve maps to dissolve', () {
      expect(TransitionType.crossDissolve.xfadeParam, 'dissolve');
    });

    test('fadeBlack maps to fadeblack', () {
      expect(TransitionType.fadeBlack.xfadeParam, 'fadeblack');
    });

    test('wipeLeft maps to wipeleft', () {
      expect(TransitionType.wipeLeft.xfadeParam, 'wipeleft');
    });

    test('wipeRight maps to wiperight', () {
      expect(TransitionType.wipeRight.xfadeParam, 'wiperight');
    });

    test('slide maps to slideleft', () {
      expect(TransitionType.slide.xfadeParam, 'slideleft');
    });

    test('fromId returns matching type', () {
      for (final t in TransitionType.values) {
        expect(TransitionType.fromId(t.name), t);
      }
    });

    test('fromId returns null for unknown id', () {
      expect(TransitionType.fromId('unknown_transition'), isNull);
    });

    test('fromId returns null for empty string', () {
      expect(TransitionType.fromId(''), isNull);
    });
  });

  // ── AppConstants transition ranges ─────────────────────────────────────────

  group('AppConstants transition', () {
    test('minTransitionDuration < defaultTransitionDuration', () {
      expect(AppConstants.minTransitionDuration,
          lessThan(AppConstants.defaultTransitionDuration));
    });

    test('defaultTransitionDuration < maxTransitionDuration', () {
      expect(AppConstants.defaultTransitionDuration,
          lessThan(AppConstants.maxTransitionDuration));
    });

    test('minTransitionDuration is positive', () {
      expect(AppConstants.minTransitionDuration, greaterThan(0.0));
    });
  });

  // ── FiltergraphBuilder.buildTransitionGraph ────────────────────────────────

  group('FiltergraphBuilder.buildTransitionGraph', () {
    test('empty clips returns empty string', () {
      expect(_graphBuilder.buildTransitionGraph([]), '');
    });

    test('single clip returns empty string', () {
      expect(_graphBuilder.buildTransitionGraph([_makeClip()]), '');
    });

    test('two clips no transition delegates to buildConcatGraph', () {
      final clips = [
        _makeClip(id: 'a', start: Duration.zero, end: const Duration(seconds: 5)),
        _makeClip(
            id: 'b',
            start: const Duration(seconds: 5),
            end: const Duration(seconds: 10)),
      ];
      final concat = _graphBuilder.buildConcatGraph(clips);
      final trans = _graphBuilder.buildTransitionGraph(clips);
      expect(trans, concat);
    });

    test('two clips with transition produces xfade and acrossfade', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 10),
          transitionOutId: 'crossDissolve',
          transitionOutDuration: _transition1s,
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
        ),
      ];
      final graph = _graphBuilder.buildTransitionGraph(clips);
      expect(graph, contains('xfade=transition=dissolve'));
      expect(graph, contains('acrossfade=d='));
      expect(graph, contains('[outv]'));
      expect(graph, contains('[outa]'));
    });

    test('xfade offset is clip_duration minus transition_duration', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 10),
          transitionOutId: 'crossDissolve',
          transitionOutDuration: _transition1s,
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
        ),
      ];
      final graph = _graphBuilder.buildTransitionGraph(clips);
      // A.duration=10s, transition=1s → offset=9.000
      expect(graph, contains('offset=9.000'));
    });

    test('three clips all transitions produces chained xfades', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 8),
          transitionOutId: 'crossDissolve',
          transitionOutDuration: _transition500ms,
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 8),
          end: const Duration(seconds: 16),
          transitionOutId: 'wipeLeft',
          transitionOutDuration: _transition1s,
        ),
        _makeClip(
          id: 'c',
          start: const Duration(seconds: 16),
          end: const Duration(seconds: 24),
        ),
      ];
      final graph = _graphBuilder.buildTransitionGraph(clips);
      // Both transitions are in one segment → two xfade filters, null/anull passthrough
      expect(graph, contains('dissolve'));
      expect(graph, contains('wipeleft'));
      expect('xfade'.allMatches(graph).length, 2);
      expect(graph, contains('null[outv]'));
      expect(graph, contains('anull[outa]'));
    });

    test('three clips transition then cut produces xfade and concat', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 10),
          transitionOutId: 'fadeBlack',
          transitionOutDuration: _transition1s,
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
          // no transition out — cut to C
        ),
        _makeClip(
          id: 'c',
          start: const Duration(seconds: 20),
          end: const Duration(seconds: 30),
        ),
      ];
      final graph = _graphBuilder.buildTransitionGraph(clips);
      expect(graph, contains('xfade'));
      expect(graph, contains('concat=n=2'));
      expect(graph, contains('[outv]'));
      expect(graph, contains('[outa]'));
    });

    test('three clips cut then transition produces concat', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 10),
          // no transition
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
          transitionOutId: 'crossDissolve',
          transitionOutDuration: _transition1s,
        ),
        _makeClip(
          id: 'c',
          start: const Duration(seconds: 20),
          end: const Duration(seconds: 30),
        ),
      ];
      final graph = _graphBuilder.buildTransitionGraph(clips);
      expect(graph, contains('xfade'));
      expect(graph, contains('concat=n=2'));
    });

    test('filtergraph brackets are balanced', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 5),
          transitionOutId: 'slide',
          transitionOutDuration: _transition500ms,
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 10),
        ),
      ];
      final graph = _graphBuilder.buildTransitionGraph(clips);
      final opens = '['.allMatches(graph).length;
      final closes = ']'.allMatches(graph).length;
      expect(opens, closes);
    });

    test('with effects and transition combines both', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 10),
          transitionOutId: 'crossDissolve',
          transitionOutDuration: _transition1s,
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
        ),
      ];
      final effects = {
        'a': [
          const EffectInstance(
            id: 'eff1',
            clipId: 'a',
            type: EffectType.blur,
            stackIndex: 0,
            parameters: {'sigma': 3.0},
          ),
        ],
      };
      final graph = _graphBuilder.buildTransitionGraph(
        clips,
        effectsByClipId: effects,
      );
      expect(graph, contains('gblur'));
      expect(graph, contains('xfade'));
    });

    test('zero transition duration produces offset=clip_duration', () {
      final clips = [
        _makeClip(
          id: 'a',
          end: const Duration(seconds: 5),
          transitionOutId: 'crossDissolve',
          transitionOutDuration: Duration.zero,
        ),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 10),
        ),
      ];
      final graph = _graphBuilder.buildTransitionGraph(clips);
      // duration=0, offset = 5-0 = 5 (or clamped to >=0)
      expect(graph, contains('offset=5.000'));
    });

    test('last clip transitionOutId is ignored when no next clip', () {
      final clips = [
        _makeClip(id: 'a', end: const Duration(seconds: 5)),
        _makeClip(
          id: 'b',
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 10),
          // transition on last clip — no next clip, so treated as cut
          transitionOutId: 'crossDissolve',
          transitionOutDuration: _transition1s,
        ),
      ];
      // hasAnyTransition = true (because b has transitionOutId)
      // but b is the last clip, so segment is [a] and [b] — 2 single-clip segments
      // result: concat of 2
      final graph = _graphBuilder.buildTransitionGraph(clips);
      expect(graph, contains('concat=n=2'));
      expect(graph, isNot(contains('xfade')));
    });
  });

  // ── TimelineState + transitions ────────────────────────────────────────────

  group('TimelineState clip transitions', () {
    late TimelineState state;

    setUp(() {
      state = TimelineState();
      state.addTrack(
        const TrackModel(
          id: 'track_v1',
          projectId: 'proj_1',
          type: TrackType.video,
          index: 0,
        ),
      );
    });
    tearDown(() => state.dispose());

    test('clip with transition is retrievable', () {
      final clip = _makeClip(
        transitionOutId: 'crossDissolve',
        transitionOutDuration: _transition1s,
      );
      state.addClip(clip);
      final found = state.clips.first;
      expect(found.transitionOutId, 'crossDissolve');
      expect(found.transitionOutDuration, _transition1s);
    });

    test('updateClip replaces transition fields', () {
      final clip = _makeClip();
      state.addClip(clip);
      final updated = clip.copyWith(
        transitionOutId: 'wipeLeft',
        transitionOutDuration: _transition500ms,
      );
      state.updateClip(updated);
      final found = state.clips.first;
      expect(found.transitionOutId, 'wipeLeft');
      expect(found.transitionOutDuration, _transition500ms);
    });

    test('clearTransition sets transitionOutId to null', () {
      final clip = _makeClip(
        transitionOutId: 'fadeBlack',
        transitionOutDuration: _transition1s,
      );
      state.addClip(clip);
      final cleared = clip.copyWith(
        transitionOutId: null,
        transitionOutDuration: Duration.zero,
      );
      state.updateClip(cleared);
      expect(state.clips.first.transitionOutId, isNull);
      expect(state.clips.first.transitionOutDuration, Duration.zero);
    });
  });

  // ── ClipModel transition copyWith ──────────────────────────────────────────

  group('ClipModel transition copyWith', () {
    test('copyWith sets transitionOutId', () {
      final clip = _makeClip();
      final updated = clip.copyWith(transitionOutId: 'slide');
      expect(updated.transitionOutId, 'slide');
      expect(updated.id, clip.id);
    });

    test('copyWith can clear transitionOutId to null', () {
      final clip = _makeClip(transitionOutId: 'crossDissolve');
      final updated = clip.copyWith(transitionOutId: null);
      expect(updated.transitionOutId, isNull);
    });

    test('copyWith sets transitionOutDuration', () {
      final clip = _makeClip();
      final updated =
          clip.copyWith(transitionOutDuration: _transition500ms);
      expect(updated.transitionOutDuration, _transition500ms);
    });
  });
}
