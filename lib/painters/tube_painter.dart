import 'package:flutter/material.dart';
import 'dart:math';

/// Custom painter for the game tubes
class TubePainter extends CustomPainter {
  final List<Color> colors;
  final bool isSelected;
  final double? angle;
  final bool isReceiving;
  final int maxColors;
  final AnimationController? liquidAnimation;
  
  // New parameters for the enhanced animations
  final int maxCapacity;
  final double? waveOffset;
  final double? liquidFillOffset;
  final bool pouringAnimation;
  final double pouringProgress;
  final bool isReceivingLiquid;

  // Default theme color for tube outline
  final Color tubeOutlineColor;
  final Color accentColor;

  TubePainter({
    required this.colors,
    this.isSelected = false,
    this.angle,
    this.isReceiving = false,
    this.maxColors = 4,
    this.liquidAnimation,
    this.maxCapacity = 4,
    this.waveOffset = 0,
    this.liquidFillOffset = 0,
    this.pouringAnimation = false,
    this.pouringProgress = 0,
    this.isReceivingLiquid = false,
    this.tubeOutlineColor = const Color(0xFF555555),
    this.accentColor = const Color(0xFF4CAF50),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate dimensions
    final width = size.width;
    final height = size.height;
    final tubeWidth = width * 0.65; // Original tube width proportion
    final tubeHeight = height * 0.9;
    final tubeLeft = (width - tubeWidth) / 2;
    final tubeTop = height * 0.05; // Position tube higher up
    final bottomRadius = tubeWidth * 0.5; // Larger rounded bottom
    final colorHeight = tubeHeight / maxCapacity;
    
    // Save canvas for rotation if needed
    if (angle != null) {
      canvas.save();
      // Rotate around center of tube
      canvas.translate(width / 2, height / 2);
      canvas.rotate(angle!);
      canvas.translate(-width / 2, -height / 2);
    }
    
    // Create test tube path with straight sides and rounded bottom
    final tubePath = Path();
    
    // Top left point
    tubePath.moveTo(tubeLeft, tubeTop);
    
    // Top right point and straight line down right side
    tubePath.lineTo(tubeLeft + tubeWidth, tubeTop);
    tubePath.lineTo(tubeLeft + tubeWidth, tubeTop + tubeHeight - bottomRadius);
    
    // Rounded bottom curve
    final bottomRect = Rect.fromLTRB(
      tubeLeft, 
      tubeTop + tubeHeight - 2 * bottomRadius,
      tubeLeft + tubeWidth, 
      tubeTop + tubeHeight
    );
    tubePath.arcTo(bottomRect, 0, pi, false);
    
    // Straight line up left side back to top
    tubePath.lineTo(tubeLeft, tubeTop);
    tubePath.close();
    
    // Draw tube background (glass effect)
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.3),
        Colors.white.withOpacity(0.1),
      ],
    );
    
    final glassPaint = Paint()
      ..shader = glassGradient.createShader(Rect.fromLTWH(tubeLeft, tubeTop, tubeWidth, tubeHeight))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(tubePath, glassPaint);
    
    // Clip to tube for liquid colors
    canvas.save(); // Save state before clipping
    canvas.clipPath(tubePath);
    
    // Draw liquid colors inside tube with wave effect if needed
    for (int i = 0; i < colors.length; i++) {
      final colorTop = tubeTop + tubeHeight - ((i + 1) * colorHeight);
      
      // Animation for receiving tube or pouring
      double animOffset = 0;
      if (isReceivingLiquid && i == colors.length - 1 && liquidFillOffset != null) {
        animOffset = colorHeight * (1 - (liquidFillOffset as double));
      } else if (pouringAnimation && pouringProgress > 0 && i == colors.length - 1) {
        // Apply pouring animation effect
        animOffset = colorHeight * pouringProgress;
      }
      
      // Apply wave effect for natural liquid movement
      double waveHeight = 0;
      if (waveOffset != null && isSelected) {
        // Small wave effect for selected tube (more noticeable at top)
        waveHeight = i == colors.length - 1 ? sin(waveOffset as double) * 3 : 0;
      }
      
      final colorRect = Rect.fromLTWH(
        tubeLeft,
        colorTop - animOffset + waveHeight,
        tubeWidth,
        colorHeight + animOffset,
      );
      
      final liquidGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors[i].withOpacity(0.9),
          colors[i],
        ],
      );
      
      final liquidPaint = Paint()
        ..shader = liquidGradient.createShader(colorRect)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(colorRect, liquidPaint);
      
      // Add shine highlight to liquid
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(
          tubeLeft + tubeWidth * 0.7,
          colorTop - animOffset + waveHeight,
          tubeWidth * 0.3,
          colorHeight * 0.3,
        ),
        highlightPaint,
      );
    }
    
    // Reset clip
    canvas.restore(); // Restore after drawing liquids
    
    // Draw tube outline with themed color
    final outlinePaint = Paint()
      ..color = isSelected 
          ? accentColor
          : tubeOutlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;
    
    canvas.drawPath(tubePath, outlinePaint);
    
    // Draw tube "rim" at the top
    final rimPaint = Paint()
      ..color = tubeOutlineColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawLine(
      Offset(tubeLeft, tubeTop),
      Offset(tubeLeft + tubeWidth, tubeTop),
      rimPaint,
    );
    
    // Restore canvas if rotated
    if (angle != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(TubePainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.angle != angle ||
        oldDelegate.isReceiving != isReceiving ||
        oldDelegate.liquidAnimation?.value != liquidAnimation?.value ||
        oldDelegate.waveOffset != waveOffset ||
        oldDelegate.liquidFillOffset != liquidFillOffset ||
        oldDelegate.pouringAnimation != pouringAnimation ||
        oldDelegate.pouringProgress != pouringProgress ||
        oldDelegate.isReceivingLiquid != isReceivingLiquid;
  }
}
