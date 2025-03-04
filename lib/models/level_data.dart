import 'package:flutter/material.dart';
import 'dart:math';

class LevelData {
  static List<List<Color>> getLevelTubes(int level) {
    if (level == 1) {
      // Tutorial level - easier to understand the game
      return _level1();
    } else if (level <= 5) {
      // Predefined levels with mixed colors
      switch (level) {
        case 2: return _level2();
        case 3: return _level3();
        case 4: return _level4();
        case 5: return _level5();
        default: return _level2(); // Fallback
      }
    } else {
      // Generate a procedural level with properly mixed colors
      return _generateMixedLevel(level);
    }
  }

  // Tutorial level - simple mix of colors to teach mechanics
  static List<List<Color>> _level1() {
    return [
      [Colors.red, Colors.blue, Colors.green, Colors.blue],
      [Colors.green, Colors.red, Colors.blue, Colors.red],
      [Colors.green, Colors.red, Colors.blue, Colors.green],
      [], // Empty tube
      [], // Empty tube
    ];
  }

  // Challenging levels with mixed color tubes
  static List<List<Color>> _level2() {
    return [
      [Colors.red, Colors.yellow, Colors.green, Colors.blue],
      [Colors.green, Colors.red, Colors.blue, Colors.yellow],
      [Colors.yellow, Colors.blue, Colors.red, Colors.yellow],
      [Colors.blue, Colors.green, Colors.yellow, Colors.green],
      [], // Empty tube
      [], // Empty tube
    ];
  }

  static List<List<Color>> _level3() {
    return [
      [Colors.red, Colors.yellow, Colors.green, Colors.blue],
      [Colors.purple, Colors.yellow, Colors.purple, Colors.green],
      [Colors.yellow, Colors.blue, Colors.red, Colors.purple],
      [Colors.blue, Colors.green, Colors.yellow, Colors.red],
      [Colors.purple, Colors.red, Colors.green, Colors.blue],
      [], // Empty tube
      [], // Empty tube
    ];
  }

  static List<List<Color>> _level4() {
    return [
      [Colors.red, Colors.orange, Colors.green, Colors.blue],
      [Colors.green, Colors.purple, Colors.blue, Colors.orange],
      [Colors.purple, Colors.blue, Colors.red, Colors.purple],
      [Colors.orange, Colors.red, Colors.orange, Colors.green],
      [Colors.blue, Colors.purple, Colors.green, Colors.red],
      [], // Empty tube
      [], // Empty tube
    ];
  }

  static List<List<Color>> _level5() {
    return [
      [Colors.red, Colors.orange, Colors.green, Colors.blue],
      [Colors.green, Colors.purple, Colors.pink, Colors.orange],
      [Colors.purple, Colors.blue, Colors.red, Colors.purple],
      [Colors.orange, Colors.pink, Colors.orange, Colors.green],
      [Colors.blue, Colors.purple, Colors.green, Colors.red],
      [Colors.pink, Colors.red, Colors.pink, Colors.yellow],
      [Colors.yellow, Colors.yellow, Colors.yellow, Colors.pink],
      [], // Empty tube
      [], // Empty tube
    ];
  }

  // Generate a completely mixed level where no tube is sorted
  static List<List<Color>> _generateMixedLevel(int level) {
    try {
      // Define available colors
      List<Color> availableColors = [
        Colors.red, Colors.blue, Colors.green, Colors.yellow,
        Colors.purple, Colors.orange, Colors.teal, Colors.pink,
        Colors.indigo, Colors.amber, Colors.cyan, Colors.brown,
        Colors.lime, Colors.deepOrange, Colors.lightBlue, Colors.deepPurple,
      ];
      
      availableColors.shuffle();
      
      // Determine level parameters - ensure proper setup
      int numColors = min(3 + (level ~/ 2), 8); // Cap at 8 colors for playability
      int emptyTubes = max(2, numColors ~/ 3); // At least 2 empty tubes, more for higher levels
      int numTubes = numColors + emptyTubes;
      
      // Choose colors for this level
      List<Color> levelColors = availableColors.take(numColors).toList();
      
      // Create complete set with all colors (4 of each)
      List<Color> allColorUnits = [];
      for (var color in levelColors) {
        allColorUnits.addAll(List.filled(4, color));
      }
      
      // Shuffle the colors thoroughly
      final random = Random();
      for (int i = 0; i < 5; i++) { // Multiple shuffles for better randomization
        allColorUnits.shuffle(random);
      }
      
      // Create tubes array - all initially empty
      List<List<Color>> tubes = List.generate(numTubes, (_) => []);
      
      // Calculate filled tubes count
      int filledTubes = numTubes - emptyTubes;
      
      // Distribute colors to tubes, ensuring no tube has more than 4 colors
      int colorIndex = 0;
      for (int tubeIndex = 0; tubeIndex < filledTubes; tubeIndex++) {
        for (int position = 0; position < 4 && colorIndex < allColorUnits.length; position++) {
          tubes[tubeIndex].add(allColorUnits[colorIndex]);
          colorIndex++;
        }
      }
      
      // Additional validation to prevent fully sorted tubes at start
      bool hasProblem;
      do {
        hasProblem = false;
        
        // Check for tubes that are already sorted (all same color)
        for (int i = 0; i < filledTubes; i++) {
          if (tubes[i].length == 4 && tubes[i].toSet().length == 1) {
            // This tube is already sorted, need to mix it up
            hasProblem = true;
            
            // Find another tube to swap with
            for (int j = 0; j < filledTubes; j++) {
              if (i != j && tubes[j].isNotEmpty) {
                // Swap a color
                Color temp = tubes[i][0]; // Take first color
                tubes[i][0] = tubes[j][0]; // Swap with another tube
                tubes[j][0] = temp;
                break;
              }
            }
          }
        }
      } while (hasProblem);
      
      return tubes;
    } catch (e) {
      print("Error in level generation: $e");
      // Fallback simple mixed level - guaranteed to work
      return [
        [Colors.red, Colors.green, Colors.blue],
        [Colors.blue, Colors.red, Colors.green],
        [Colors.green, Colors.blue, Colors.red],
        [], // Empty tube 1
        [], // Empty tube 2
      ];
    }
  }

  // Ensure no tube has all the same color
  static void _validateNoSameColorTubes(List<List<Color>> tubes, int filledTubes) {
    for (int i = 0; i < filledTubes; i++) {
      Set<Color> uniqueColors = tubes[i].toSet();
      
      // If tube has just one color, mix it up
      if (uniqueColors.length == 1) {
        // Find another tube to swap with
        for (int j = 0; j < filledTubes; j++) {
          if (i != j && tubes[j].any((color) => color != tubes[i][0])) {
            // Find a different color in the other tube
            int indexToSwap = tubes[j].indexWhere((color) => color != tubes[i][0]);
            if (indexToSwap >= 0) {
              // Swap a color
              Color temp = tubes[i][1]; // Take second color from current tube
              tubes[i][1] = tubes[j][indexToSwap];
              tubes[j][indexToSwap] = temp;
              break;
            }
          }
        }
      }
    }
  }

  // Check if a level is solvable
  static bool isLevelSolvable(List<List<Color>> tubes) {
    // Count color occurrences
    Map<Color, int> colorCounts = {};
    
    for (var tube in tubes) {
      for (var color in tube) {
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Each color should appear exactly 4 times
    bool validColorCounts = colorCounts.values.every((count) => count == 4);
    
    // Also check that we don't have any tube that's already completed
    int completeTubes = 0;
    for (var tube in tubes) {
      if (tube.length == 4 && tube.toSet().length == 1) {
        completeTubes++;
      }
    }
    
    // Allow at most one complete tube in harder levels for challenge
    return validColorCounts && completeTubes <= 1;
  }
}