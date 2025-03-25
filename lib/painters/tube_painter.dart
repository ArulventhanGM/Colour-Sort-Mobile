import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class TubePainter extends CustomPainter {
  final List<Color> colors;
  final bool isSelected;
  final int maxCapacity;
  final bool pouringAnimation;
  final double pouringProgress;
  // New parameters for enhanced animation
  final double waveOffset;
  final double liquidFillOffset;
  final bool isReceivingLiquid;

  TubePainter({
    required this.colors,
    this.isSelected = false,
    this.maxCapacity = 4,
    this.pouringAnimation = false,
    this.pouringProgress = 0.0,
    // Initialize new parameters with defaults
    this.waveOffset = 0.0,
    this.liquidFillOffset = 0.0,
    this.isReceivingLiquid = false,
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

    // Create a glass reflection effect - enhanced with more realistic glass look
    final glassHighlight = Path()
      ..moveTo(offsetX + tubeWidth * 0.2, offsetY)
      ..lineTo(offsetX + tubeWidth * 0.35, offsetY)
      ..lineTo(offsetX + tubeWidth * 0.25, size.height - borderRadius * 1.3)
      ..lineTo(offsetX + tubeWidth * 0.1, size.height - borderRadius * 1.3)
      ..close();

    // Draw tube body with enhanced glass effect - more transparent
    Paint glassPaint = Paint()
      ..shader = ui.Gradient.linear(
          const Offset(0, 0), Offset(size.width, size.height), [
        Colors.white.withOpacity(0.25),
        Colors.white.withOpacity(0.05),
        Colors.transparent
      ], [
        0.0,
        0.3,
        1.0
      ])
      ..style = PaintingStyle.fill;
    canvas.drawPath(tubePath, glassPaint);

    // Draw tube background with subtle glass texture
    Paint tubeBackgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(tubePath, tubeBackgroundPaint);

    // Add glass reflection
    Paint highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glassHighlight, highlightPaint);

    // Draw liquid levels
    double segmentHeight =
        (size.height - borderRadius * 2 - offsetY * 2) / maxCapacity;

    // If tube is not currently pouring or just starting the animation, draw liquid normally
    if (!pouringAnimation || pouringProgress <= 0.1) {
      _drawNormalLiquid(canvas, size, offsetX, offsetY, tubeWidth, borderRadius,
          segmentHeight);
    }
    // Handle pouring animation
    else {
      _drawPouringLiquid(canvas, size, offsetX, offsetY, tubeWidth,
          borderRadius, segmentHeight);
    }

    // Add liquid surface reflections for realism
    if (colors.isNotEmpty && (!pouringAnimation || pouringProgress < 0.7)) {
      _addLiquidSurfaceReflections(canvas, size, offsetX, offsetY, tubeWidth,
          borderRadius, segmentHeight);
    }

    // Add receiving liquid splash effect when tube is receiving liquid
    if (isReceivingLiquid && liquidFillOffset > 0) {
      _addReceivingSplashEffect(canvas, size, offsetX, tubeWidth,
          colors.isEmpty ? Colors.blue : colors.last, borderRadius);
    }

    // Draw tube outline - on top of everything for crisp edges
    canvas.drawPath(tubePath, paint);
  }

  void _drawNormalLiquid(
      Canvas canvas,
      Size size,
      double offsetX,
      double offsetY,
      double tubeWidth,
      double borderRadius,
      double segmentHeight) {
    for (int i = 0; i < colors.length; i++) {
      // Use a richer gradient for more realistic liquid appearance
      Paint waterPaint = Paint()
        ..shader = ui.Gradient.linear(
            Offset(0, size.height - (i + 1) * segmentHeight),
            Offset(size.width, size.height - i * segmentHeight), [
          colors[i].withOpacity(0.75), // More transparent at edges
          colors[i].withOpacity(0.9), // More saturated in middle
          colors[i], // Full color
        ], [
          0.0,
          0.4,
          1.0
        ]);

      // Add wave effect to the top liquid surface with dynamic waveOffset
      if (i == colors.length - 1) {
        // This is the top liquid surface - make it wavy
        final wavePath = Path();
        final topY = size.height - (i + 1) * segmentHeight - borderRadius;
        final bottomY = size.height - i * segmentHeight - borderRadius;

        wavePath.moveTo(offsetX, bottomY);

        // Create a more dynamic wave with time-based animation
        final waveHeight = isSelected ? 4.0 : 2.5; // Bigger waves when selected
        const waveCount = 4; // More waves for more detail

        for (int w = 0; w <= waveCount * 2; w++) {
          final waveX = offsetX + (tubeWidth / (waveCount * 2)) * w;

          // Use sine wave with phase shift from waveOffset for smooth animation
          final normalizedOffset = w / (waveCount * 2);
          final wavePhase = waveOffset + normalizedOffset * 2 * pi;
          final waveY = topY + sin(wavePhase) * waveHeight;

          wavePath.lineTo(waveX, waveY);
        }

        wavePath.lineTo(offsetX + tubeWidth, bottomY);
        wavePath.lineTo(offsetX, bottomY);
        wavePath.close();

        canvas.drawPath(wavePath, waterPaint);

        // Add foam/bubbles at the edges of the top liquid for more realism
        if (isSelected) {
          _addFoamBubbles(
              canvas, colors[i], offsetX, offsetX + tubeWidth, topY, 3);
        }
      } else {
        // Calculate any fill animation offset for this segment
        double segmentOffset = 0.0;
        if (isReceivingLiquid && i == colors.length - 1) {
          segmentOffset = liquidFillOffset * segmentHeight;
        }

        // Regular rectangle for lower liquid levels
        canvas.drawRect(
          Rect.fromLTWH(
            offsetX,
            size.height -
                (i + 1) * segmentHeight -
                borderRadius -
                segmentOffset,
            tubeWidth,
            segmentHeight + segmentOffset,
          ),
          waterPaint,
        );
      }
    }
  }

  void _drawPouringLiquid(
      Canvas canvas,
      Size size,
      double offsetX,
      double offsetY,
      double tubeWidth,
      double borderRadius,
      double segmentHeight) {
    if (colors.isEmpty) return;

    // Draw the colors in the tube, except the top one which is being poured
    for (int i = 0; i < colors.length - 1; i++) {
      Paint waterPaint = Paint()
        ..shader = ui.Gradient.linear(
            Offset(0, size.height - (i + 1) * segmentHeight),
            Offset(size.width, size.height - i * segmentHeight), [
          colors[i].withOpacity(0.75),
          colors[i].withOpacity(0.9),
          colors[i],
        ], [
          0.0,
          0.4,
          1.0
        ]);

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

      // Calculate dynamic wave properties based on pouring progress
      double amplitude = sin(waveOffset) * 3.0 * (1.0 - pouringProgress);
      double frequency = 2.0 + pouringProgress * 4.0;

      // Calculate remaining liquid with smoother draining
      final drainFactor = min(1.0, pouringProgress * 2.0);
      final remainingLiquidHeight = segmentHeight * (1.0 - drainFactor);

      if (remainingLiquidHeight > 0) {
        // Create a smoother liquid path with bezier curves
        Path liquidPath = Path();

        // Starting point at bottom-left of liquid section
        liquidPath.moveTo(offsetX,
            size.height - topColorIndex * segmentHeight - borderRadius);

        // Create wave effect on liquid surface
        List<Point<double>> points = [];
        for (int i = 0; i <= 10; i++) {
          double x = i / 10.0 * tubeWidth + offsetX;
          double y = size.height -
              topColorIndex * segmentHeight -
              borderRadius -
              remainingLiquidHeight +
              amplitude * sin(frequency * i / 10.0 + waveOffset);
          points.add(Point(x, y));
        }

        // Draw smooth curve through points
        liquidPath.moveTo(points[0].x.toDouble(), points[0].y.toDouble());
        for (int i = 0; i < points.length - 1; i++) {
          double xc = (points[i].x + points[i + 1].x) / 2;
          double yc = (points[i].y + points[i + 1].y) / 2;
          liquidPath.quadraticBezierTo(
              points[i].x.toDouble(), points[i].y.toDouble(), xc, yc);
        }

        // Complete the path
        liquidPath.lineTo(offsetX + tubeWidth,
            size.height - topColorIndex * segmentHeight - borderRadius);
        liquidPath.lineTo(offsetX,
            size.height - topColorIndex * segmentHeight - borderRadius);
        liquidPath.close();

        // Draw liquid with gradient for depth effect
        final gradient = ui.Gradient.linear(
          Offset(offsetX, size.height - topColorIndex * segmentHeight),
          Offset(
              offsetX + tubeWidth, size.height - topColorIndex * segmentHeight),
          [
            topColor.withOpacity(0.9),
            topColor,
            topColor.withOpacity(0.9),
          ],
          [0.0, 0.5, 1.0],
        );

        final gradientPaint = Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill;

        canvas.drawPath(liquidPath, gradientPaint);

        // Add bubble effects during pouring
        if (pouringProgress > 0.2 && pouringProgress < 0.8) {
          _addBubbleEffects(canvas, size, offsetX, tubeWidth, topColor,
              topColorIndex, segmentHeight, borderRadius);
        }
      }

      // Draw pouring stream with droplets
      if (pouringProgress > 0.1 && pouringProgress < 0.9) {
        _drawPouringStream(
            canvas, topColor, offsetX + tubeWidth, offsetY, pouringProgress);
      }
    }
  }

  void _addBubbleEffects(
      Canvas canvas,
      Size size,
      double offsetX,
      double tubeWidth,
      Color liquidColor,
      int topColorIndex,
      double segmentHeight,
      double borderRadius) {
    final random = Random();
    final bubbleCount = 3 + (pouringProgress * 5).round();

    for (int i = 0; i < bubbleCount; i++) {
      double bubbleX =
          offsetX + random.nextDouble() * tubeWidth * 0.8 + tubeWidth * 0.1;
      double bubbleY = size.height -
          topColorIndex * segmentHeight -
          borderRadius -
          random.nextDouble() * segmentHeight * pouringProgress;

      double bubbleSize = 2 + random.nextDouble() * 3;

      // Draw bubble with gradient for 3D effect
      final bubbleGradient = ui.Gradient.radial(
        Offset(bubbleX - bubbleSize * 0.3, bubbleY - bubbleSize * 0.3),
        bubbleSize,
        [
          Colors.white.withOpacity(0.8),
          liquidColor.withOpacity(0.3),
        ],
      );

      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        bubbleSize,
        Paint()..shader = bubbleGradient,
      );
    }
  }

  void _drawPouringStream(Canvas canvas, Color liquidColor, double startX,
      double startY, double progress) {
    // Define the stream path
    final streamWidth = 2.0 + progress * 3.0; // Stream gets thinner as it pours
    final streamLength =
        60.0 + progress * 40.0; // Stream gets longer as it pours

    // Add some randomization to make it look more natural
    final wiggle = sin(progress * 10) * 2.0;

    final streamPath = Path()
      ..moveTo(startX, startY)
      ..quadraticBezierTo(startX + wiggle, startY + streamLength / 2,
          startX + wiggle * 2, startY + streamLength);

    // Draw the stream with gradient
    final streamPaint = Paint()
      ..shader = ui.Gradient.linear(
          Offset(startX, startY), Offset(startX, startY + streamLength), [
        liquidColor,
        liquidColor.withOpacity(0.7),
      ], [
        0.0,
        1.0
      ])
      ..style = PaintingStyle.stroke
      ..strokeWidth = streamWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(streamPath, streamPaint);

    // Add droplets falling from the stream
    final dropletCount = 1 + (progress * 5).floor();
    for (int i = 0; i < dropletCount; i++) {
      final dropProgress = (progress + i / 10) % 1.0;
      final dropY = startY + streamLength * 0.7 + dropProgress * 50.0;
      final dropX = startX + wiggle + sin(dropProgress * 10) * 5.0;
      final dropSize = 2.0 + (1.0 - dropProgress) * 2.0;

      final dropPaint = Paint()
        ..shader = ui.Gradient.radial(
            Offset(dropX - dropSize * 0.3, dropY - dropSize * 0.3), dropSize, [
          Colors.white.withOpacity(0.8),
          liquidColor,
        ], [
          0.0,
          1.0
        ]);

      canvas.drawCircle(Offset(dropX, dropY), dropSize, dropPaint);
    }
  }

  void _addReceivingSplashEffect(Canvas canvas, Size size, double offsetX,
      double tubeWidth, Color liquidColor, double borderRadius) {
    final random = Random();
    final splashCenter =
        Offset(offsetX + tubeWidth / 2, size.height - borderRadius * 1.1);

    // Create splash particles radiating outward
    final particleCount = 8 + (liquidFillOffset * 8).round();

    for (int i = 0; i < particleCount; i++) {
      final angle = i * 2 * pi / particleCount;
      final distance = 3.0 + liquidFillOffset * 10.0;
      final particleSize = 1.0 + random.nextDouble() * 2.0;

      final particleX = splashCenter.dx + cos(angle) * distance;
      final particleY =
          splashCenter.dy + sin(angle) * distance * 0.6; // Elliptical

      // Splash particle with highlight
      final particlePaint = Paint()
        ..shader =
            ui.Gradient.radial(Offset(particleX, particleY), particleSize, [
          Colors.white.withOpacity(0.9),
          liquidColor.withOpacity(0.8),
          liquidColor.withOpacity(0.0),
        ], [
          0.0,
          0.5,
          1.0
        ]);

      canvas.drawCircle(
          Offset(particleX, particleY), particleSize, particlePaint);
    }

    // Add a ripple effect
    final ripplePaint = Paint()
      ..color = liquidColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(splashCenter, 8.0 + liquidFillOffset * 10.0, ripplePaint);
  }

  void _addFoamBubbles(Canvas canvas, Color liquidColor, double leftX,
      double rightX, double surfaceY, int count) {
    final random = Random();

    for (int i = 0; i < count; i++) {
      // Position bubbles at the edges where foam would naturally form
      double bubbleX;
      if (i < count / 2) {
        // Left side
        bubbleX = leftX + random.nextDouble() * 8.0;
      } else {
        // Right side
        bubbleX = rightX - random.nextDouble() * 8.0;
      }

      final bubbleY = surfaceY + random.nextDouble() * 4.0 - 2.0;
      final bubbleSize = 1.0 + random.nextDouble() * 1.5;

      final bubblePaint = Paint()
        ..color = Colors.white.withOpacity(0.6 + random.nextDouble() * 0.3);

      canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleSize, bubblePaint);
    }
  }

  void _addLiquidSurfaceReflections(
      Canvas canvas,
      Size size,
      double offsetX,
      double offsetY,
      double tubeWidth,
      double borderRadius,
      double segmentHeight) {
    if (colors.isEmpty) return;

    // Only add reflections to the top color
    final topColorIndex = colors.length - 1;
    final surfaceY =
        size.height - (topColorIndex + 1) * segmentHeight - borderRadius + 2;

    // Create a thin highlight on the liquid surface - more dynamic with waveOffset
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final highlightPath = Path()
      ..moveTo(offsetX + tubeWidth * 0.2, surfaceY + sin(waveOffset) * 2)
      ..quadraticBezierTo(
          offsetX + tubeWidth * 0.5,
          surfaceY + 2 + cos(waveOffset + 1) * 2,
          offsetX + tubeWidth * 0.8,
          surfaceY + sin(waveOffset + 2) * 2);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(TubePainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.pouringAnimation != pouringAnimation ||
        oldDelegate.pouringProgress != pouringProgress ||
        oldDelegate.waveOffset != waveOffset ||
        oldDelegate.liquidFillOffset != liquidFillOffset ||
        oldDelegate.isReceivingLiquid != isReceivingLiquid;
  }
}
