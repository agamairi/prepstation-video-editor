import 'package:flutter_test/flutter_test.dart';
import 'package:fluxedit/core/help/help_data.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/core/timeline/track_model.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

ClipModel _makeClip({
  String id = 'clip_1',
  String trackId = 'track_v1',
  Duration start = Duration.zero,
  Duration end = const Duration(seconds: 10),
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
    );

// ── HelpData ───────────────────────────────────────────────────────────────

void main() {
  group('HelpData entries', () {
    test('entries list is non-empty', () {
      expect(HelpData.entries, isNotEmpty);
    });

    test('every entry has a non-empty title', () {
      for (final e in HelpData.entries) {
        expect(e.title, isNotEmpty,
            reason: 'entry ${e.title} has empty title');
      }
    });

    test('every entry has a non-empty description', () {
      for (final e in HelpData.entries) {
        expect(e.description, isNotEmpty,
            reason: 'entry ${e.title} has empty description');
      }
    });

    test('categoryOrder contains all HelpCategory values', () {
      expect(
        HelpData.categoryOrder.toSet(),
        HelpCategory.values.toSet(),
      );
    });

    test('entriesForCategory returns only matching entries', () {
      for (final cat in HelpCategory.values) {
        final filtered = HelpData.entriesForCategory(cat);
        for (final e in filtered) {
          expect(e.category, cat);
        }
      }
    });

    test('every category has at least one entry', () {
      for (final cat in HelpCategory.values) {
        expect(
          HelpData.entriesForCategory(cat),
          isNotEmpty,
          reason: '$cat has no entries',
        );
      }
    });

    test('categoryLabel returns non-empty string for every category', () {
      for (final cat in HelpCategory.values) {
        expect(HelpData.categoryLabel(cat), isNotEmpty);
      }
    });

    test('playback category has Play/Pause entry', () {
      final playback = HelpData.entriesForCategory(HelpCategory.playback);
      expect(
        playback.any((e) => e.title.contains('Play')),
        isTrue,
      );
    });

    test('editing category has Undo entry with Cmd+Z shortcut', () {
      final editing = HelpData.entriesForCategory(HelpCategory.editing);
      final undo = editing.firstWhere(
        (e) => e.title == 'Undo',
        orElse: () => throw TestFailure('Undo entry not found'),
      );
      expect(undo.shortcut, contains('Z'));
    });

    test('tools category has Select Tool and Blade Tool entries', () {
      final tools = HelpData.entriesForCategory(HelpCategory.tools);
      expect(tools.any((e) => e.title.contains('Select')), isTrue);
      expect(tools.any((e) => e.title.contains('Blade')), isTrue);
    });

    test('entries with shortcuts are all non-null shortcuts', () {
      final withShortcuts =
          HelpData.entries.where((e) => e.shortcut != null).toList();
      for (final e in withShortcuts) {
        expect(e.shortcut, isNotEmpty);
      }
    });

    test('HelpCategory has correct number of values', () {
      expect(HelpCategory.values.length, 5);
    });
  });

  // ── HelpCategory labels ────────────────────────────────────────────────────

  group('HelpCategory labels', () {
    test('timeline label is Timeline', () {
      expect(HelpData.categoryLabel(HelpCategory.timeline), 'Timeline');
    });

    test('playback label is Playback', () {
      expect(HelpData.categoryLabel(HelpCategory.playback), 'Playback');
    });

    test('tools label is Tools', () {
      expect(HelpData.categoryLabel(HelpCategory.tools), 'Tools');
    });

    test('editing label is Editing', () {
      expect(HelpData.categoryLabel(HelpCategory.editing), 'Editing');
    });

    test('mobile label is Mobile', () {
      expect(HelpData.categoryLabel(HelpCategory.mobile), 'Mobile');
    });
  });

  // ── Timeline scroll offset ─────────────────────────────────────────────────

  group('TimelineState scroll offset', () {
    late TimelineState state;

    setUp(() {
      state = TimelineState();
    });
    tearDown(() => state.dispose());

    test('initial scroll offset is zero', () {
      expect(state.scrollOffset, Duration.zero);
    });

    test('setScrollOffset updates scrollOffset', () {
      state.setScrollOffset(const Duration(seconds: 5));
      expect(state.scrollOffset, const Duration(seconds: 5));
    });

    test('setScrollOffset clamps to zero for negative values', () {
      state.setScrollOffset(const Duration(seconds: -10));
      expect(state.scrollOffset, Duration.zero);
    });

    test('setScrollOffset notifies listeners', () {
      var notified = false;
      state.addListener(() => notified = true);
      state.setScrollOffset(const Duration(seconds: 3));
      expect(notified, isTrue);
    });
  });

  // ── ClipModel duplicate semantics ──────────────────────────────────────────

  group('ClipModel duplicate via copyWith', () {
    test('copyWith with new id creates distinct clip', () {
      final original = _makeClip(id: 'clip_a');
      final dupe = original.copyWith(
        id: 'clip_b',
        startOnTimeline: original.endOnTimeline,
        endOnTimeline: original.endOnTimeline + original.duration,
      );
      expect(dupe.id, 'clip_b');
      expect(dupe.startOnTimeline, original.endOnTimeline);
      expect(dupe.duration, original.duration);
      expect(dupe.mediaId, original.mediaId);
    });

    test('duplicate preserves mediaInPoint and mediaOutPoint', () {
      final original = _makeClip();
      final dupe = original.copyWith(
        id: 'clip_dup',
        startOnTimeline: const Duration(seconds: 10),
        endOnTimeline: const Duration(seconds: 20),
      );
      expect(dupe.mediaInPoint, original.mediaInPoint);
      expect(dupe.mediaOutPoint, original.mediaOutPoint);
    });

    test('duplicate does not equal original', () {
      final original = _makeClip(id: 'a');
      final dupe = original.copyWith(id: 'b');
      expect(dupe, isNot(equals(original)));
    });
  });

  // ── TimelineState with duplicate clip ─────────────────────────────────────

  group('TimelineState duplicated clip', () {
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

    test('adding two clips with different ids is allowed', () {
      final a = _makeClip(id: 'a', start: Duration.zero, end: const Duration(seconds: 5));
      final b = _makeClip(
          id: 'b',
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 10));
      state.addClip(a);
      state.addClip(b);
      expect(state.clips.length, 2);
    });

    test('duration accounts for both clips', () {
      final a = _makeClip(id: 'a', start: Duration.zero, end: const Duration(seconds: 5));
      final b = _makeClip(
          id: 'b',
          start: const Duration(seconds: 5),
          end: const Duration(seconds: 10));
      state.addClip(a);
      state.addClip(b);
      expect(state.duration, const Duration(seconds: 10));
    });
  });
}
