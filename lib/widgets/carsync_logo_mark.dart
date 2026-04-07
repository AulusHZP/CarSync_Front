import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CarSyncLogoMark extends StatelessWidget {
  final double size;

  const CarSyncLogoMark({
    super.key,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _CarSyncMarkPainter(),
          ),
          Icon(
            LucideIcons.carFront,
            size: size * 0.44,
            color: const Color(0xFF0F1115),
          ),
        ],
      ),
    );
  }
}

class _CarSyncMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF0F1115)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.12,
      size.width * 0.76,
      size.height * 0.76,
    );

    // Upper arc
    canvas.drawArc(rect, math.pi * 1.02, math.pi * 0.98, false, strokePaint);

    // Lower dynamic arc
    const lowerStart = math.pi * 0.08;
    const lowerSweep = math.pi * 1.06;
    canvas.drawArc(rect, lowerStart, lowerSweep, false, strokePaint);

    final center = rect.center;
    final radius = rect.width / 2;
    const endAngle = lowerStart + lowerSweep;
    final endPoint = Offset(
      center.dx + math.cos(endAngle) * radius,
      center.dy + math.sin(endAngle) * radius,
    );

    const arrowDir = endAngle + math.pi / 2;
    final arrowLen = size.width * 0.14;

    final p1 = endPoint;
    final p2 = Offset(
      endPoint.dx - math.cos(arrowDir - 0.7) * arrowLen,
      endPoint.dy - math.sin(arrowDir - 0.7) * arrowLen,
    );
    final p3 = Offset(
      endPoint.dx - math.cos(arrowDir + 0.7) * arrowLen,
      endPoint.dy - math.sin(arrowDir + 0.7) * arrowLen,
    );

    final arrowFill = Paint()
      ..color = const Color(0xFF0F1115)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(path, arrowFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
