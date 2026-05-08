import 'package:flutter_test/flutter_test.dart';
import 'package:fluxedit/core/constants/app_constants.dart';
import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_registry.dart';
import 'package:fluxedit/core/effects/effect_type.dart';
import 'package:fluxedit/core/ffmpeg/filtergraph_builder.dart';
import 'package:fluxedit/core/history/effect_commands.dart';
import 'package:fluxedit/core/history/history_manager.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/core/timeline/track_model.dart';

// ── Minimal stub repository ────────────────────────────────────────────────

class _StubRepo implements ProjectRepository {
  final _effects = <String, EffectInstance>{};

  @override
  Future<void> saveEffect(EffectInstance effect) async =>
      _effects[effect.id] = effect;

  @override
  Future<void> deleteEffect(String id) async => _effects.remove(id);

  @override
  Future<List<EffectInstance>> getEffectsForClip(String clipId) async =>
      _effects.values.where((e) => e.clipId == clipId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

// ── Fixtures ───────────────────────────────────────────────────────────────

const _track = TrackModel(
  id: 'track_v1',
  projectId: 'proj_1',
  type: TrackType.video,
  index: 0,
);

const _clip1 = ClipModel(
  id: 'clip_1',
  trackId: 'track_v1',
  mediaId: 'asset_1',
  type: ClipType.video,
  startOnTimeline: Duration(seconds: 0),
  endOnTimeline: Duration(seconds: 5),
  mediaInPoint: Duration.zero,
  mediaOutPoint: Duration(seconds: 5),
);

const _clip2 = ClipModel(
  id: 'clip_2',
  trackId: 'track_v1',
  mediaId: 'asset_2',
  type: ClipType.video,
  startOnTimeline: Duration(seconds: 5),
  endOnTimeline: Duration(seconds: 10),
  mediaInPoint: Duration.zero,
  mediaOutPoint: Duration(seconds: 5),
);

EffectInstance _makeEffect({
  String id = 'eff_1',
  String clipId = 'clip_1',
  EffectType type = EffectType.colorCorrection,
  int stackIndex = 0,
  bool isEnabled = true,
  Map<String, double>? parameters,
}) {
  return EffectInstance(
    id: id,
    clipId: clipId,
    type: type,
    stackIndex: stackIndex,
    isEnabled: isEnabled,
    parameters:
        parameters ?? EffectRegistry.defaultParameters(type),
  );
}

void main() {
  // ── EffectType ─────────────────────────────────────────────────────────────

  group('EffectType', () {
    test('displayName returns human-readable names', () {
      expect(EffectType.colorCorrection.displayName, 'Color Correction');
      expect(EffectType.blur.displayName, 'Blur');
      expect(EffectType.vignette.displayName, 'Vignette');
      expect(EffectType.grain.displayName, 'Film Grain');
      expect(EffectType.lut.displayName, 'LUT');
    });

    test('all types are distinct', () {
      final names =
          EffectType.values.map((t) => t.displayName).toSet();
      expect(names.length, EffectType.values.length);
    });
  });

  // ── EffectInstance ─────────────────────────────────────────────────────────

  group('EffectInstance', () {
    test('copyWith preserves unspecified fields', () {
      final e = _makeEffect();
      final copy = e.copyWith(isEnabled: false);
      expect(copy.isEnabled, isFalse);
      expect(copy.id, e.id);
      expect(copy.type, e.type);
    });

    test('equality is id-based', () {
      final a = _makeEffect(id: 'x');
      final b = _makeEffect(id: 'x', stackIndex: 5);
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      final a = _makeEffect(id: 'a');
      final b = _makeEffect(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('parametersToJson roundtrip', () {
      const params = {'brightness': 0.5, 'contrast': 1.2};
      final e = _makeEffect(parameters: params);
      final json = e.parametersToJson();
      final decoded = EffectInstance.parametersFromJson(json);
      expect(decoded['brightness'], closeTo(0.5, 0.001));
      expect(decoded['contrast'], closeTo(1.2, 0.001));
    });

    test('parametersFromJson handles empty string', () {
      final result = EffectInstance.parametersFromJson('{}');
      expect(result, isEmpty);
    });

    test('displayName delegates to EffectType', () {
      final e = _makeEffect(type: EffectType.blur);
      expect(e.displayName, 'Blur');
    });
  });

  // ── EffectRegistry ─────────────────────────────────────────────────────────

  group('EffectRegistry.defaultParameters', () {
    test('colorCorrection has four keys', () {
      final p = EffectRegistry.defaultParameters(EffectType.colorCorrection);
      expect(p.keys, containsAll(['brightness', 'contrast', 'saturation', 'hue']));
    });

    test('blur has radius key', () {
      final p = EffectRegistry.defaultParameters(EffectType.blur);
      expect(p.containsKey('radius'), isTrue);
    });

    test('lut returns empty map', () {
      expect(EffectRegistry.defaultParameters(EffectType.lut), isEmpty);
    });
  });

  group('EffectRegistry.buildFilterString', () {
    test('disabled effect returns empty string', () {
      final e = _makeEffect(isEnabled: false);
      expect(EffectRegistry.buildFilterString(e), '');
    });

    test('colorCorrection builds eq filter', () {
      final e = _makeEffect(
        type: EffectType.colorCorrection,
        parameters: {
          'brightness': 0.1,
          'contrast': 1.2,
          'saturation': 1.5,
          'hue': 0.0,
        },
      );
      final filter = EffectRegistry.buildFilterString(e);
      expect(filter, startsWith('eq=brightness='));
      expect(filter, contains('contrast='));
      expect(filter, contains('saturation='));
    });

    test('blur builds gblur filter', () {
      final e = _makeEffect(
        type: EffectType.blur,
        parameters: {'radius': 8.0},
      );
      expect(EffectRegistry.buildFilterString(e), 'gblur=sigma=8.0');
    });

    test('vignette builds vignette filter', () {
      final e = _makeEffect(
        type: EffectType.vignette,
        parameters: {'angle': 1.5708},
      );
      expect(EffectRegistry.buildFilterString(e), startsWith('vignette=angle='));
    });

    test('grain builds noise filter', () {
      final e = _makeEffect(
        type: EffectType.grain,
        parameters: {'strength': 30.0},
      );
      expect(EffectRegistry.buildFilterString(e), startsWith('noise=alls=30'));
    });

    test('lut returns empty string (no path)', () {
      final e = _makeEffect(type: EffectType.lut, parameters: {});
      expect(EffectRegistry.buildFilterString(e), '');
    });
  });

  group('EffectRegistry.buildClipEffectChain', () {
    test('empty effect list returns empty string', () {
      expect(
        EffectRegistry.buildClipEffectChain('0:v', 'v0', []),
        '',
      );
    });

    test('all disabled effects returns empty string', () {
      final effects = [_makeEffect(isEnabled: false)];
      expect(
        EffectRegistry.buildClipEffectChain('0:v', 'v0', effects),
        '',
      );
    });

    test('single effect chain has correct labels', () {
      final effects = [
        _makeEffect(
          type: EffectType.blur,
          parameters: {'radius': 4.0},
        ),
      ];
      final chain =
          EffectRegistry.buildClipEffectChain('0:v', 'v0', effects);
      expect(chain, startsWith('[0:v]'));
      expect(chain, endsWith('[v0]'));
    });

    test('effects are sorted by stackIndex', () {
      final blur = _makeEffect(
        id: 'blur',
        type: EffectType.blur,
        stackIndex: 1,
        parameters: {'radius': 4.0},
      );
      final cc = _makeEffect(
        id: 'cc',
        type: EffectType.colorCorrection,
        stackIndex: 0,
        parameters: EffectRegistry.defaultParameters(
          EffectType.colorCorrection,
        ),
      );
      final chain =
          EffectRegistry.buildClipEffectChain('0:v', 'v0', [blur, cc]);
      final eqPos = chain.indexOf('eq=');
      final blurPos = chain.indexOf('gblur=');
      expect(eqPos, lessThan(blurPos));
    });
  });

  // ── FiltergraphBuilder (Phase 3) ────────────────────────────────────────────

  group('FiltergraphBuilder with effects', () {
    const builder = FiltergraphBuilder();
    final clips = [_clip1, _clip2];

    test('no effects produces simple concat', () {
      final graph = builder.buildConcatGraph(clips);
      expect(graph, contains('concat=n=2'));
      expect(graph, contains('[0:v][0:a]'));
    });

    test('effects map adds filter chains', () {
      final effects = {
        'clip_1': [
          _makeEffect(
            type: EffectType.blur,
            parameters: {'radius': 4.0},
          ),
        ],
      };
      final graph =
          builder.buildConcatGraph(clips, effectsByClipId: effects);
      expect(graph, contains('gblur='));
      expect(graph, contains('concat=n=2'));
    });

    test('graph with effects is valid (balanced brackets)', () {
      final effects = {
        'clip_1': [
          _makeEffect(
            type: EffectType.blur,
            parameters: {'radius': 4.0},
          ),
        ],
      };
      final graph =
          builder.buildConcatGraph(clips, effectsByClipId: effects);
      expect(builder.validate(graph), isTrue);
    });

    test('disabled effects produce simple concat', () {
      final effects = {
        'clip_1': [_makeEffect(isEnabled: false)],
      };
      final graph =
          builder.buildConcatGraph(clips, effectsByClipId: effects);
      expect(graph, isNot(contains('gblur=')));
      expect(graph, contains('[0:v][0:a]'));
    });
  });

  // ── Effect Commands ────────────────────────────────────────────────────────

  group('AddEffectCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip1);
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute adds effect to state and repo', () async {
      final effect = _makeEffect();
      final cmd = AddEffectCommand(effect);
      await cmd.execute(state, repo);
      expect(state.effectsForClip('clip_1').length, 1);
      expect(state.effectsForClip('clip_1').first.id, 'eff_1');
    });

    test('undo removes effect from state and repo', () async {
      final effect = _makeEffect();
      final cmd = AddEffectCommand(effect);
      await cmd.execute(state, repo);
      await cmd.undo(state, repo);
      expect(state.effectsForClip('clip_1'), isEmpty);
    });

    test('description includes effect name', () {
      final cmd = AddEffectCommand(_makeEffect(type: EffectType.blur));
      expect(cmd.description, contains('Blur'));
    });
  });

  group('RemoveEffectCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip1);
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute removes effect; undo restores it', () async {
      final effect = _makeEffect();
      state.addEffect(effect);
      repo._effects[effect.id] = effect;

      final cmd = RemoveEffectCommand(effect);
      await cmd.execute(state, repo);
      expect(state.effectsForClip('clip_1'), isEmpty);

      await cmd.undo(state, repo);
      expect(state.effectsForClip('clip_1').length, 1);
    });
  });

  group('UpdateEffectCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip1);
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute applies after; undo restores before', () async {
      final before = _makeEffect(parameters: {'radius': 4.0},
          type: EffectType.blur);
      state.addEffect(before);
      repo._effects[before.id] = before;

      final after = before.copyWith(parameters: {'radius': 12.0});
      final cmd = UpdateEffectCommand(before: before, after: after);

      await cmd.execute(state, repo);
      expect(
        state.effectsForClip('clip_1').first.parameters['radius'],
        12.0,
      );

      await cmd.undo(state, repo);
      expect(
        state.effectsForClip('clip_1').first.parameters['radius'],
        4.0,
      );
    });

    test('description includes type name', () {
      final e = _makeEffect(type: EffectType.grain);
      final cmd = UpdateEffectCommand(before: e, after: e);
      expect(cmd.description, contains('Grain'));
    });
  });

  // ── HistoryManager with effect commands ────────────────────────────────────

  group('HistoryManager with effect commands', () {
    late TimelineState state;
    late _StubRepo repo;
    late HistoryManager history;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      state.addClip(_clip1);
      repo = _StubRepo();
      history = HistoryManager();
    });
    tearDown(() {
      state.dispose();
      history.dispose();
    });

    test('add/undo/redo roundtrip', () async {
      final effect = _makeEffect();
      await history.execute(AddEffectCommand(effect), state, repo);
      expect(state.effectsForClip('clip_1').length, 1);

      await history.undo(state, repo);
      expect(state.effectsForClip('clip_1'), isEmpty);

      await history.redo(state, repo);
      expect(state.effectsForClip('clip_1').length, 1);
    });
  });

  // ── AppConstants ───────────────────────────────────────────────────────────

  group('AppConstants (Phase 3)', () {
    test('maxEffectsPerClip is positive', () {
      expect(AppConstants.maxEffectsPerClip, greaterThan(0));
    });
  });

  // ── TimelineState effect methods ───────────────────────────────────────────

  group('TimelineState effect methods', () {
    late TimelineState state;

    setUp(() {
      state = TimelineState();
      state.addClip(_clip1);
    });
    tearDown(() => state.dispose());

    test('effectsForClip returns empty list initially', () {
      expect(state.effectsForClip('clip_1'), isEmpty);
    });

    test('addEffect grows the list', () {
      state.addEffect(_makeEffect());
      expect(state.effectsForClip('clip_1').length, 1);
    });

    test('removeEffect shrinks the list', () {
      final e = _makeEffect();
      state.addEffect(e);
      state.removeEffect(e);
      expect(state.effectsForClip('clip_1'), isEmpty);
    });

    test('updateEffect replaces the matching entry', () {
      final e = _makeEffect(parameters: {'radius': 4.0},
          type: EffectType.blur);
      state.addEffect(e);
      final updated = e.copyWith(parameters: {'radius': 20.0});
      state.updateEffect(updated);
      expect(
        state.effectsForClip('clip_1').first.parameters['radius'],
        20.0,
      );
    });

    test('setEffectsForClip replaces entire list', () {
      state.addEffect(_makeEffect(id: 'a'));
      state.addEffect(_makeEffect(id: 'b'));
      state.setEffectsForClip('clip_1', [_makeEffect(id: 'c')]);
      final list = state.effectsForClip('clip_1');
      expect(list.length, 1);
      expect(list.first.id, 'c');
    });
  });
}
