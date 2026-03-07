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
    final tubeWidth = width * 0.75;
    final tubeHeight = height * 0.95;
    final tubeLeft = (width - tubeWidth) / 2;
    final tubeTop = height * 0.02; 
    final bottomRadius = tubeWidth * 0.5;
    
    // Gap from top before liquids start
    final topPadding = tubeHeight * 0.1;
    final liquidAreaHeight = tubeHeight - topPadding - bottomRadius;
    final colorHeight = liquidAreaHeight / maxCapacity;

    if (angle != null) {
      canvas.save();
      canvas.translate(width / 2, height / 2);
      canvas.rotate(angle!);
      canvas.translate(-width / 2, -height / 2);
    }

    final tubePath = Path();
    tubePath.moveTo(tubeLeft, tubeTop);
    tubePath.lineTo(tubeLeft + tubeWidth, tubeTop);
    tubePath.lineTo(tubeLeft + tubeWidth, tubeTop + tubeHeight - bottomRadius);
    final bottomRect = Rect.fromLTRB(
      tubeLeft,
      tubeTop + tubeHeight - 2 * bottomRadius,
      tubeLeft + tubeWidth,
      tubeTop + tubeHeight,
    );
    tubePath.arcTo(bottomRect, 0, pi, false);
    tubePath.lineTo(tubeLeft, tubeTop);
    tubePath.close();

    // Draw inner tube background shadow/depth
    final backWallGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.0),
        Colors.black.withOpacity(0.1),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    canvas.drawPath(
      tubePath,
      Paint()
        ..shader = backWallGradient.createShader(Rect.fromLTWH(tubeLeft, tubeTop, tubeWidth, tubeHeight))
        ..style = PaintingStyle.fill,
    );

    // DRAW LIQUIDS
    canvas.save();
    canvas.clipPath(tubePath);

    // We draw liquids from bottom up so top layers overlap correctly
    for (int i = 0; i < colors.length; i++) {
      // Index from bottom (0 is bottom-most, but colors[0] is bottom in our data model)
      // Actually colors[0] is usually bottom in water sort. Let's assume colors[0] is bottom layer.
      final layerIndex = i;
      
      final colorBaseTop = tubeTop + topPadding + liquidAreaHeight - (layerIndex * colorHeight);
      
      double animOffset = 0;
      if (isReceivingLiquid && i == colors.length - 1 && liquidFillOffset != null) {
        animOffset = colorHeight * (1 - (liquidFillOffset as double));
      } else if (pouringAnimation && pouringProgress > 0 && i == colors.length - 1) {
        animOffset = colorHeight * pouringProgress;
      }

      double waveHeight = 0;
      if (waveOffset != null && isSelected && i == colors.length - 1) {
        waveHeight = sin(waveOffset as double) * 4;
      }

      final colorTop = colorBaseTop - animOffset + waveHeight;
      final currentColorHeight = colorHeight + animOffset;
      
      // We draw each liquid layer extending down to the bottom of the tube to cover the rounded part nicely,
      // but only if it's the bottom layer. The subsequent layers sit on top.
      // Wait, since we clip to the tube, we can just draw rectangles!
      // To allow smooth curves at the boundary, we draw a curved path.
      
      Path liquidLayerPath = Path();
      
      // Top curve
      liquidLayerPath.moveTo(tubeLeft, colorTop);
      
      // Add subtle meniscus (curve) at top
      liquidLayerPath.quadraticBezierTo(
        tubeLeft + tubeWidth / 2, 
        colorTop + (isSelected ? waveHeight * 1.5 : 4), 
        tubeLeft + tubeWidth, 
        colorTop
      );
      
      // Right edge down
      // If bottom layer, go all the way to bottom, otherwise to bottom of *this* layer
      double bottomY = layerIndex == 0 ? (tubeTop + tubeHeight) : (colorBaseTop + colorHeight + 2); // +2 to prevent gaps
      liquidLayerPath.lineTo(tubeLeft + tubeWidth, bottomY);
      liquidLayerPath.lineTo(tubeLeft, bottomY);
      liquidLayerPath.close();

      // Liquid base color gradient (darker edges, brighter center)
      final liquidGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _darken(colors[i], 0.15),
          colors[i],
          _darken(colors[i], 0.2),
        ],
        stops: const [0.0, 0.4, 1.0],
      );
      
      canvas.drawPath(
        liquidLayerPath,
        Paint()
          ..shader = liquidGradient.createShader(Rect.fromLTWH(tubeLeft, colorTop, tubeWidth, currentColorHeight))
          ..style = PaintingStyle.fill,
      );
      
      // Top surface highlight (oval)
      final topSurfaceRect = Rect.fromCenter(
        center: Offset(tubeLeft + tubeWidth / 2, colorTop),
        width: tubeWidth, 
        height: tubeWidth * 0.25
      );
      final surfaceGradient = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.white.withOpacity(0.6),
          colors[i].withOpacity(0.8),
          _darken(colors[i], 0.2).withOpacity(0.9),
        ]
      );
      canvas.drawOval(
        topSurfaceRect, 
        Paint()..shader = surfaceGradient.createShader(topSurfaceRect)
      );

      // Add bubbles
      _drawBubbles(canvas, tubeLeft, colorTop, tubeWidth, currentColorHeight, layerIndex, colors[i]);
    }
    canvas.restore();

    // DRAW TUBE REFLECTIONS / GLASS HIGHLIGHTS (over liquids)
    
    // Left rim highlight (thick specular curve)
    final leftHighlightPath = Path();
    leftHighlightPath.moveTo(tubeLeft + tubeWidth * 0.1, tubeTop + topPadding);
    leftHighlightPath.lineTo(tubeLeft + tubeWidth * 0.1, tubeTop + tubeHeight - bottomRadius);
    leftHighlightPath.arcTo(
      Rect.fromLTRB(
        tubeLeft + tubeWidth * 0.1, 
        tubeTop + tubeHeight - 2 * bottomRadius + tubeWidth * 0.1, 
        tubeLeft + tubeWidth - tubeWidth * 0.1, 
        tubeTop + tubeHeight - tubeWidth * 0.1
      ), 
      pi, 
      -pi / 2.5, 
      false
    );
    
    canvas.drawPath(
      leftHighlightPath,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = tubeWidth * 0.08
        ..strokeCap = StrokeCap.round,
    );
    
    // Right thin edge highlight
    canvas.drawLine(
      Offset(tubeLeft + tubeWidth * 0.95, tubeTop + topPadding),
      Offset(tubeLeft + tubeWidth * 0.95, tubeTop + tubeHeight - bottomRadius),
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = tubeWidth * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Glowing Outline (Selected) or Normal Outline
    if (isSelected) {
      canvas.drawPath(
        tubePath,
        Paint()
          ..color = accentColor.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
      );
      canvas.drawPath(
        tubePath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    } else {
      // Soft glass boundary outline
      canvas.drawPath(
        tubePath,
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      canvas.drawPath(
        tubePath,
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Top Rim Output (3D Oval Ring)
    final rimRect = Rect.fromCenter(
      center: Offset(tubeLeft + tubeWidth / 2, tubeTop),
      width: tubeWidth + 6,
      height: tubeWidth * 0.25,
    );
    
    // Rim shadow
    canvas.drawOval(
      rimRect.translate(0, 2),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    
    // Rim body
    canvas.drawOval(
      rimRect,
      Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    
    // Rim top bright highlight
    canvas.drawArc(
      rimRect,
      pi + pi / 4,
      pi / 2,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    if (angle != null) canvas.restore();
  }

  void _drawBubbles(Canvas canvas, double left, double top, double width, double height, int seed, Color baseColor) {
    final rand = Random(seed + 100);
    final numBubbles = 4 + rand.nextInt(5);
    
    for (int j = 0; j < numBubbles; j++) {
      double bx = left + 4 + rand.nextDouble() * (width - 8);
      // Ensure bubbles are well within the vertical space
      double by = top + 10 + rand.nextDouble() * (height - 20); 
      double bSize = 1.5 + rand.nextDouble() * 2.5;

      // Draw bubble
      canvas.drawCircle(
        Offset(bx, by),
        bSize,
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      // Bubble inner highlight
      canvas.drawCircle(
        Offset(bx - bSize * 0.3, by - bSize * 0.3),
        bSize * 0.3,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
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

