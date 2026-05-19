import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/app/theme/typography.dart';
import 'package:prepstation/core/ffmpeg/codec_registry.dart';
import 'package:prepstation/core/ffmpeg/ffmpeg_engine.dart';
import 'package:prepstation/core/ffmpeg/filtergraph_builder.dart';
import 'package:prepstation/core/project/project_model.dart';
import 'package:prepstation/core/project/project_repository.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_controller.dart';
import 'package:path_provider/path_provider.dart';

enum _ExportStatus { idle, exporting, done, failed }

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key, required this.project});

  final ProjectModel project;

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportPreset _selectedPreset = CodecRegistry.presets.first;
  _ExportStatus _status = _ExportStatus.idle;
  String _outputPath = '';
  double _progress = 0;
  String _progressText = '';
  String _errorMessage = '';
  bool _useCustom = false;

  // Custom export settings
  int _customWidth = 1920;
  int _customHeight = 1080;
  double _customFrameRate = 30.0;
  VideoCodec _customVideoCodec = VideoCodec.h264;
  AudioCodec _customAudioCodec = AudioCodec.aac;
  ContainerFormat _customContainer = ContainerFormat.mp4;
  int _customVideoBitRate = 8000;
  int _customAudioBitRate = 192;
  int? _customCrf = 23;

  @override
  void initState() {
    super.initState();
    _initOutputPath();
  }

  Future<void> _initOutputPath() async {
    Directory exportDir;
    if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      exportDir = Directory(
        '${extDir?.path ?? (await getApplicationDocumentsDirectory()).path}'
        '/exports',
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      exportDir = Directory('${dir.path}/prepstation/exports');
    }
    await exportDir.create(recursive: true);
    if (!mounted) return;
    setState(() {
      _outputPath =
          '${exportDir.path}/${widget.project.name}_export.'
          '${_selectedPreset.containerExtension}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorTokens.backgroundPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const Divider(height: 1),
              _buildBody(),
              const Divider(height: 1),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Text('Export', style: AppTypography.headlineMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _status == _ExportStatus.exporting
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_status == _ExportStatus.exporting) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: ColorTokens.backgroundSurface,
                valueColor: const AlwaysStoppedAnimation(
                  ColorTokens.accentPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(_progressText, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_status == _ExportStatus.done) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: ColorTokens.success,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text('Export Complete!', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text(
                _outputPath,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_status == _ExportStatus.failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: ColorTokens.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text('Export Failed', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text(_errorMessage, style: AppTypography.bodySmall),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            Row(
              children: [
                const Text('Preset', style: AppTypography.headlineSmall),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Custom', style: AppTypography.bodySmall),
                    const SizedBox(width: 4),
                    Switch(
                      value: _useCustom,
                      onChanged: (v) => setState(() => _useCustom = v),
                      activeTrackColor: ColorTokens.accentPrimary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_useCustom) ...[
              DropdownButton<ExportPreset>(
                value: _selectedPreset,
                isExpanded: true,
                dropdownColor: ColorTokens.backgroundElevated,
                style: AppTypography.bodyMedium,
                underline: Container(
                  height: 1,
                  color: ColorTokens.borderDefault,
                ),
                items: CodecRegistry.presets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.label),
                      ),
                    )
                    .toList(),
                onChanged: (p) {
                  if (p == null) return;
                  setState(() {
                    _selectedPreset = p;
                    _outputPath = _outputPath.replaceAll(
                      RegExp(r'\.\w+$'),
                      '.${p.containerExtension}',
                    );
                  });
                },
              ),
            ] else ...[
              _buildCustomSettings(),
            ],
            const SizedBox(height: 20),
            const Text('Output File', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _outputPath.isEmpty
                        ? 'Select output location...'
                        : _outputPath,
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _pickOutputPath,
                  child: const Text('Browse'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_useCustom) _buildCustomSummary() else _buildPresetSummary(),
          ],
      ),
    );
  }

  Widget _buildCustomSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resolution
        Row(
          children: [
            Expanded(
              child: _CustomField(
                label: 'Width',
                value: _customWidth.toString(),
                onChanged: (v) =>
                    setState(() => _customWidth = int.tryParse(v) ?? 1920),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CustomField(
                label: 'Height',
                value: _customHeight.toString(),
                onChanged: (v) =>
                    setState(() => _customHeight = int.tryParse(v) ?? 1080),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Frame rate
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Frame Rate', style: AppTypography.labelMedium),
            ),
            Expanded(
              child: DropdownButton<double>(
                value: _customFrameRate,
                isExpanded: true,
                dropdownColor: ColorTokens.backgroundElevated,
                style: AppTypography.bodySmall,
                underline: Container(height: 1, color: ColorTokens.borderDefault),
                items: const [23.976, 24.0, 25.0, 29.97, 30.0, 50.0, 59.94, 60.0]
                    .map((r) => DropdownMenuItem(value: r, child: Text('$r fps')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _customFrameRate = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Video codec
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Video', style: AppTypography.labelMedium),
            ),
            Expanded(
              child: DropdownButton<VideoCodec>(
                value: _customVideoCodec,
                isExpanded: true,
                dropdownColor: ColorTokens.backgroundElevated,
                style: AppTypography.bodySmall,
                underline: Container(height: 1, color: ColorTokens.borderDefault),
                items: VideoCodec.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _customVideoCodec = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Audio codec
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Audio', style: AppTypography.labelMedium),
            ),
            Expanded(
              child: DropdownButton<AudioCodec>(
                value: _customAudioCodec,
                isExpanded: true,
                dropdownColor: ColorTokens.backgroundElevated,
                style: AppTypography.bodySmall,
                underline: Container(height: 1, color: ColorTokens.borderDefault),
                items: AudioCodec.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _customAudioCodec = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Container
        Row(
          children: [
            const SizedBox(
              width: 80,
              child: Text('Container', style: AppTypography.labelMedium),
            ),
            Expanded(
              child: DropdownButton<ContainerFormat>(
                value: _customContainer,
                isExpanded: true,
                dropdownColor: ColorTokens.backgroundElevated,
                style: AppTypography.bodySmall,
                underline: Container(height: 1, color: ColorTokens.borderDefault),
                items: ContainerFormat.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _customContainer = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bitrate / CRF
        Row(
          children: [
            Expanded(
              child: _CustomField(
                label: 'Video kbps',
                value: _customVideoBitRate.toString(),
                onChanged: (v) => setState(
                    () => _customVideoBitRate = int.tryParse(v) ?? 8000),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CustomField(
                label: 'Audio kbps',
                value: _customAudioBitRate.toString(),
                onChanged: (v) => setState(
                    () => _customAudioBitRate = int.tryParse(v) ?? 192),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CustomField(
                label: 'CRF (opt)',
                value: _customCrf?.toString() ?? '',
                onChanged: (v) =>
                    setState(() => _customCrf = int.tryParse(v)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorTokens.backgroundSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorTokens.borderSubtle),
      ),
      child: Column(
        children: [
          _SummaryRow('Resolution', '$_customWidth×$_customHeight'),
          _SummaryRow('Frame Rate', '$_customFrameRate fps'),
          _SummaryRow('Video Codec', _customVideoCodec.name.toUpperCase()),
          _SummaryRow('Audio Codec', _customAudioCodec.name.toUpperCase()),
          _SummaryRow('Container', _customContainer.name.toUpperCase()),
          _SummaryRow('Video Bit Rate', '$_customVideoBitRate kbps'),
          _SummaryRow('Audio Bit Rate', '$_customAudioBitRate kbps'),
          if (_customCrf != null) _SummaryRow('CRF', '$_customCrf'),
        ],
      ),
    );
  }

  ExportPreset get _effectivePreset => _useCustom
      ? ExportPreset(
          id: 'custom',
          label: 'Custom',
          videoCodec: _customVideoCodec,
          audioCodec: _customAudioCodec,
          container: _customContainer,
          width: _customWidth,
          height: _customHeight,
          frameRate: _customFrameRate,
          videoBitRate: _customVideoBitRate,
          audioBitRate: _customAudioBitRate,
          crf: _customCrf,
          isCustom: true,
        )
      : _selectedPreset;

  Widget _buildPresetSummary() {
    final p = _selectedPreset;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorTokens.backgroundSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ColorTokens.borderSubtle),
      ),
      child: Column(
        children: [
          _SummaryRow('Resolution', '${p.width}×${p.height}'),
          _SummaryRow(
            'Frame Rate',
            '${p.frameRate == p.frameRate.truncate() ? p.frameRate.toInt() : p.frameRate} fps',
          ),
          _SummaryRow('Video Codec', p.videoCodec.name.toUpperCase()),
          _SummaryRow('Audio Codec', p.audioCodec.name.toUpperCase()),
          _SummaryRow('Container', p.containerExtension.toUpperCase()),
          _SummaryRow('Video Bit Rate', '${p.videoBitRate} kbps'),
          _SummaryRow('Audio Bit Rate', '${p.audioBitRate} kbps'),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_status == _ExportStatus.exporting)
            TextButton(
              onPressed: _cancelExport,
              child: const Text(
                'Cancel',
                style: TextStyle(color: ColorTokens.error),
              ),
            )
          else if (_status == _ExportStatus.done ||
              _status == _ExportStatus.failed)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _outputPath.isNotEmpty ? _startExport : null,
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Export'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickOutputPath() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Location',
      fileName:
          '${widget.project.name}_export.${_selectedPreset.containerExtension}',
      type: FileType.custom,
      allowedExtensions: [_selectedPreset.containerExtension],
    );
    if (result != null) {
      setState(() => _outputPath = result);
    }
  }

  Future<void> _startExport() async {
    setState(() {
      _status = _ExportStatus.exporting;
      _progress = 0;
      _progressText = 'Building export command...';
    });

    try {
      final timeline = ref.read(timelineStateProvider);
      final repository = ref.read(projectRepositoryProvider);
      final engine = ref.read(ffmpegEngineProvider);
      const graphBuilder = FiltergraphBuilder();
      final preset = _effectivePreset;

      // Gather clips from all video tracks
      final clips = timeline.clips
          .where((c) => c.type == ClipType.video)
          .toList()
        ..sort((a, b) => a.startOnTimeline.compareTo(b.startOnTimeline));

      if (clips.isEmpty) {
        setState(() {
          _status = _ExportStatus.failed;
          _errorMessage = 'No video clips on timeline.';
        });
        return;
      }

      // Resolve file paths and check audio availability
      final filePaths = <String>[];
      var hasAudio = false;
      for (final clip in clips) {
        final asset = await repository.getMediaAsset(clip.mediaId);
        if (asset == null) {
          throw Exception('Asset not found for clip ${clip.id}');
        }
        filePaths.add(asset.filePath);
        if (asset.hasAudio) hasAudio = true;
      }

      setState(() => _progressText = 'Encoding...');

      final inputArgs = graphBuilder.buildInputArgs(clips, filePaths);
      final effectsByClipId = {
        for (final clip in clips)
          clip.id: timeline.effectsForClip(clip.id),
      };

      final tw = preset.width;
      final th = preset.height;

      String filtergraph;
      if (clips.length > 1) {
        if (hasAudio) {
          final graph = graphBuilder.buildTransitionGraph(
              clips, effectsByClipId: effectsByClipId,
              targetWidth: tw, targetHeight: th);
          filtergraph = '-filter_complex "$graph" -map "[outv]" -map "[outa]" ';
        } else {
          final graph = graphBuilder.buildVideoOnlyGraph(
              clips, effectsByClipId: effectsByClipId,
              targetWidth: tw, targetHeight: th);
          filtergraph = '-filter_complex "$graph" -map "[outv]" ';
        }
      } else {
        final clip = clips.first;
        final clipEffects = effectsByClipId[clip.id] ?? [];
        final hasEffects = clipEffects.any((e) => e.isEnabled);
        final hasTransform = clip.scaleX != 1.0 ||
            clip.scaleY != 1.0 ||
            clip.rotation != 0.0 ||
            clip.cropLeft > 0 ||
            clip.cropRight > 0 ||
            clip.cropTop > 0 ||
            clip.cropBottom > 0 ||
            clip.flipHorizontal ||
            clip.flipVertical ||
            clip.isReversed ||
            (clip.volume != 1.0 && hasAudio);
        if (hasEffects || hasTransform) {
          if (hasAudio) {
            final graph = graphBuilder.buildConcatGraph(
                clips, effectsByClipId: effectsByClipId,
                targetWidth: tw, targetHeight: th);
            filtergraph =
                '-filter_complex "$graph" -map "[outv]" -map "[outa]" ';
          } else {
            final graph = graphBuilder.buildVideoOnlyGraph(
                clips, effectsByClipId: effectsByClipId,
                targetWidth: tw, targetHeight: th);
            filtergraph = '-filter_complex "$graph" -map "[outv]" ';
          }
        } else {
          filtergraph = '-vf "${FiltergraphBuilder.scaleFilter(tw, th)}" ';
        }
      }

      final videoCodecArgs = CodecRegistry.buildVideoCodecArgs(preset);
      final audioCodecArgs = hasAudio
          ? CodecRegistry.buildAudioCodecArgs(preset)
          : '-an';

      final command =
          '-y $inputArgs '
          '$filtergraph'
          '$videoCodecArgs '
          '$audioCodecArgs '
          '-r ${preset.frameRate} '
          '"$_outputPath"';

      debugPrint('FFmpeg export command: $command');

      await engine.execute(
        command,
        onProgress: (stats) {
          final totalMs = timeline.duration.inMilliseconds.toDouble();
          if (totalMs > 0) {
            final progress = stats.getTime() / totalMs;
            setState(() {
              _progress = progress.clamp(0.0, 1.0);
              _progressText =
                  'Encoding... ${(_progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() => _status = _ExportStatus.done);
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        setState(() {
          _status = _ExportStatus.failed;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _cancelExport() async {
    await ref.read(ffmpegEngineProvider).cancelAll();
    if (mounted) {
      setState(() => _status = _ExportStatus.idle);
    }
  }
}

class _CustomField extends StatelessWidget {
  const _CustomField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          style: AppTypography.bodySmall,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: ColorTokens.borderDefault),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTypography.labelMedium),
          ),
          Text(value, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
