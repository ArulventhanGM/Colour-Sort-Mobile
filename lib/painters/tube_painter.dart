import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class TubePainter extends CustomPainter {
  final List<Color> colors;
  final bool isSelected;
  final int maxCapacity;

  TubePainter({
    required this.colors,
    this.isSelected = false,
    this.maxCapacity = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = isSelected ? Colors.amber.shade700 : Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4.0 : 3.0;

    // Define tube boundaries
    double tubeWidth = size.width * 0.75;
    double borderRadius = tubeWidth * 0.5; // Fully rounded bottom
    double offsetX = (size.width - tubeWidth) / 2;
    double offsetY = 5;

    // Create tube shape
    Path tubePath = Path()
      ..moveTo(offsetX, offsetY)
      ..lineTo(offsetX + tubeWidth, offsetY)
      ..lineTo(offsetX + tubeWidth, size.height - borderRadius)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(offsetX + tubeWidth / 2, size.height - borderRadius),
          radius: borderRadius,
        ),
        0,
        pi,
        false,
      )
      ..lineTo(offsetX, offsetY)
      ..close();

    // Draw tube body
    Paint glassPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [Colors.white.withOpacity(0.2), Colors.transparent],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(tubePath, glassPaint);
    canvas.drawPath(tubePath, paint);

    // Draw liquid levels
    double segmentHeight = (size.height - borderRadius * 2 - offsetY * 2) / maxCapacity;
    for (int i = 0; i < colors.length; i++) {
      Paint waterPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height - (i + 1) * segmentHeight),
          Offset(size.width, size.height - i * segmentHeight),
          [colors[i].withOpacity(0.85), colors[i]],
        );
      canvas.drawRect(
        Rect.fromLTWH(
          offsetX,
          size.height - (i + 1) * segmentHeight - borderRadius,
          tubeWidth,
          segmentHeight,
        ),
        waterPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TubePainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.isSelected != isSelected;
  }
}
