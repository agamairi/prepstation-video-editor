enum TransitionType {
  crossDissolve,
  fadeBlack,
  wipeLeft,
  wipeRight,
  slide;

  String get displayName {
    switch (this) {
      case crossDissolve:
        return 'Cross Dissolve';
      case fadeBlack:
        return 'Fade to Black';
      case wipeLeft:
        return 'Wipe Left';
      case wipeRight:
        return 'Wipe Right';
      case slide:
        return 'Slide';
    }
  }

  /// FFmpeg xfade transition= parameter value.
  String get xfadeParam {
    switch (this) {
      case crossDissolve:
        return 'dissolve';
      case fadeBlack:
        return 'fadeblack';
      case wipeLeft:
        return 'wipeleft';
      case wipeRight:
        return 'wiperight';
      case slide:
        return 'slideleft';
    }
  }

  static TransitionType? fromId(String id) {
    for (final type in values) {
      if (type.name == id) return type;
    }
    return null;
  }
}
