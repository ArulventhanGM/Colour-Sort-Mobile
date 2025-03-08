import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'game_animations.dart';

/// Widget that renders the liquid pouring animation between tubes
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

        try {
          final metrics = path.computeMetrics();
          if (metrics.isEmpty) {
            return const SizedBox.shrink();
          }

          PathMetric? metric;
          for (final m in metrics) {
            metric = m;
            break;
          }

          if (metric == null) {
            return const SizedBox.shrink();
          }

          final currentDistance = metric.length * widget.pourAnimation.value;

          if (currentDistance <= 0 || currentDistance > metric.length) {
            return const SizedBox.shrink();
          }

          return Stack(
            children: [
              // Water stream - main path
              ClipPath(
                clipper: WaterStreamClipper(
                  path: path,
                  progress: widget.pourAnimation.value,
                  width: 8.0,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: widget.pouringColor.withOpacity(0.7),
                ),
              ),

              // Water droplets for realism
              ...List.generate(10, (index) {
                if (widget.pourAnimation.value < 0.1 ||
                    widget.pourAnimation.value > 0.9) {
                  return const SizedBox.shrink();
                }

                // Random offsets for droplets
                final random = Random();
                final dropletOffset =
                    random.nextDouble() * metric!.length * 0.7;
                final sideOffset = (random.nextDouble() - 0.5) * 15;

                // Only show droplets in the middle section of the pour
                if (dropletOffset < currentDistance * 0.2 ||
                    dropletOffset > currentDistance * 0.8) {
                  return const SizedBox.shrink();
                }

                final dropletPosition =
                    metric.getTangentForOffset(dropletOffset);
                if (dropletPosition == null) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: dropletPosition.position.dx + sideOffset,
                  top: dropletPosition.position.dy + random.nextDouble() * 10,
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value * 15),
                        child: Opacity(
                          opacity: 1.0 - value,
                          child: Container(
                            width: 3 + random.nextDouble() * 4,
                            height: 3 + random.nextDouble() * 4,
                            decoration: BoxDecoration(
                              color: widget.pouringColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

              // Splash effect at destination
              if (widget.pourAnimation.value > 0.4)
                Positioned(
                  left: widget.pourEnd.dx - 20,
                  top: widget.pourEnd.dy - 5,
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(
                        begin: 0.0,
                        end: widget.pourAnimation.value > 0.7
                            ? 1.0
                            : widget.pourAnimation.value),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity:
                            value < 0.7 ? value : 1.0 - ((value - 0.7) / 0.3),
                        child: Container(
                          width: 40 * value,
                          height: 10 * value,
                          decoration: BoxDecoration(
                            color: widget.pouringColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        } catch (e) {
          print("Animation error: $e");
          return const SizedBox.shrink();
        }
      },
    );
  }
}
