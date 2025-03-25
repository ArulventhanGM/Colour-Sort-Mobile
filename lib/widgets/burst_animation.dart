import 'dart:math';
import 'package:flutter/material.dart';

class BurstAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final VoidCallback? onComplete;

  const BurstAnimation({
    Key? key,
    this.color = Colors.yellow,
    this.size = 300.0,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  }) : super(key: key);

  @override
  State<BurstAnimation> createState() => _BurstAnimationState();
}

class _BurstAnimationState extends State<BurstAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    );
    
    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BurstPainter(
            progress: _animation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Paint _paint = Paint();
  final Random _random = Random();
  
  _BurstPainter({required this.progress, required this.color}) {
    _paint.style = PaintingStyle.fill;
    _paint.color = color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * progress;
    
    // Main circle burst
    _paint.color = color.withOpacity(1 - progress);
    canvas.drawCircle(center, radius, _paint);
    
    // Burst rays
    const rayCount = 12;
    final innerRadius = radius * 0.5;
    final outerRadius = radius * 1.2;
    
    for (int i = 0; i < rayCount; i++) {
      double angle = (i * 2 * pi / rayCount);
      
      // Add some randomness to the ray angles for a more dynamic effect
      angle += _random.nextDouble() * 0.2 - 0.1;
      
      final rayPath = Path();
      rayPath.moveTo(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );
      
      rayPath.lineTo(
        center.dx + outerRadius * cos(angle - 0.1),
        center.dy + outerRadius * sin(angle - 0.1),
      );
      
      rayPath.lineTo(
        center.dx + outerRadius * cos(angle + 0.1),
        center.dy + outerRadius * sin(angle + 0.1),
      );
      
      rayPath.close();
      
      _paint.color = color.withOpacity((1 - progress) * 0.8);
      canvas.drawPath(rayPath, _paint);
    }
    
    // Particles
    const particleCount = 20;
    final particleSize = size.width * 0.03;
    
    for (int i = 0; i < particleCount; i++) {
      final particleRadius = radius * (0.5 + _random.nextDouble() * 0.7);
      final particleAngle = _random.nextDouble() * 2 * pi;
      final particleOffset = Offset(
        center.dx + particleRadius * cos(particleAngle),
        center.dy + particleRadius * sin(particleAngle)
      );
      
      _paint.color = color.withOpacity((1 - progress) * 0.9);
      canvas.drawCircle(particleOffset, particleSize * (1 - progress), _paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
