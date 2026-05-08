enum EffectType {
  colorCorrection,
  blur,
  vignette,
  grain,
  lut;

  String get displayName {
    switch (this) {
      case EffectType.colorCorrection:
        return 'Color Correction';
      case EffectType.blur:
        return 'Blur';
      case EffectType.vignette:
        return 'Vignette';
      case EffectType.grain:
        return 'Film Grain';
      case EffectType.lut:
        return 'LUT';
    }
  }
}
