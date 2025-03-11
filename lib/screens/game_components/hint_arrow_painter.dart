import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Custom painter for drawing animated hint arrows between tubes
class HintArrowPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Animation<double> animation;
  final Color arrowColor;
  final double arrowWidth;
  final bool pulsate;

  HintArrowPainter({
    required this.startPoint,
    required this.endPoint,
    required this.animation,
    this.arrowColor = Colors.amber,
    this.arrowWidth = 5.0,
    this.pulsate = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate path progress based on animation
    final pathProgress = animation.value;
    
    // Create a path for the arrow
    final path = Path();
    
    // Calculate the current point along the path
    final currentPoint = Offset.lerp(startPoint, endPoint, pathProgress)!;
    
    // Calculate the angle of the line for the arrow head
    final angle = math.atan2(
      endPoint.dy - startPoint.dy, 
      endPoint.dx - startPoint.dx
    );
    
    // Calculate pulsating effect if enabled
    double effectiveWidth = arrowWidth;
    double opacity = 1.0;
    
    if (pulsate) {
      // Add pulse effect using sine wave based on animation value
      final pulse = math.sin(animation.value * math.pi * 2 * 2) * 0.3 + 0.7;
      effectiveWidth = arrowWidth * pulse;
      opacity = 0.7 + (pulse * 0.3);
    }
    
    // Create a gradient paint for the line
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        startPoint,
        endPoint,
        [
          arrowColor.withOpacity(opacity * 0.8),
          arrowColor.withOpacity(opacity),
        ],
      )
      ..strokeWidth = effectiveWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw the line
    path.moveTo(startPoint.dx, startPoint.dy);
    
    // Draw a slight curve for more visual appeal
    final midPoint = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2 - 10,
    );
    
    if (pathProgress < 1.0) {
      // Draw a quadratic curve to the current point for animation
      final animatedMidPoint = Offset.lerp(startPoint, midPoint, pathProgress * 2 > 1 ? 1 : pathProgress * 2)!;
      if (pathProgress < 0.5) {
        path.quadraticBezierTo(
          animatedMidPoint.dx,
          animatedMidPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      } else {
        path.quadraticBezierTo(
          midPoint.dx,
          midPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    } else {
      // Draw the full path when animation is complete
      path.quadraticBezierTo(
        midPoint.dx,
        midPoint.dy,
        endPoint.dx,
        endPoint.dy,
      );
    }
    
    // Draw the path
    canvas.drawPath(path, paint);
    
    // Draw arrow head if we're near the end of the animation
    if (pathProgress > 0.9) {
      final arrowSize = effectiveWidth * 4;
      
      final arrowPath = Path();
      
      // Create arrow head
      arrowPath.moveTo(
        endPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
        endPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
      );
      arrowPath.lineTo(endPoint.dx, endPoint.dy);
      arrowPath.lineTo(
        endPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
        endPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
      );
      
      // Use a solid color for arrow head
      final arrowPaint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = effectiveWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      
      canvas.drawPath(arrowPath, arrowPaint);
      
      // Add a pulse highlight at the end point
      final highlightPaint = Paint()
        ..color = arrowColor.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      
      final highlightSize = arrowSize * (1.0 + math.sin(animation.value * math.pi * 8) * 0.3);
      canvas.drawCircle(endPoint, highlightSize / 2, highlightPaint);
    }
    
    // Add subtle glow effect along the line
    if (pathProgress > 0.3) {
      final glowPaint = Paint()
        ..shader = ui.Gradient.linear(
          startPoint,
          currentPoint,
          [
            arrowColor.withOpacity(0.0),
            arrowColor.withOpacity(0.3),
          ],
        )
        ..strokeWidth = effectiveWidth * 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      final glowPath = Path();
      glowPath.moveTo(startPoint.dx, startPoint.dy);
      
      if (pathProgress < 0.5) {
        final animatedMidPoint = Offset.lerp(startPoint, midPoint, pathProgress * 2)!;
        glowPath.quadraticBezierTo(
          animatedMidPoint.dx,
          animatedMidPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      } else {
        glowPath.quadraticBezierTo(
          midPoint.dx,
          midPoint.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
      
      canvas.drawPath(glowPath, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HintArrowPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.arrowColor != arrowColor ||
        oldDelegate.arrowWidth != arrowWidth;
  }
}
