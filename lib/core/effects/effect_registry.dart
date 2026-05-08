import 'package:fluxedit/core/effects/effect_model.dart';
import 'package:fluxedit/core/effects/effect_type.dart';

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
        return {};
    }
  }

  /// Returns parameter ranges [min, max] for each parameter name.
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
        return {};
    }
  }

  /// Builds the FFmpeg filter string for one effect.
  /// Returns an empty string if the effect is disabled or produces no filter.
  static String buildFilterString(EffectInstance effect) {
    if (!effect.isEnabled) return '';
    final p = effect.parameters;
    switch (effect.type) {
      case EffectType.colorCorrection:
        final brightness = p['brightness'] ?? 0.0;
        final contrast = p['contrast'] ?? 1.0;
        final saturation = p['saturation'] ?? 1.0;
        final hue = p['hue'] ?? 0.0;
        return 'eq=brightness=$brightness:contrast=$contrast'
            ':saturation=$saturation:hue=$hue';
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
    }
  }

  /// Builds a comma-chained filter segment for a list of effects on one clip.
  /// Returns the complete segment with pad labels, or '' if there are no
  /// active filter-producing effects.
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
}
