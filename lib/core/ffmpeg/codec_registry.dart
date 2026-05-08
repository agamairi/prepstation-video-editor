import 'package:flutter/foundation.dart';

enum VideoCodec {
  h264,
  h265,
  vp9,
  prores,
  av1,
  passthrough,
}

enum AudioCodec {
  aac,
  mp3,
  pcm,
  opus,
  flac,
  passthrough,
}

enum ContainerFormat {
  mp4,
  mov,
  mkv,
  webm,
  gif,
}

enum ColorSpace {
  rec709,
  hdr10,
  hlg,
}

@immutable
class ExportPreset {
  const ExportPreset({
    required this.id,
    required this.label,
    required this.videoCodec,
    required this.audioCodec,
    required this.container,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.videoBitRate,
    required this.audioBitRate,
    this.colorSpace = ColorSpace.rec709,
    this.crf,
    this.isCustom = false,
  });

  final String id;
  final String label;
  final VideoCodec videoCodec;
  final AudioCodec audioCodec;
  final ContainerFormat container;
  final int width;
  final int height;
  final double frameRate;
  final int videoBitRate; // kbps
  final int audioBitRate; // kbps
  final ColorSpace colorSpace;
  final int? crf;
  final bool isCustom;

  String get containerExtension => switch (container) {
    ContainerFormat.mp4 => 'mp4',
    ContainerFormat.mov => 'mov',
    ContainerFormat.mkv => 'mkv',
    ContainerFormat.webm => 'webm',
    ContainerFormat.gif => 'gif',
  };
}

abstract final class CodecRegistry {
  static const List<ExportPreset> presets = [
    ExportPreset(
      id: 'youtube_1080p',
      label: 'YouTube 1080p H.264',
      videoCodec: VideoCodec.h264,
      audioCodec: AudioCodec.aac,
      container: ContainerFormat.mp4,
      width: 1920,
      height: 1080,
      frameRate: 30,
      videoBitRate: 8000,
      audioBitRate: 192,
      crf: 23,
    ),
    ExportPreset(
      id: 'youtube_4k',
      label: 'YouTube 4K H.264',
      videoCodec: VideoCodec.h264,
      audioCodec: AudioCodec.aac,
      container: ContainerFormat.mp4,
      width: 3840,
      height: 2160,
      frameRate: 30,
      videoBitRate: 35000,
      audioBitRate: 192,
      crf: 20,
    ),
    ExportPreset(
      id: 'instagram_reels',
      label: 'Instagram Reels 9:16',
      videoCodec: VideoCodec.h264,
      audioCodec: AudioCodec.aac,
      container: ContainerFormat.mp4,
      width: 1080,
      height: 1920,
      frameRate: 30,
      videoBitRate: 6000,
      audioBitRate: 128,
      crf: 23,
    ),
    ExportPreset(
      id: 'h265_1080p',
      label: 'H.265 1080p',
      videoCodec: VideoCodec.h265,
      audioCodec: AudioCodec.aac,
      container: ContainerFormat.mp4,
      width: 1920,
      height: 1080,
      frameRate: 30,
      videoBitRate: 4000,
      audioBitRate: 192,
      crf: 28,
    ),
    ExportPreset(
      id: 'vp9_webm',
      label: 'VP9 WebM',
      videoCodec: VideoCodec.vp9,
      audioCodec: AudioCodec.opus,
      container: ContainerFormat.webm,
      width: 1920,
      height: 1080,
      frameRate: 30,
      videoBitRate: 4000,
      audioBitRate: 128,
    ),
    ExportPreset(
      id: 'dnxhd',
      label: 'DNxHD 1080p',
      videoCodec: VideoCodec.passthrough,
      audioCodec: AudioCodec.pcm,
      container: ContainerFormat.mov,
      width: 1920,
      height: 1080,
      frameRate: 30,
      videoBitRate: 145000,
      audioBitRate: 1536,
    ),
  ];

  static String buildVideoCodecArgs(ExportPreset preset) {
    return switch (preset.videoCodec) {
      VideoCodec.h264 =>
        '-c:v libx264 -preset medium '
        '${preset.crf != null ? '-crf ${preset.crf}' : '-b:v ${preset.videoBitRate}k'} '
        '-profile:v high -pix_fmt yuv420p',
      VideoCodec.h265 =>
        '-c:v libx265 -preset medium '
        '${preset.crf != null ? '-crf ${preset.crf}' : '-b:v ${preset.videoBitRate}k'} '
        '-pix_fmt yuv420p',
      VideoCodec.vp9 =>
        '-c:v libvpx-vp9 -b:v ${preset.videoBitRate}k '
        '-deadline good -cpu-used 2',
      VideoCodec.av1 =>
        '-c:v libaom-av1 -crf ${preset.crf ?? 30} '
        '-b:v 0 -strict experimental',
      VideoCodec.prores =>
        '-c:v prores_ks -profile:v 2',
      VideoCodec.passthrough =>
        '-c:v dnxhd -b:v ${preset.videoBitRate}k '
        '-pix_fmt yuv422p',
    };
  }

  static String buildAudioCodecArgs(ExportPreset preset) {
    return switch (preset.audioCodec) {
      AudioCodec.aac =>
        '-c:a aac -b:a ${preset.audioBitRate}k -ar 48000',
      AudioCodec.mp3 =>
        '-c:a libmp3lame -b:a ${preset.audioBitRate}k',
      AudioCodec.pcm =>
        '-c:a pcm_s24le -ar 48000',
      AudioCodec.opus =>
        '-c:a libopus -b:a ${preset.audioBitRate}k -ar 48000',
      AudioCodec.flac =>
        '-c:a flac -ar 48000',
      AudioCodec.passthrough =>
        '-c:a copy',
    };
  }
}
