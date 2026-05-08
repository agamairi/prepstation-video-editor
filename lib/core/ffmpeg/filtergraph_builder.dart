import 'package:fluxedit/core/timeline/clip_model.dart';

/// Builds FFmpeg filtergraph strings for export-time rendering.
class FiltergraphBuilder {
  const FiltergraphBuilder();

  /// Constructs a complete FFmpeg filtergraph for a list of clips on a
  /// single video track. This is a simplified concat-based graph for
  /// Phase 1; advanced compositing is added in later phases.
  String buildConcatGraph(List<ClipModel> clips) {
    if (clips.isEmpty) return '';
    final sb = StringBuffer();
    for (var i = 0; i < clips.length; i++) {
      sb.write('[$i:v][$i:a]');
    }
    sb.write('concat=n=${clips.length}:v=1:a=1[outv][outa]');
    return sb.toString();
  }

  /// Builds an input argument string for all clips.
  String buildInputArgs(List<ClipModel> clips, List<String> filePaths) {
    assert(clips.length == filePaths.length, 'clips and filePaths must match');
    final sb = StringBuffer();
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final path = filePaths[i];
      final inSecs = clip.mediaInPoint.inMilliseconds / 1000.0;
      final duration = clip.mediaDuration.inMilliseconds / 1000.0;
      sb.write('-ss $inSecs -t $duration -i "$path" ');
    }
    return sb.toString().trim();
  }

  /// Validates that a filtergraph string is well-formed (basic check).
  bool validate(String filtergraph) {
    if (filtergraph.isEmpty) return false;
    final openBrackets = '['.allMatches(filtergraph).length;
    final closeBrackets = ']'.allMatches(filtergraph).length;
    return openBrackets == closeBrackets;
  }
}
