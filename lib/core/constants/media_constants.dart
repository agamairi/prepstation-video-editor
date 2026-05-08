abstract final class MediaConstants {
  // Supported video extensions
  static const List<String> videoExtensions = [
    'mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v', 'mts', 'm2ts',
  ];

  // Supported audio extensions
  static const List<String> audioExtensions = [
    'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'opus',
  ];

  // Supported image extensions
  static const List<String> imageExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'gif', 'bmp', 'tiff',
  ];

  // All media extensions combined
  static List<String> get allExtensions => [
    ...videoExtensions,
    ...audioExtensions,
    ...imageExtensions,
  ];

  // Supported LUT extensions
  static const List<String> lutExtensions = ['cube', '3dl'];

  // Supported subtitle extensions
  static const List<String> subtitleExtensions = ['srt', 'vtt', 'ass'];

  // FFmpeg probe timeout
  static const Duration probeTimeout = Duration(seconds: 30);

  // Export timeout per minute of footage
  static const Duration exportTimeoutPerMinute = Duration(minutes: 5);

  // Waveform samples per second
  static const int waveformSamplesPerSecond = 100;

  // Max concurrent thumbnail generation tasks
  static const int maxConcurrentThumbnails = 4;
}
