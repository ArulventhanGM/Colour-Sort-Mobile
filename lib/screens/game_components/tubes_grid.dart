import 'package:flutter/material.dart';
import 'dart:math';
import '../../widgets/game_tube.dart';
import 'game_controller.dart';
import 'splash_effect_info.dart';

/// Callback for tube selection
typedef TubeSelectionCallback = void Function(int index);

/// Callback for pouring between tubes
typedef PourActionCallback = void Function(int fromTube, int toTube);

/// Widget that manages the tube grid display and interactions
class TubesGrid extends StatelessWidget {
  final GameController gameController;
  final int? selectedTube;
  final int? liftedTube;
  final int? receivingTube;
  final double? liftedTubeAngle;
  final Animation<double>? liftAnimation;
  final Animation<double>? rotateAnimation;
  final Animation<double>? dropAnimation;
  final Animation<double>? pourAnimation;
  final List<SplashEffectInfo> splashEffects;
  final TubeSelectionCallback onTubeSelected;
  final PourActionCallback onPourAction;
  final VoidCallback
      onAddExtraTube; // Keeping the parameter for backward compatibility

  const TubesGrid({
    Key? key,
    required this.gameController,
    required this.selectedTube,
    this.liftedTube,
    this.receivingTube,
    this.liftedTubeAngle,
    this.liftAnimation,
    this.rotateAnimation,
    this.dropAnimation,
    this.pourAnimation,
    required this.splashEffects,
    required this.onTubeSelected,
    required this.onPourAction,
    required this.onAddExtraTube,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate tube dimensions
        double tubeWidth =
            constraints.maxWidth / (gameController.tubes.length + 1);
        tubeWidth = min(tubeWidth, 60.0);
        double tubeHeight = tubeWidth * 3;

        // Calculate total width of all tubes including spacing
        double totalWidth = (tubeWidth + 10) * gameController.tubes.length;
        double horizontalPadding =
            max(0, (constraints.maxWidth - totalWidth) / 2);

        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 20,
                children: [
                  // Tubes - only showing the game tubes, no "Add Tube" button
                  ...List.generate(gameController.tubes.length, (index) {
                    return GestureDetector(
                      key: gameController.tubeKeys[index],
                      onTap: () {
                        if (gameController.animating) return;

                        if (selectedTube == null) {
                          // Select a tube if it has liquid
                          if (gameController.tubes[index].isNotEmpty) {
                            onTubeSelected(index);
                          }
                        } else {
                          // If same tube is tapped, deselect it
                          if (selectedTube == index) {
                            onTubeSelected(-1); // -1 to deselect
                          } else {
                            // Pour water from selected to this tube
                            onPourAction(selectedTube!, index);
                          }
                        }
                      },
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          if (liftAnimation != null) liftAnimation!,
                          if (rotateAnimation != null) rotateAnimation!,
                          if (dropAnimation != null) dropAnimation!,
                          if (pourAnimation != null) pourAnimation!,
                        ]),
                        builder: (context, child) {
                          // If this is the tube being animated for pouring
                          if (index == liftedTube) {
                            return GameTube(
                              key: ValueKey('animatedTube_$index'),
                              colors: gameController.tubes[index],
                              isSelected: true,
                              isAnimating: true,
                              width: tubeWidth,
                              height: tubeHeight,
                              liftAnimation: liftAnimation,
                              rotateAnimation: rotateAnimation,
                              dropAnimation: dropAnimation,
                              pourAnimation: pourAnimation,
                              rotationAngle: liftedTubeAngle,
                            );
                          }

                          // If this is the receiving tube
                          if (index == receivingTube) {
                            return GameTube(
                              key: ValueKey('receivingTube_$index'),
                              colors: gameController.tubes[index],
                              isSelected: false,
                              width: tubeWidth,
                              height: tubeHeight,
                              isReceivingLiquid: true,
                            );
                          }

                          // Otherwise render normal tube
                          return GameTube(
                            key: ValueKey('normalTube_$index'),
                            colors: gameController.tubes[index],
                            isSelected: selectedTube == index,
                            width: tubeWidth,
                            height: tubeHeight,
                          );
                        },
                      ),
                    );
                  }),
                  // "Add Tube" button removed from here
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
