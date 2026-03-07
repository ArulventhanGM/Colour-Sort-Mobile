import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../models/game_theme.dart';

/// Animated background pattern for the game
class BackgroundPattern extends StatefulWidget {
  const BackgroundPattern({super.key});

  @override
  State<BackgroundPattern> createState() => _BackgroundPatternState();
}

class _BackgroundPatternState extends State<BackgroundPattern> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Dreamy Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0F2FE), // Light blue
                Color(0xFFF3E8FF), // Light purple
                Color(0xFFFDF4FF), // Light pink
                Color(0xFFE0F2FE), // Light blue
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        
        // Floating Bubbles & Blurred Shapes
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: _DreamyBubblesPainter(
                animation: _animationController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class _DreamyBubblesPainter extends CustomPainter {
  final double animation;
  
  _DreamyBubblesPainter({required this.animation});
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); 
    
    // Draw blurred ambient background orbs for color variation
    for (int i = 0; i < 4; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      
      final xOffset = math.sin((animation + i * 0.25) * math.pi * 2) * size.width * 0.2;
      final yOffset = math.cos((animation + i * 0.25) * math.pi * 2) * size.height * 0.15;
      
      final px = (x + xOffset) % size.width;
      final py = (y + yOffset) % size.height;
      
      final radius = size.width * (0.3 + random.nextDouble() * 0.3);
      
      Color orbColor;
      if (i == 0) orbColor = const Color(0xFFC084FC).withOpacity(0.3); // vivid purple
      else if (i == 1) orbColor = const Color(0xFF60A5FA).withOpacity(0.2); // blue
      else if (i == 2) orbColor = const Color(0xFFF472B6).withOpacity(0.2); // pink
      else orbColor = const Color(0xFF34D399).withOpacity(0.15); // soft green

      final paint = Paint()
        ..color = orbColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
      
      canvas.drawCircle(Offset(px, py), radius, paint);
    }
    
    // Draw floating distinct "glass" bubbles
    for (int i = 0; i < 15; i++) {
        final speed = 0.5 + random.nextDouble();
        final startX = random.nextDouble() * size.width;
        // Float upwards
        final currentY = (size.height + 100) - (((animation * speed * 2) % 1.0) * (size.height + 200));
        
        // Wobble horizontally
        final wobble = math.sin(animation * math.pi * 4 * speed + i) * 30;
        final currentX = startX + wobble;
        
        final bubbleRadius = 10.0 + random.nextDouble() * 25.0;
        
        // Draw bubble outline
        final bubblePaint = Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
            
        canvas.drawCircle(Offset(currentX, currentY), bubbleRadius, bubblePaint);
        
        // Bubble highlight
        final highlightPaint = Paint()
            ..color = Colors.white.withOpacity(0.7)
            ..style = PaintingStyle.fill;
            
        // small oval highlight
        canvas.drawOval(
           Rect.fromCenter(
               center: Offset(currentX - bubbleRadius * 0.3, currentY - bubbleRadius * 0.3),
               width: bubbleRadius * 0.4,
               height: bubbleRadius * 0.2
           ),
           highlightPaint
        );
        
        // alternative simple highlight:
        canvas.drawCircle(Offset(currentX - bubbleRadius * 0.3, currentY - bubbleRadius * 0.3), bubbleRadius * 0.2, highlightPaint);
    }
    
    // Draw tiny stars/sparkles
    for (int i = 0; i < 20; i++) {
        final sx = random.nextDouble() * size.width;
        final sy = random.nextDouble() * size.height;
        final sizeBase = 2.0 + random.nextDouble() * 3.0;
        
        // Twinkle based on animation
        final twinkle = (math.sin(animation * math.pi * 10 + i) + 1) / 2; // 0 to 1
        
        final starPaint = Paint()
            ..color = Colors.white.withOpacity(0.3 + (twinkle * 0.6))
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
            
        canvas.drawCircle(Offset(sx, sy), sizeBase * (0.8 + twinkle * 0.4), starPaint);
        
        // Draw cross for star
        final crossPaint = Paint()
            ..color = Colors.white.withOpacity(0.5 + (twinkle * 0.5))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
            
        canvas.drawLine(Offset(sx - sizeBase * 2, sy), Offset(sx + sizeBase * 2, sy), crossPaint);
        canvas.drawLine(Offset(sx, sy - sizeBase * 2), Offset(sx, sy + sizeBase * 2), crossPaint);
    }
  }

  @override
  bool shouldRepaint(_DreamyBubblesPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

