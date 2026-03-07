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
  final VoidCallback onAddExtraTube;

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
        // Calculate rows
        int totalTubes = gameController.tubes.length;
        int maxTubesPerRow = 7;
        int numRows = (totalTubes / maxTubesPerRow).ceil();
        if (numRows == 0) numRows = 1;
        int tubesPerRow = (totalTubes / numRows).ceil();

        List<List<int>> tubeRows = [];
        for (int i = 0; i < totalTubes; i += tubesPerRow) {
          int end = (i + tubesPerRow < totalTubes) ? i + tubesPerRow : totalTubes;
          tubeRows.add(List<int>.generate(end - i, (index) => i + index));
        }

        // Calculate tube dimensions based on tubes per row
        double tubeWidth = constraints.maxWidth / (tubesPerRow + 1.5);
        tubeWidth = min(tubeWidth, 55.0); // Slightly thinner for AAA look
        double tubeHeight = tubeWidth * 3.5;

        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: tubeRows.map((rowIndices) {
                return Container(
                  margin: EdgeInsets.only(bottom: tubeHeight * 0.3),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Render the 3D Shelf
                      Positioned(
                        bottom: -15, // Put the shelf exactly under the tubes
                        child: _buildShelf(constraints.maxWidth * 0.9),
                      ),
                      
                      // Render the Tubes in this row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: rowIndices.map((index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: tubeWidth * 0.15),
                            child: _buildTubeGesture(index, tubeWidth, tubeHeight),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShelf(double width) {
    return Container(
      width: width,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.9),
            Color(0xFFE2E8F0),
            Color(0xFFCBD5E1),
          ],
          stops: [0.0, 0.4, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            offset: Offset(0, -2),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, 6),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            offset: Offset(0, 10),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Shelf front rim highlight
          Positioned(
            bottom: 2,
            left: 5,
            right: 5,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTubeGesture(int index, double width, double height) {
    return GestureDetector(
      key: gameController.tubeKeys[index],
      onTap: () {
        if (gameController.animating) return;

        if (selectedTube == null) {
          if (gameController.tubes[index].isNotEmpty) {
            onTubeSelected(index);
          }
        } else {
          if (selectedTube == index) {
            onTubeSelected(-1);
          } else {
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
          if (index == liftedTube) {
            return GameTube(
              key: ValueKey('animatedTube_$index'),
              colors: gameController.tubes[index],
              isSelected: true,
              isAnimating: true,
              width: width,
              height: height,
              liftAnimation: liftAnimation,
              rotateAnimation: rotateAnimation,
              dropAnimation: dropAnimation,
              pourAnimation: pourAnimation,
              rotationAngle: liftedTubeAngle,
            );
          }

          if (index == receivingTube) {
            return GameTube(
              key: ValueKey('receivingTube_$index'),
              colors: gameController.tubes[index],
              isSelected: false,
              width: width,
              height: height,
              isReceivingLiquid: true,
            );
          }

          return GameTube(
            key: ValueKey('normalTube_$index'),
            colors: gameController.tubes[index],
            isSelected: selectedTube == index,
            width: width,
            height: height,
          );
        },
      ),
    );
  }
}
