import 'package:flutter/material.dart';

class BackgroundPattern extends StatelessWidget {
  const BackgroundPattern({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BackgroundPatternPainter(),
      child: Container(),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade100.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    const dotSize = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }

    // Add subtle diagonal lines
    final linePaint = Paint()
      ..color = Colors.blue.shade100.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (double offset = 0;
        offset < size.width + size.height;
        offset += spacing * 2) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(0, offset),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
