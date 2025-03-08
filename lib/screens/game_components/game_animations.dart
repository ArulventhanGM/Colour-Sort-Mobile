import 'package:flutter/material.dart';
import 'dart:math';

/// Helper class for water pouring stream animation
class WaterStreamClipper extends CustomClipper<Path> {
  final Path path;
  final double progress;
  final double width;

  WaterStreamClipper({
    required this.path,
    required this.progress,
    this.width = 8.0,
  });

  @override
  Path getClip(Size size) {
    try {
      final metrics = path.computeMetrics();
      if (metrics.isEmpty) {
        return Path();
      }

      final metric = metrics.first;
      final pathLength = metric.length;

      // Extract a portion of the path based on progress
      final extractPath = metric.extractPath(
        0,
        pathLength * progress,
      );

      // Create a wider path by stroking
      final expandedPath = Path();

      // Create a slightly expanded version of the path for better visibility
      expandedPath.addPath(extractPath, Offset.zero);

      return expandedPath;
    } catch (e) {
      print("Error in WaterStreamClipper: $e");
      return Path(); // Return empty path on error
    }
  }

  @override
  bool shouldReclip(WaterStreamClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.path != path ||
        oldClipper.width != width;
  }
}

/// Utility class for animations in the game
class GameAnimations {
  /// Calculates the optimal angle for pouring from one tube to another
  static double calculatePouringAngle(Offset? sourcePosition,
      Offset? targetPosition, int fromTube, int toTube) {
    // Calculate which direction to pour based on tube positions
    if (sourcePosition != null && targetPosition != null) {
      // Pour to the right
      if (sourcePosition.dx < targetPosition.dx) {
        return pi / 4; // 45 degrees clockwise
      }
      // Pour to the left
      else {
        return -pi / 4; // 45 degrees counter-clockwise
      }
    }

    // Default pour angle if positions aren't available
    return fromTube < toTube ? pi / 4 : -pi / 4;
  }

  /// Creates a bezier path for water pouring between two points
  static Path createPouringPath(
      Offset startPoint, Offset endPoint, double? angle) {
    final path = Path();

    // The pour path comes from the source tube at an angle
    final adjustedStart = Offset(
        startPoint.dx + (angle != null && angle > 0 ? 15 : -15),
        startPoint.dy + 5);

    path.moveTo(adjustedStart.dx, adjustedStart.dy);

    // Create a realistic pouring arc with gravity effect
    final midY = adjustedStart.dy +
        (endPoint.dy - adjustedStart.dy) *
            0.3; // Higher drop for more realistic curve

    // Control points for a realistic water flow
    final controlPoint1 = Offset(
        adjustedStart.dx + (endPoint.dx - adjustedStart.dx) * 0.2, midY - 20);

    final controlPoint2 = Offset(
        adjustedStart.dx + (endPoint.dx - adjustedStart.dx) * 0.8,
        endPoint.dy - 10);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    return path;
  }
}
