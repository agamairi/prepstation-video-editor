import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluxedit/app/theme/color_tokens.dart';
import 'package:fluxedit/app/theme/typography.dart';
import 'package:fluxedit/core/audio/waveform_data.dart';
import 'package:fluxedit/core/timeline/clip_model.dart';
import 'package:fluxedit/core/timeline/keyframe_model.dart';
import 'package:fluxedit/core/timeline/timeline_state.dart';
import 'package:fluxedit/core/timeline/timeline_tool.dart';
import 'package:fluxedit/core/timeline/track_model.dart';
import 'package:fluxedit/core/transitions/transition_type.dart';

typedef ClipCallback = void Function(String clipId);
typedef ClipDragCallback = void Function(String clipId, double delta);
typedef ClipTrimCallback = void Function(String clipId, double dx);
typedef ClipBladeCallback = void Function(String clipId, Duration time);

class TimelineCanvas extends StatefulWidget {
  const TimelineCanvas({
    super.key,
    required this.timelineState,
    required this.tool,
    required this.onClipTap,
    required this.onClipBladeAt,
    required this.onClipDragStart,
    required this.onClipDrag,
    required this.onClipTrimStart,
    required this.onClipTrimEnd,
    this.waveforms = const {},
  });

  final TimelineState timelineState;
  final TimelineTool tool;
  final ClipCallback onClipTap;
  final ClipBladeCallback onClipBladeAt;
  final ClipCallback onClipDragStart;
  final ClipDragCallback onClipDrag;
  final ClipTrimCallback onClipTrimStart;
  final ClipTrimCallback onClipTrimEnd;

  /// Optional waveform data keyed by asset ID.
  final Map<String, WaveformData> waveforms;

  @override
  State<TimelineCanvas> createState() => _TimelineCanvasState();
}

class _TimelineCanvasState extends State<TimelineCanvas> {
  String? _draggingClipId;
  double _dragStartX = 0;
  double? _bladeX; // current blade cursor x for preview line

  static const double _trimHandleWidth = 8.0;
  static const double _rulerHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.tool == TimelineTool.blade
          ? SystemMouseCursors.precise
          : MouseCursor.defer,
      onHover: widget.tool == TimelineTool.blade
          ? (e) => setState(() => _bladeX = e.localPosition.dx)
          : null,
      onExit: widget.tool == TimelineTool.blade
          ? (_) => setState(() => _bladeX = null)
          : null,
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final state = widget.timelineState;
            final deltaSecs = event.scrollDelta.dx / state.zoom;
            final newOffset = state.scrollOffset +
                Duration(microseconds: (deltaSecs * 1000000).round());
            state.setScrollOffset(newOffset);
          }
        },
        child: CustomPaint(
          painter: _TimelinePainter(
            timelineState: widget.timelineState,
            trimHandleWidth: _trimHandleWidth,
            rulerHeight: _rulerHeight,
            waveforms: widget.waveforms,
            bladeX: widget.tool == TimelineTool.blade ? _bladeX : null,
          ),
          child: _buildGestureLayer(),
        ),
      ),
    );
  }

  Widget _buildGestureLayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final state = widget.timelineState;
        final tracks = state.tracks;

        return Stack(
          children: [
            // Playhead drag target (ruler area — select tool only)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _rulerHeight,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  if (widget.tool == TimelineTool.select) {
                    final time = state.pixelToTime(d.localPosition.dx);
                    state.setPlayhead(time);
                  }
                },
              ),
            ),
            // Clip gesture areas
            ...tracks.indexed.expand(
              (e) => _buildTrackClipGestures(
                e.$2,
                e.$1,
                constraints.maxWidth,
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<Widget> _buildTrackClipGestures(
    TrackModel track,
    int trackIndex,
    double canvasWidth,
  ) {
    final state = widget.timelineState;
    final clips = state.clipsForTrack(track.id);
    final trackTop = _rulerHeight + trackIndex * track.height;

    return clips.map((clip) {
      final left = state.timeToPixel(clip.startOnTimeline);
      final right = state.timeToPixel(clip.endOnTimeline);
      final width = (right - left).clamp(0.0, canvasWidth - left);
      if (width <= 0) return const SizedBox.shrink();

      final isSelected = state.selectedClipIds.contains(clip.id);

      if (widget.tool == TimelineTool.blade) {
        // In blade mode, entire clip area is a tap target for splitting
        return Positioned(
          left: left,
          top: trackTop + 2,
          width: width,
          height: track.height - 4,
          child: GestureDetector(
            onTapDown: (d) {
              final tapTime = state.pixelToTime(left + d.localPosition.dx);
              widget.onClipBladeAt(clip.id, tapTime);
            },
          ),
        );
      }

      return Positioned(
        left: left,
        top: trackTop + 2,
        width: width,
        height: track.height - 4,
        child: _ClipGestureArea(
          clip: clip,
          isSelected: isSelected,
          trimHandleWidth: _trimHandleWidth,
          onTap: () => widget.onClipTap(clip.id),
          onDragStart: (dx) {
            _draggingClipId = clip.id;
            _dragStartX = dx;
            widget.onClipDragStart(clip.id);
          },
          onDrag: (dx) {
            if (_draggingClipId == clip.id) {
              widget.onClipDrag(clip.id, dx - _dragStartX);
              _dragStartX = dx;
            }
          },
          onDragEnd: () => _draggingClipId = null,
          onTrimStartDrag: (dx) => widget.onClipTrimStart(clip.id, left + dx),
          onTrimEndDrag: (dx) => widget.onClipTrimEnd(clip.id, left + dx),
        ),
      );
    });
  }
}

class _ClipGestureArea extends StatelessWidget {
  const _ClipGestureArea({
    required this.clip,
    required this.isSelected,
    required this.trimHandleWidth,
    required this.onTap,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    required this.onTrimStartDrag,
    required this.onTrimEndDrag,
  });

  final ClipModel clip;
  final bool isSelected;
  final double trimHandleWidth;
  final VoidCallback onTap;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;
  final ValueChanged<double> onTrimStartDrag;
  final ValueChanged<double> onTrimEndDrag;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main clip body
        Positioned.fill(
          left: trimHandleWidth,
          right: trimHandleWidth,
          child: GestureDetector(
            onTap: onTap,
            onHorizontalDragStart: (d) => onDragStart(d.globalPosition.dx),
            onHorizontalDragUpdate: (d) => onDrag(d.globalPosition.dx),
            onHorizontalDragEnd: (_) => onDragEnd(),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        // Left trim handle
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: trimHandleWidth,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) =>
                onTrimStartDrag(d.localPosition.dx),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorTokens.accentPrimary
                      : ColorTokens.borderStrong,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Right trim handle
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: trimHandleWidth,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) =>
                onTrimEndDrag(d.localPosition.dx),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeRight,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorTokens.accentPrimary
                      : ColorTokens.borderStrong,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({
    required this.timelineState,
    required this.trimHandleWidth,
    required this.rulerHeight,
    required this.waveforms,
    this.bladeX,
  }) : super(repaint: timelineState);

  final TimelineState timelineState;
  final double trimHandleWidth;
  final double rulerHeight;
  final Map<String, WaveformData> waveforms;
  final double? bladeX;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintRuler(canvas, size);
    _paintTracks(canvas, size);
    _paintPlayhead(canvas, size);
    if (bladeX != null) _paintBladeCursor(canvas, size, bladeX!);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = ColorTokens.backgroundBase,
    );
  }

  void _paintRuler(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, rulerHeight),
      Paint()..color = ColorTokens.timeRuler,
    );

    final zoomSecs = size.width / timelineState.zoom;
    final step = _rulerStep(timelineState.zoom);
    final offsetSecs =
        timelineState.scrollOffset.inMicroseconds / 1000000.0;

    final startSec = (offsetSecs / step).floor() * step;
    final endSec = offsetSecs + zoomSecs;

    final tickPaint = Paint()..color = ColorTokens.timeRulerTick;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var sec = startSec; sec <= endSec; sec += step) {
      final x = (sec - offsetSecs) * timelineState.zoom;
      canvas.drawLine(
        Offset(x, rulerHeight - 10),
        Offset(x, rulerHeight),
        tickPaint..strokeWidth = 1,
      );
      tp.text = TextSpan(
        text: _formatRulerLabel(sec),
        style: AppTypography.labelSmall,
      );
      tp.layout();
      tp.paint(canvas, Offset(x + 3, rulerHeight - 16));
    }

    final minorStep = step / 5;
    for (var sec = startSec; sec <= endSec; sec += minorStep) {
      final x = (sec - offsetSecs) * timelineState.zoom;
      canvas.drawLine(
        Offset(x, rulerHeight - 4),
        Offset(x, rulerHeight),
        tickPaint..strokeWidth = 0.5,
      );
    }
  }

  void _paintTracks(Canvas canvas, Size size) {
    final tracks = timelineState.tracks;
    var yOffset = rulerHeight;

    final clipPaint = Paint();
    final clipBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final track in tracks) {
      canvas.drawRect(
        Rect.fromLTWH(0, yOffset, size.width, track.height),
        Paint()..color = ColorTokens.backgroundSurface,
      );
      canvas.drawLine(
        Offset(0, yOffset + track.height),
        Offset(size.width, yOffset + track.height),
        Paint()
          ..color = ColorTokens.trackDivider
          ..strokeWidth = 1,
      );

      for (final clip in timelineState.clipsForTrack(track.id)) {
        _paintClip(canvas, clip, track, yOffset, clipPaint, clipBorderPaint, tp);
      }

      yOffset += track.height;
    }
  }

  void _paintClip(
    Canvas canvas,
    ClipModel clip,
    TrackModel track,
    double trackTop,
    Paint paint,
    Paint borderPaint,
    TextPainter tp,
  ) {
    final left = timelineState.timeToPixel(clip.startOnTimeline);
    final right = timelineState.timeToPixel(clip.endOnTimeline);
    final width = right - left;
    if (width <= 0) return;

    final isSelected = timelineState.selectedClipIds.contains(clip.id);
    final rect = Rect.fromLTWH(left + 1, trackTop + 2, width - 2, track.height - 4);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

    final baseColor = track.isVideo
        ? (isSelected ? ColorTokens.clipVideoSelected : ColorTokens.clipVideo)
        : (isSelected ? ColorTokens.clipAudioSelected : ColorTokens.clipAudio);

    paint.color = baseColor;
    canvas.drawRRect(rrect, paint);

    // Waveform for audio clips
    if (track.isAudio) {
      final waveform = waveforms[clip.mediaId];
      if (waveform != null) {
        _paintWaveform(canvas, clip, rect, waveform);
      }
    }

    borderPaint.color = isSelected
        ? ColorTokens.accentPrimary
        : baseColor.withValues(alpha: 0.4);
    canvas.drawRRect(rrect, borderPaint);

    // Transition stripe at clip tail
    if (clip.transitionOutId != null &&
        clip.transitionOutDuration > Duration.zero) {
      _paintTransitionStripe(canvas, clip, trackTop, track.height);
    }

    // Keyframe diamonds
    final keyframes = timelineState.allKeyframesForClip(clip.id);
    if (keyframes.isNotEmpty) {
      _paintKeyframeDiamonds(canvas, clip, keyframes, trackTop, track.height);
    }

    // Label
    if (width > 40) {
      tp.text = TextSpan(
        text: clip.name.isNotEmpty ? clip.name : '  Clip',
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
        ),
      );
      tp.layout(maxWidth: width - 16);
      tp.paint(canvas, Offset(left + 8, trackTop + 6));
    }
  }

  void _paintTransitionStripe(
    Canvas canvas,
    ClipModel clip,
    double trackTop,
    double trackHeight,
  ) {
    final clipRight = timelineState.timeToPixel(clip.endOnTimeline);
    final transStart = timelineState.timeToPixel(
      clip.endOnTimeline - clip.transitionOutDuration,
    );
    final top = trackTop + 2;
    final bottom = trackTop + trackHeight - 2;

    // Semi-transparent fill triangle indicating the transition zone.
    final fillPath = Path()
      ..moveTo(transStart, bottom)
      ..lineTo(transStart, top)
      ..lineTo(clipRight, top)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color =
            ColorTokens.transitionStripe.withValues(alpha: 0.3),
    );

    // Left boundary line of transition zone.
    canvas.drawLine(
      Offset(transStart, top),
      Offset(transStart, bottom),
      Paint()
        ..color = ColorTokens.transitionStripe
        ..strokeWidth = 1.5,
    );

    // Small label showing the transition type abbreviation.
    final transType = clip.transitionOutId != null
        ? TransitionType.fromId(clip.transitionOutId!)
        : null;
    if (transType != null) {
      final tp = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: transType.displayName[0],
          style: AppTypography.labelSmall.copyWith(
            color: ColorTokens.transitionStripe,
            fontSize: 9,
          ),
        )
        ..layout();
      tp.paint(canvas, Offset(transStart + 3, top + 2));
    }
  }

  void _paintKeyframeDiamonds(
    Canvas canvas,
    ClipModel clip,
    List<KeyframeModel> keyframes,
    double trackTop,
    double trackHeight,
  ) {
    final diamondPaint = Paint()..color = ColorTokens.keyframeDiamond;
    const r = 4.0;
    final cy = trackTop + trackHeight - 6.0;

    for (final kf in keyframes) {
      final x = timelineState.timeToPixel(clip.startOnTimeline + kf.time);
      final path = Path()
        ..moveTo(x, cy - r)
        ..lineTo(x + r, cy)
        ..lineTo(x, cy + r)
        ..lineTo(x - r, cy)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }
  }

  void _paintWaveform(
    Canvas canvas,
    ClipModel clip,
    Rect clipRect,
    WaveformData waveform,
  ) {
    final pixelWidth = clipRect.width.toInt().clamp(1, 4000);
    final peaks = waveform.peaksForRange(
      clip.mediaInPoint,
      clip.mediaOutPoint,
      pixelWidth,
    );

    final waveformPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    final midY = clipRect.center.dy;
    final halfH = (clipRect.height / 2 - 4).clamp(2.0, 100.0);

    for (var i = 0; i < peaks.length; i++) {
      final x = clipRect.left + i.toDouble();
      final amp = peaks[i] * halfH;
      canvas.drawLine(
        Offset(x, midY - amp),
        Offset(x, midY + amp),
        waveformPaint,
      );
    }
  }

  void _paintPlayhead(Canvas canvas, Size size) {
    final x = timelineState.timeToPixel(timelineState.playhead);
    if (x < 0 || x > size.width) return;

    final paint = Paint()
      ..color = ColorTokens.playhead
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

    final path = Path()
      ..moveTo(x - 6, 0)
      ..lineTo(x + 6, 0)
      ..lineTo(x, 10)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  void _paintBladeCursor(Canvas canvas, Size size, double x) {
    final paint = Paint()
      ..color = ColorTokens.accentPrimary.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(x, rulerHeight),
      Offset(x, size.height),
      paint,
    );
  }

  double _rulerStep(double zoom) {
    final targetInterval = 100.0 / zoom;
    const steps = [
      0.1, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 30.0, 60.0, 120.0, 300.0,
      600.0,
    ];
    for (final s in steps) {
      if (s >= targetInterval) return s;
    }
    return 600.0;
  }

  String _formatRulerLabel(double secs) {
    final d = Duration(milliseconds: (secs * 1000).round());
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    if (m == 0) return '${s}s';
    return '${m}m${s.toString().padLeft(2, '0')}s';
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) => true;
}
