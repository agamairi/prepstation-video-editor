enum EffectType {
  colorCorrection,
  blur,
  vignette,
  grain,
  lut,
  chromaKey,
  sharpen,
  denoise,
  stabilize,
  colorWheels,
  curves,
  audioEq,
  audioCompressor,
  audioNoiseReduction,
  audioReverb;

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
      case EffectType.chromaKey:
        return 'Chroma Key';
      case EffectType.sharpen:
        return 'Sharpen';
      case EffectType.denoise:
        return 'Denoise';
      case EffectType.stabilize:
        return 'Stabilize';
      case EffectType.colorWheels:
        return 'Color Wheels';
      case EffectType.curves:
        return 'Curves';
      case EffectType.audioEq:
        return 'Equalizer';
      case EffectType.audioCompressor:
        return 'Compressor';
      case EffectType.audioNoiseReduction:
        return 'Noise Reduction';
      case EffectType.audioReverb:
        return 'Reverb';
    }
  }

  bool get isVideoEffect => switch (this) {
        audioEq || audioCompressor || audioNoiseReduction || audioReverb =>
          false,
        _ => true,
      };

  bool get isAudioEffect => !isVideoEffect;
}
