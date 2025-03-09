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

  // Settings
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  // Game configuration
  static const int maxTubes = 7;
  static const int maxColors = 4;

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

    // Fixed set of distinct colors
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    // Calculate the number of color sets and tubes based on level difficulty
    int colorSets = 3 + (level - 1) ~/ 3;
    colorSets = colorSets.clamp(3, 6); // Limit to available colors

    int tubeCount = colorSets; // One tube per color set
    int emptyTubes = 2; // Always provide 2 empty tubes for maneuvering

    // Total tubes including empties
    int totalTubes = tubeCount + emptyTubes;
    totalTubes = totalTubes.clamp(3, maxTubes); // Apply max tube limit

    // Create tubes
    List<List<Color>> newTubes = List.generate(totalTubes, (i) => []);

    // Create a flat list of all colors needed (maxColors of each color type)
    List<Color> allColors = [];
    for (int c = 0; c < colorSets; c++) {
      for (int i = 0; i < maxColors; i++) {
        allColors.add(colors[c]);
      }
    }

    // Shuffle all colors to randomize their positions
    allColors.shuffle(random);

    // Distribute colors evenly across tubes (excluding empty tubes)
    for (int i = 0; i < allColors.length; i++) {
      int tubeIndex = i % tubeCount; // Distribute colors evenly
      if (newTubes[tubeIndex].length < maxColors) {
        newTubes[tubeIndex].add(allColors[i]);
      }
    }

    // Validate all tubes have proper number of colors
    for (int i = 0; i < tubeCount; i++) {
      if (newTubes[i].length != maxColors) {
        debugPrint(
            'Warning: Tube $i has ${newTubes[i].length} colors instead of $maxColors');
      }
    }

    // Ensure the puzzle is not trivially solved
    bool hasSameColorGroups = false;
    do {
      hasSameColorGroups = false;

      // Check each tube
      for (int i = 0; i < tubeCount; i++) {
        if (newTubes[i].isEmpty) continue;

        // Count consecutive same colors from the top
        Color topColor = newTubes[i][0];
        int sameColorCount = 1;
        for (int j = 1; j < newTubes[i].length; j++) {
          if (newTubes[i][j] == topColor) {
            sameColorCount++;
          } else {
            break;
          }
        }

        // If tube has all same colors, shuffle it with another tube
        if (sameColorCount == maxColors) {
          hasSameColorGroups = true;

          // Find another tube to swap with
          int otherTube = (i + 1) % tubeCount;

          // Swap a random color
          int idx1 = random.nextInt(newTubes[i].length);
          int idx2 = random.nextInt(newTubes[otherTube].length);
          Color temp = newTubes[i][idx1];
          newTubes[i][idx1] = newTubes[otherTube][idx2];
          newTubes[otherTube][idx2] = temp;
        }
      }
    } while (hasSameColorGroups);

    return newTubes;
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
  bool get vibrateEnabled => vibrationEnabled; // Add getter for vibration state
}
