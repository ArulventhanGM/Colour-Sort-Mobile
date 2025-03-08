import 'package:flutter/material.dart';
import 'dart:math';

class SplashEffect extends StatelessWidget {
  final Offset offset;
  final Color color;
  final double size;
  final VoidCallback onComplete;
  final bool isColorMixing;

  const SplashEffect({
    Key? key,
    required this.offset,
    required this.color,
    required this.size,
    required this.onComplete,
    this.isColorMixing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        onEnd: onComplete,
        builder: (context, value, child) {
          return Transform.scale(
            scale: Curves.easeOutBack.transform(value),
            child: CustomPaint(
              size: Size(size, size),
              painter: _SplashPainter(
                progress: value,
                color: color,
                isColorMixing: isColorMixing,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isColorMixing;

  _SplashPainter({
    required this.progress,
    required this.color,
    this.isColorMixing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * progress;

    // Draw main splash circle
    final mainSplashPaint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, mainSplashPaint);

    // Draw outer ring
    final outerRingPaint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius * 1.2, outerRingPaint);

    if (isColorMixing) {
      // Add particles for color mixing effect
      final particleCount = 8;
      final random = Random(42); // Fixed seed for consistent effect

      for (int i = 0; i < particleCount; i++) {
        final angle = (i * 2 * pi / particleCount) + progress * pi;
        final particleRadius = radius * (0.3 + random.nextDouble() * 0.7);
        final x = center.dx + cos(angle) * particleRadius;
        final y = center.dy + sin(angle) * particleRadius;

        final particleSize = size.width * 0.1 * (1 - progress);
        final particlePaint = Paint()
          ..color = color.withOpacity((1 - progress) * 0.5)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isColorMixing != isColorMixing;
  }
}
