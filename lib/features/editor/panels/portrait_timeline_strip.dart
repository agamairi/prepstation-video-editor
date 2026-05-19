import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/core/constants/app_constants.dart';
import 'package:prepstation/core/timeline/clip_model.dart';
import 'package:prepstation/core/timeline/timeline_controller.dart';
import 'package:prepstation/core/timeline/timeline_state.dart';

class PortraitTimelineStrip extends ConsumerStatefulWidget {
  const PortraitTimelineStrip({super.key});

  @override
  ConsumerState<PortraitTimelineStrip> createState() =>
      _PortraitTimelineStripState();
}

class _PortraitTimelineStripState
    extends ConsumerState<PortraitTimelineStrip> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _pxPerSec(TimelineState state, double viewWidth) {
    final totalSec = state.duration.inMilliseconds / 1000.0;
    if (totalSec <= 0) return AppConstants.portraitStripDefaultPxPerSec;
    final desired = viewWidth * 1.5 / totalSec;
    return desired.clamp(
      AppConstants.portraitStripMinPxPerSec,
      AppConstants.portraitStripMaxPxPerSec,
    );
  }

  void _handleTapDown(
    TapDownDetails details,
    TimelineState state,
    double pxPerSec,
  ) {
    final tapX = details.localPosition.dx + _scroll.offset;
    final tapY = details.localPosition.dy;

    const rulerH = AppConstants.portraitStripRulerHeight;
    const trackH = AppConstants.portraitStripTrackHeight;
    const gap = AppConstants.portraitStripTrackGap;
    const padTop = 4.0;

    double y = padTop + rulerH + gap;
    for (final track in state.tracks) {
      if (tapY >= y && tapY < y + trackH) {
        for (final clip in state.clipsForTrack(track.id)) {
          final clipX =
              clip.startOnTimeline.inMilliseconds / 1000.0 * pxPerSec;
          final clipW = clip.duration.inMilliseconds / 1000.0 * pxPerSec;
          if (tapX >= clipX && tapX < clipX + clipW) {
            state.selectClip(clip.id);
            return;
          }
        }
        state.clearSelection();
        return;
      }
      y += trackH + gap;
    }
    state.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineStateProvider);
    final hasClips = state.clips.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        final pxPerSec = _pxPerSec(state, viewW);
        final totalSec = state.duration.inMilliseconds / 1000.0;
        final canvasW = math.max(viewW, totalSec * pxPerSec + 48.0);

        return Container(
          height: AppConstants.portraitStripHeight,
          color: ColorTokens.backgroundBase,
          child: hasClips
              ? GestureDetector(
                  onTapDown: (d) => _handleTapDown(d, state, pxPerSec),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: canvasW,
                      height: AppConstants.portraitStripHeight,
                      child: CustomPaint(
                        painter:
                            _StripPainter(state: state, pxPerSec: pxPerSec),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.movie_creation_outlined,
                        size: 16,
                        color: ColorTokens.textDisabled,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap Media to import and add clips',
                        style: TextStyle(
                          color: ColorTokens.textDisabled,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _StripPainter extends CustomPainter {
  const _StripPainter({required this.state, required this.pxPerSec});

  final TimelineState state;
  final double pxPerSec;

  static const _rulerH = AppConstants.portraitStripRulerHeight;
  static const _trackH = AppConstants.portraitStripTrackHeight;
  static const _gap = AppConstants.portraitStripTrackGap;
  static const _padTop = 4.0;
  static const _clipRadius = Radius.circular(3);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = ColorTokens.backgroundBase;
    canvas.drawRect(Offset.zero & size, bgPaint);

    _paintRuler(canvas, size);

    double y = _padTop + _rulerH + _gap;
    for (final track in state.tracks) {
      _paintTrack(canvas, size, track.id, y);
      y += _trackH + _gap;
    }

    _paintPlayhead(canvas, size);
  }

  void _paintTrack(Canvas canvas, Size size, String trackId, double y) {
    final clips = state.clipsForTrack(trackId);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, size.width, _trackH),
        const Radius.circular(2),
      ),
      Paint()
        ..color = ColorTokens.backgroundSurface.withValues(alpha: 0.5),
    );

    for (final clip in clips) {
      final clipX = clip.startOnTimeline.inMilliseconds / 1000.0 * pxPerSec;
      final clipW = math.max(
        2.0,
        clip.duration.inMilliseconds / 1000.0 * pxPerSec - 1,
      );
      final isSelected = state.selectedClipIds.contains(clip.id);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(clipX, y, clipW, _trackH),
        _clipRadius,
      );

      canvas.drawRRect(rrect, Paint()..color = _clipColor(clip, isSelected));

      if (isSelected) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _paintRuler(Canvas canvas, Size size) {
    final totalSec = state.duration.inMilliseconds / 1000.0;
    if (totalSec <= 0) return;

    final secPerTick = _niceInterval(80.0 / pxPerSec);
    final tickPaint = Paint()..color = ColorTokens.timeRulerTick;

    double t = 0;
    while (t <= totalSec + secPerTick) {
      final x = t * pxPerSec;
      canvas.drawRect(
        Rect.fromLTWH(x, _rulerH - 4, 0.5, 4),
        tickPaint,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: _formatTime(t),
          style: const TextStyle(
            color: ColorTokens.timeRulerText,
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);
      tp.paint(canvas, Offset(x + 2, 0));
      t += secPerTick;
    }
  }

  void _paintPlayhead(Canvas canvas, Size size) {
    final x = state.playhead.inMilliseconds / 1000.0 * pxPerSec;
    if (x < 0 || x > size.width) return;

    canvas.drawRect(
      Rect.fromLTWH(x - 0.75, _padTop, 1.5, size.height - _padTop),
      Paint()..color = ColorTokens.playhead,
    );
    final path = Path()
      ..moveTo(x - 4, _padTop)
      ..lineTo(x + 4, _padTop)
      ..lineTo(x, _padTop + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = ColorTokens.playhead);
  }

  double _niceInterval(double raw) {
    const nice = [0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, 120.0, 300.0];
    for (final v in nice) {
      if (v >= raw) return v;
    }
    return nice.last;
  }

  String _formatTime(double seconds) {
    final s = seconds.floor();
    final m = s ~/ 60;
    final rem = s % 60;
    if (m > 0) return '$m:${rem.toString().padLeft(2, '0')}';
    return '${rem}s';
  }

  Color _clipColor(ClipModel clip, bool selected) {
    if (selected) return ColorTokens.clipVideoSelected;
    return switch (clip.type) {
      ClipType.audio => ColorTokens.clipAudio,
      ClipType.title => ColorTokens.clipTitle,
      ClipType.colorCard => const Color(0xFF3D3520),
      ClipType.image => const Color(0xFF1E3D3D),
      ClipType.adjustment => const Color(0xFF1E3D1E),
      ClipType.video => ColorTokens.clipVideo,
    };
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.state != state || old.pxPerSec != pxPerSec;
}
