import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_registry.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/transitions/transition_type.dart';

/// Builds FFmpeg filtergraph strings for export-time rendering.
class FiltergraphBuilder {
  const FiltergraphBuilder();

  /// Constructs a complete FFmpeg filtergraph for a list of clips on a single
  /// video track. When [effectsByClipId] is provided, per-clip effect chains
  /// are injected before the concat filter.
  String buildConcatGraph(
    List<ClipModel> clips, {
    Map<String, List<EffectInstance>>? effectsByClipId,
  }) {
    if (clips.isEmpty) return '';

    final effects = effectsByClipId ?? {};
    final hasAnyEffects =
        effects.values.any((list) => list.any((e) => e.isEnabled));

    if (!hasAnyEffects) {
      return _simpleConcatGraph(clips);
    }

    final sb = StringBuffer();

    // Per-clip effect chains
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final chain = EffectRegistry.buildClipEffectChain(
        '$i:v',
        'v$i',
        clipEffects,
      );
      if (chain.isNotEmpty) {
        sb.write('$chain;');
      }
    }

    // Concat inputs: use effect output label if chain exists, else raw input
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final hasChain = EffectRegistry.buildClipEffectChain(
        '$i:v',
        'v$i',
        clipEffects,
      ).isNotEmpty;
      sb.write(hasChain ? '[v$i][$i:a]' : '[$i:v][$i:a]');
    }
    sb.write('concat=n=${clips.length}:v=1:a=1[outv][outa]');
    return sb.toString();
  }

  String _simpleConcatGraph(List<ClipModel> clips) {
    final sb = StringBuffer();
    for (var i = 0; i < clips.length; i++) {
      sb.write('[$i:v][$i:a]');
    }
    sb.write('concat=n=${clips.length}:v=1:a=1[outv][outa]');
    return sb.toString();
  }

  /// Builds an input argument string for all clips.
  String buildInputArgs(List<ClipModel> clips, List<String> filePaths) {
    assert(clips.length == filePaths.length, 'clips and filePaths must match');
    final sb = StringBuffer();
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final path = filePaths[i];
      final inSecs = clip.mediaInPoint.inMilliseconds / 1000.0;
      final duration = clip.mediaDuration.inMilliseconds / 1000.0;
      sb.write('-ss $inSecs -t $duration -i "$path" ');
    }
    return sb.toString().trim();
  }

  /// Builds a filtergraph that handles both cuts and transitions between clips.
  ///
  /// Adjacent clips where `clips[i].transitionOutId != null` are connected with
  /// FFmpeg `xfade` (video) and `acrossfade` (audio). Remaining boundaries are
  /// assembled with `concat`. Falls back to [buildConcatGraph] when no clip has
  /// a transition set.
  String buildTransitionGraph(
    List<ClipModel> clips, {
    Map<String, List<EffectInstance>>? effectsByClipId,
  }) {
    if (clips.length < 2) return '';

    final hasAnyTransition = clips.any((c) => c.transitionOutId != null);
    if (!hasAnyTransition) {
      return buildConcatGraph(clips, effectsByClipId: effectsByClipId);
    }

    final effects = effectsByClipId ?? {};
    final sb = StringBuffer();

    // ── Step 1: Per-clip effect chains ─────────────────────────────────────
    // clipVideoLabels[i] is the video label (without brackets) after effects.
    final clipVideoLabels = List<String>.generate(clips.length, (i) => '$i:v');
    for (var i = 0; i < clips.length; i++) {
      final clipEffects = (effects[clips[i].id] ?? [])
          .where((e) => e.isEnabled)
          .toList();
      if (clipEffects.isNotEmpty) {
        final outLabel = 'eff${i}v';
        final chain =
            EffectRegistry.buildClipEffectChain('$i:v', outLabel, clipEffects);
        if (chain.isNotEmpty) {
          sb.write('$chain;');
          clipVideoLabels[i] = outLabel;
        }
      }
    }

    // ── Step 2: Partition clips into transition segments ───────────────────
    // A segment is a maximal run of clips where each adjacent pair is connected
    // by a transition. Cuts start a new segment.
    final segments = <List<int>>[];
    var segStart = 0;
    while (segStart < clips.length) {
      var segEnd = segStart;
      while (
          segEnd < clips.length - 1 && clips[segEnd].transitionOutId != null) {
        segEnd++;
      }
      segments.add(List.generate(segEnd - segStart + 1, (j) => segStart + j));
      segStart = segEnd + 1;
    }

    // ── Step 3: Build xfade chains within each segment ─────────────────────
    final segVideoLabels = <String>[];
    final segAudioLabels = <String>[];

    for (final segIndices in segments) {
      if (segIndices.length == 1) {
        final i = segIndices.first;
        segVideoLabels.add(clipVideoLabels[i]);
        segAudioLabels.add('$i:a');
      } else {
        var currVideoLabel = clipVideoLabels[segIndices.first];
        var currAudioLabel = '${segIndices.first}:a';
        var accDurSecs =
            clips[segIndices.first].duration.inMicroseconds / 1e6;
        final segId = segIndices.first;
        var xfIdx = 0;

        for (var k = 1; k < segIndices.length; k++) {
          final prevGlobalIdx = segIndices[k - 1];
          final nextGlobalIdx = segIndices[k];
          final prevClip = clips[prevGlobalIdx];

          final transType = TransitionType.fromId(prevClip.transitionOutId!);
          final xfParam = transType?.xfadeParam ?? 'dissolve';
          final durSecs =
              prevClip.transitionOutDuration.inMicroseconds / 1e6;
          final offset = (accDurSecs - durSecs).clamp(0.0, double.maxFinite);

          final outV = 'xfv${segId}_$xfIdx';
          final outA = 'xfa${segId}_$xfIdx';

          sb.write(
            '[$currVideoLabel][${clipVideoLabels[nextGlobalIdx]}]'
            'xfade=transition=$xfParam'
            ':duration=${_fmt(durSecs)}'
            ':offset=${_fmt(offset)}'
            '[$outV];',
          );
          sb.write(
            '[$currAudioLabel][$nextGlobalIdx:a]'
            'acrossfade=d=${_fmt(durSecs)}'
            '[$outA];',
          );

          currVideoLabel = outV;
          currAudioLabel = outA;
          accDurSecs +=
              clips[nextGlobalIdx].duration.inMicroseconds / 1e6 - durSecs;
          xfIdx++;
        }

        segVideoLabels.add(currVideoLabel);
        segAudioLabels.add(currAudioLabel);
      }
    }

    // ── Step 4: Concat segment outputs ─────────────────────────────────────
    if (segments.length == 1) {
      // Pass-through rename to standard [outv][outa] labels.
      sb.write('[${segVideoLabels.first}]null[outv];'
          '[${segAudioLabels.first}]anull[outa]');
    } else {
      for (var i = 0; i < segVideoLabels.length; i++) {
        sb.write('[${segVideoLabels[i]}][${segAudioLabels[i]}]');
      }
      sb.write('concat=n=${segments.length}:v=1:a=1[outv][outa]');
    }

    return sb.toString();
  }

  static String _fmt(double v) => v.toStringAsFixed(3);

  /// Validates that a filtergraph string is well-formed (basic check).
  bool validate(String filtergraph) {
    if (filtergraph.isEmpty) return false;
    final openBrackets = '['.allMatches(filtergraph).length;
    final closeBrackets = ']'.allMatches(filtergraph).length;
    return openBrackets == closeBrackets;
  }
}
