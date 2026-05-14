enum TransitionType {
  crossDissolve,
  fadeBlack,
  fadeWhite,
  wipeLeft,
  wipeRight,
  wipeUp,
  wipeDown,
  slide,
  slideRight,
  slideUp,
  slideDown,
  circleOpen,
  circleClose,
  radial,
  rectCrop,
  distance,
  fadeGrays,
  squeezeh,
  squeezev,
  zoomIn,
  hlwind,
  hrwind,
  coverleft,
  coverright,
  coverup,
  coverdown,
  revealleft,
  revealright,
  revealup,
  revealdown;

  String get displayName {
    switch (this) {
      case crossDissolve:
        return 'Cross Dissolve';
      case fadeBlack:
        return 'Fade to Black';
      case fadeWhite:
        return 'Fade to White';
      case wipeLeft:
        return 'Wipe Left';
      case wipeRight:
        return 'Wipe Right';
      case wipeUp:
        return 'Wipe Up';
      case wipeDown:
        return 'Wipe Down';
      case slide:
        return 'Slide Left';
      case slideRight:
        return 'Slide Right';
      case slideUp:
        return 'Slide Up';
      case slideDown:
        return 'Slide Down';
      case circleOpen:
        return 'Circle Open';
      case circleClose:
        return 'Circle Close';
      case radial:
        return 'Radial';
      case rectCrop:
        return 'Rectangle Crop';
      case distance:
        return 'Distance';
      case fadeGrays:
        return 'Fade Grays';
      case squeezeh:
        return 'Squeeze H';
      case squeezev:
        return 'Squeeze V';
      case zoomIn:
        return 'Zoom In';
      case hlwind:
        return 'Wind Left';
      case hrwind:
        return 'Wind Right';
      case coverleft:
        return 'Cover Left';
      case coverright:
        return 'Cover Right';
      case coverup:
        return 'Cover Up';
      case coverdown:
        return 'Cover Down';
      case revealleft:
        return 'Reveal Left';
      case revealright:
        return 'Reveal Right';
      case revealup:
        return 'Reveal Up';
      case revealdown:
        return 'Reveal Down';
    }
  }

  /// FFmpeg xfade transition= parameter value.
  String get xfadeParam {
    switch (this) {
      case crossDissolve:
        return 'dissolve';
      case fadeBlack:
        return 'fadeblack';
      case fadeWhite:
        return 'fadewhite';
      case wipeLeft:
        return 'wipeleft';
      case wipeRight:
        return 'wiperight';
      case wipeUp:
        return 'wipeup';
      case wipeDown:
        return 'wipedown';
      case slide:
        return 'slideleft';
      case slideRight:
        return 'slideright';
      case slideUp:
        return 'slideup';
      case slideDown:
        return 'slidedown';
      case circleOpen:
        return 'circleopen';
      case circleClose:
        return 'circleclose';
      case radial:
        return 'radial';
      case rectCrop:
        return 'rectcrop';
      case distance:
        return 'distance';
      case fadeGrays:
        return 'fadegrays';
      case squeezeh:
        return 'squeezeh';
      case squeezev:
        return 'squeezev';
      case zoomIn:
        return 'zoomin';
      case hlwind:
        return 'hlwind';
      case hrwind:
        return 'hrwind';
      case coverleft:
        return 'coverleft';
      case coverright:
        return 'coverright';
      case coverup:
        return 'coverup';
      case coverdown:
        return 'coverdown';
      case revealleft:
        return 'revealleft';
      case revealright:
        return 'revealright';
      case revealup:
        return 'revealup';
      case revealdown:
        return 'revealdown';
    }
  }

  static TransitionType? fromId(String id) {
    for (final type in values) {
      if (type.name == id) return type;
    }
    return null;
  }
}
