import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxedit/core/ffmpeg/probe_result.dart';

final ffmpegEngineProvider = Provider<FfmpegEngine>((ref) => FfmpegEngine());

/// Singleton FFmpeg orchestrator. All heavy operations are dispatched so
/// they do not block the UI thread, then awaited by callers.
class FfmpegEngine {
  FfmpegEngine();

  /// Probe a media file and return structured metadata.
  Future<ProbeResult> probe(String filePath) async {
    final session = await FFprobeKit.execute(
      '-v quiet -print_format json -show_format -show_streams "$filePath"',
    );
    final output = await session.getOutput();
    if (output == null || output.isEmpty) {
      throw FfmpegException('ffprobe returned no output for $filePath');
    }
    final json = jsonDecode(output) as Map<String, dynamic>;
    return ProbeResult.fromJson(json);
  }

  /// Execute an FFmpeg command string. Runs on the platform thread pool via
  /// [FFmpegKit] (which is already off-main-thread).
  /// [onProgress] receives statistics updates during encoding.
  Future<void> execute(
    String command, {
    void Function(Statistics)? onProgress,
    void Function(String)? onLog,
  }) async {
    final completer = Completer<void>();
    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          completer.complete();
        } else {
          final logs = await session.getAllLogsAsString();
          debugPrint('FFmpeg logs:\n$logs');
          completer.completeError(FfmpegException(
            'FFmpeg failed (code ${returnCode?.getValue()}): $logs',
          ));
        }
      },
      onLog != null ? (log) => onLog(log.getMessage()) : null,
      onProgress != null ? (stats) => onProgress(stats) : null,
    );
    await completer.future;
  }

  /// Cancel all active FFmpeg sessions.
  Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }

  /// Run a Dart closure in an isolate so it cannot block the main thread.
  /// Useful for JSON parsing or other CPU-bound work after ffprobe returns.
  static Future<T> runInIsolate<T>(T Function() computation) {
    return Isolate.run(computation);
  }
}

class FfmpegException implements Exception {
  const FfmpegException(this.message);

  final String message;

  @override
  String toString() => 'FfmpegException: $message';
}
