import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Circular progress meter used by the hero and the insights header.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
    this.size = 118,
    this.stroke = 10,
  });

  /// 0–100.
  final double progress;
  final String value;
  final String label;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = BloomExtras.of(context);
    final clamped = progress.clamp(0, 100).toDouble();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: animated,
                stroke: stroke,
                track: extras.ringTrack,
                arc: scheme.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: BloomText.display(
                  22,
                  FontWeight.w800,
                  letterSpacing: -0.5,
                  color: scheme.primary,
                ),
              ),
              Text(
                label,
                style: BloomText.body(9, FontWeight.w500, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.arc,
  });

  final double progress;
  final double stroke;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (progress / 100) * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.track != track ||
      old.arc != arc;
}
