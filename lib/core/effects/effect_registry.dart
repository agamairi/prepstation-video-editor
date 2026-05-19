import 'package:prepstation/core/effects/effect_model.dart';
import 'package:prepstation/core/effects/effect_type.dart';

abstract final class EffectRegistry {
  static Map<String, double> defaultParameters(EffectType type) {
    switch (type) {
      case EffectType.colorCorrection:
        return {
          'brightness': 0.0,
          'contrast': 1.0,
          'saturation': 1.0,
          'hue': 0.0,
        };
      case EffectType.blur:
        return {'radius': 4.0};
      case EffectType.vignette:
        return {'angle': 1.5708};
      case EffectType.grain:
        return {'strength': 20.0};
      case EffectType.lut:
        return {'intensity': 1.0};
      case EffectType.chromaKey:
        return {
          'colorR': 0.0,
          'colorG': 1.0,
          'colorB': 0.0,
          'similarity': 0.3,
          'blend': 0.05,
        };
      case EffectType.sharpen:
        return {'amount': 1.0, 'size': 5.0};
      case EffectType.denoise:
        return {'strength': 4.0, 'patchSize': 7.0, 'searchSize': 15.0};
      case EffectType.stabilize:
        return {'smoothing': 10.0, 'zoom': 0.0};
      case EffectType.colorWheels:
        return {
          'liftR': 1.0, 'liftG': 1.0, 'liftB': 1.0,
          'gammaR': 1.0, 'gammaG': 1.0, 'gammaB': 1.0,
          'gainR': 1.0, 'gainG': 1.0, 'gainB': 1.0,
          'temperature': 0.0, 'tint': 0.0,
        };
      case EffectType.curves:
        return {
          'masterBlack': 0.0,
          'masterWhite': 1.0,
          'masterGamma': 1.0,
          'redBlack': 0.0,
          'redWhite': 1.0,
          'redGamma': 1.0,
          'greenBlack': 0.0,
          'greenWhite': 1.0,
          'greenGamma': 1.0,
          'blueBlack': 0.0,
          'blueWhite': 1.0,
          'blueGamma': 1.0,
        };
      case EffectType.audioEq:
        return {
          'lowGain': 0.0,
          'midGain': 0.0,
          'highGain': 0.0,
          'lowFreq': 200.0,
          'highFreq': 3000.0,
        };
      case EffectType.audioCompressor:
        return {
          'threshold': -20.0,
          'ratio': 4.0,
          'attack': 20.0,
          'release': 250.0,
          'makeup': 0.0,
        };
      case EffectType.audioNoiseReduction:
        return {'amount': 12.0, 'floor': -30.0};
      case EffectType.audioReverb:
        return {
          'roomSize': 0.5,
          'damping': 0.5,
          'wetLevel': 0.3,
          'dryLevel': 0.7,
        };
    }
  }

  static Map<String, (double, double)> parameterRanges(EffectType type) {
    switch (type) {
      case EffectType.colorCorrection:
        return {
          'brightness': (-1.0, 1.0),
          'contrast': (0.0, 3.0),
          'saturation': (0.0, 3.0),
          'hue': (-3.14159, 3.14159),
        };
      case EffectType.blur:
        return {'radius': (0.0, 40.0)};
      case EffectType.vignette:
        return {'angle': (0.0, 3.14159)};
      case EffectType.grain:
        return {'strength': (0.0, 100.0)};
      case EffectType.lut:
        return {'intensity': (0.0, 1.0)};
      case EffectType.chromaKey:
        return {
          'colorR': (0.0, 1.0),
          'colorG': (0.0, 1.0),
          'colorB': (0.0, 1.0),
          'similarity': (0.01, 0.5),
          'blend': (0.0, 0.3),
        };
      case EffectType.sharpen:
        return {'amount': (0.0, 5.0), 'size': (3.0, 13.0)};
      case EffectType.denoise:
        return {
          'strength': (1.0, 20.0),
          'patchSize': (3.0, 15.0),
          'searchSize': (5.0, 25.0),
        };
      case EffectType.stabilize:
        return {'smoothing': (1.0, 30.0), 'zoom': (-1.0, 1.0)};
      case EffectType.colorWheels:
        return {
          'liftR': (0.0, 2.0), 'liftG': (0.0, 2.0), 'liftB': (0.0, 2.0),
          'gammaR': (0.0, 2.0), 'gammaG': (0.0, 2.0), 'gammaB': (0.0, 2.0),
          'gainR': (0.0, 2.0), 'gainG': (0.0, 2.0), 'gainB': (0.0, 2.0),
          'temperature': (-1.0, 1.0), 'tint': (-1.0, 1.0),
        };
      case EffectType.curves:
        return {
          'masterBlack': (0.0, 1.0), 'masterWhite': (0.0, 1.0),
          'masterGamma': (0.1, 4.0),
          'redBlack': (0.0, 1.0), 'redWhite': (0.0, 1.0),
          'redGamma': (0.1, 4.0),
          'greenBlack': (0.0, 1.0), 'greenWhite': (0.0, 1.0),
          'greenGamma': (0.1, 4.0),
          'blueBlack': (0.0, 1.0), 'blueWhite': (0.0, 1.0),
          'blueGamma': (0.1, 4.0),
        };
      case EffectType.audioEq:
        return {
          'lowGain': (-20.0, 20.0),
          'midGain': (-20.0, 20.0),
          'highGain': (-20.0, 20.0),
          'lowFreq': (60.0, 500.0),
          'highFreq': (1000.0, 10000.0),
        };
      case EffectType.audioCompressor:
        return {
          'threshold': (-60.0, 0.0),
          'ratio': (1.0, 20.0),
          'attack': (0.1, 200.0),
          'release': (10.0, 2000.0),
          'makeup': (0.0, 30.0),
        };
      case EffectType.audioNoiseReduction:
        return {'amount': (0.0, 40.0), 'floor': (-60.0, 0.0)};
      case EffectType.audioReverb:
        return {
          'roomSize': (0.0, 1.0),
          'damping': (0.0, 1.0),
          'wetLevel': (0.0, 1.0),
          'dryLevel': (0.0, 1.0),
        };
    }
  }

  /// Builds the FFmpeg filter string for one effect.
  static String buildFilterString(EffectInstance effect) {
    if (!effect.isEnabled) return '';
    final p = effect.parameters;
    switch (effect.type) {
      case EffectType.colorCorrection:
        final brightness = p['brightness'] ?? 0.0;
        final contrast = p['contrast'] ?? 1.0;
        final saturation = p['saturation'] ?? 1.0;
        final hue = p['hue'] ?? 0.0;
        final eq = 'eq=brightness=$brightness:contrast=$contrast'
            ':saturation=$saturation';
        if (hue != 0.0) return '$eq,hue=h=${(hue * 180 / 3.14159).toStringAsFixed(2)}';
        return eq;
      case EffectType.blur:
        final sigma = (p['radius'] ?? 4.0).clamp(0.0, 100.0);
        return 'gblur=sigma=$sigma';
      case EffectType.vignette:
        final angle = (p['angle'] ?? 1.5708).clamp(0.0, 3.14159);
        return 'vignette=angle=$angle';
      case EffectType.grain:
        final strength = (p['strength'] ?? 20.0).round().clamp(0, 100);
        return 'noise=alls=$strength:allf=t+u';
      case EffectType.lut:
        return '';
      case EffectType.chromaKey:
        final r = (p['colorR'] ?? 0.0).clamp(0.0, 1.0);
        final g = (p['colorG'] ?? 1.0).clamp(0.0, 1.0);
        final b = (p['colorB'] ?? 0.0).clamp(0.0, 1.0);
        final rH = (r * 255).round().toRadixString(16).padLeft(2, '0');
        final gH = (g * 255).round().toRadixString(16).padLeft(2, '0');
        final bH = (b * 255).round().toRadixString(16).padLeft(2, '0');
        final sim = (p['similarity'] ?? 0.3).clamp(0.01, 0.5);
        final blend = (p['blend'] ?? 0.05).clamp(0.0, 0.3);
        return 'chromakey=0x$rH$gH$bH:similarity=$sim:blend=$blend';
      case EffectType.sharpen:
        final amount = (p['amount'] ?? 1.0).clamp(0.0, 5.0);
        final size = (p['size'] ?? 5.0).round().clamp(3, 13);
        final sizeOdd = size.isEven ? size + 1 : size;
        return 'unsharp=$sizeOdd:$sizeOdd:$amount:$sizeOdd:$sizeOdd:$amount';
      case EffectType.denoise:
        final s = (p['strength'] ?? 4.0).clamp(1.0, 20.0);
        return 'nlmeans=s=$s';
      case EffectType.stabilize:
        return '';
      case EffectType.colorWheels:
        final lr = p['liftR'] ?? 1.0;
        final lg = p['liftG'] ?? 1.0;
        final lb = p['liftB'] ?? 1.0;
        final gr = p['gammaR'] ?? 1.0;
        final gg = p['gammaG'] ?? 1.0;
        final gb = p['gammaB'] ?? 1.0;
        final gnr = p['gainR'] ?? 1.0;
        final gng = p['gainG'] ?? 1.0;
        final gnb = p['gainB'] ?? 1.0;
        return 'colorbalance=rs=${lr - 1}:gs=${lg - 1}:bs=${lb - 1}'
            ':rm=${gr - 1}:gm=${gg - 1}:bm=${gb - 1}'
            ':rh=${gnr - 1}:gh=${gng - 1}:bh=${gnb - 1}';
      case EffectType.curves:
        final mb = p['masterBlack'] ?? 0.0;
        final mw = p['masterWhite'] ?? 1.0;
        final mg = p['masterGamma'] ?? 1.0;
        return 'curves=master='
            "'${mb.toStringAsFixed(2)}/${(mb * mg).clamp(0.0, 1.0).toStringAsFixed(2)}"
            ':${mw.toStringAsFixed(2)}/${mw.toStringAsFixed(2)}'
            "'"
            ',eq=gamma=$mg';
      case EffectType.audioEq:
        final lowG = p['lowGain'] ?? 0.0;
        final midG = p['midGain'] ?? 0.0;
        final highG = p['highGain'] ?? 0.0;
        final lowF = (p['lowFreq'] ?? 200.0).round();
        final highF = (p['highFreq'] ?? 3000.0).round();
        return 'equalizer=f=$lowF:t=h:w=200:g=$lowG,'
            'equalizer=f=${((lowF + highF) / 2).round()}:t=h:w=$highF:g=$midG,'
            'equalizer=f=${highF * 2}:t=h:w=2000:g=$highG';
      case EffectType.audioCompressor:
        final thresh = p['threshold'] ?? -20.0;
        final ratio = p['ratio'] ?? 4.0;
        final attack = p['attack'] ?? 20.0;
        final release = p['release'] ?? 250.0;
        final makeup = p['makeup'] ?? 0.0;
        return 'acompressor=threshold=${thresh}dB:ratio=$ratio'
            ':attack=$attack:release=$release:makeup=${makeup}dB';
      case EffectType.audioNoiseReduction:
        final amount = (p['amount'] ?? 12.0).round();
        final floor = p['floor'] ?? -30.0;
        return 'afftdn=nr=$amount:nf=$floor';
      case EffectType.audioReverb:
        final wet = p['wetLevel'] ?? 0.3;
        final dry = p['dryLevel'] ?? 0.7;
        final damping = p['damping'] ?? 0.5;
        final room = p['roomSize'] ?? 0.5;
        final delays = (room * 80 + 20).round();
        final decays = (1.0 - damping).clamp(0.1, 0.9);
        return 'aecho=$dry:$wet:$delays:$decays';
    }
  }

  /// Builds a comma-chained filter segment for a list of effects on one clip.
  static String buildClipEffectChain(
    String inputLabel,
    String outputLabel,
    List<EffectInstance> effects,
  ) {
    final active = effects
        .where((e) => e.isEnabled)
        .toList()
      ..sort((a, b) => a.stackIndex.compareTo(b.stackIndex));

    final filters = active
        .map(buildFilterString)
        .where((s) => s.isNotEmpty)
        .toList();

    if (filters.isEmpty) return '';
    return '[$inputLabel]${filters.join(',')}[$outputLabel]';
  }

  /// Builds audio-only effect chain for a clip's audio stream.
  static String buildAudioEffectChain(
    String inputLabel,
    String outputLabel,
    List<EffectInstance> effects,
  ) {
    final active = effects
        .where((e) => e.isEnabled && e.type.isAudioEffect)
        .toList()
      ..sort((a, b) => a.stackIndex.compareTo(b.stackIndex));

    final filters = active
        .map(buildFilterString)
        .where((s) => s.isNotEmpty)
        .toList();

    if (filters.isEmpty) return '';
    return '[$inputLabel]${filters.join(',')}[$outputLabel]';
  }
}
