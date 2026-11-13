import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Crisp vector lychee mark used across the UI (auth screen, title bar, about).
///
/// Keeps the TDesign silhouette language: a rounded fruit body with a soft
/// top-left highlight, a short stem and two leaves, drawn in the brand
/// lychee-red palette.
class LitchiLogo extends StatelessWidget {
  final double size;
  final bool showBackground;

  const LitchiLogo({super.key, this.size = 48, this.showBackground = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LitchiPainter(showBackground: showBackground)),
    );
  }
}

class _LitchiPainter extends CustomPainter {
  final bool showBackground;
  const _LitchiPainter({this.showBackground = false});

  static const _bgTop = Color(0xFFFFF4F5);
  static const _bgBot = Color(0xFFFFDFE3);
  static const _light = Color(0xFFF5848A);
  static const _base = Color(0xFFE34D59);
  static const _dark = Color(0xFFB02A36);
  static const _leafLight = Color(0xFF6ECD8A);
  static const _leafDark = Color(0xFF2C9858);
  static const _stem = Color(0xFF7A5230);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Rect.fromLTWH(0, 0, s, s);

    if (showBackground) {
      final r = s * 0.225;
      final bgPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBot],
        ).createShader(rect);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), bgPaint);
    }

    final cx = s * 0.5;
    final cy = s * 0.56;
    final r = s * 0.30;

    // body with radial shading (lit from top-left)
    final bodyRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.35,
        colors: [_light, _base, _dark],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bodyRect);
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

    // bumpy skin texture (clipped to body)
    canvas.save();
    canvas.clipPath(Path()..addOval(bodyRect));
    final rng = math.Random(7);
    final dot = r * 0.075;
    for (var i = 0; i < 90; i++) {
      // sample points inside the body circle
      final ang = rng.nextDouble() * math.pi * 2;
      final rad = math.sqrt(rng.nextDouble()) * r * 0.96;
      final px = cx + math.cos(ang) * rad;
      final py = cy + math.sin(ang) * rad;
      final lit = (px - cx) + (py - cy) < 0;
      final paint = Paint()
        ..color = (lit ? const Color(0x46FFCDD0) : const Color(0x50962430));
      canvas.drawCircle(Offset(px, py), dot * (0.7 + rng.nextDouble() * 0.6), paint);
    }
    canvas.restore();

    // glossy highlight
    final glossPaint = Paint()..color = const Color(0x33FFFFFF);
    canvas.drawOval(
      Rect.fromLTWH(cx - r * 0.72, cy - r * 0.86, r * 0.62, r * 0.68),
      glossPaint,
    );

    // stem
    final stemPaint = Paint()
      ..color = _stem
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    final stemTop = cy - r - s * 0.085;
    canvas.drawLine(Offset(cx, cy - r + r * 0.10), Offset(cx + r * 0.05, stemTop), stemPaint);

    // leaves
    _drawLeaf(canvas, Offset(cx + r * 0.05, stemTop), s * 0.30, s * 0.13, -0.55);
    _drawLeaf(canvas, Offset(cx + r * 0.05, stemTop), s * 0.32, s * 0.14, 0.5);
  }

  void _drawLeaf(Canvas canvas, Offset anchor, double length, double width, double angle) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(angle);
    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -width * 0.5, length, 0)
      ..quadraticBezierTo(length * 0.5, width * 0.5, 0, 0);
    final leafPaint = Paint()
      ..shader = LinearGradient(
        colors: [_leafLight, _leafDark],
      ).createShader(Rect.fromLTWH(0, -width * 0.5, length, width));
    canvas.drawPath(leafPath, leafPaint);
    final ribPaint = Paint()
      ..color = _leafDark
      ..strokeWidth = math.max(1.0, width * 0.09);
    canvas.drawLine(Offset(0, 0), Offset(length, 0), ribPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LitchiPainter oldDelegate) => oldDelegate.showBackground != showBackground;
}