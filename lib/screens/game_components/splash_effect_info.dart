import 'package:flutter/material.dart';

/// Represents information about a splash effect in the game
class SplashEffectInfo {
  /// The position of the splash effect on the screen
  final Offset offset;

  /// The color of the splash effect
  final Color color;

  /// The size of the splash effect
  final double size;

  /// Whether this splash represents colors mixing
  final bool isColorMixing;

  /// When the splash was created (used for cleanup)
  final DateTime startTime;

  SplashEffectInfo({
    required this.offset,
    required this.color,
    required this.size,
    required this.isColorMixing,
    required this.startTime,
  });
}
