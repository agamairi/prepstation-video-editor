import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/core/audio/waveform_data.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';

final waveformGeneratorProvider = Provider<WaveformGenerator>(
  (ref) => WaveformGenerator(),
);

/// Riverpod cache: assetId → WaveformData
final waveformCacheProvider =
    StateNotifierProvider<_WaveformCache, Map<String, WaveformData>>(
  (ref) => _WaveformCache(),
);

class _WaveformCache extends StateNotifier<Map<String, WaveformData>> {
  _WaveformCache() : super({});

  void put(String assetId, WaveformData data) {
    state = {...state, assetId: data};
  }
}

class WaveformGenerator {
  Future<WaveformData?> generateWaveform({
    required String sourceFilePath,
    required String assetId,
    int sampleRate = AppConstants.waveformSampleRate,
  }) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final waveDir = Directory('${cacheDir.path}/waveforms');
      await waveDir.create(recursive: true);

      final outputPath = '${waveDir.path}/$assetId.raw';

      if (!File(outputPath).existsSync()) {
        final command =
            '-i "$sourceFilePath" '
            '-filter:a "aformat=sample_fmts=s16:sample_rates=$sampleRate:channel_layouts=mono" '
            '-map a:0 -f s16le "$outputPath"';

        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();
        if (!ReturnCode.isSuccess(returnCode)) return null;
      }

      final file = File(outputPath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final peaks = await compute(_computePeaks, _PeakArgs(bytes, sampleRate));

      return WaveformData(
        assetId: assetId,
        peaks: peaks,
        sampleRate: sampleRate,
      );
    } catch (_) {
      return null;
    }
  }
}

class _PeakArgs {
  const _PeakArgs(this.bytes, this.sampleRate);
  final Uint8List bytes;
  final int sampleRate;
}

List<double> _computePeaks(_PeakArgs args) {
  final bytes = args.bytes;
  final numSamples = bytes.length ~/ 2;
  if (numSamples == 0) return [];

  final targetCount =
      numSamples.clamp(0, AppConstants.maxWaveformPeaks);
  final stride = (numSamples / targetCount).ceil().clamp(1, numSamples);

  final peaks = <double>[];
  for (var i = 0; i < numSamples; i += stride) {
    double maxAmp = 0;
    final end = (i + stride).clamp(0, numSamples);
    for (var j = i; j < end; j++) {
      final lo = bytes[j * 2];
      final hi = bytes[j * 2 + 1];
      var sample = (hi << 8) | lo;
      if (sample > 32767) sample -= 65536;
      final amp = sample.abs() / 32768.0;
      if (amp > maxAmp) maxAmp = amp;
    }
    peaks.add(maxAmp);
  }
  return peaks;
}
