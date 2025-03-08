import 'package:flutter/material.dart';
import 'dart:math';

class SplashEffect extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final VoidCallback? onComplete;

  const SplashEffect({
    Key? key,
    required this.color,
    this.size = 30.0,
    this.duration = const Duration(milliseconds: 600),
    this.onComplete,
  }) : super(key: key);

  @override
  State<SplashEffect> createState() => _SplashEffectState();
}

class _SplashEffectState extends State<SplashEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _opacityAnimation;
  
  final List<_SplashDrop> _drops = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _sizeAnimation = Tween<double>(
      begin: widget.size * 0.2,
      end: widget.size,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));
    
    // Create splash drops
    _createDrops();
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
    
    _controller.forward();
  }
  
  void _createDrops() {
    // Create 8-12 drops with random properties
    final dropCount = 8 + _random.nextInt(5);
    
    for (int i = 0; i < dropCount; i++) {
      _drops.add(_SplashDrop(
        angle: _random.nextDouble() * 2 * pi,
        distance: _random.nextDouble() * 0.8 + 0.2, // 0.2 to 1.0
        size: _random.nextDouble() * 0.5 + 0.5, // 0.5 to 1.0
        speedFactor: _random.nextDouble() * 0.4 + 0.8, // 0.8 to 1.2
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: _sizeAnimation.value * 2,
          height: _sizeAnimation.value * 2,
          child: CustomPaint(
            painter: _SplashPainter(
              progress: _controller.value,
              color: widget.color.withOpacity(_opacityAnimation.value),
              drops: _drops,
            ),
          ),
        );
      },
    );
  }
}

class _SplashDrop {
  final double angle;      // Direction of movement
  final double distance;   // How far it travels (0-1)
  final double size;       // Relative size of the drop
  final double speedFactor; // How fast it moves

  _SplashDrop({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speedFactor,
  });
}

class _SplashPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<_SplashDrop> drops;

  _SplashPainter({
    required this.progress,
    required this.color,
    required this.drops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // Draw main splash circle
    final mainSplashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, maxRadius * 0.7 * (0.7 + progress * 0.3), mainSplashPaint);
    
    // Draw splash drops
    for (var drop in drops) {
      // Calculate drop position based on progress and properties
      final currentProgress = progress * drop.speedFactor;
      
      // Only draw if progressed enough but not too far
      if (currentProgress >= 0.1 && currentProgress <= 1.0) {
        final distanceFactor = drop.distance * currentProgress;
        final dropX = center.dx + cos(drop.angle) * maxRadius * distanceFactor;
        final dropY = center.dy + sin(drop.angle) * maxRadius * distanceFactor;
        
        // Drop size changes over time (grows then shrinks)
        final dropSizeFactor = sin(currentProgress * pi) * drop.size;
        final dropSize = maxRadius * 0.2 * dropSizeFactor;
        
        // Drop opacity fades out
        final dropOpacity = color.opacity * (1.0 - currentProgress);
        
        final dropPaint = Paint()
          ..color = color.withOpacity(dropOpacity)
          ..style = PaintingStyle.fill;
          
        canvas.drawCircle(Offset(dropX, dropY), dropSize, dropPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SplashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
