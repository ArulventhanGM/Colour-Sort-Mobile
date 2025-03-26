import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_effect_info.dart';
import 'dart:math';

/// Manages animations for when individual tubes are completed
class TubeCompletionManager {
  final void Function(SplashEffectInfo) addSplashEffect;
  final Random _random = Random();
  
  // Track which tubes have already been celebrated
  final Set<int> _celebratedTubes = {};
  
  TubeCompletionManager({
    required this.addSplashEffect,
  });
  
  /// Check if a tube is complete (filled with same color)
  bool isTubeComplete(List<Color> tube, int maxColors) {
    if (tube.isEmpty) return false;
    if (tube.length != maxColors) return false;
    
    // Check if all colors are the same
    final Color firstColor = tube.first;
    return tube.every((color) => color == firstColor);
  }
  
  /// Create a burst effect when a tube is completed
  void celebrateTubeCompletion(List<List<Color>> tubes, Map<int, GlobalKey> tubeKeys, int maxColors) {
    // Find which tubes are complete
    for (int i = 0; i < tubes.length; i++) {
      if (_celebratedTubes.contains(i)) continue; // Skip already celebrated tubes
      
      if (isTubeComplete(tubes[i], maxColors)) {
        _createTubeCompletionEffect(i, tubes[i].first, tubeKeys[i]);
        _celebratedTubes.add(i);
        
        // Provide haptic feedback
        HapticFeedback.lightImpact();
      }
    }
  }
  
  /// Reset the celebrated tubes tracking (when starting a new level)
  void reset() {
    _celebratedTubes.clear();
  }
  
  /// Create the visual effect for tube completion
  void _createTubeCompletionEffect(int tubeIndex, Color tubeColor, GlobalKey? tubeKey) {
    if (tubeKey == null || tubeKey.currentContext == null) return;
    
    // Get the position of the tube
    final RenderBox renderBox = tubeKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    
    // Calculate tube top center position
    final Offset tubeTopCenter = Offset(
      position.dx + size.width / 2,
      position.dy + size.height * 0.2, // Near the top of the tube
    );
    
    // Create a primary burst at the tube top
    _createBurst(tubeTopCenter, tubeColor, 40.0);
    
    // Create 3-5 small secondary bursts around the tube
    final int secondaryBurstCount = 3 + _random.nextInt(3);
    for (int i = 0; i < secondaryBurstCount; i++) {
      // Add random offset around the tube
      final double offsetX = (i % 2 == 0 ? 1 : -1) * (10 + _random.nextDouble() * 30);
      final double offsetY = -30 - _random.nextDouble() * 40; // Always above the tube
      
      final Offset burstPosition = Offset(
        tubeTopCenter.dx + offsetX,
        tubeTopCenter.dy + offsetY,
      );
      
      // Slight delay for secondary bursts
      Future.delayed(Duration(milliseconds: 50 * i), () {
        _createBurst(burstPosition, tubeColor, 20.0 + _random.nextDouble() * 10.0);
      });
    }
  }
  
  /// Create a single burst effect
  void _createBurst(Offset position, Color color, double size) {
    // Create a slightly brighter color for more visible bursts
    final Color brightColor = _brightenColor(color);
    
    addSplashEffect(SplashEffectInfo(
      offset: position,
      color: brightColor,
      size: size,
      isColorMixing: true, // Use the mixing effect for extra particles
      startTime: DateTime.now(),
    ));
  }
  
  /// Make a color brighter for better visibility
  Color _brightenColor(Color color) {
    // Increase brightness but keep the hue
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness(min(0.8, hsl.lightness + 0.2)).toColor();
  }
}