import 'package:flutter/material.dart';
import '../painters/tube_painter.dart';

class GameTube extends StatefulWidget {
  final List<Color> colors;
  final bool isSelected;
  final bool isAnimating;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final Animation<double>? liftAnimation;
  final Animation<double>? rotateAnimation;
  final Animation<double>? dropAnimation;
  final Animation<double>? pourAnimation;
  final double? rotationAngle;

  const GameTube({
    Key? key,
    required this.colors,
    this.isSelected = false,
    this.isAnimating = false,
    required this.width,
    required this.height,
    this.onTap,
    this.liftAnimation,
    this.rotateAnimation,
    this.dropAnimation,
    this.pourAnimation,
    this.rotationAngle,
  }) : super(key: key);

  @override
  State<GameTube> createState() => _GameTubeState();
}

class _GameTubeState extends State<GameTube> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) {
      return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: widget.isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: CustomPaint(
            painter: TubePainter(
              colors: widget.colors,
              isSelected: widget.isSelected,
              maxCapacity: 4,
            ),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
            ),
          ),
        ),
      );
    }

    // If this is an animating tube, apply complex transforms
    return AnimatedBuilder(
      animation: Listenable.merge([
        if (widget.liftAnimation != null) widget.liftAnimation!,
        if (widget.rotateAnimation != null) widget.rotateAnimation!,
        if (widget.dropAnimation != null) widget.dropAnimation!, 
        if (widget.pourAnimation != null) widget.pourAnimation!,
      ]),
      builder: (context, child) {
        // Calculate lift, rotation and position
        double liftValue = widget.liftAnimation != null ? widget.liftAnimation!.value * 30.0 : 0.0;
        double dropValue = widget.dropAnimation != null ? widget.dropAnimation!.value * 30.0 : 0.0;
        double translateY = -liftValue + (widget.dropAnimation != null ? widget.dropAnimation!.value * liftValue : 0);
        
        // Calculate rotation angle
        double rotationAngle = (widget.rotationAngle != null && widget.rotateAnimation != null) 
            ? widget.rotateAnimation!.value * widget.rotationAngle!
            : 0.0;
            
        bool isPouringAnimation = widget.rotateAnimation != null && 
            widget.rotateAnimation!.value > 0.5;
            
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateZ(rotationAngle),
            child: CustomPaint(
              painter: TubePainter(
                colors: widget.colors,
                isSelected: true,
                maxCapacity: 4,
                pouringAnimation: isPouringAnimation,
                pouringProgress: widget.pourAnimation?.value ?? 0.0,
              ),
              child: SizedBox(
                width: widget.width,
                height: widget.height,
              ),
            ),
          ),
        );
      },
    );
  }
}
