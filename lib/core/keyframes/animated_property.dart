/// String identifiers for clip-level animatable parameters.
abstract final class AnimatedProperty {
  static const String opacity = 'opacity';
  static const String speed = 'speed';
  static const String volume = 'volume';

  // Transform
  static const String posX = 'posX';
  static const String posY = 'posY';
  static const String scaleX = 'scaleX';
  static const String scaleY = 'scaleY';
  static const String rotation = 'rotation';
  static const String anchorX = 'anchorX';
  static const String anchorY = 'anchorY';

  // Crop
  static const String cropLeft = 'cropLeft';
  static const String cropRight = 'cropRight';
  static const String cropTop = 'cropTop';
  static const String cropBottom = 'cropBottom';

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
