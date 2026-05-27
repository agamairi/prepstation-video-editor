import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_controller.dart';
import 'package:prepstation/core/tracker/tracker_model.dart';

class TrackerOverlay extends ConsumerWidget {
  const TrackerOverlay({
    super.key,
    required this.activeClip,
  });

  final ClipModel activeClip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineStateProvider);
    final sessions = state.trackerSessionsForClip(activeClip.id);
    final activeSessionId = state.activeTrackerSessionId;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final pinX =
                (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
            final pinY =
                (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
            _dropPin(ref, pinX, pinY);
          },
          child: Stack(
            children: [
              for (final session in sessions) ...[
                if (session.status == TrackerStatus.completed)
                  _TrackPath(
                    session: session,
                    clip: activeClip,
                    playhead: state.playhead,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    isActive: session.id == activeSessionId,
                  ),
                _TrackPin(
                  session: session,
                  clip: activeClip,
                  playhead: state.playhead,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  isActive: session.id == activeSessionId,
                ),
              ],
              if (sessions.isEmpty)
                const Center(
                  child: _DropPinHint(),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _dropPin(WidgetRef ref, double pinX, double pinY) async {
    final controller = ref.read(timelineControllerProvider);
    final session = await controller.createTrackerSession(
      clipId: activeClip.id,
      pinX: pinX,
      pinY: pinY,
    );
    if (session != null) {
      unawaited(controller.runTracking(session.id));
    }
  }
}

class _DropPinHint extends StatelessWidget {
  const _DropPinHint();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pin_drop, size: 16, color: Colors.white70),
            SizedBox(width: 8),
            Text(
              'Tap to drop a tracking pin',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackPin extends StatelessWidget {
  const _TrackPin({
    required this.session,
    required this.clip,
    required this.playhead,
    required this.width,
    required this.height,
    required this.isActive,
  });

  final TrackerSession session;
  final ClipModel clip;
  final Duration playhead;
  final double width;
  final double height;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final mediaTime = playhead - clip.startOnTimeline + clip.mediaInPoint;

    double x, y;
    if (session.status == TrackerStatus.completed && session.points.isNotEmpty) {
      final point = session.interpolatedAt(mediaTime);
      if (point != null) {
        x = point.x;
        y = point.y;
      } else {
        x = session.pinX;
        y = session.pinY;
      }
    } else {
      x = session.pinX;
      y = session.pinY;
    }

    final color = Color(session.colorHex);
    final isTracking = session.status == TrackerStatus.tracking;

    return Positioned(
      left: x * width - 12,
      top: y * height - 12,
      child: IgnorePointer(
        child: SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? color : color.withValues(alpha: 0.5),
                    width: isActive ? 2 : 1.5,
                  ),
                ),
              ),
              // Inner crosshair
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              // Horizontal crosshair lines
              Positioned(
                left: 2,
                right: 2,
                child: Container(
                  height: 0.5,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
              // Vertical crosshair lines
              Positioned(
                top: 2,
                bottom: 2,
                child: Container(
                  width: 0.5,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
              if (isTracking)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackPath extends StatelessWidget {
  const _TrackPath({
    required this.session,
    required this.clip,
    required this.playhead,
    required this.width,
    required this.height,
    required this.isActive,
  });

  final TrackerSession session;
  final ClipModel clip;
  final Duration playhead;
  final double width;
  final double height;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (session.points.length < 2) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _TrackPathPainter(
            points: session.points,
            color: Color(session.colorHex),
            width: width,
            height: height,
            isActive: isActive,
            mediaTime: playhead - clip.startOnTimeline + clip.mediaInPoint,
          ),
        ),
      ),
    );
  }
}

class _TrackPathPainter extends CustomPainter {
  _TrackPathPainter({
    required this.points,
    required this.color,
    required this.width,
    required this.height,
    required this.isActive,
    required this.mediaTime,
  });

  final List<TrackPoint> points;
  final Color color;
  final double width;
  final double height;
  final bool isActive;
  final Duration mediaTime;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final pathPaint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.6 : 0.3)
      ..strokeWidth = isActive ? 1.5 : 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points.first.x * width, points.first.y * height);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x * width, points[i].y * height);
    }

    canvas.drawPath(path, pathPaint);

    // Draw dots at lower-confidence points
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    for (final point in points) {
      if (point.confidence < 0.7) {
        dotPaint.color = Colors.redAccent.withValues(alpha: 0.6);
        canvas.drawCircle(
          Offset(point.x * width, point.y * height),
          2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrackPathPainter old) =>
      old.mediaTime != mediaTime ||
      old.isActive != isActive ||
      old.points != points;
}
