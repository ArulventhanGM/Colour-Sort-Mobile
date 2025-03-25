import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'splash_effect_info.dart';
import 'game_animations.dart';

/// Manages the animations related to tube pouring and movement
class TubeAnimationController {
  final GameController gameController;
  final AnimationController liftController;
  final AnimationController rotateController;
  final AnimationController pourController;
  final AnimationController dropController;
  final void Function(SplashEffectInfo) addSplashEffect;

  // Animation state
  Color? pouringColor;
  Offset? pourStart;
  Offset? pourEnd;
  int? liftedTube;
  int? targetTubeReceiving;
  Offset? liftedTubeStartPosition;
  Offset? targetTubePosition;
  double? liftedTubeAngle;
  bool animating = false;

  TubeAnimationController({
    required this.gameController,
    required this.liftController,
    required this.rotateController,
    required this.pourController,
    required this.dropController, 
    required this.addSplashEffect,
  });

  /// Handle pouring action between tubes with visual effects
  Future<bool> animatePouring(int fromTube, int toTube, void Function(void Function()) setState) async {
    try {
      // Make sure we have the correct tube keys
      if (gameController.tubeKeys[fromTube] == null ||
          gameController.tubeKeys[toTube] == null) {
        gameController.performBasicPour(fromTube, toTube);
        return false;
      }

      // Try to get contexts for both tubes
      final sourceTubeContext =
          gameController.tubeKeys[fromTube]!.currentContext;
      final targetTubeContext =
          gameController.tubeKeys[toTube]!.currentContext;

      if (sourceTubeContext == null || targetTubeContext == null) {
        gameController.performBasicPour(fromTube, toTube);
        return false;
      }

      // Try to get render boxes for both tubes
      final sourceTubeRenderBox =
          sourceTubeContext.findRenderObject() as RenderBox?;
      final targetTubeRenderBox =
          targetTubeContext.findRenderObject() as RenderBox?;

      if (sourceTubeRenderBox == null || targetTubeRenderBox == null) {
        gameController.performBasicPour(fromTube, toTube);
        return false;
      }

      // Ensure source tube has colors to pour
      if (gameController.tubes[fromTube].isEmpty) {
        return false;
      }

      // Get the colors to pour before starting animation
      List<Color> colorsToPour = [];
      Color colorToPour = gameController.tubes[fromTube].last;

      // Check if this pour will cause a color mixing effect
      bool willMixColors = gameController.tubes[toTube].isNotEmpty &&
          gameController.tubes[toTube].last != colorToPour;

      // Count how many colors we'll be pouring (don't actually remove them yet)
      int colorCount = 0;
      for (int i = gameController.tubes[fromTube].length - 1; i >= 0; i--) {
        if (gameController.tubes[fromTube][i] == colorToPour &&
            colorCount + gameController.tubes[toTube].length < 4) {
          colorCount++;
        } else {
          break;
        }
      }

      // If no colors to pour, exit early
      if (colorCount == 0) {
        return false;
      }

      setState(() {
        animating = true;
        gameController.animating = true;
        pouringColor = colorToPour;
        liftedTube = fromTube;
        targetTubeReceiving = toTube;

        // Calculate global positions for animation
        final sourcePosition = sourceTubeRenderBox.localToGlobal(Offset.zero);
        final targetPosition = targetTubeRenderBox.localToGlobal(Offset.zero);

        liftedTubeStartPosition = sourcePosition;
        targetTubePosition = targetPosition;

        // Calculate pour start and end positions more accurately
        pourStart = Offset(
            sourcePosition.dx + sourceTubeRenderBox.size.width / 2,
            sourcePosition.dy + 10);

        pourEnd = Offset(
            targetPosition.dx + targetTubeRenderBox.size.width / 2,
            targetPosition.dy + 10);

        // Remove the colors to pour
        for (int i = 0; i < colorCount; i++) {
          if (gameController.tubes[fromTube].isNotEmpty) {
            colorsToPour.add(gameController.tubes[fromTube].removeLast());
          }
        }

        // Save history and update moves
        gameController.saveHistory();
        gameController.moves++;
        gameController.updateStars();
      });

      // Begin lift animation sequence
      gameController.vibrateDevice();
      gameController.playSound('select');

      await liftController.forward(from: 0).orCancel;
      
      // Rotate tube to pour
      liftedTubeAngle = GameAnimations.calculatePouringAngle(
          liftedTubeStartPosition!, targetTubePosition!, fromTube, toTube);
      gameController.playSound('pour');

      await rotateController.forward(from: 0).orCancel;
      
      // Run pouring animation
      pourController.forward(from: 0);
      
      // Wait for pouring to complete
      await pourController.forward(from: 0).orCancel;
      
      // Set the receiving tube indicator
      setState(() {
        targetTubeReceiving = toTube;
      });

      // Show splash effect if colors are mixing
      if (willMixColors) {
        _showSplashEffect(
            targetTubePosition!.dx + targetTubeRenderBox.size.width / 2,
            targetTubePosition!.dy + targetTubeRenderBox.size.height * 0.7,
            gameController.tubes[toTube].isNotEmpty
                ? gameController.tubes[toTube].last
                : colorToPour,
            colorToPour,
            true // This is a color mixing event
        );
        gameController.playSound('bubble'); // Play bubble sound for mixing
      }

      // Return tube to upright position
      await rotateController.reverse().orCancel;
      
      // Return tube to original position
      await dropController.forward(from: 0).orCancel;
      
      setState(() {
        gameController.tubes[toTube].addAll(colorsToPour);
        animating = false;
        gameController.animating = false;
        pouringColor = null;
        liftedTube = null;
        targetTubeReceiving = null;
        liftedTubeStartPosition = null;
        targetTubePosition = null;
        liftedTubeAngle = null;

        // Reset animation controllers
        liftController.reset();
        rotateController.reset();
        dropController.reset();
      });

      return true;
    } catch (e) {
      print("Error during pour animation: $e");
      gameController.performBasicPour(fromTube, toTube);
      return false;
    }
  }

  /// Show a splash effect at a specific position
  void _showSplashEffect(
      double x, double y, Color color1, Color color2, bool isColorMixing) {
    // Calculate a blended color for the splash
    Color blendedColor = Color.lerp(color1, color2, 0.5) ?? color1;

    addSplashEffect(SplashEffectInfo(
      offset: Offset(x, y),
      color: blendedColor,
      size: 30.0,
      isColorMixing: isColorMixing,
      startTime: DateTime.now(),
    ));
  }

  void reset() {
    animating = false;
    pouringColor = null;
    liftedTube = null;
    targetTubeReceiving = null;
    liftedTubeStartPosition = null;
    targetTubePosition = null;
    liftedTubeAngle = null;
    
    liftController.reset();
    rotateController.reset();
    dropController.reset();
    pourController.reset();
  }
}