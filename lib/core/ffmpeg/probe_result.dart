import 'package:flutter/foundation.dart';
import 'package:fluxedit/core/project/project_model.dart';

/// Parsed output from `ffprobe -show_format -show_streams`.
@immutable
class ProbeResult {
  const ProbeResult({
    required this.filePath,
    required this.duration,
    required this.bitRate,
    required this.fileSize,
    required this.formatName,
    this.videoStream,
    this.audioStreams = const [],
  });

  final String filePath;
  final Duration duration;
  final int bitRate;
  final int fileSize;
  final String formatName;
  final VideoStreamInfo? videoStream;
  final List<AudioStreamInfo> audioStreams;

  bool get hasVideo => videoStream != null;
  bool get hasAudio => audioStreams.isNotEmpty;

  String get mediaType {
    if (hasVideo) return 'video';
    if (hasAudio) return 'audio';
    return 'unknown';
  }

  factory ProbeResult.fromJson(Map<String, dynamic> json) {
    final format = json['format'] as Map<String, dynamic>? ?? {};
    final streams = (json['streams'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final durationSecs =
        double.tryParse(format['duration']?.toString() ?? '0') ?? 0;
    final bitRateVal =
        int.tryParse(format['bit_rate']?.toString() ?? '0') ?? 0;
    final fileSizeVal =
        int.tryParse(format['size']?.toString() ?? '0') ?? 0;

    VideoStreamInfo? videoStream;
    final List<AudioStreamInfo> audioStreams = [];

    for (final stream in streams) {
      final codecType = stream['codec_type']?.toString();
      if (codecType == 'video' && videoStream == null) {
        videoStream = VideoStreamInfo.fromJson(stream);
      } else if (codecType == 'audio') {
        audioStreams.add(AudioStreamInfo.fromJson(stream));
      }
    }

    return ProbeResult(
      filePath: format['filename']?.toString() ?? '',
      duration: Duration(
        microseconds: (durationSecs * 1000000).round(),
      ),
      bitRate: bitRateVal,
      fileSize: fileSizeVal,
      formatName: format['format_name']?.toString() ?? '',
      videoStream: videoStream,
      audioStreams: audioStreams,
    );
  }

  /// Converts this ProbeResult into a [MediaAsset] for the given project.
  MediaAsset toMediaAsset({
    required String id,
    required String projectId,
    required String filePath,
    String? thumbnailPath,
  }) {
    final vs = videoStream;
    final as_ = audioStreams.isNotEmpty ? audioStreams.first : null;
    return MediaAsset(
      id: id,
      projectId: projectId,
      filePath: filePath,
      name: filePath.split('/').last,
      type: mediaType,
      duration: duration,
      width: vs?.width ?? 0,
      height: vs?.height ?? 0,
      frameRate: vs?.frameRate ?? 0,
      sampleRate: as_?.sampleRate ?? 0,
      channels: as_?.channels ?? 0,
      videoCodec: vs?.codecName ?? '',
      audioCodec: as_?.codecName ?? '',
      bitRate: bitRate,
      fileSize: fileSize,
      colorSpace: vs?.colorSpace ?? '',
      thumbnailPath: thumbnailPath,
      dateAdded: DateTime.now(),
    );
  }
}

@immutable
class VideoStreamInfo {
  const VideoStreamInfo({
    required this.width,
    required this.height,
    required this.frameRate,
    required this.codecName,
    required this.colorSpace,
    required this.pixelFormat,
    required this.bitRate,
    required this.profile,
  });

  final int width;
  final int height;
  final double frameRate;
  final String codecName;
  final String colorSpace;
  final String pixelFormat;
  final int bitRate;
  final String profile;

  factory VideoStreamInfo.fromJson(Map<String, dynamic> json) {
    final rFrameRate = json['r_frame_rate']?.toString() ?? '0/1';
    final parts = rFrameRate.split('/');
    double frameRate = 0;
    if (parts.length == 2) {
      final num = double.tryParse(parts[0]) ?? 0;
      final den = double.tryParse(parts[1]) ?? 1;
      frameRate = den != 0 ? num / den : 0;
    }
    return VideoStreamInfo(
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      frameRate: frameRate,
      codecName: json['codec_name']?.toString() ?? '',
      colorSpace: json['color_space']?.toString() ?? '',
      pixelFormat: json['pix_fmt']?.toString() ?? '',
      bitRate: int.tryParse(json['bit_rate']?.toString() ?? '0') ?? 0,
      profile: json['profile']?.toString() ?? '',
    );
  }
}

@immutable
class AudioStreamInfo {
  const AudioStreamInfo({
    required this.codecName,
    required this.sampleRate,
    required this.channels,
    required this.bitRate,
  });

  final String codecName;
  final int sampleRate;
  final int channels;
  final int bitRate;

  factory AudioStreamInfo.fromJson(Map<String, dynamic> json) {
    return AudioStreamInfo(
      codecName: json['codec_name']?.toString() ?? '',
      sampleRate: int.tryParse(json['sample_rate']?.toString() ?? '0') ?? 0,
      channels: (json['channels'] as num?)?.toInt() ?? 0,
      bitRate: int.tryParse(json['bit_rate']?.toString() ?? '0') ?? 0,
    );
  }
}
