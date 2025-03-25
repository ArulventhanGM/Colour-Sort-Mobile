import 'package:flutter/material.dart';
import 'splash_effect_info.dart';

/// Manages splash effects for visual feedback in the game
class SplashEffectManager {
  final void Function(void Function()) setState;
  final List<SplashEffectInfo> splashEffects = [];

  SplashEffectManager({
    required this.setState,
  });

  /// Show a splash effect at a specific position
  void showSplashEffect(
      double x, double y, Color color1, Color color2, bool isColorMixing) {
    // Calculate a blended color for the splash
    Color blendedColor = Color.lerp(color1, color2, 0.5) ?? color1;

    setState(() {
      splashEffects.add(SplashEffectInfo(
        offset: Offset(x, y),
        color: blendedColor,
        size: 30.0,
        isColorMixing: isColorMixing,
        startTime: DateTime.now(),
      ));
    });

    // Remove the splash after its animation completes
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        if (splashEffects.isNotEmpty) {
          splashEffects.removeWhere((effect) =>
              DateTime.now().difference(effect.startTime).inMilliseconds >=
              800);
        }
      });
    });
  }

  /// Add a splash effect directly using a SplashEffectInfo object
  void addSplashEffect(SplashEffectInfo effect) {
    setState(() {
      splashEffects.add(effect);
    });
    
    // Remove the splash after its animation completes
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        if (splashEffects.isNotEmpty) {
          splashEffects.removeWhere((e) => e == effect);
        }
      });
    });
  }

  /// Remove a specific splash effect
  void removeSplashEffect(SplashEffectInfo effect) {
    setState(() {
      splashEffects.remove(effect);
    });
  }
}