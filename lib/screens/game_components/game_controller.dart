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
    initializeLevel();
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
    // Example level generation - you can make this more sophisticated
    final random = Random();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    int tubeCount = 3 + (level - 1) ~/ 2;
    tubeCount = tubeCount.clamp(3, maxTubes);

    List<List<Color>> newTubes = List.generate(tubeCount + 2, (i) => []);

    // Fill tubes with colors
    for (int i = 0; i < tubeCount; i++) {
      for (int j = 0; j < maxColors; j++) {
        newTubes[i].add(colors[random.nextInt(colors.length)]);
      }
    }

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
    AudioManager().initialize().then((_) {
      switch (soundName) {
        case 'select':
          AudioManager().playSelect();
          break;
        case 'pour':
          AudioManager().playPour();
          break;
        case 'bubble':
          AudioManager().playBubble();
          break;
        case 'complete':
          AudioManager().playComplete();
          break;
        case 'error':
          AudioManager().playError();
          break;
      }
    });
  }

  void vibrateDevice() {
    if (!vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }

  void setSoundEnabled(bool enabled) {
    soundEnabled = enabled;
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
