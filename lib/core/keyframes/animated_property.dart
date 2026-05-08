/// String identifiers for clip-level animatable parameters.
abstract final class AnimatedProperty {
  static const String opacity = 'opacity';
  static const String speed = 'speed';

  /// Returns the parameter ID for an effect parameter.
  static String effectParam(String effectId, String paramKey) =>
      'effect.$effectId.$paramKey';

  /// Parses an effect parameter ID into [effectId, paramKey], or null if
  /// the id does not follow the effect parameter format.
  static ({String effectId, String paramKey})? parseEffectParam(String id) {
    if (!id.startsWith('effect.')) return null;
    final parts = id.split('.');
    if (parts.length != 3) return null;
    return (effectId: parts[1], paramKey: parts[2]);
  }
}
