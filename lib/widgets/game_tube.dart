import 'package:flutter/material.dart';
import 'dart:math';
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
  final bool isReceivingLiquid;

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
    this.isReceivingLiquid = false,
  }) : super(key: key);

  @override
  State<GameTube> createState() => _GameTubeState();
}

class _GameTubeState extends State<GameTube>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleAnimController;
  late Animation<double> _waveAnimation;
  late Animation<double> _tiltAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _liquidFillAnimation;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Initialize the idle animation controller with smoother timing
    _idleAnimController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Wave animation with smoother curve
    _waveAnimation = _idleAnimController.drive(CurveTween(
      curve: Curves.easeInOut,
    ));

    // Subtle tilt animation for selected state
    _tiltAnimation = _idleAnimController.drive(TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.02, end: 0.02)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.02, end: -0.02)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]));

    // Bounce animation for user feedback
    _bounceAnimation = _idleAnimController.drive(TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -2, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 2,
      ),
    ]));

    // Liquid fill animation with natural easing
    _liquidFillAnimation = _idleAnimController.drive(CurveTween(
      curve: Curves.easeInOutCubic,
    ));

    // Movement animation for tube translation
    _moveAnimation = _idleAnimController.drive(CurveTween(
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(GameTube oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animations based on tube state
    if (!oldWidget.isReceivingLiquid && widget.isReceivingLiquid) {
      _idleAnimController.forward(from: 0.0);
    }

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _idleAnimController.duration = const Duration(milliseconds: 1500);
        _idleAnimController.forward(from: 0.3);
      } else {
        _idleAnimController.duration = const Duration(milliseconds: 3000);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) {
      return AnimatedBuilder(
        animation: _idleAnimController,
        builder: (context, child) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(0.0, widget.isSelected ? _bounceAnimation.value : 0)
                ..rotateZ(widget.isSelected ? _tiltAnimation.value : 0),
              child: AnimatedScale(
                scale: widget.isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: CustomPaint(
                  painter: TubePainter(
                    colors: widget.colors,
                    isSelected: widget.isSelected,
                    maxCapacity: 4,
                    waveOffset: _waveAnimation.value * (2 * pi),
                    liquidFillOffset: widget.isReceivingLiquid
                        ? _liquidFillAnimation.value
                        : 0.0,
                    isReceivingLiquid: widget.isReceivingLiquid,
                  ),
                  child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // For animating tubes during pouring
    return AnimatedBuilder(
      animation: Listenable.merge([
        if (widget.liftAnimation != null) widget.liftAnimation!,
        if (widget.rotateAnimation != null) widget.rotateAnimation!,
        if (widget.dropAnimation != null) widget.dropAnimation!,
        if (widget.pourAnimation != null) widget.pourAnimation!,
        _idleAnimController,
      ]),
      builder: (context, child) {
        // Calculate lift, rotation and position with smoother transitions
        double liftValue = widget.liftAnimation != null
            ? widget.liftAnimation!.value * 30.0
            : 0.0;
        double dropValue = widget.dropAnimation != null
            ? widget.dropAnimation!.value * 30.0
            : 0.0;
        double translateY = -liftValue +
            (widget.dropAnimation != null
                ? widget.dropAnimation!.value * liftValue
                : 0);

        // Calculate rotation with dynamic easing
        double rotationAngle =
            (widget.rotationAngle != null && widget.rotateAnimation != null)
                ? widget.rotateAnimation!.value * widget.rotationAngle!
                : 0.0;

        bool isPouringAnimation = widget.rotateAnimation != null &&
            widget.rotateAnimation!.value > 0.5;

        // Add slight wobble during pouring for realism
        double wobbleAngle = 0.0;
        if (isPouringAnimation && widget.rotateAnimation!.value > 0.7) {
          wobbleAngle = sin(_idleAnimController.value * 20) * 0.03;
        }

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateZ(rotationAngle + wobbleAngle),
            child: CustomPaint(
              painter: TubePainter(
                colors: widget.colors,
                isSelected: true,
                maxCapacity: 4,
                pouringAnimation: isPouringAnimation,
                pouringProgress: widget.pourAnimation?.value ?? 0.0,
                waveOffset: _waveAnimation.value * (2 * pi),
                liquidFillOffset:
                    widget.isReceivingLiquid ? _liquidFillAnimation.value : 0.0,
                isReceivingLiquid: widget.isReceivingLiquid,
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

  @override
  void dispose() {
    _idleAnimController.dispose();
    super.dispose();
  }
}
