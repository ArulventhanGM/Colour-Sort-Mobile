import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class TubePainter extends CustomPainter {
  final List<Color> colors;
  final bool isSelected;
  final int maxCapacity;
  final bool pouringAnimation;
  final double pouringProgress;

  TubePainter({
    required this.colors,
    this.isSelected = false,
    this.maxCapacity = 4,
    this.pouringAnimation = false,
    this.pouringProgress = 0.0,
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

    // Create a glass reflection effect
    final glassHighlight = Path()
      ..moveTo(offsetX + tubeWidth * 0.2, offsetY)
      ..lineTo(offsetX + tubeWidth * 0.35, offsetY)
      ..lineTo(offsetX + tubeWidth * 0.25, size.height - borderRadius * 1.3)
      ..lineTo(offsetX + tubeWidth * 0.1, size.height - borderRadius * 1.3)
      ..close();

    // Draw tube body with glass effect
    Paint glassPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.width, size.height),
        [Colors.white.withOpacity(0.2), Colors.transparent],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(tubePath, glassPaint);
    
    // Add glass reflection
    Paint highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glassHighlight, highlightPaint);
    
    // Draw tube outline
    canvas.drawPath(tubePath, paint);

    // Draw liquid levels
    double segmentHeight = (size.height - borderRadius * 2 - offsetY * 2) / maxCapacity;
    
    // If tube is not currently pouring or just starting the animation, draw liquid normally
    if (!pouringAnimation || pouringProgress <= 0.1) {
      _drawNormalLiquid(canvas, size, offsetX, offsetY, tubeWidth, borderRadius, segmentHeight);
    } 
    // Handle pouring animation 
    else {
      _drawPouringLiquid(canvas, size, offsetX, offsetY, tubeWidth, borderRadius, segmentHeight);
    }
    
    // Add liquid surface reflections for realism
    if (colors.isNotEmpty && (!pouringAnimation || pouringProgress < 0.7)) {
      _addLiquidSurfaceReflections(canvas, size, offsetX, offsetY, tubeWidth, borderRadius, segmentHeight);
    }
  }

  void _drawNormalLiquid(Canvas canvas, Size size, double offsetX, double offsetY, 
      double tubeWidth, double borderRadius, double segmentHeight) {
    for (int i = 0; i < colors.length; i++) {
      Paint waterPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height - (i + 1) * segmentHeight),
          Offset(size.width, size.height - i * segmentHeight),
          [colors[i].withOpacity(0.85), colors[i]],
        );
        
      // Add wave effect to the top liquid surface
      if (i == colors.length - 1) {
        // This is the top liquid surface - make it wavy
        final wavePath = Path();
        final topY = size.height - (i + 1) * segmentHeight - borderRadius;
        final bottomY = size.height - i * segmentHeight - borderRadius;
        
        wavePath.moveTo(offsetX, bottomY);
        
        // Create a subtle wave
        const waveHeight = 3.0;
        const waveCount = 3;
        
        for (int w = 0; w <= waveCount * 2; w++) {
          final waveX = offsetX + (tubeWidth / (waveCount * 2)) * w;
          final waveY = topY + (w % 2 == 0 ? waveHeight : -waveHeight);
          
          wavePath.lineTo(waveX, waveY);
        }
        
        wavePath.lineTo(offsetX + tubeWidth, bottomY);
        wavePath.lineTo(offsetX, bottomY);
        wavePath.close();
        
        canvas.drawPath(wavePath, waterPaint);
      } else {
        // Regular rectangle for lower liquid levels
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
  }
  
  void _drawPouringLiquid(Canvas canvas, Size size, double offsetX, double offsetY, 
      double tubeWidth, double borderRadius, double segmentHeight) {
    if (colors.isEmpty) return;
    
    // Draw the colors in the tube, except the top one which is being poured
    for (int i = 0; i < colors.length - 1; i++) {
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
    
    // Handle the top color that's being poured
    if (colors.isNotEmpty) {
      final topColorIndex = colors.length - 1;
      final topColor = colors[topColorIndex];
      
      // Calculate how much of the liquid remains in the tube
      final drainFactor = min(1.0, pouringProgress * 2.0); // Drain faster
      final remainingLiquidHeight = segmentHeight * (1.0 - drainFactor);
      
      // Only draw the remaining liquid if there's any
      if (remainingLiquidHeight > 0) {
        Paint topColorPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, size.height - (topColorIndex + 1) * segmentHeight + segmentHeight - remainingLiquidHeight),
            Offset(size.width, size.height - topColorIndex * segmentHeight),
            [topColor.withOpacity(0.85), topColor],
          );
          
        // Draw the partial top color with sloped surface for realism
        const slopeAngle = 0.3; // How sloped the liquid surface is when pouring
        
        final liquidPath = Path();
        
        // Start at bottom-left of liquid section
        liquidPath.moveTo(
          offsetX, 
          size.height - topColorIndex * segmentHeight - borderRadius - remainingLiquidHeight
        );
        
        // Draw sloped top surface (higher on the pouring side)
        if (pouringProgress > 0.2) {
          // Left-to-right pour
          liquidPath.lineTo(
            offsetX + tubeWidth, 
            size.height - topColorIndex * segmentHeight - borderRadius - remainingLiquidHeight * (1 - slopeAngle)
          );
          liquidPath.lineTo(
            offsetX + tubeWidth,
            size.height - topColorIndex * segmentHeight - borderRadius
          );
        } else {
          // Flat surface at beginning of animation
          liquidPath.lineTo(
            offsetX + tubeWidth,
            size.height - topColorIndex * segmentHeight - borderRadius - remainingLiquidHeight
          );
          liquidPath.lineTo(
            offsetX + tubeWidth,
            size.height - topColorIndex * segmentHeight - borderRadius
          );
        }
        
        // Complete the path
        liquidPath.lineTo(
          offsetX,
          size.height - topColorIndex * segmentHeight - borderRadius
        );
        liquidPath.close();
        
        canvas.drawPath(liquidPath, topColorPaint);
        
        // Add bubbles if pouring is in progress
        if (pouringProgress > 0.3 && pouringProgress < 0.8) {
          _addBubbles(canvas, topColor, offsetX, tubeWidth, 
            size.height - topColorIndex * segmentHeight - borderRadius - remainingLiquidHeight / 2,
            remainingLiquidHeight);
        }
      }
      
      // Draw liquid at the tube opening when pouring starts
      if (pouringProgress > 0.1 && pouringProgress < 0.5) {
        final dropletRadius = 3.0 + (pouringProgress - 0.1) * 5.0;
        
        // Position the droplet at the edge of the tube
        final dropletX = offsetX + tubeWidth;
        final dropletY = offsetY + 2.0;
        
        Paint dropletPaint = Paint()
          ..color = topColor
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(
          Offset(dropletX, dropletY), 
          dropletRadius, 
          dropletPaint
        );
      }
    }
  }
  
  void _addBubbles(Canvas canvas, Color liquidColor, double offsetX, double tubeWidth, double centerY, double height) {
    // Add random bubbles for realism
    final random = Random();
    final bubbleCount = 2 + random.nextInt(3); // 2-4 bubbles
    
    for (int i = 0; i < bubbleCount; i++) {
      final bubbleX = offsetX + tubeWidth * (0.2 + 0.6 * random.nextDouble());
      final bubbleY = centerY + (random.nextDouble() - 0.5) * height * 0.7;
      final bubbleSize = 1.5 + random.nextDouble() * 2.5;
      
      // Bubble gradient for 3D effect
      final bubblePaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(bubbleX - bubbleSize * 0.3, bubbleY - bubbleSize * 0.3),
          bubbleSize,
          [
            Colors.white.withOpacity(0.9),
            liquidColor.withOpacity(0.4),
          ],
          [0.0, 1.0],
        );
        
      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        bubbleSize,
        bubblePaint,
      );
    }
  }
  
  void _addLiquidSurfaceReflections(Canvas canvas, Size size, double offsetX, double offsetY, 
      double tubeWidth, double borderRadius, double segmentHeight) {
    if (colors.isEmpty) return;
    
    // Only add reflections to the top color
    final topColorIndex = colors.length - 1;
    final surfaceY = size.height - (topColorIndex + 1) * segmentHeight - borderRadius + 2;
    
    // Create a thin highlight on the liquid surface
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final highlightPath = Path()
      ..moveTo(offsetX + tubeWidth * 0.2, surfaceY)
      ..quadraticBezierTo(
        offsetX + tubeWidth * 0.5, surfaceY + 2,
        offsetX + tubeWidth * 0.8, surfaceY
      );
      
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(TubePainter oldDelegate) {
    return oldDelegate.colors != colors || 
           oldDelegate.isSelected != isSelected ||
           oldDelegate.pouringAnimation != pouringAnimation ||
           oldDelegate.pouringProgress != pouringProgress;
  }
}
