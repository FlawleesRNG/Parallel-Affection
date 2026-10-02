import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/connections_colors_v3.dart';

class ConnectionsGlobalBackgroundV3 extends StatelessWidget {
  const ConnectionsGlobalBackgroundV3({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: const ValueKey('connections_global_background_v3'),
    painter: const _ConnectionsGlobalBackgroundPainterV3(),
    child: child,
  );
}

class _ConnectionsGlobalBackgroundPainterV3 extends CustomPainter {
  const _ConnectionsGlobalBackgroundPainterV3();

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = ConnectionsColorsV3.background;
    canvas.drawRect(Offset.zero & size, base);

    final wash = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ConnectionsColorsV3.paper,
          ConnectionsColorsV3.backgroundSecondary,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    final dotPaint = Paint()
      ..color = ConnectionsColorsV3.outlineSoft.withValues(alpha: .10)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final heartPaint = Paint()
      ..color = ConnectionsColorsV3.relationship.withValues(alpha: .075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final linePaint = Paint()
      ..color = ConnectionsColorsV3.interaction.withValues(alpha: .06)
      ..strokeWidth = 1.2;

    for (var y = 28.0; y < size.height; y += 74) {
      for (var x = 32.0; x < size.width; x += 118) {
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
        if (((x + y) ~/ 50).isEven) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(x + 36, y + 16),
              width: 22,
              height: 18,
            ),
            math.pi * .15,
            math.pi * .92,
            false,
            heartPaint,
          );
        } else {
          canvas.drawLine(
            Offset(x - 10, y + 22),
            Offset(x + 28, y + 8),
            linePaint,
          );
        }
      }
    }

    final vignette = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: .10),
              ConnectionsColorsV3.backgroundSecondary.withValues(alpha: .22),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .52, size.height * .42),
              radius: math.max(size.width, size.height) * .72,
            ),
          );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
