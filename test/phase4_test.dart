import 'package:flutter_test/flutter_test.dart';
import 'package:prepstation/core/history/history_manager.dart';
import 'package:prepstation/core/history/keyframe_commands.dart';
import 'package:prepstation/core/keyframes/animated_property.dart';
import 'package:prepstation/core/keyframes/keyframe_repository.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/keyframe_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';
import 'package:prepstation/core/timeline/track_model.dart';

// ── Stub repositories ──────────────────────────────────────────────────────

class _StubProjectRepo implements ProjectRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _StubKeyframeRepo implements KeyframeRepository {
  final _store = <String, KeyframeModel>{};

  @override
  Future<void> saveKeyframe(String clipId, KeyframeModel kf) async =>
      _store[kf.id] = kf;

  @override
  Future<void> deleteKeyframe(String id) async => _store.remove(id);

  @override
  Future<List<KeyframeModel>> getKeyframesForClip(String clipId) async =>
      _store.values.toList();

  @override
  Future<List<KeyframeModel>> getKeyframesForParameter(
    String clipId,
    String parameterId,
  ) async =>
      _store.values.where((k) => k.parameterId == parameterId).toList();

  @override
  Future<void> deleteKeyframesForClip(String clipId) async =>
      _store.clear();
}

// ── Fixtures ───────────────────────────────────────────────────────────────

const _track = TrackModel(
  id: 'track_v1',
  projectId: 'proj_1',
  type: TrackType.video,
  index: 0,
);

const _clip = ClipModel(
  id: 'clip_1',
  trackId: 'track_v1',
  mediaId: 'asset_1',
  type: ClipType.video,
  startOnTimeline: Duration.zero,
  endOnTimeline: Duration(seconds: 10),
  mediaInPoint: Duration.zero,
  mediaOutPoint: Duration(seconds: 10),
);

KeyframeModel _makeKf({
  String id = 'kf_1',
  String parameterId = AnimatedProperty.opacity,
  Duration time = const Duration(seconds: 2),
  double value = 0.8,
  KeyframeInterpolation interpolation = KeyframeInterpolation.linear,
}) =>
    KeyframeModel(
      id: id,
      parameterId: parameterId,
      time: time,
      value: value,
      interpolation: interpolation,
    );

void main() {
  // ── AnimatedProperty ───────────────────────────────────────────────────────

  group('AnimatedProperty', () {
    test('opacity and speed are distinct strings', () {
      expect(AnimatedProperty.opacity, isNot(AnimatedProperty.speed));
    });

    test('effectParam builds dotted path', () {
      final id =
          AnimatedProperty.effectParam('eff_abc', 'brightness');
      expect(id, 'effect.eff_abc.brightness');
    });

    test('parseEffectParam roundtrips', () {
      const id = 'effect.eff_abc.brightness';
      final parsed = AnimatedProperty.parseEffectParam(id);
      expect(parsed?.effectId, 'eff_abc');
      expect(parsed?.paramKey, 'brightness');
    });

    test('parseEffectParam returns null for non-effect id', () {
      expect(AnimatedProperty.parseEffectParam('opacity'), isNull);
    });
  });

  // ── KeyframeModel & ParameterCurve ─────────────────────────────────────────

  group('KeyframeModel', () {
    test('copyWith updates only specified fields', () {
      final kf = _makeKf();
      final copy = kf.copyWith(value: 0.3);
      expect(copy.value, 0.3);
      expect(copy.id, kf.id);
      expect(copy.time, kf.time);
    });

    test('equality is id-based', () {
      final a = _makeKf(id: 'x', value: 0.5);
      final b = _makeKf(id: 'x', value: 0.9);
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      expect(_makeKf(id: 'a'), isNot(equals(_makeKf(id: 'b'))));
    });
  });

  group('ParameterCurve', () {
    test('evaluate with no keyframes returns defaultValue', () {
      const curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [],
        defaultValue: 0.5,
      );
      expect(curve.evaluate(const Duration(seconds: 5)), 0.5);
    });

    test('evaluate clamps before first keyframe', () {
      final curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [_makeKf(time: const Duration(seconds: 2), value: 0.8)],
        defaultValue: 1.0,
      );
      expect(curve.evaluate(Duration.zero), 0.8);
    });

    test('evaluate clamps after last keyframe', () {
      final curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [_makeKf(time: const Duration(seconds: 2), value: 0.8)],
        defaultValue: 1.0,
      );
      expect(curve.evaluate(const Duration(seconds: 10)), 0.8);
    });

    test('linear interpolation midpoint', () {
      final curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [
          _makeKf(id: 'a', time: const Duration(seconds: 0), value: 0.0),
          _makeKf(id: 'b', time: const Duration(seconds: 4), value: 1.0),
        ],
        defaultValue: 0.0,
      );
      expect(
        curve.evaluate(const Duration(seconds: 2)),
        closeTo(0.5, 0.001),
      );
    });

    test('hold interpolation stays at prev value', () {
      final curve = ParameterCurve(
        parameterId: 'opacity',
        keyframes: [
          _makeKf(
            id: 'a',
            time: const Duration(seconds: 0),
            value: 0.2,
            interpolation: KeyframeInterpolation.hold,
          ),
          _makeKf(id: 'b', time: const Duration(seconds: 4), value: 1.0),
        ],
        defaultValue: 0.0,
      );
      expect(
        curve.evaluate(const Duration(seconds: 2)),
        closeTo(0.2, 0.001),
      );
    });
  });

  // ── TimelineState keyframe methods ─────────────────────────────────────────

  group('TimelineState keyframe methods', () {
    late TimelineState state;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip);
    });
    tearDown(() => state.dispose());

    test('allKeyframesForClip empty initially', () {
      expect(state.allKeyframesForClip('clip_1'), isEmpty);
    });

    test('addKeyframe grows the list', () {
      state.addKeyframe('clip_1', _makeKf());
      expect(state.allKeyframesForClip('clip_1').length, 1);
    });

    test('removeKeyframe shrinks the list', () {
      final kf = _makeKf();
      state.addKeyframe('clip_1', kf);
      state.removeKeyframe('clip_1', kf.id);
      expect(state.allKeyframesForClip('clip_1'), isEmpty);
    });

    test('updateKeyframe replaces matching entry', () {
      final kf = _makeKf(value: 0.5);
      state.addKeyframe('clip_1', kf);
      state.updateKeyframe('clip_1', kf.copyWith(value: 0.9));
      expect(
        state.curvesForClip('clip_1')[AnimatedProperty.opacity]!.keyframes.first.value,
        0.9,
      );
    });

    test('setKeyframesForClip replaces entire map', () {
      state.addKeyframe('clip_1', _makeKf(id: 'a'));
      state.setKeyframesForClip('clip_1', {
        AnimatedProperty.opacity: [_makeKf(id: 'b')],
      });
      expect(state.allKeyframesForClip('clip_1').length, 1);
      expect(
        state.allKeyframesForClip('clip_1').first.id,
        'b',
      );
    });

    test('evaluateParameter returns staticValue with no keyframes', () {
      expect(
        state.evaluateParameter(
          'clip_1',
          AnimatedProperty.opacity,
          const Duration(seconds: 5),
          0.7,
        ),
        0.7,
      );
    });

    test('evaluateParameter returns animated value when keyframes exist', () {
      state.addKeyframe(
        'clip_1',
        _makeKf(id: 'a', time: Duration.zero, value: 0.0),
      );
      state.addKeyframe(
        'clip_1',
        _makeKf(id: 'b', time: const Duration(seconds: 4), value: 1.0),
      );
      final val = state.evaluateParameter(
        'clip_1',
        AnimatedProperty.opacity,
        const Duration(seconds: 2),
        1.0,
      );
      expect(val, closeTo(0.5, 0.01));
    });

    test('hasKeyframeAt returns true within tolerance', () {
      state.addKeyframe(
        'clip_1',
        _makeKf(time: const Duration(seconds: 3)),
      );
      expect(
        state.hasKeyframeAt(
          'clip_1',
          AnimatedProperty.opacity,
          const Duration(milliseconds: 3005),
          tolerance: const Duration(milliseconds: 17),
        ),
        isTrue,
      );
    });

    test('hasKeyframeAt returns false beyond tolerance', () {
      state.addKeyframe(
        'clip_1',
        _makeKf(time: const Duration(seconds: 3)),
      );
      expect(
        state.hasKeyframeAt(
          'clip_1',
          AnimatedProperty.opacity,
          const Duration(seconds: 5),
        ),
        isFalse,
      );
    });

    test('keyframeAt returns matching keyframe', () {
      final kf = _makeKf(time: const Duration(seconds: 2));
      state.addKeyframe('clip_1', kf);
      final found = state.keyframeAt(
        'clip_1',
        AnimatedProperty.opacity,
        const Duration(seconds: 2),
      );
      expect(found?.id, kf.id);
    });

    test('keyframeAt returns null when none match', () {
      expect(
        state.keyframeAt(
          'clip_1',
          AnimatedProperty.opacity,
          const Duration(seconds: 9),
        ),
        isNull,
      );
    });
  });

  // ── Keyframe Commands ──────────────────────────────────────────────────────

  group('AddKeyframeCommand', () {
    late TimelineState state;
    late _StubProjectRepo repo;
    late _StubKeyframeRepo kfRepo;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip);
      repo = _StubProjectRepo();
      kfRepo = _StubKeyframeRepo();
    });
    tearDown(() => state.dispose());

    test('execute adds keyframe; undo removes it', () async {
      final kf = _makeKf();
      final cmd = AddKeyframeCommand(
        clipId: 'clip_1',
        keyframe: kf,
        keyframeRepo: kfRepo,
      );
      await cmd.execute(state, repo);
      expect(state.allKeyframesForClip('clip_1').length, 1);

      await cmd.undo(state, repo);
      expect(state.allKeyframesForClip('clip_1'), isEmpty);
    });

    test('description is "Add Keyframe"', () {
      final cmd = AddKeyframeCommand(
        clipId: 'clip_1',
        keyframe: _makeKf(),
        keyframeRepo: kfRepo,
      );
      expect(cmd.description, 'Add Keyframe');
    });
  });

  group('RemoveKeyframeCommand', () {
    late TimelineState state;
    late _StubProjectRepo repo;
    late _StubKeyframeRepo kfRepo;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip);
      repo = _StubProjectRepo();
      kfRepo = _StubKeyframeRepo();
    });
    tearDown(() => state.dispose());

    test('execute removes keyframe; undo restores it', () async {
      final kf = _makeKf();
      state.addKeyframe('clip_1', kf);
      kfRepo._store[kf.id] = kf;

      final cmd = RemoveKeyframeCommand(
        clipId: 'clip_1',
        keyframe: kf,
        keyframeRepo: kfRepo,
      );
      await cmd.execute(state, repo);
      expect(state.allKeyframesForClip('clip_1'), isEmpty);

      await cmd.undo(state, repo);
      expect(state.allKeyframesForClip('clip_1').length, 1);
    });
  });

  group('UpdateKeyframeCommand', () {
    late TimelineState state;
    late _StubProjectRepo repo;
    late _StubKeyframeRepo kfRepo;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip);
      repo = _StubProjectRepo();
      kfRepo = _StubKeyframeRepo();
    });
    tearDown(() => state.dispose());

    test('execute applies after; undo restores before', () async {
      final before = _makeKf(value: 0.3);
      state.addKeyframe('clip_1', before);
      kfRepo._store[before.id] = before;
      final after = before.copyWith(value: 0.9);

      final cmd = UpdateKeyframeCommand(
        clipId: 'clip_1',
        before: before,
        after: after,
        keyframeRepo: kfRepo,
      );
      await cmd.execute(state, repo);
      expect(
        state
            .curvesForClip('clip_1')[AnimatedProperty.opacity]!
            .keyframes
            .first
            .value,
        0.9,
      );

      await cmd.undo(state, repo);
      expect(
        state
            .curvesForClip('clip_1')[AnimatedProperty.opacity]!
            .keyframes
            .first
            .value,
        0.3,
      );
    });
  });

  // ── HistoryManager with keyframe commands ──────────────────────────────────

  group('HistoryManager with keyframe commands', () {
    late TimelineState state;
    late _StubProjectRepo repo;
    late _StubKeyframeRepo kfRepo;
    late HistoryManager history;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip);
      repo = _StubProjectRepo();
      kfRepo = _StubKeyframeRepo();
      history = HistoryManager();
    });
    tearDown(() {
      state.dispose();
      history.dispose();
    });

    test('add/undo/redo roundtrip', () async {
      final kf = _makeKf();
      await history.execute(
        AddKeyframeCommand(
          clipId: 'clip_1',
          keyframe: kf,
          keyframeRepo: kfRepo,
        ),
        state,
        repo,
      );
      expect(state.allKeyframesForClip('clip_1').length, 1);

      await history.undo(state, repo);
      expect(state.allKeyframesForClip('clip_1'), isEmpty);

      await history.redo(state, repo);
      expect(state.allKeyframesForClip('clip_1').length, 1);
    });
  });
}
