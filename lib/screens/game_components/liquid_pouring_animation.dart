import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'game_animations.dart';

/// AAA Widget that renders a beautiful glowing liquid pouring animation between tubes
class LiquidPouringAnimation extends StatefulWidget {
  final Color pouringColor;
  final Offset pourStart;
  final Offset pourEnd;
  final Animation<double> pourAnimation;
  final double? angleDirection;

  const LiquidPouringAnimation({
    Key? key,
    required this.pouringColor,
    required this.pourStart,
    required this.pourEnd,
    required this.pourAnimation,
    this.angleDirection,
  }) : super(key: key);

  @override
  State<LiquidPouringAnimation> createState() => _LiquidPouringAnimationState();
}

class _LiquidPouringAnimationState extends State<LiquidPouringAnimation> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.pourAnimation,
      builder: (context, child) {
        final path = GameAnimations.createPouringPath(
            widget.pourStart, widget.pourEnd, widget.angleDirection);

        final metrics = path.computeMetrics().toList();
        if (metrics.isEmpty) return const SizedBox.shrink();
        
        final metric = metrics.first;
        final currentDistance = metric.length * widget.pourAnimation.value;
        if (currentDistance <= 0) return const SizedBox.shrink();

        final extractPath = metric.extractPath(0, currentDistance);

        return Stack(
          children: [
            // Glowing Stream
            CustomPaint(
               size: Size.infinite,
               painter: _LiquidStreamPainter(
                  path: extractPath,
                  color: widget.pouringColor,
               ),
            ),
            
            // Lively Splashing at Destination
            if (widget.pourAnimation.value > 0.4)
              Positioned(
                 left: widget.pourEnd.dx - 20,
                 top: widget.pourEnd.dy - 5,
                 child: _buildSplash(widget.pourAnimation.value),
              ),
              
            // Animated Particles
            ...List.generate(8, (index) {
               if (widget.pourAnimation.value < 0.2 || widget.pourAnimation.value > 0.9) {
                 return const SizedBox.shrink();
               }
               final r = Random(index);
               final offset = r.nextDouble() * currentDistance;
               final pos = metric.getTangentForOffset(offset);
               if (pos == null) return const SizedBox.shrink();
               
               final dxBounce = (r.nextDouble() - 0.5) * 20;
               final sz = 3.0 + r.nextDouble() * 5.0;
               
               return Positioned(
                  left: pos.position.dx + dxBounce,
                  top: pos.position.dy + r.nextDouble() * 10 - 5,
                  child: Container(
                     width: sz,
                     height: sz,
                     decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: widget.pouringColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                        ]
                     ),
                  )
               );
            }),
          ],
        );
      },
    );
  }
  
  Widget _buildSplash(double progress) {
     final p = progress < 0.7 ? progress : 1.0 - ((progress - 0.7) / 0.3);
     return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Container(
            width: 40 * p,
            height: 15 * p,
            decoration: BoxDecoration(
               color: widget.pouringColor,
               borderRadius: BorderRadius.circular(10),
               boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5, spreadRadius: 2)
               ]
            ),
        ),
     );
  }
}

class _LiquidStreamPainter extends CustomPainter {
   final Path path;
   final Color color;
   
   _LiquidStreamPainter({required this.path, required this.color});
   
   @override
   void paint(Canvas canvas, Size size) {
      // Glow
      final glowPaint = Paint()
         ..color = color.withOpacity(0.4)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 14.0
         ..strokeCap = StrokeCap.round
         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
         
      // Main Body
      final bodyPaint = Paint()
         ..color = color
         ..style = PaintingStyle.stroke
         ..strokeWidth = 8.0
         ..strokeCap = StrokeCap.round;
         
      // Specular Highlight (Inner lighter stripe)
      final highlightPaint = Paint()
         ..color = Colors.white.withOpacity(0.6)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 3.0
         ..strokeCap = StrokeCap.round;
         
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, bodyPaint);
      
      // slightly offset highlight to give 3D gloss
      canvas.save();
      canvas.translate(-2, 0);
      canvas.drawPath(path, highlightPaint);
      canvas.restore();
   }
   
   @override
   bool shouldRepaint(_LiquidStreamPainter oldDelegate) {
      return oldDelegate.path != path || oldDelegate.color != color;
   }
}
