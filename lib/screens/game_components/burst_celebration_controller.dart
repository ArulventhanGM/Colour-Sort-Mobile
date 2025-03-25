import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_effect_info.dart';
import 'game_controller.dart';

/// Manages the burst celebration animations shown when a level is completed
class BurstCelebrationController {
  final BuildContext context;
  final void Function(SplashEffectInfo) addSplashEffect;
  final GameController gameController;
  final AnimationController burstController;

  BurstCelebrationController({
    required this.context,
    required this.addSplashEffect,
    required this.gameController,
    required this.burstController,
  });

  /// Show level completion burst animation celebration
  void showCompletionBurst() {
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    
    // Get colors from game tubes for the burst animation
    List<Color> tubeColors = [];
    for (var tube in gameController.tubes) {
      if (tube.isNotEmpty) {
        tubeColors.add(tube.first);
      }
    }
    
    // Use random tube colors for burst animation or default to a gold color
    final burstColors = tubeColors.isNotEmpty 
        ? tubeColors 
        : [Colors.amber, Colors.yellow, Colors.orange];
    
    // Trigger haptic feedback for an immersive experience
    HapticFeedback.mediumImpact();
    
    // Show first burst at the center
    addSplashEffect(SplashEffectInfo(
      offset: screenCenter,
      color: burstColors[0],
      size: screenSize.width * 0.6,
      isColorMixing: true,
      startTime: DateTime.now(),
    ));
    
    // Add staggered additional bursts with delayed timing for a dynamic effect
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
      addSplashEffect(SplashEffectInfo(
        offset: Offset(
          screenCenter.dx + 50,
          screenCenter.dy - 50,
        ),
        color: burstColors.length > 1 ? burstColors[1] : burstColors[0],
        size: screenSize.width * 0.4,
        isColorMixing: true,
        startTime: DateTime.now(),
      ));
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      HapticFeedback.lightImpact();
      addSplashEffect(SplashEffectInfo(
        offset: Offset(
          screenCenter.dx - 70,
          screenCenter.dy + 30,
        ),
        color: burstColors.length > 2 ? burstColors[2] : burstColors[0],
        size: screenSize.width * 0.3,
        isColorMixing: true,
        startTime: DateTime.now(),
      ));
    });
    
    // Start the burst animation controller
    burstController.forward(from: 0);
  }
}