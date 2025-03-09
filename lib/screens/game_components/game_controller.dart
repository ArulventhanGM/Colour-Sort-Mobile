import 'package:flutter/material.dart';
import '../../utils/audio_manager.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Controller class for managing game state and operations
class GameController {
  // Game state
  List<List<Color>> tubes = [];
  List<List<List<Color>>> history = [];
  Map<int, GlobalKey> tubeKeys = {};
  bool animating = false;

  // Audio manager reference for direct access
  final AudioManager _audioManager = AudioManager();

  // Game progress
  int currentLevel = 1;
  int score = 0;
  int moves = 0;
  int coins = 100;
  int coinsEarned = 0;
  int undoMovesLeft = 3;
  int _maxLevel = 200; // Maximum number of levels

  // Settings
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  // Game configuration
  static const int maxTubes =
      12; // Increased from 7 to allow more complex levels
  static const int maxColors = 4;

  // Available colors for the game - extended palette for variety
  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.amber,
    Colors.indigo,
    Colors.lime,
  ];

  GameController() {
    _initializeAudio();
    initializeLevel();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioManager.initialize();
      debugPrint('Audio initialized successfully in GameController');
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  void initializeLevel() {
    tubes = _generateLevel(currentLevel);
    moves = 0;
    history.clear();
    tubeKeys.clear();

    // Initialize tube keys
    for (int i = 0; i < tubes.length; i++) {
      tubeKeys[i] = GlobalKey();
    }
  }

  List<List<Color>> _generateLevel(int level) {
    final random = Random();

    // Calculate game parameters based on level difficulty
    final difficulty = _calculateLevelDifficulty(level);

    int colorSets = difficulty.colorSets;
    int emptyTubes = difficulty.emptyTubes;
    int totalTubes = colorSets + emptyTubes;
    int complexityFactor = difficulty.complexityFactor;

    // Create tubes
    List<List<Color>> newTubes = List.generate(totalTubes, (i) => []);

    // Create a flat list of all colors needed (maxColors of each color type)
    List<Color> allColors = [];
    for (int c = 0; c < colorSets; c++) {
      Color selectedColor = availableColors[c % availableColors.length];

      // For higher difficulty, slightly vary the colors to make matching harder
      if (level > 100 && random.nextDouble() < 0.3) {
        selectedColor = _slightlyVaryColor(selectedColor, random);
      }

      for (int i = 0; i < maxColors; i++) {
        allColors.add(selectedColor);
      }
    }

    // Shuffle all colors to randomize their positions
    allColors.shuffle(random);

    // Distribute colors across tubes with increasing complexity
    if (complexityFactor > 1 && level > 5) {
      // Create more complex distributions for higher levels
      _createComplexDistribution(
          newTubes, allColors, colorSets, random, complexityFactor);
    } else {
      // Basic distribution for early levels
      _createBasicDistribution(newTubes, allColors, colorSets);
    }

    // Add special challenges for milestone levels (every 25 levels)
    if (level % 25 == 0) {
      _addMilestoneChallenge(newTubes, level, random);
    }

    // Make sure the puzzle is not in a solved state
    _ensurePuzzleIsNotSolved(newTubes, colorSets, random);

    return newTubes;
  }

  /// Calculate difficulty parameters based on level number
  _LevelDifficulty _calculateLevelDifficulty(int level) {
    // Base difficulty scales with level
    int colorSets = 3;
    int emptyTubes = 2;
    int complexityFactor = 1;

    // Increment colors as level increases
    if (level <= 10) {
      // Level 1-10: 3 colors
      colorSets = 3;
    } else if (level <= 25) {
      // Level 11-25: 3-4 colors
      colorSets = 3 + (level - 10) ~/ 8;
    } else if (level <= 50) {
      // Level 26-50: 4-5 colors
      colorSets = 4 + (level - 25) ~/ 13;
    } else if (level <= 100) {
      // Level 51-100: 5-7 colors
      colorSets = 5 + (level - 50) ~/ 25;
    } else if (level <= 150) {
      // Level 101-150: 7-9 colors
      colorSets = 7 + (level - 100) ~/ 25;
    } else {
      // Level 151-200: 9-10 colors
      colorSets = 9 + (level - 150) ~/ 50;
    }

    // Cap color sets to available distinct colors
    colorSets = colorSets.clamp(3, availableColors.length);

    // Empty tubes increases slowly with level
    emptyTubes = 2 + (level ~/ 40);
    emptyTubes = emptyTubes.clamp(2, 4); // At most 4 empty tubes

    // Complexity factor increases with level
    complexityFactor = 1 + (level ~/ 20);
    complexityFactor = complexityFactor.clamp(1, 5);

    // Total tubes should not exceed max
    int totalTubes = colorSets + emptyTubes;
    if (totalTubes > maxTubes) {
      // Reduce empty tubes if needed
      emptyTubes = (maxTubes - colorSets).clamp(1, 4);
    }

    return _LevelDifficulty(
        colorSets: colorSets,
        emptyTubes: emptyTubes,
        complexityFactor: complexityFactor);
  }

  /// Create a color that's a slight variation of the original for extra challenge
  Color _slightlyVaryColor(Color baseColor, Random random) {
    // Only apply to higher levels for subtle differences in shade
    int variance = 25;

    return Color.fromARGB(
      255,
      (baseColor.red + random.nextInt(variance) - variance ~/ 2).clamp(0, 255),
      (baseColor.green + random.nextInt(variance) - variance ~/ 2)
          .clamp(0, 255),
      (baseColor.blue + random.nextInt(variance) - variance ~/ 2).clamp(0, 255),
    );
  }

  /// Basic distribution - simple patterns for early levels
  void _createBasicDistribution(
      List<List<Color>> tubes, List<Color> allColors, int colorSets) {
    // Distribute colors evenly across tubes
    for (int i = 0; i < allColors.length; i++) {
      int tubeIndex = i % colorSets; // Distribute colors evenly
      if (tubes[tubeIndex].length < maxColors) {
        tubes[tubeIndex].add(allColors[i]);
      }
    }
  }

  /// Complex distribution - creates more challenging patterns
  void _createComplexDistribution(
      List<List<Color>> tubes,
      List<Color> allColors,
      int colorSets,
      Random random,
      int complexityFactor) {
    // Initial distribution - put most colors somewhere
    for (int i = 0; i < allColors.length; i++) {
      int tubeIndex = random.nextInt(colorSets);
      if (tubes[tubeIndex].length < maxColors) {
        tubes[tubeIndex].add(allColors[i]);
      } else {
        // Find another tube with space
        int attempts = 0;
        while (attempts < colorSets) {
          tubeIndex = (tubeIndex + 1) % colorSets;
          if (tubes[tubeIndex].length < maxColors) {
            tubes[tubeIndex].add(allColors[i]);
            break;
          }
          attempts++;
        }
      }
    }

    // Perform some swaps to increase complexity
    int swaps = complexityFactor * 3;

    for (int i = 0; i < swaps; i++) {
      // Pick two random tubes
      int tube1 = random.nextInt(colorSets);
      int tube2 = random.nextInt(colorSets);

      if (tube1 != tube2 && !tubes[tube1].isEmpty && !tubes[tube2].isEmpty) {
        // Swap random elements
        int idx1 = random.nextInt(tubes[tube1].length);
        int idx2 = random.nextInt(tubes[tube2].length);

        Color temp = tubes[tube1][idx1];
        tubes[tube1][idx1] = tubes[tube2][idx2];
        tubes[tube2][idx2] = temp;
      }
    }
  }

  /// Add special challenges for milestone levels
  void _addMilestoneChallenge(
      List<List<Color>> tubes, int level, Random random) {
    int colorSets = tubes.length - (2 + (level ~/ 40)).clamp(2, 4);

    if (level % 50 == 0) {
      // Every 50 levels - create a tube with alternating colors for extra challenge
      int targetTube = random.nextInt(colorSets);
      if (tubes[targetTube].length >= 3) {
        // Create alternating pattern ABABA
        Color colorA = tubes[targetTube][0];
        Color colorB = _findDifferentColor(tubes, colorA, random);

        tubes[targetTube] = [colorA, colorB, colorA, colorB];
      }
    } else if (level % 25 == 0) {
      // Every 25 levels - create tubes with just 1 different color each
      for (int i = 0; i < min(2, colorSets); i++) {
        int targetTube = random.nextInt(colorSets);
        if (tubes[targetTube].length >= 3) {
          Color mainColor = tubes[targetTube][0];
          Color differentColor = _findDifferentColor(tubes, mainColor, random);

          List<Color> newTubeContents = List.filled(3, mainColor);
          newTubeContents.add(differentColor);
          tubes[targetTube] = newTubeContents;
        }
      }
    }
  }

  /// Find a color different from the specified color
  Color _findDifferentColor(
      List<List<Color>> tubes, Color colorToAvoid, Random random) {
    // Collect all colors in use
    Set<Color> colorsInUse = {};
    for (var tube in tubes) {
      for (var color in tube) {
        colorsInUse.add(color);
      }
    }

    // Remove the color to avoid
    colorsInUse.remove(colorToAvoid);

    if (colorsInUse.isEmpty) {
      // If no other colors, use a random color from available colors
      return availableColors[
          (availableColors.indexOf(colorToAvoid) + 1) % availableColors.length];
    }

    return colorsInUse.elementAt(random.nextInt(colorsInUse.length));
  }

  /// Make sure the puzzle isn't trivially solved
  void _ensurePuzzleIsNotSolved(
      List<List<Color>> tubes, int colorSets, Random random) {
    bool hasSameColorGroups = false;

    // Check each tube
    for (int i = 0; i < colorSets; i++) {
      if (tubes[i].isEmpty) continue;

      // Check if all colors in tube are the same
      if (tubes[i].length == maxColors &&
          tubes[i].every((color) => color == tubes[i][0])) {
        hasSameColorGroups = true;

        // Find another tube to swap with
        int otherTube = (i + 1) % colorSets;

        // Swap a random color
        if (tubes[otherTube].isNotEmpty) {
          int idx1 = random.nextInt(tubes[i].length);
          int idx2 = random.nextInt(tubes[otherTube].length);
          Color temp = tubes[i][idx1];
          tubes[i][idx1] = tubes[otherTube][idx2];
          tubes[otherTube][idx2] = temp;
        }
      }
    }

    if (hasSameColorGroups) {
      // Double-check that we broke up all same-color groups
      _ensurePuzzleIsNotSolved(tubes, colorSets, random);
    }
  }

  bool canPour(int fromTube, int toTube) {
    if (fromTube == toTube) return false;
    if (tubes[fromTube].isEmpty) return false;
    if (tubes[toTube].length >= maxColors) return false;

    final sourceColor = tubes[fromTube].last;
    return tubes[toTube].isEmpty || tubes[toTube].last == sourceColor;
  }

  void performBasicPour(int fromTube, int toTube) {
    if (!canPour(fromTube, toTube)) return;

    final sourceColor = tubes[fromTube].last;
    int colorCount = 0;

    // Count consecutive matching colors
    for (int i = tubes[fromTube].length - 1; i >= 0; i--) {
      if (tubes[fromTube][i] == sourceColor &&
          colorCount + tubes[toTube].length < maxColors) {
        colorCount++;
      } else {
        break;
      }
    }

    // Move the colors
    for (int i = 0; i < colorCount; i++) {
      tubes[toTube].add(tubes[fromTube].removeLast());
    }

    moves++;
    saveHistory();
    updateStars();
  }

  bool isGameComplete() {
    for (var tube in tubes) {
      if (tube.isEmpty) continue;
      if (tube.length != maxColors) return false;
      if (!tube.every((color) => color == tube[0])) return false;
    }
    return true;
  }

  void nextLevel() {
    currentLevel++;

    // Bonus coins for completing levels
    int levelCompletionBonus = 5 + (currentLevel ~/ 10) * 5;
    coins += levelCompletionBonus;

    // Reset undo moves every 10 levels
    if (currentLevel % 10 == 1) {
      undoMovesLeft = min(3 + (currentLevel ~/ 20), 10);
    }

    initializeLevel();
  }

  void saveHistory() {
    history.add(tubes.map((tube) => List<Color>.from(tube)).toList());
  }

  bool undoMove() {
    if (history.isEmpty) return false;
    if (undoMovesLeft <= 0) return false;

    tubes = history.removeLast().map((tube) => List<Color>.from(tube)).toList();
    undoMovesLeft--;
    return true;
  }

  bool addExtraTube() {
    if (tubes.length >= maxTubes || coins < 50) return false;

    tubes.add([]);
    tubeKeys[tubes.length - 1] = GlobalKey();
    coins -= 50;
    return true;
  }

  void updateStars() {
    // Calculate stars based on moves and level
    int maxMoves = 10 + currentLevel * 2;
    score = (maxMoves - moves).clamp(0, maxMoves);
    coinsEarned = score * 2;
    coins += coinsEarned;
  }

  void playSound(String soundName) {
    if (!soundEnabled) return;

    try {
      switch (soundName) {
        case 'select':
          _audioManager.playSelect();
          break;
        case 'pour':
          _audioManager.playPour();
          break;
        case 'bubble':
          _audioManager.playBubble();
          break;
        case 'complete':
          _audioManager.playComplete();
          break;
        case 'error':
          _audioManager.playError();
          break;
      }
    } catch (e) {
      debugPrint('Error playing sound $soundName: $e');
    }
  }

  void vibrateDevice() {
    if (!vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }

  void setSoundEnabled(bool enabled) {
    soundEnabled = enabled;
    _audioManager.setSoundEnabled(enabled);
  }

  void setVibrationEnabled(bool enabled) {
    vibrationEnabled = enabled;
  }

  // Getters for game state
  bool get canUndo => history.isNotEmpty && undoMovesLeft > 0;
  bool get canAddTube => tubes.length < maxTubes && coins >= 50;
  int get movesCount => moves;
  int get extraTubePrice => 50; // Price in coins to add a new tube
  bool get vibrateEnabled => vibrationEnabled;
  int get maxLevel => _maxLevel; // New getter for max level
}

/// Helper class to store difficulty parameters for each level
class _LevelDifficulty {
  final int colorSets;
  final int emptyTubes;
  final int complexityFactor;

  _LevelDifficulty({
    required this.colorSets,
    required this.emptyTubes,
    required this.complexityFactor,
  });
}
