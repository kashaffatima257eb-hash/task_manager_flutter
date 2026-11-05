import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlowerSpot {
  final double dx; // 0..1 of width
  final double dy; // 0..1 of height
  final double r; // radius in logical pixels
  final Color color;
  final bool heart;
  final double rot;
  const FlowerSpot(this.dx, this.dy, this.r, this.color,
      {this.heart = false, this.rot = 0});
}

const _pink = Color(0xFFFFC2D6);
const _mint = Color(0xFFB5EBD6);
const _sky = Color(0xFFBBDDF7);
const _lav = Color(0xFFD9C8F3);
const _peach = Color(0xFFFFD0B0);
const _butter = Color(0xFFFFEDA8);
const _white = Color(0xFFFFFFFF);
const _heartPink = Color(0xFFE56B94);

/// Flowers + hearts peeking in on the right side of the header.
const headerSpots = [
  FlowerSpot(0.93, 0.18, 30, _white, rot: 0.2),
  FlowerSpot(0.78, 0.82, 22, _lav, rot: 0.5),
  FlowerSpot(0.62, 0.12, 14, _heartPink, heart: true),
  FlowerSpot(0.99, 0.72, 26, _mint, rot: 0.1),
  FlowerSpot(0.70, 0.55, 10, _butter, rot: 0.3),
  FlowerSpot(0.86, 0.50, 12, _heartPink, heart: true),
  FlowerSpot(0.55, 0.88, 16, _peach, rot: 0.7),
];

/// Faint flowers scattered along the edges of the page background.
const pageSpots = [
  FlowerSpot(0.02, 0.10, 34, _pink, rot: 0.3),
  FlowerSpot(0.98, 0.22, 30, _mint, rot: 0.6),
  FlowerSpot(0.03, 0.45, 28, _lav, rot: 0.1),
  FlowerSpot(0.97, 0.58, 36, _peach, rot: 0.4),
  FlowerSpot(0.04, 0.78, 32, _sky, rot: 0.8),
  FlowerSpot(0.96, 0.92, 28, _pink, rot: 0.2),
  FlowerSpot(0.50, 0.97, 18, _heartPink, heart: true),
  FlowerSpot(0.12, 0.28, 12, _butter, rot: 0.5),
  FlowerSpot(0.88, 0.40, 12, _heartPink, heart: true),
];

class FlowerDecor extends StatelessWidget {
  const FlowerDecor({super.key, required this.spots, this.opacity = 1});
  final List<FlowerSpot> spots;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FlowerPainter(spots, opacity),
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  _FlowerPainter(this.spots, this.opacity);
  final List<FlowerSpot> spots;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in spots) {
      final c = Offset(s.dx * size.width, s.dy * size.height);
      final paint = Paint()..color = s.color.withValues(alpha: opacity);
      if (s.heart) {
        _heart(canvas, c, s.r, paint);
      } else {
        _flower(canvas, c, s, paint);
      }
    }
  }

  void _flower(Canvas canvas, Offset c, FlowerSpot s, Paint paint) {
    const petals = 6;
    for (var i = 0; i < petals; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(s.rot + i * 2 * math.pi / petals);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -s.r * 0.55),
            width: s.r * 0.66,
            height: s.r * 0.98),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      c,
      s.r * 0.24,
      Paint()
        ..color = const Color(0xFFFFE08A).withValues(alpha: opacity.clamp(0.0, 1.0)),
    );
  }

  void _heart(Canvas canvas, Offset c, double r, Paint paint) {
    final p = Path()
      ..moveTo(c.dx, c.dy + r * 0.9)
      ..cubicTo(c.dx - r * 1.6, c.dy - r * 0.1, c.dx - r * 0.7, c.dy - r * 1.3,
          c.dx, c.dy - r * 0.45)
      ..cubicTo(c.dx + r * 0.7, c.dy - r * 1.3, c.dx + r * 1.6, c.dy - r * 0.1,
          c.dx, c.dy + r * 0.9);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter old) =>
      old.opacity != opacity || old.spots != spots;
}
