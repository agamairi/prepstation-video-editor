import 'dart:math' as math;
import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_registry.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/transitions/transition_type.dart';

/// Builds FFmpeg filtergraph strings for export-time rendering.
class FiltergraphBuilder {
  const FiltergraphBuilder();

  /// Builds per-clip transform/crop/flip/reverse filter chain.
  String _buildClipTransformChain(ClipModel clip) {
    final filters = <String>[];

    // Reverse
    if (clip.isReversed) {
      filters.add('reverse');
    }

    // Flip
    if (clip.flipHorizontal) filters.add('hflip');
    if (clip.flipVertical) filters.add('vflip');

    // Crop (fraction-based: cropLeft 0.1 = remove 10% from left)
    final cl = clip.cropLeft;
    final cr = clip.cropRight;
    final ct = clip.cropTop;
    final cb = clip.cropBottom;
    if (cl > 0 || cr > 0 || ct > 0 || cb > 0) {
      filters.add(
        'crop=w=iw*(${1.0 - cl - cr}):h=ih*(${1.0 - ct - cb})'
        ':x=iw*$cl:y=ih*$ct',
      );
    }

    // Scale (scaleX/scaleY relative to original)
    if (clip.scaleX != 1.0 || clip.scaleY != 1.0) {
      filters.add(
        'scale=w=iw*${clip.scaleX}:h=ih*${clip.scaleY}'
        ':flags=lanczos',
      );
    }

    // Rotation (degrees → radians for FFmpeg rotate filter)
    if (clip.rotation != 0.0) {
      final rad = clip.rotation * math.pi / 180.0;
      filters.add(
        "rotate=$rad:fillcolor=black@0:ow='hypot(iw,ih)':oh='hypot(iw,ih)'",
      );
    }

    // Position (overlay onto black canvas at comp size is handled by
    // the overlay step in the final graph — here we just pad if needed)
    // We handle posX/posY via overlay in the export pipeline.

    return filters.join(',');
  }

  /// Builds audio filters for a single clip (volume, reverse, audio effects).
  String _buildClipAudioChain(
    ClipModel clip,
    List<EffectInstance> effects,
  ) {
    final filters = <String>[];

    if (clip.isReversed) filters.add('areverse');
    if (clip.volume != 1.0) filters.add('volume=${clip.volume}');

    // Audio effects
    final audioChain = EffectRegistry.buildAudioEffectChain('', '', effects);
    if (audioChain.isNotEmpty) {
      // buildAudioEffectChain returns [label]filters[label], extract just filters
      final parts = audioChain.split(']');
      if (parts.length > 2) {
        filters.add(parts[1]);
      }
    }

    return filters.join(',');
  }

  /// Constructs a complete FFmpeg filtergraph for a list of clips on a single
  /// video track. When [effectsByClipId] is provided, per-clip effect chains
  /// are injected before the concat filter.
  String buildConcatGraph(
    List<ClipModel> clips, {
    Map<String, List<EffectInstance>>? effectsByClipId,
  }) {
    if (clips.isEmpty) return '';

    final effects = effectsByClipId ?? {};
    final sb = StringBuffer();
    var hasAnyChain = false;

    // Per-clip video chains (effects + transform)
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final videoEffects = clipEffects.where((e) => e.type.isVideoEffect).toList();

      final effectChain = EffectRegistry.buildClipEffectChain(
        '$i:v', 'v$i', videoEffects,
      );
      final transformChain = _buildClipTransformChain(clip);
      final audioChain = _buildClipAudioChain(clip, clipEffects);

      if (effectChain.isNotEmpty || transformChain.isNotEmpty) {
        hasAnyChain = true;
        if (effectChain.isNotEmpty && transformChain.isNotEmpty) {
          // Chain: effect output → transform
          sb.write('$effectChain;[v$i]$transformChain[vt$i];');
        } else if (effectChain.isNotEmpty) {
          sb.write('$effectChain;');
        } else {
          sb.write('[$i:v]$transformChain[vt$i];');
        }
      }

      if (audioChain.isNotEmpty) {
        hasAnyChain = true;
        sb.write('[$i:a]$audioChain[a$i];');
      }
    }

    if (!hasAnyChain) return _simpleConcatGraph(clips);

    // Concat inputs
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final videoEffects = clipEffects.where((e) => e.type.isVideoEffect).toList();
      final effectChain = EffectRegistry.buildClipEffectChain(
        '$i:v', 'v$i', videoEffects,
      );
      final transformChain = _buildClipTransformChain(clip);
      final audioChain = _buildClipAudioChain(clip, clipEffects);

      // Video label
      if (effectChain.isNotEmpty && transformChain.isNotEmpty) {
        sb.write('[vt$i]');
      } else if (effectChain.isNotEmpty) {
        sb.write('[v$i]');
      } else if (transformChain.isNotEmpty) {
        sb.write('[vt$i]');
      } else {
        sb.write('[$i:v]');
      }

      // Audio label
      sb.write(audioChain.isNotEmpty ? '[a$i]' : '[$i:a]');
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

    // ── Step 1: Per-clip effect + transform chains ─────────────────────────
    final clipVideoLabels = List<String>.generate(clips.length, (i) => '$i:v');
    final clipAudioLabels = List<String>.generate(clips.length, (i) => '$i:a');

    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = (effects[clip.id] ?? [])
          .where((e) => e.isEnabled)
          .toList();
      final videoEffects = clipEffects.where((e) => e.type.isVideoEffect).toList();

      final effectChain = EffectRegistry.buildClipEffectChain(
        '$i:v', 'eff${i}v', videoEffects,
      );
      final transformChain = _buildClipTransformChain(clip);

      if (effectChain.isNotEmpty && transformChain.isNotEmpty) {
        sb.write('$effectChain;[eff${i}v]$transformChain[vt$i];');
        clipVideoLabels[i] = 'vt$i';
      } else if (effectChain.isNotEmpty) {
        sb.write('$effectChain;');
        clipVideoLabels[i] = 'eff${i}v';
      } else if (transformChain.isNotEmpty) {
        sb.write('[$i:v]$transformChain[vt$i];');
        clipVideoLabels[i] = 'vt$i';
      }

      final audioChain = _buildClipAudioChain(clip, clipEffects);
      if (audioChain.isNotEmpty) {
        sb.write('[$i:a]$audioChain[a$i];');
        clipAudioLabels[i] = 'a$i';
      }
    }

    // ── Step 2: Partition clips into transition segments ───────────────────
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

    // ── Step 3: Build xfade chains within each segment ────────────────────
    final segVideoLabels = <String>[];
    final segAudioLabels = <String>[];

    for (final segIndices in segments) {
      if (segIndices.length == 1) {
        final i = segIndices.first;
        segVideoLabels.add(clipVideoLabels[i]);
        segAudioLabels.add(clipAudioLabels[i]);
      } else {
        var currVideoLabel = clipVideoLabels[segIndices.first];
        var currAudioLabel = clipAudioLabels[segIndices.first];
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
            '[$currAudioLabel][${clipAudioLabels[nextGlobalIdx]}]'
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

    // ── Step 4: Concat segment outputs ────────────────────────────────────
    if (segments.length == 1) {
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
