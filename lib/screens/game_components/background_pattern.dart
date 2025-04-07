import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../models/game_theme.dart'; // Added import for GameTheme

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
      duration: const Duration(seconds: 30),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return Stack(
      children: [
        // Base gradient
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: currentTheme.backgroundGradient,
          ),
        ),
        
        // Animated patterns based on theme
        if (currentTheme.isDark) 
          _buildDarkModePattern(currentTheme)
        else
          _buildLightModePattern(currentTheme),
      ],
    );
  }
  
  Widget _buildDarkModePattern(GameTheme theme) {
    return Stack(
      children: [
        // Animated glowing orbs in the background
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: _GlowingOrbsPainter(
                animation: _animationController.value,
                primaryColor: theme.primaryColor,
                accentColor: theme.accentColor,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        // Subtle geometric patterns
        CustomPaint(
          painter: _GeometricPatternPainter(
            primaryColor: theme.primaryColor,
            accentColor: theme.accentColor,
          ),
          size: Size.infinite,
        ),
        
        // Very subtle ambient particles
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: _AmbientParticlesPainter(
                animation: _animationController.value,
                color: theme.accentColor,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildLightModePattern(GameTheme theme) {
    // Keep existing light mode pattern
    return CustomPaint(
      painter: _BackgroundPatternPainter(themeColor: theme.primaryColor),
      size: Size.infinite,
    );
  }
}

/// Original background pattern painter (for light mode)
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
      
    const gridSize = 30.0;
    
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

/// Glowing orbs painter for dark mode
class _GlowingOrbsPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;
  
  _GlowingOrbsPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    // Draw several large, subtle glowing orbs that move slowly
    for (int i = 0; i < 5; i++) {
      final baseX = size.width * random.nextDouble();
      final baseY = size.height * random.nextDouble();
      
      // Calculate movement based on animation value
      final xOffset = math.sin((animation + i * 0.2) * math.pi * 2) * size.width * 0.15;
      final yOffset = math.cos((animation + i * 0.2) * math.pi * 2) * size.height * 0.1;
      
      final x = (baseX + xOffset) % size.width;
      final y = (baseY + yOffset) % size.height;
      
      // Create a radial gradient for the glow effect
      final radius = size.width * (0.15 + random.nextDouble() * 0.2);
      final gradient = RadialGradient(
        colors: [
          i % 2 == 0 
              ? primaryColor.withOpacity(0.15)
              : accentColor.withOpacity(0.12),
          i % 2 == 0
              ? primaryColor.withOpacity(0.02)
              : accentColor.withOpacity(0.01),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      
      final rect = Rect.fromCircle(
        center: Offset(x, y),
        radius: radius,
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_GlowingOrbsPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor != accentColor;
  }
}

/// Geometric pattern painter for dark mode
class _GeometricPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  
  _GeometricPatternPainter({
    required this.primaryColor,
    required this.accentColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create a subtle hexagonal grid pattern
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    const hexSize = 100.0;
    const horizontalSpacing = hexSize * 0.75;
    const verticalSpacing = hexSize * 0.866; // sqrt(3)/2 * hexSize
    
    for (int row = -1; row < size.height ~/ verticalSpacing + 2; row++) {
      for (int col = -1; col < size.width ~/ horizontalSpacing + 2; col++) {
        final isEvenRow = row % 2 == 0;
        final xOffset = isEvenRow ? 0.0 : horizontalSpacing / 2;
        final x = col * horizontalSpacing + xOffset;
        final y = row * verticalSpacing;
        
        // Draw hexagon
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60 + 30) * math.pi / 180;
          final pointX = x + hexSize * 0.5 * math.cos(angle);
          final pointY = y + hexSize * 0.5 * math.sin(angle);
          
          if (i == 0) {
            path.moveTo(pointX, pointY);
          } else {
            path.lineTo(pointX, pointY);
          }
        }
        path.close();
        
        canvas.drawPath(path, paint);
      }
    }
    
    // Add a few accent accent lines
    final accentPaint = Paint()
      ..color = accentColor.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.15);
      final path = Path();
      path.moveTo(0, y);
      
      // Create a wavy line
      for (double x = 0; x < size.width; x += size.width / 20) {
        final waveHeight = math.sin(x / size.width * math.pi * 4) * 10;
        path.lineTo(x, y + waveHeight);
      }
      
      canvas.drawPath(path, accentPaint);
    }
  }
  
  @override
  bool shouldRepaint(_GeometricPatternPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor != accentColor;
  }
}

/// Ambient particles painter for dark mode
class _AmbientParticlesPainter extends CustomPainter {
  final double animation;
  final Color color;
  
  _AmbientParticlesPainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(12); // Fixed seed for consistent particles
    
    // Draw small floating particles
    final particles = 50;
    for (int i = 0; i < particles; i++) {
      // Use animation to move particles
      final speed = 0.2 + random.nextDouble() * 0.3;
      final angle = random.nextDouble() * math.pi * 2;
      
      final x = (size.width * random.nextDouble() + 
                math.sin(animation * speed + i) * 30) % size.width;
      final y = (size.height * random.nextDouble() + 
                animation * 50 * speed) % size.height;
      
      final particleSize = 1.0 + random.nextDouble() * 2.0;
      final opacity = 0.1 + random.nextDouble() * 0.2;
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_AmbientParticlesPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.color != color;
  }
}
