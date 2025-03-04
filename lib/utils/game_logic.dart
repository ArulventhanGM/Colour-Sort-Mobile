import 'package:flutter/material.dart';

class GameLogic {
  // Updated canPour method with clearer logic
  static bool canPour(List<List<Color>> tubes, int fromTube, int toTube) {
    // Can't pour from an empty tube
    if (tubes[fromTube].isEmpty) return false; 
    
    // Can't pour into a full tube
    if (tubes[toTube].length >= 4) return false; 
    
    // Allow pouring if target tube is empty OR if the top colors match
    return tubes[toTube].isEmpty || tubes[toTube].last == tubes[fromTube].last;
  }
  
  // Check if the game is complete
  static bool isGameComplete(List<List<Color>> tubes) {
    // A tube is complete if it's empty or has 4 identical colors
    return tubes.every((tube) => 
      tube.isEmpty || (tube.length == 4 && tube.toSet().length == 1)
    );
  }
  
  // Get a hint for the next possible move
  static int? getHint(List<List<Color>> tubes) {
    // Look for a tube that has colors which can be poured into another tube
    for (int fromTube = 0; fromTube < tubes.length; fromTube++) {
      if (tubes[fromTube].isEmpty) continue;
      
      // If the tube has all same colors and is either full or rests on the bottom
      // it's already in its final position, don't suggest moving from it
      if (tubes[fromTube].every((color) => color == tubes[fromTube][0])) {
        if (tubes[fromTube].length == 4 || 
           !tubes.any((t) => t.isNotEmpty && t.last == tubes[fromTube][0] && t != tubes[fromTube])) {
          continue;
        }
      }
      
      for (int toTube = 0; toTube < tubes.length; toTube++) {
        if (fromTube == toTube) continue;
        if (canPour(tubes, fromTube, toTube)) {
          return fromTube; // Return index of tube to move from
        }
      }
    }
    return null; // No hint available
  }
  
  // Helper method to check if a tube is complete (all same color)
  static bool isTubeComplete(List<Color> tube) {
    return tube.length == 4 && tube.toSet().length == 1;
  }
  
  // Helper method to check if a move would complete a tube
  static bool willCompleteTube(List<List<Color>> tubes, int fromTube, int toTube) {
    if (!canPour(tubes, fromTube, toTube)) return false;
    
    // Count how many colors will be moved
    Color colorToMove = tubes[fromTube].last;
    int count = 0;
    for (int i = tubes[fromTube].length - 1; i >= 0; i--) {
      if (tubes[fromTube][i] == colorToMove) {
        count++;
      } else {
        break;
      }
    }
    
    // Check if adding these colors would make the destination tube complete
    int destinationCount = tubes[toTube].where((c) => c == colorToMove).length;
    return (destinationCount + count == 4);
  }
  
  // Validate that initial tubes are properly set up
  static bool validateInitialTubes(List<List<Color>> tubes) {
    // Check if we have at least one empty tube
    bool hasEmptyTube = tubes.any((tube) => tube.isEmpty);
    if (!hasEmptyTube) {
      return false; // Need at least one empty tube
    }
    
    // Check if there are at least 3 colors to sort
    Set<Color> uniqueColors = {};
    for (var tube in tubes) {
      for (var color in tube) {
        uniqueColors.add(color);
      }
    }
    
    return uniqueColors.length >= 3; // Game should have at least 3 colors
  }
}