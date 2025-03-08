import 'package:flutter/material.dart';
import 'dart:math';

class HintArrowPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Animation<double> progress;

  HintArrowPainter({
    required this.startPoint,
    required this.endPoint,
    required this.progress,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade300
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate the path points
    final deltaX = endPoint.dx - startPoint.dx;
    final deltaY = endPoint.dy - startPoint.dy;
    final distance = sqrt(deltaX * deltaX + deltaY * deltaY);
    final angle = atan2(deltaY, deltaX);

    // Create a curved path
    final controlPoint1 = Offset(
      startPoint.dx + distance * 0.5 * cos(angle - 0.3),
      startPoint.dy + distance * 0.5 * sin(angle - 0.3),
    );

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(
        controlPoint1.dx,
        controlPoint1.dy,
        endPoint.dx,
        endPoint.dy,
      );

    // Draw the animated path
    final pathMetric = path.computeMetrics().first;
    final pathProgress = pathMetric.extractPath(
      0,
      pathMetric.length * progress.value,
    );

    // Add glow effect
    final glowPaint = Paint()
      ..color = Colors.amber.shade100.withOpacity(0.5)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(pathProgress, glowPaint);
    canvas.drawPath(pathProgress, paint);

    // Draw arrowhead if progress is near completion
    if (progress.value > 0.9) {
      final arrowSize = 15.0;
      final arrowPaint = Paint()
        ..color = Colors.amber.shade300
        ..style = PaintingStyle.fill;

      final endTangent = pathMetric.getTangentForOffset(pathMetric.length)!;
      final arrowAngle = endTangent.angle;

      final arrowPath = Path()
        ..moveTo(
          endPoint.dx - arrowSize * cos(arrowAngle),
          endPoint.dy - arrowSize * sin(arrowAngle),
        )
        ..lineTo(
          endPoint.dx - arrowSize * cos(arrowAngle - pi / 6),
          endPoint.dy - arrowSize * sin(arrowAngle - pi / 6),
        )
        ..lineTo(endPoint.dx, endPoint.dy)
        ..lineTo(
          endPoint.dx - arrowSize * cos(arrowAngle + pi / 6),
          endPoint.dy - arrowSize * sin(arrowAngle + pi / 6),
        )
        ..close();

      // Draw arrow glow
      final arrowGlowPaint = Paint()
        ..color = Colors.amber.shade100.withOpacity(0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawPath(arrowPath, arrowGlowPaint);
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HintArrowPainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.progress != progress;
  }
}
