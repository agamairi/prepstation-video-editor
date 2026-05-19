// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/ffmpeg/filtergraph_builder.dart';
import 'package:prepstation/core/segmentation/isolation_mode.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';

void main() {
  group('IsolationMode', () {
    test('displayName returns human-readable labels', () {
      expect(IsolationMode.transparent.displayName, 'Transparent');
      expect(IsolationMode.blur.displayName, 'Blur Background');
      expect(IsolationMode.solidColor.displayName, 'Solid Color');
    });

    test('fromName round-trips all values', () {
      for (final mode in IsolationMode.values) {
        expect(IsolationMode.fromName(mode.name), mode);
      }
    });

    test('fromName falls back to transparent for unknown', () {
      expect(IsolationMode.fromName('unknown'), IsolationMode.transparent);
    });

    test('has exactly 3 values', () {
      expect(IsolationMode.values.length, 3);
    });
  });

  group('AppConstants — isolation', () {
    test('blur radius min < default < max', () {
      expect(AppConstants.minIsolationBlurRadius, lessThan(AppConstants.defaultIsolationBlurRadius));
      expect(AppConstants.defaultIsolationBlurRadius, lessThan(AppConstants.maxIsolationBlurRadius));
    });

    test('default blur radius is 20', () {
      expect(AppConstants.defaultIsolationBlurRadius, 20.0);
    });
  });

  group('ClipModel — isolation fields', () {
    ClipModel _baseClip() => const ClipModel(
          id: 'c1',
          trackId: 't1',
          mediaId: 'm1',
          type: ClipType.video,
          startOnTimeline: Duration.zero,
          endOnTimeline: Duration(seconds: 5),
          mediaInPoint: Duration.zero,
          mediaOutPoint: Duration(seconds: 5),
        );

    test('defaults: isolation disabled, transparent, no mask', () {
      final clip = _baseClip();
      expect(clip.isolationEnabled, false);
      expect(clip.isolationMode, IsolationMode.transparent);
      expect(clip.isolationMaskPath, isNull);
      expect(clip.isolationProcessing, false);
      expect(clip.isolationBlurRadius, AppConstants.defaultIsolationBlurRadius);
    });

    test('copyWith enables isolation', () {
      final clip = _baseClip().copyWith(isolationEnabled: true);
      expect(clip.isolationEnabled, true);
    });

    test('copyWith changes mode', () {
      final clip = _baseClip().copyWith(isolationMode: IsolationMode.blur);
      expect(clip.isolationMode, IsolationMode.blur);
    });

    test('copyWith sets mask path', () {
      final clip = _baseClip().copyWith(isolationMaskPath: '/path/mask.mp4');
      expect(clip.isolationMaskPath, '/path/mask.mp4');
    });

    test('copyWith clears mask path to null', () {
      final clip = _baseClip()
          .copyWith(isolationMaskPath: '/path/mask.mp4')
          .copyWith(isolationMaskPath: null);
      expect(clip.isolationMaskPath, isNull);
    });

    test('copyWith changes color', () {
      final clip = _baseClip().copyWith(isolationColorValue: 0xFFFF0000);
      expect(clip.isolationColorValue, 0xFFFF0000);
    });

    test('copyWith changes blur radius', () {
      final clip = _baseClip().copyWith(isolationBlurRadius: 40.0);
      expect(clip.isolationBlurRadius, 40.0);
    });

    test('copyWith sets processing flag', () {
      final clip = _baseClip().copyWith(isolationProcessing: true);
      expect(clip.isolationProcessing, true);
    });

    test('copyWith preserves isolation fields when not specified', () {
      final clip = _baseClip().copyWith(
        isolationEnabled: true,
        isolationMode: IsolationMode.solidColor,
        isolationColorValue: 0xFFABCDEF,
        isolationBlurRadius: 42.0,
        isolationMaskPath: '/path/mask.mp4',
      );
      final updated = clip.copyWith(name: 'renamed');
      expect(updated.isolationEnabled, true);
      expect(updated.isolationMode, IsolationMode.solidColor);
      expect(updated.isolationColorValue, 0xFFABCDEF);
      expect(updated.isolationBlurRadius, 42.0);
      expect(updated.isolationMaskPath, '/path/mask.mp4');
    });

    test('selection rect defaults to null', () {
      final clip = _baseClip();
      expect(clip.isolationSelectionLeft, isNull);
      expect(clip.isolationSelectionTop, isNull);
      expect(clip.isolationSelectionRight, isNull);
      expect(clip.isolationSelectionBottom, isNull);
    });

    test('copyWith sets selection rect', () {
      final clip = _baseClip().copyWith(
        isolationSelectionLeft: 0.1,
        isolationSelectionTop: 0.2,
        isolationSelectionRight: 0.8,
        isolationSelectionBottom: 0.9,
      );
      expect(clip.isolationSelectionLeft, 0.1);
      expect(clip.isolationSelectionTop, 0.2);
      expect(clip.isolationSelectionRight, 0.8);
      expect(clip.isolationSelectionBottom, 0.9);
    });

    test('copyWith clears selection rect to null', () {
      final clip = _baseClip().copyWith(
        isolationSelectionLeft: 0.1,
        isolationSelectionTop: 0.2,
        isolationSelectionRight: 0.8,
        isolationSelectionBottom: 0.9,
      ).copyWith(
        isolationSelectionLeft: null,
        isolationSelectionTop: null,
        isolationSelectionRight: null,
        isolationSelectionBottom: null,
      );
      expect(clip.isolationSelectionLeft, isNull);
      expect(clip.isolationSelectionTop, isNull);
      expect(clip.isolationSelectionRight, isNull);
      expect(clip.isolationSelectionBottom, isNull);
    });

    test('copyWith preserves selection rect when not specified', () {
      final clip = _baseClip().copyWith(
        isolationSelectionLeft: 0.1,
        isolationSelectionTop: 0.2,
        isolationSelectionRight: 0.8,
        isolationSelectionBottom: 0.9,
      );
      final updated = clip.copyWith(name: 'renamed');
      expect(updated.isolationSelectionLeft, 0.1);
      expect(updated.isolationSelectionTop, 0.2);
      expect(updated.isolationSelectionRight, 0.8);
      expect(updated.isolationSelectionBottom, 0.9);
    });
  });

  group('TimelineState — isolation clip updates', () {
    late TimelineState state;

    setUp(() {
      state = TimelineState();
      state.addClip(const ClipModel(
        id: 'c1',
        trackId: 't1',
        mediaId: 'm1',
        type: ClipType.video,
        startOnTimeline: Duration.zero,
        endOnTimeline: Duration(seconds: 5),
        mediaInPoint: Duration.zero,
        mediaOutPoint: Duration(seconds: 5),
      ));
    });

    test('updateClip toggles isolation', () {
      final clip = state.clips.first;
      state.updateClip(clip.copyWith(isolationEnabled: true));
      expect(state.clips.first.isolationEnabled, true);
    });

    test('updateClip changes isolation mode', () {
      final clip = state.clips.first;
      state.updateClip(clip.copyWith(
        isolationEnabled: true,
        isolationMode: IsolationMode.blur,
      ));
      expect(state.clips.first.isolationMode, IsolationMode.blur);
    });

    test('updateClip sets mask path', () {
      final clip = state.clips.first;
      state.updateClip(clip.copyWith(isolationMaskPath: '/masks/c1.mp4'));
      expect(state.clips.first.isolationMaskPath, '/masks/c1.mp4');
    });

    test('updateClip sets selection rect', () {
      final clip = state.clips.first;
      state.updateClip(clip.copyWith(
        isolationSelectionLeft: 0.1,
        isolationSelectionTop: 0.2,
        isolationSelectionRight: 0.8,
        isolationSelectionBottom: 0.9,
      ));
      expect(state.clips.first.isolationSelectionLeft, 0.1);
      expect(state.clips.first.isolationSelectionTop, 0.2);
      expect(state.clips.first.isolationSelectionRight, 0.8);
      expect(state.clips.first.isolationSelectionBottom, 0.9);
    });

    test('updateClip clears selection rect and mask path', () {
      final clip = state.clips.first;
      state.updateClip(clip.copyWith(
        isolationSelectionLeft: 0.1,
        isolationSelectionTop: 0.2,
        isolationSelectionRight: 0.8,
        isolationSelectionBottom: 0.9,
        isolationMaskPath: '/masks/c1.mp4',
      ));
      state.updateClip(state.clips.first.copyWith(
        isolationSelectionLeft: null,
        isolationSelectionTop: null,
        isolationSelectionRight: null,
        isolationSelectionBottom: null,
        isolationMaskPath: null,
      ));
      expect(state.clips.first.isolationSelectionLeft, isNull);
      expect(state.clips.first.isolationMaskPath, isNull);
    });
  });

  group('FiltergraphBuilder — isolation graph', () {
    const builder = FiltergraphBuilder();

    ClipModel _isolatedClip({
      IsolationMode mode = IsolationMode.transparent,
      double blurRadius = 20.0,
      int colorValue = 0xFF00FF00,
    }) =>
        ClipModel(
          id: 'c1',
          trackId: 't1',
          mediaId: 'm1',
          type: ClipType.video,
          startOnTimeline: Duration.zero,
          endOnTimeline: const Duration(seconds: 5),
          mediaInPoint: Duration.zero,
          mediaOutPoint: const Duration(seconds: 5),
          isolationEnabled: true,
          isolationMode: mode,
          isolationBlurRadius: blurRadius,
          isolationColorValue: colorValue,
        );

    test('transparent mode uses alphamerge', () {
      final graph = builder.buildIsolationGraph(
        _isolatedClip(mode: IsolationMode.transparent),
        videoInputIdx: 0,
        maskInputIdx: 1,
      );
      expect(graph, contains('alphamerge'));
      expect(graph, contains('[isov]'));
      expect(graph, contains('format=rgba'));
    });

    test('blur mode uses boxblur', () {
      final graph = builder.buildIsolationGraph(
        _isolatedClip(mode: IsolationMode.blur, blurRadius: 30.0),
        videoInputIdx: 0,
        maskInputIdx: 1,
      );
      expect(graph, contains('boxblur=30:30'));
      expect(graph, contains('alphamerge'));
      expect(graph, contains('overlay'));
      expect(graph, contains('[isov]'));
    });

    test('solidColor mode uses color source and overlay', () {
      final graph = builder.buildIsolationGraph(
        _isolatedClip(mode: IsolationMode.solidColor, colorValue: 0xFF00FF00),
        videoInputIdx: 0,
        maskInputIdx: 1,
      );
      expect(graph, contains('color=c=0x'));
      expect(graph, contains('overlay'));
      expect(graph, contains('[isov]'));
    });

    test('graph has balanced brackets', () {
      for (final mode in IsolationMode.values) {
        final graph = builder.buildIsolationGraph(
          _isolatedClip(mode: mode),
          videoInputIdx: 0,
          maskInputIdx: 1,
        );
        final open = '['.allMatches(graph).length;
        final close = ']'.allMatches(graph).length;
        expect(open, close, reason: 'unbalanced brackets in $mode');
      }
    });

    test('transparent mode with target resolution includes scale', () {
      final graph = builder.buildIsolationGraph(
        _isolatedClip(mode: IsolationMode.transparent),
        videoInputIdx: 0,
        maskInputIdx: 1,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(graph, contains('scale=1920:1080'));
    });
  });
}
