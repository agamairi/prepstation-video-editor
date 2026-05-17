import 'dart:math' as math;
import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_registry.dart';
import 'package:fluxedit/core/segmentation/isolation_mode.dart';
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

  /// Scale+pad filter to normalize a stream to target resolution.
  static String scaleFilter(int w, int h) =>
      'scale=$w:$h:force_original_aspect_ratio=decrease,pad=$w:$h:(ow-iw)/2:(oh-ih)/2,setsar=1';

  /// Constructs a complete FFmpeg filtergraph for a list of clips on a single
  /// video track. When [effectsByClipId] is provided, per-clip effect chains
  /// are injected before the concat filter.
  String buildConcatGraph(
    List<ClipModel> clips, {
    Map<String, List<EffectInstance>>? effectsByClipId,
    int? targetWidth,
    int? targetHeight,
  }) {
    if (clips.isEmpty) return '';

    final effects = effectsByClipId ?? {};
    final sb = StringBuffer();
    final normalize = targetWidth != null && targetHeight != null;
    final scale = normalize ? scaleFilter(targetWidth, targetHeight) : '';

    // Per-clip video + audio chains
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final videoEffects = clipEffects.where((e) => e.type.isVideoEffect).toList();

      final effectChain = EffectRegistry.buildClipEffectChain(
        '$i:v', 'eff$i', videoEffects,
      );
      final transformChain = _buildClipTransformChain(clip);
      final audioChain = _buildClipAudioChain(clip, clipEffects);

      // Build video chain: effects → transform → scale normalize
      final videoFilters = <String>[];
      String currentLabel = '$i:v';

      if (effectChain.isNotEmpty) {
        sb.write('$effectChain;');
        currentLabel = 'eff$i';
      }

      if (transformChain.isNotEmpty) {
        videoFilters.add(transformChain);
      }
      if (normalize) {
        videoFilters.add(scale);
      }

      if (videoFilters.isNotEmpty) {
        sb.write('[$currentLabel]${videoFilters.join(",")}[norm$i];');
      }

      if (audioChain.isNotEmpty) {
        sb.write('[$i:a]$audioChain[a$i];');
      }
    }

    // Concat inputs
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final videoEffects = clipEffects.where((e) => e.type.isVideoEffect).toList();
      final effectChain = EffectRegistry.buildClipEffectChain(
        '$i:v', 'eff$i', videoEffects,
      );
      final transformChain = _buildClipTransformChain(clip);
      final audioChain = _buildClipAudioChain(clip, clipEffects);

      // Video label: if we wrote any video filters (transform or normalize), use norm$i
      final hasVideoFilters = transformChain.isNotEmpty || normalize;
      if (hasVideoFilters) {
        sb.write('[norm$i]');
      } else if (effectChain.isNotEmpty) {
        sb.write('[eff$i]');
      } else {
        sb.write('[$i:v]');
      }

      // Audio label
      sb.write(audioChain.isNotEmpty ? '[a$i]' : '[$i:a]');
    }
    sb.write('concat=n=${clips.length}:v=1:a=1[outv][outa]');
    return sb.toString();
  }


  /// Builds a video-only filtergraph (no audio streams in inputs).
  String buildVideoOnlyGraph(
    List<ClipModel> clips, {
    Map<String, List<EffectInstance>>? effectsByClipId,
    int? targetWidth,
    int? targetHeight,
  }) {
    if (clips.isEmpty) return '';

    final effects = effectsByClipId ?? {};
    final sb = StringBuffer();
    final normalize = targetWidth != null && targetHeight != null;
    final scale = normalize ? scaleFilter(targetWidth, targetHeight) : '';

    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final videoEffects =
          clipEffects.where((e) => e.isEnabled && e.type.isVideoEffect).toList();

      final effectChain = EffectRegistry.buildClipEffectChain(
        '$i:v', 'eff$i', videoEffects,
      );
      final transformChain = _buildClipTransformChain(clip);

      String currentLabel = '$i:v';
      final videoFilters = <String>[];

      if (effectChain.isNotEmpty) {
        sb.write('$effectChain;');
        currentLabel = 'eff$i';
      }

      if (transformChain.isNotEmpty) videoFilters.add(transformChain);
      if (normalize) videoFilters.add(scale);

      if (videoFilters.isNotEmpty) {
        sb.write('[$currentLabel]${videoFilters.join(",")}[norm$i];');
      }
    }

    // Concat inputs
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final clipEffects = effects[clip.id] ?? [];
      final videoEffects =
          clipEffects.where((e) => e.isEnabled && e.type.isVideoEffect).toList();
      final effectChain = EffectRegistry.buildClipEffectChain(
        '$i:v', 'eff$i', videoEffects,
      );
      final transformChain = _buildClipTransformChain(clip);

      final hasVideoFilters = transformChain.isNotEmpty || normalize;
      if (hasVideoFilters) {
        sb.write('[norm$i]');
      } else if (effectChain.isNotEmpty) {
        sb.write('[eff$i]');
      } else {
        sb.write('[$i:v]');
      }
    }
    sb.write('concat=n=${clips.length}:v=1:a=0[outv]');
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
    int? targetWidth,
    int? targetHeight,
  }) {
    if (clips.length < 2) return '';

    final hasAnyTransition = clips.any((c) => c.transitionOutId != null);
    if (!hasAnyTransition) {
      return buildConcatGraph(clips,
          effectsByClipId: effectsByClipId,
          targetWidth: targetWidth,
          targetHeight: targetHeight);
    }

    final effects = effectsByClipId ?? {};
    final sb = StringBuffer();
    final normalize = targetWidth != null && targetHeight != null;
    final scale = normalize ? scaleFilter(targetWidth, targetHeight) : '';

    // ── Step 1: Per-clip effect + transform + normalize chains ────────────
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

      String currentLabel = '$i:v';
      final videoFilters = <String>[];

      if (effectChain.isNotEmpty) {
        sb.write('$effectChain;');
        currentLabel = 'eff${i}v';
      }

      if (transformChain.isNotEmpty) videoFilters.add(transformChain);
      if (normalize) videoFilters.add(scale);

      if (videoFilters.isNotEmpty) {
        sb.write('[$currentLabel]${videoFilters.join(",")}[norm$i];');
        clipVideoLabels[i] = 'norm$i';
      } else if (effectChain.isNotEmpty) {
        clipVideoLabels[i] = 'eff${i}v';
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

  // ignore_for_file: lines_longer_than_80_chars
  /// Builds an isolation filtergraph for a single clip.
  ///
  /// [videoInputIdx] is the input index of the original video.
  /// [maskInputIdx] is the input index of the grayscale mask video.
  /// Returns the filtergraph fragment producing `[isov]` output label.
  String buildIsolationGraph(
    ClipModel clip, {
    required int videoInputIdx,
    required int maskInputIdx,
    int? targetWidth,
    int? targetHeight,
  }) {
    final sb = StringBuffer();
    final normalize = targetWidth != null && targetHeight != null;
    final scale = normalize ? scaleFilter(targetWidth, targetHeight) : '';

    // Scale mask to match video dimensions
    sb.write('[$maskInputIdx:v]format=gray');
    if (normalize) {
      sb.write(',${scaleFilter(targetWidth, targetHeight)}');
    }
    sb.write('[mask];');

    switch (clip.isolationMode) {
      case IsolationMode.transparent:
        sb.write('[$videoInputIdx:v]format=rgba[rgbsrc];');
        sb.write('[rgbsrc][mask]alphamerge[isov]');

      case IsolationMode.blur:
        final r = clip.isolationBlurRadius.toInt();
        sb.write('[$videoInputIdx:v]split[orig][bg];');
        sb.write('[bg]boxblur=$r:$r[blurred];');
        sb.write('[orig]format=rgba[rgborig];');
        sb.write('[rgborig][mask]alphamerge[subject];');
        if (normalize) {
          sb.write('[blurred]$scale[normbg];');
          sb.write('[normbg][subject]overlay=format=auto[isov]');
        } else {
          sb.write('[blurred][subject]overlay=format=auto[isov]');
        }

      case IsolationMode.solidColor:
        final hex = clip.isolationColorValue
            .toRadixString(16)
            .padLeft(8, '0')
            .substring(2);
        final w = targetWidth ?? 1920;
        final h = targetHeight ?? 1080;
        sb.write(
          'color=c=0x$hex:s=${w}x$h:r=30[colorbg];',
        );
        sb.write('[$videoInputIdx:v]format=rgba[rgbsrc2];');
        sb.write('[rgbsrc2][mask]alphamerge[subject2];');
        sb.write('[colorbg][subject2]overlay=format=auto:shortest=1[isov]');
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
