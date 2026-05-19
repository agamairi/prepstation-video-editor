import 'package:flutter/foundation.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/timeline/composition_model.dart';

@immutable
class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.projectId,
    required this.filePath,
    required this.name,
    required this.type,
    required this.duration,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.sampleRate,
    required this.channels,
    required this.videoCodec,
    required this.audioCodec,
    required this.bitRate,
    required this.fileSize,
    required this.colorSpace,
    required this.dateAdded,
    this.proxyPath,
    this.thumbnailPath,
    this.binId,
  });

  final String id;
  final String projectId;
  final String filePath;
  final String name;
  final String type; // 'video', 'audio', 'image'
  final Duration duration;
  final int width;
  final int height;
  final double frameRate;
  final int sampleRate;
  final int channels;
  final String videoCodec;
  final String audioCodec;
  final int bitRate;
  final int fileSize;
  final String colorSpace;
  final DateTime dateAdded;
  final String? proxyPath;
  final String? thumbnailPath;
  final String? binId;

  bool get hasVideo => width > 0 && height > 0;
  bool get hasAudio => channels > 0;
  bool get hasProxy => proxyPath != null;

  String get resolution => '${width}x$height';
  String get frameRateDisplay {
    const frameRatePairs = [
      [23.976, '23.976'], [24.0, '24'], [25.0, '25'],
      [29.97, '29.97'], [30.0, '30'], [50.0, '50'],
      [59.94, '59.94'], [60.0, '60'],
    ];
    for (final pair in frameRatePairs) {
      if ((frameRate - (pair[0] as double)).abs() < 0.01) {
        return pair[1] as String;
      }
    }
    return frameRate.toStringAsFixed(2);
  }

  MediaAsset copyWith({
    String? id,
    String? projectId,
    String? filePath,
    String? name,
    String? type,
    Duration? duration,
    int? width,
    int? height,
    double? frameRate,
    int? sampleRate,
    int? channels,
    String? videoCodec,
    String? audioCodec,
    int? bitRate,
    int? fileSize,
    String? colorSpace,
    DateTime? dateAdded,
    String? proxyPath,
    String? thumbnailPath,
    String? binId,
  }) {
    return MediaAsset(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      filePath: filePath ?? this.filePath,
      name: name ?? this.name,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      bitRate: bitRate ?? this.bitRate,
      fileSize: fileSize ?? this.fileSize,
      colorSpace: colorSpace ?? this.colorSpace,
      dateAdded: dateAdded ?? this.dateAdded,
      proxyPath: proxyPath ?? this.proxyPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      binId: binId ?? this.binId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaAsset &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.filePath,
    required this.composition,
    required this.dateCreated,
    required this.dateModified,
    this.description = '',
    this.version = '0.1.0',
  });

  final String id;
  final String name;
  final String filePath;
  final CompositionModel composition;
  final DateTime dateCreated;
  final DateTime dateModified;
  final String description;
  final String version;

  static ProjectModel create({
    required String name,
    required String filePath,
    int width = AppConstants.defaultWidth,
    int height = AppConstants.defaultHeight,
    double frameRate = AppConstants.defaultFrameRate,
  }) {
    final now = DateTime.now();
    final id = 'proj_${now.millisecondsSinceEpoch}';
    return ProjectModel(
      id: id,
      name: name,
      filePath: filePath,
      composition: CompositionModel(
        id: 'comp_$id',
        name: 'Main Composition',
        width: width,
        height: height,
        frameRate: frameRate,
      ),
      dateCreated: now,
      dateModified: now,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? filePath,
    CompositionModel? composition,
    DateTime? dateCreated,
    DateTime? dateModified,
    String? description,
    String? version,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      composition: composition ?? this.composition,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      description: description ?? this.description,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
