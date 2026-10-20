import 'package:flutter/material.dart';

import '../models.dart';

/// The five-line mood glyph from the prototype, drawn as a painter so it can
/// inherit whatever colour its parent is using.
class MoodFace extends StatelessWidget {
  const MoodFace({super.key, required this.mood, this.size = 34, this.color});

  final Mood mood;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MoodPainter(mouth: mood.index, color: resolved)),
    );
  }
}

class _MoodPainter extends CustomPainter {
  _MoodPainter({required this.mouth, required this.color});

  /// 0 = Low … 4 = Amazing.
  final int mouth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The original artwork is described on a 32x32 grid.
    final s = size.width / 32;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s
      ..strokeCap = StrokeCap.round
      ..color = color;
    final dot = Paint()..color = color;

    canvas.drawCircle(Offset(16 * s, 16 * s), 12 * s, outline);
    canvas.drawCircle(Offset(12 * s, 13 * s), 0.9 * s, dot);
    canvas.drawCircle(Offset(20 * s, 13 * s), 0.9 * s, dot);

    final path = Path();
    if (mouth == 0) {
      path.moveTo(11 * s, 22.5 * s);
      path.quadraticBezierTo(16 * s, 16 * s, 21 * s, 22.5 * s);
    } else if (mouth == 1) {
      path.moveTo(11 * s, 21 * s);
      path.lineTo(21 * s, 21 * s);
    } else if (mouth <= 3) {
      path.moveTo(10 * s, 19 * s);
      path.quadraticBezierTo(16 * s, 26 * s, 22 * s, 19 * s);
    } else {
      path.moveTo(10 * s, 19 * s);
      path.quadraticBezierTo(16 * s, 30 * s, 22 * s, 19 * s);
      path.close();
    }

    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(_MoodPainter old) => old.mouth != mouth || old.color != color;
}
