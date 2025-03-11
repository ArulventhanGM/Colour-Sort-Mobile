import 'package:flutter/material.dart';

/// A class that manages game hints and helps find optimal moves
class HintManager {
  /// Calculates the best next move based on current tube state
  /// Returns a tuple with source tube index and target tube index
  /// Returns null if no valid moves are found
  static HintMove? findBestMove(List<List<Color>> tubes) {
    if (tubes.isEmpty) return null;

    // List to store all possible valid moves with their score
    List<ScoredMove> possibleMoves = [];

    // Find all valid moves and score them
    for (int sourceIndex = 0; sourceIndex < tubes.length; sourceIndex++) {
      final sourceTube = tubes[sourceIndex];
      if (sourceTube.isEmpty) continue;

      for (int targetIndex = 0; targetIndex < tubes.length; targetIndex++) {
        if (sourceIndex == targetIndex) continue;

        final targetTube = tubes[targetIndex];
        
        // Check if this is a valid move
        if (canPour(sourceTube, targetTube)) {
          final moveScore = scorePossibleMove(
            tubes, 
            sourceIndex, 
            targetIndex, 
            sourceTube, 
            targetTube,
          );
          
          possibleMoves.add(ScoredMove(
            sourceIndex: sourceIndex,
            targetIndex: targetIndex,
            score: moveScore,
          ));
        }
      }
    }

    // Sort moves by score (higher is better)
    possibleMoves.sort((a, b) => b.score.compareTo(a.score));

    // Return the best move if any valid moves exist
    if (possibleMoves.isNotEmpty) {
      return HintMove(
        fromTube: possibleMoves.first.sourceIndex,
        toTube: possibleMoves.first.targetIndex,
      );
    }

    return null;
  }

  /// Checks if pouring from source tube to target tube is valid
  static bool canPour(List<Color> sourceTube, List<Color> targetTube) {
    if (sourceTube.isEmpty) return false;
    if (targetTube.length >= 4) return false;

    final sourceColor = sourceTube.last;
    return targetTube.isEmpty || targetTube.last == sourceColor;
  }

  /// Scores a possible move based on various heuristics
  /// Higher score indicates a better move
  static int scorePossibleMove(
    List<List<Color>> tubes,
    int sourceIndex,
    int targetIndex,
    List<Color> sourceTube,
    List<Color> targetTube,
  ) {
    int score = 0;
    final sourceColor = sourceTube.last;

    // Count consecutive matching colors at the top of source tube
    int consecutiveColors = 0;
    for (int i = sourceTube.length - 1; i >= 0; i--) {
      if (sourceTube[i] == sourceColor) {
        consecutiveColors++;
      } else {
        break;
      }
    }

    // Base score is the number of consecutive colors we can move
    score += consecutiveColors;

    // Prioritize moves that will complete a tube
    if (targetTube.isNotEmpty && 
        targetTube.last == sourceColor && 
        targetTube.length + consecutiveColors == 4) {
      score += 50;  // High priority for completing a tube
    }

    // Prioritize moves into empty tubes if the entire color group can be moved
    if (targetTube.isEmpty) {
      bool isCompleteColorGroup = true;
      Color firstColor = sourceTube.last;
      
      for (int i = sourceTube.length - 1; i >= 0; i--) {
        if (sourceTube[i] != firstColor) {
          isCompleteColorGroup = false;
          break;
        }
      }
      
      if (isCompleteColorGroup) {
        score += 30;  // Good to move an entire color group to an empty tube
      } else {
        score -= 5;  // Slightly discourage moving partial groups to empty tubes
      }
    }

    // Prioritize moves that will free up a blocked color
    if (sourceTube.length > consecutiveColors) {
      // There are different colors below
      score += 10;
    }

    // Check if source tube will be empty after move
    if (sourceTube.length == consecutiveColors) {
      score += 5;  // Good to empty a tube
    }

    // Prioritize moves that consolidate the same color
    if (targetTube.isNotEmpty && targetTube.last == sourceColor) {
      score += 20;
    }

    // Check for deadlock avoidance
    if (wouldCreateDeadlock(tubes, sourceIndex, targetIndex, consecutiveColors)) {
      score -= 40;  // Heavily penalize moves that lead to deadlocks
    }

    return score;
  }

  /// Checks if a move would potentially create a deadlock situation
  static bool wouldCreateDeadlock(
    List<List<Color>> tubes,
    int sourceIndex,
    int targetIndex,
    int consecutiveColors,
  ) {
    // Deep copy tubes to simulate the move
    List<List<Color>> simulatedTubes = tubes.map((tube) => [...tube]).toList();
    
    // Simulate the move
    final sourceColor = simulatedTubes[sourceIndex].last;
    List<Color> colorsToMove = [];
    
    // Remove consecutive colors from source
    for (int i = 0; i < consecutiveColors; i++) {
      if (simulatedTubes[sourceIndex].isNotEmpty) {
        colorsToMove.insert(0, simulatedTubes[sourceIndex].removeLast());
      }
    }
    
    // Add to target
    simulatedTubes[targetIndex].addAll(colorsToMove);
    
    // Check for deadlock scenarios
    
    // 1. Check if any tube has different colors and is full
    for (var tube in simulatedTubes) {
      if (tube.length == 4) {
        Set<Color> uniqueColors = tube.toSet();
        if (uniqueColors.length > 1) {
          return true;  // Tube is full but has mixed colors - deadlock
        }
      }
    }
    
    // More complex deadlock detection could be added here
    
    return false;
  }
}

/// Class representing a hint move with source and destination tubes
class HintMove {
  final int fromTube;
  final int toTube;

  HintMove({required this.fromTube, required this.toTube});
}

/// Class for a move with a calculated score for sorting
class ScoredMove {
  final int sourceIndex;
  final int targetIndex;
  final int score;

  ScoredMove({
    required this.sourceIndex, 
    required this.targetIndex, 
    required this.score,
  });
}