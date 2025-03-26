import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';

/// Animated background pattern for the game
class BackgroundPattern extends StatelessWidget {
  const BackgroundPattern({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: currentTheme.backgroundGradient,
      ),
      child: CustomPaint(
        painter: _BackgroundPatternPainter(themeColor: currentTheme.primaryColor),
        size: Size.infinite,
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final Color themeColor;

  _BackgroundPatternPainter({required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = themeColor.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw background pattern - circles
    for (int i = 0; i < 20; i++) {
      final radius = (size.width / 10) * (i % 3 + 1);
      canvas.drawCircle(
        Offset(
          size.width * 0.1 + (i % 5) * size.width * 0.2,
          (i ~/ 5) * size.height * 0.25,
        ),
        radius,
        paint,
      );
    }
    
    // Add a subtle grid pattern
    final gridPaint = Paint()
      ..color = themeColor.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final gridSize = 30.0;
    
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPatternPainter oldDelegate) {
    return oldDelegate.themeColor != themeColor;
  }
}
