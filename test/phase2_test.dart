import 'package:flutter_test/flutter_test.dart';
import 'package:fluxedit/core/audio/waveform_data.dart';
import 'package:fluxedit/core/history/clip_commands.dart';
import 'package:fluxedit/core/history/history_manager.dart';
import 'package:fluxedit/core/project/project_repository.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/core/timeline/timeline_tool.dart';
import 'package:fluxedit/core/timeline/track_model.dart';

// ── Minimal stub repository ────────────────────────────────────────────────

class _StubRepo implements ProjectRepository {
  final _clips = <String, ClipModel>{};

  @override
  Future<void> saveClip(ClipModel clip) async => _clips[clip.id] = clip;

  @override
  Future<void> deleteClip(String clipId) async => _clips.remove(clipId);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value();
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

const _clip3 = ClipModel(
  id: 'clip_3',
  trackId: 'track_v1',
  mediaId: 'asset_3',
  type: ClipType.video,
  startOnTimeline: Duration(seconds: 10),
  endOnTimeline: Duration(seconds: 15),
  mediaInPoint: Duration.zero,
  mediaOutPoint: Duration(seconds: 5),
);

void main() {
  // ── HistoryManager ─────────────────────────────────────────────────────────

  group('HistoryManager', () {
    late TimelineState state;
    late _StubRepo repo;
    late HistoryManager history;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      repo = _StubRepo();
      history = HistoryManager();
    });

    tearDown(() {
      state.dispose();
      history.dispose();
    });

    test('initial state: canUndo=false, canRedo=false', () {
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('execute: applies command and grows undo stack', () async {
      await history.execute(const AddClipCommand(_clip1), state, repo);
      expect(state.clips.length, 1);
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('undo: reverts command and grows redo stack', () async {
      await history.execute(const AddClipCommand(_clip1), state, repo);
      await history.undo(state, repo);
      expect(state.clips, isEmpty);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
    });

    test('redo: re-applies command', () async {
      await history.execute(const AddClipCommand(_clip1), state, repo);
      await history.undo(state, repo);
      await history.redo(state, repo);
      expect(state.clips.length, 1);
      expect(history.canRedo, isFalse);
    });

    test('execute after undo clears redo stack', () async {
      await history.execute(const AddClipCommand(_clip1), state, repo);
      await history.undo(state, repo);
      await history.execute(
        const AddClipCommand(_clip2),
        state,
        repo,
      );
      expect(history.canRedo, isFalse);
      expect(state.clips.length, 1);
      expect(state.clips.first.id, 'clip_2');
    });

    test('undo on empty stack is a no-op', () async {
      await history.undo(state, repo);
      expect(state.clips, isEmpty);
    });

    test('redo on empty stack is a no-op', () async {
      await history.redo(state, repo);
      expect(state.clips, isEmpty);
    });

    test('nextUndoDescription returns description of top command', () async {
      await history.execute(const AddClipCommand(_clip1), state, repo);
      expect(history.nextUndoDescription, 'Add Clip');
    });

    test('clear empties both stacks', () async {
      await history.execute(const AddClipCommand(_clip1), state, repo);
      history.clear();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });
  });

  // ── AddClipCommand ─────────────────────────────────────────────────────────

  group('AddClipCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute adds clip; undo removes it', () async {
      const cmd = AddClipCommand(_clip1);
      await cmd.execute(state, repo);
      expect(state.clips.length, 1);
      await cmd.undo(state, repo);
      expect(state.clips, isEmpty);
    });
  });

  // ── RemoveClipCommand ──────────────────────────────────────────────────────

  group('RemoveClipCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      state.addClip(_clip1);
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute removes clip; undo restores it', () async {
      const cmd = RemoveClipCommand(_clip1);
      await cmd.execute(state, repo);
      expect(state.clips, isEmpty);
      await cmd.undo(state, repo);
      expect(state.clips.length, 1);
      expect(state.clips.first.id, 'clip_1');
    });
  });

  // ── UpdateClipCommand ──────────────────────────────────────────────────────

  group('UpdateClipCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      state.addClip(_clip1);
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute applies new clip; undo restores old clip', () async {
      final updated = _clip1.copyWith(opacity: 0.5);
      final cmd = UpdateClipCommand(
        before: _clip1,
        after: updated,
        description: 'Set Opacity',
      );
      await cmd.execute(state, repo);
      expect(state.clips.first.opacity, 0.5);
      await cmd.undo(state, repo);
      expect(state.clips.first.opacity, 1.0);
    });

    test('description is preserved', () {
      final cmd = UpdateClipCommand(
        before: _clip1,
        after: _clip1.copyWith(speed: 2.0),
        description: 'Set Speed',
      );
      expect(cmd.description, 'Set Speed');
    });
  });

  // ── SplitClipCommand ───────────────────────────────────────────────────────

  group('SplitClipCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      state.addClip(_clip1);
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute splits into two parts; undo restores original', () async {
      // Left part keeps the original id; right gets a new id.
      final left = _clip1.copyWith(
        endOnTimeline: const Duration(seconds: 2),
        mediaOutPoint: const Duration(seconds: 2),
      );
      final right = _clip1.copyWith(
        id: 'clip_1_r',
        startOnTimeline: const Duration(seconds: 2),
        mediaInPoint: const Duration(seconds: 2),
      );
      final cmd = SplitClipCommand(
        originalClip: _clip1,
        leftClip: left,
        rightClip: right,
      );
      await cmd.execute(state, repo);
      expect(state.clips.length, 2);
      // Right clip must exist
      expect(state.clips.any((c) => c.id == 'clip_1_r'), isTrue);
      // Left clip has new end time
      final leftInState = state.clips.firstWhere((c) => c.id == 'clip_1');
      expect(leftInState.endOnTimeline, const Duration(seconds: 2));

      await cmd.undo(state, repo);
      expect(state.clips.length, 1);
      expect(state.clips.first.id, 'clip_1');
      // Original end time restored
      expect(state.clips.first.endOnTimeline, const Duration(seconds: 5));
    });
  });

  // ── RippleDeleteCommand ────────────────────────────────────────────────────

  group('RippleDeleteCommand', () {
    late TimelineState state;
    late _StubRepo repo;

    setUp(() {
      state = TimelineState();
      state.addClip(_clip1);
      state.addClip(_clip2);
      state.addClip(_clip3);
      repo = _StubRepo();
    });
    tearDown(() => state.dispose());

    test('execute deletes clip and shifts subsequent clips', () async {
      // Delete clip1 (0..5s); clip2 (5..10) and clip3 (10..15) should shift left by 5s
      final shifted2 = _clip2.copyWith(
        startOnTimeline: Duration.zero,
        endOnTimeline: const Duration(seconds: 5),
      );
      final shifted3 = _clip3.copyWith(
        startOnTimeline: const Duration(seconds: 5),
        endOnTimeline: const Duration(seconds: 10),
      );
      final cmd = RippleDeleteCommand(
        deletedClip: _clip1,
        originalSubsequentClips: [_clip2, _clip3],
        shiftedSubsequentClips: [shifted2, shifted3],
      );

      await cmd.execute(state, repo);
      expect(state.clips.length, 2);
      expect(state.clips.any((c) => c.id == 'clip_1'), isFalse);
      final s2 = state.clips.firstWhere((c) => c.id == 'clip_2');
      expect(s2.startOnTimeline, Duration.zero);

      await cmd.undo(state, repo);
      expect(state.clips.length, 3);
      final orig2 = state.clips.firstWhere((c) => c.id == 'clip_2');
      expect(orig2.startOnTimeline, const Duration(seconds: 5));
    });

    test('description is "Ripple Delete"', () {
      const cmd = RippleDeleteCommand(
        deletedClip: _clip1,
        originalSubsequentClips: [],
        shiftedSubsequentClips: [],
      );
      expect(cmd.description, 'Ripple Delete');
    });
  });

  // ── TimelineTool ───────────────────────────────────────────────────────────

  group('TimelineTool', () {
    test('select is the first value', () {
      expect(TimelineTool.values.first, TimelineTool.select);
    });

    test('blade is distinct from select', () {
      expect(TimelineTool.blade, isNot(TimelineTool.select));
    });
  });

  // ── WaveformData ───────────────────────────────────────────────────────────

  group('WaveformData', () {
    final waveform = WaveformData(
      assetId: 'asset_1',
      peaks: List.generate(200, (i) => i / 200.0),
      sampleRate: 200,
    );

    test('totalDuration is correct', () {
      expect(waveform.totalDuration, const Duration(seconds: 1));
    });

    test('peaksForRange returns requested pixel count', () {
      final peaks = waveform.peaksForRange(
        Duration.zero,
        const Duration(seconds: 1),
        100,
      );
      expect(peaks.length, 100);
    });

    test('peaksForRange returns correct count for sub-range', () {
      final peaks = waveform.peaksForRange(
        const Duration(milliseconds: 250),
        const Duration(milliseconds: 750),
        50,
      );
      expect(peaks.length, 50);
    });

    test('peaksForRange handles zero pixel count', () {
      final peaks = waveform.peaksForRange(Duration.zero, const Duration(seconds: 1), 0);
      expect(peaks, isEmpty);
    });

    test('empty waveform returns zeros', () {
      const empty = WaveformData(assetId: 'x', peaks: [], sampleRate: 200);
      final peaks = empty.peaksForRange(Duration.zero, const Duration(seconds: 1), 10);
      expect(peaks, everyElement(0.0));
    });

    test('peaksForRange values are in [0, 1]', () {
      final peaks = waveform.peaksForRange(
        Duration.zero,
        const Duration(seconds: 1),
        50,
      );
      for (final p in peaks) {
        expect(p, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  // ── Multi-command undo/redo sequence ───────────────────────────────────────

  group('HistoryManager multi-command sequence', () {
    late TimelineState state;
    late _StubRepo repo;
    late HistoryManager history;

    setUp(() {
      state = TimelineState();
      state.addTrack(_track);
      repo = _StubRepo();
      history = HistoryManager();
    });
    tearDown(() {
      state.dispose();
      history.dispose();
    });

    test('undo/redo across multiple commands maintains correct state', () async {
      await history.execute(const AddClipCommand(_clip1), state, repo);
      await history.execute(const AddClipCommand(_clip2), state, repo);
      expect(state.clips.length, 2);

      await history.undo(state, repo); // undo add clip2
      expect(state.clips.length, 1);
      expect(state.clips.first.id, 'clip_1');

      await history.undo(state, repo); // undo add clip1
      expect(state.clips, isEmpty);

      await history.redo(state, repo); // redo add clip1
      expect(state.clips.length, 1);

      await history.redo(state, repo); // redo add clip2
      expect(state.clips.length, 2);
    });
  });
}
