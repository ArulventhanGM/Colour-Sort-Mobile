import 'package:flutter/material.dart';
import '../utils/audio_manager.dart';
import 'dart:math' as math;

import 'game_components/game_controller.dart';
import 'game_components/splash_effect_info.dart';
import 'game_components/game_animations.dart';
import 'game_components/liquid_pouring_animation.dart';
import 'game_components/game_header.dart';
import 'game_components/game_stats.dart';
import 'game_components/game_controls.dart';
import 'game_components/tubes_grid.dart';
import 'game_components/settings_dialog.dart';
import 'game_components/store_dialog.dart';
import 'game_components/completion_dialog.dart';
import 'game_components/background_pattern.dart';

import '../widgets/splash_effect.dart';

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class HintArrowPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Animation<double> progress;

  HintArrowPainter({
    required this.startPoint,
    required this.endPoint,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Calculate current point based on animation progress
    final currentPoint = Offset.lerp(startPoint, endPoint, progress.value)!;

    // Draw the line
    path.moveTo(startPoint.dx, startPoint.dy);
    path.lineTo(currentPoint.dx, currentPoint.dy);

    // Draw arrow head if we're near the end
    if (progress.value > 0.9) {
      double angle =
          math.atan2(endPoint.dy - startPoint.dy, endPoint.dx - startPoint.dx);
      double arrowSize = 20.0;

      path.moveTo(
        endPoint.dx - arrowSize * math.cos(angle - math.pi / 6),
        endPoint.dy - arrowSize * math.sin(angle - math.pi / 6),
      );
      path.lineTo(endPoint.dx, endPoint.dy);
      path.lineTo(
        endPoint.dx - arrowSize * math.cos(angle + math.pi / 6),
        endPoint.dy - arrowSize * math.sin(angle + math.pi / 6),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HintArrowPainter oldDelegate) => true;
}

class _GameHomePageState extends State<GameHomePage>
    with TickerProviderStateMixin {
  // Game state and logic controller
  late GameController _gameController;

  // UI state variables
  int? _selectedTube;
  bool _animating = false;

  // Animation controllers
  late AnimationController _popupController;
  late AnimationController _pourController;
  late AnimationController _liftController;
  late AnimationController _rotateController;
  late AnimationController _dropController;

  // Animation tracking variables
  Color? _pouringColor;
  Offset? _pourStart;
  Offset? _pourEnd;
  int? _liftedTube;
  int? _targetTubeReceiving; // This is the only target tube state we need
  Offset? _liftedTubeStartPosition;
  Offset? _targetTubePosition;
  double? _liftedTubeAngle;

  // Splash effects for visual feedback
  final List<SplashEffectInfo> _splashEffects = [];

  @override
  void initState() {
    super.initState();

    // Initialize game controller
    _gameController = GameController();
    _gameController.initializeLevel();

    // Initialize animation controllers
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pourController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _animating = false;
            _pouringColor = null;
          });
        }
      });

    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadSoundEffects();
  }

  @override
  void dispose() {
    _popupController.dispose();
    _pourController.dispose();
    _liftController.dispose();
    _rotateController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  /// Initialize audio for the game
  Future<void> _loadSoundEffects() async {
    try {
      // Use AudioManager to handle all sounds
      await AudioManager().initialize();
    } catch (e) {
      print('Error loading sound effects: $e');
    }
  }

  /// Handle tube selection
  void _handleTubeSelection(int index) {
    if (_animating) return;

    setState(() {
      // -1 means deselect
      if (index == -1) {
        _selectedTube = null;
        _gameController.playSound('select');
        _gameController.vibrateDevice();
      } else {
        _selectedTube = index;
        _gameController.playSound('select');
        _gameController.vibrateDevice();
      }
    });
  }

  /// Handle pouring action between tubes
  void _handlePourAction(int fromTube, int toTube) {
    if (_animating) return;

    if (_gameController.canPour(fromTube, toTube)) {
      _animatePouring(fromTube, toTube);
      _selectedTube = null;
    } else {
      _showErrorPopup("Invalid move! Cannot pour water.\n"
          "Make sure destination tube isn't full and colors match.");
    }
  }

  /// Animate pouring between tubes with visual effects
  void _animatePouring(int fromTube, int toTube) {
    try {
      // Make sure we have the correct tube keys
      if (_gameController.tubeKeys[fromTube] == null ||
          _gameController.tubeKeys[toTube] == null) {
        _gameController.performBasicPour(fromTube, toTube);
        return;
      }

      // Set target tubes for animation tracking
      _targetTubeReceiving = toTube;

      // Try to get contexts for both tubes
      final sourceTubeContext =
          _gameController.tubeKeys[fromTube]!.currentContext;
      final targetTubeContext =
          _gameController.tubeKeys[toTube]!.currentContext;

      if (sourceTubeContext == null || targetTubeContext == null) {
        _gameController.performBasicPour(fromTube, toTube);
        return;
      }

      // Try to get render boxes for both tubes
      final sourceTubeRenderBox =
          sourceTubeContext.findRenderObject() as RenderBox?;
      final targetTubeRenderBox =
          targetTubeContext.findRenderObject() as RenderBox?;

      if (sourceTubeRenderBox == null || targetTubeRenderBox == null) {
        _gameController.performBasicPour(fromTube, toTube);
        return;
      }

      // Ensure source tube has colors to pour
      if (_gameController.tubes[fromTube].isEmpty) {
        return;
      }

      // Get the colors to pour before starting animation
      List<Color> colorsToPour = [];
      Color colorToPour = _gameController.tubes[fromTube].last;

      // Check if this pour will cause a color mixing effect
      bool willMixColors = _gameController.tubes[toTube].isNotEmpty &&
          _gameController.tubes[toTube].last != colorToPour;

      // Count how many colors we'll be pouring (don't actually remove them yet)
      int colorCount = 0;
      for (int i = _gameController.tubes[fromTube].length - 1; i >= 0; i--) {
        if (_gameController.tubes[fromTube][i] == colorToPour &&
            colorCount + _gameController.tubes[toTube].length < 4) {
          colorCount++;
        } else {
          break;
        }
      }

      // If no colors to pour, exit early
      if (colorCount == 0) {
        return;
      }

      setState(() {
        _animating = true;
        _gameController.animating = true;
        _pouringColor = colorToPour;
        _liftedTube = fromTube;
        _targetTubeReceiving = toTube;

        // Calculate global positions for animation
        final sourcePosition = sourceTubeRenderBox.localToGlobal(Offset.zero);
        final targetPosition = targetTubeRenderBox.localToGlobal(Offset.zero);

        _liftedTubeStartPosition = sourcePosition;
        _targetTubePosition = targetPosition;

        // Calculate pour start and end positions more accurately
        _pourStart = Offset(
            sourcePosition.dx + sourceTubeRenderBox.size.width / 2,
            sourcePosition.dy + 10);

        _pourEnd = Offset(
            targetPosition.dx + targetTubeRenderBox.size.width / 2,
            targetPosition.dy + 10);

        // Remove the colors to pour
        for (int i = 0; i < colorCount; i++) {
          if (_gameController.tubes[fromTube].isNotEmpty) {
            colorsToPour.add(_gameController.tubes[fromTube].removeLast());
          }
        }

        // Save history and update moves
        _gameController.saveHistory();
        _gameController.moves++;
        _gameController.updateStars();
      });

      // Begin lift animation sequence
      _gameController.vibrateDevice();
      _gameController.playSound('select');

      _liftController.forward(from: 0).then((_) {
        // Rotate tube to pour
        _liftedTubeAngle = GameAnimations.calculatePouringAngle(
            _liftedTubeStartPosition, _targetTubePosition, fromTube, toTube);
        _gameController.playSound('pour');

        _rotateController.forward(from: 0).then((_) {
          // Run pouring animation
          _pourController.forward(from: 0).then((_) {
            // Set the receiving tube indicator
            setState(() {
              _targetTubeReceiving = toTube;
            });

            // Show splash effect if colors are mixing
            if (willMixColors) {
              _showSplashEffect(
                  _targetTubePosition!.dx + targetTubeRenderBox.size.width / 2,
                  _targetTubePosition!.dy +
                      targetTubeRenderBox.size.height * 0.7,
                  _gameController.tubes[toTube].isNotEmpty
                      ? _gameController.tubes[toTube].last
                      : colorToPour,
                  colorToPour,
                  true // This is a color mixing event
                  );
              _gameController
                  .playSound('bubble'); // Play bubble sound for mixing
            }

            // Return tube to upright position
            _rotateController.reverse().then((_) {
              // Return tube to original position
              _dropController.forward(from: 0).then((_) {
                if (mounted) {
                  setState(() {
                    _gameController.tubes[toTube].addAll(colorsToPour);
                    _animating = false;
                    _gameController.animating = false;
                    _pouringColor = null;
                    _liftedTube = null;
                    _targetTubeReceiving = null;
                    _liftedTubeStartPosition = null;
                    _targetTubePosition = null;
                    _liftedTubeAngle = null;

                    // Reset animation controllers
                    _liftController.reset();
                    _rotateController.reset();
                    _dropController.reset();

                    // Check if game is complete
                    if (_gameController.isGameComplete()) {
                      _gameController.playSound('complete');
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _showCompletionPopup();
                        }
                      });
                    }
                  });
                }
              });
            });
          });
        });
      });

      // Reset target tubes when animation completes
      _pourController.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _targetTubeReceiving = null;
            // ... rest of completion logic ...
          });
        }
      });
    } catch (e) {
      print("Error during pour animation: $e");
      _gameController.performBasicPour(fromTube, toTube);
    }
  }

  /// Show a splash effect at a specific position
  void _showSplashEffect(
      double x, double y, Color color1, Color color2, bool isColorMixing) {
    // Calculate a blended color for the splash
    Color blendedColor = Color.lerp(color1, color2, 0.5) ?? color1;

    setState(() {
      _splashEffects.add(SplashEffectInfo(
        offset: Offset(x, y),
        color: blendedColor,
        size: 30.0,
        isColorMixing: isColorMixing,
        startTime: DateTime.now(),
      ));
    });

    // Remove the splash after its animation completes
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          if (_splashEffects.isNotEmpty) {
            _splashEffects.removeWhere((effect) =>
                DateTime.now().difference(effect.startTime).inMilliseconds >=
                800);
          }
        });
      }
    });
  }

  /// Show error message to the user
  void _showErrorPopup(String message) {
    _gameController.playSound('error');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[300],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.7,
            left: 20,
            right: 20),
      ),
    );
  }

  /// Show completion popup when level is finished
  void _showCompletionPopup() {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: CompletionDialog(
            gameController: _gameController,
            onNextLevel: () {
              setState(() {
                _gameController.nextLevel();
              });
            },
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: false,
      barrierLabel: 'Level complete',
    );
  }

  /// Show settings dialog
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        gameController: _gameController,
        onSoundToggled: (enabled) {
          setState(() {
            _gameController.setSoundEnabled(enabled);
          });
        },
        onVibrationToggled: (enabled) {
          setState(() {
            _gameController.setVibrationEnabled(enabled);
          });
        },
      ),
    );
  }

  /// Show store dialog
  void _showStore() {
    showDialog(
      context: context,
      builder: (context) => StoreDialog(
        gameController: _gameController,
        onUndoPurchase: () {
          setState(() {
            _gameController.undoMovesLeft += 10;
            _gameController.coins -= 30;
          });
        },
        onHintPurchase: () {
          // TODO: Implement hint purchase
        },
        onCoinPurchase: () {
          // TODO: Implement coin purchase
        },
      ),
    );
  }

  /// Show hint for the next best move
  void _showHint() {
    if (_gameController.coins < 10) {
      _showErrorPopup("Not enough coins! You need 10 coins for a hint.");
      return;
    }

    // Find a valid move to suggest
    int? fromTube;
    int? toTube;

    // Check each tube combination for a valid move
    for (int i = 0; i < _gameController.tubes.length; i++) {
      if (_gameController.tubes[i].isEmpty) continue;

      for (int j = 0; j < _gameController.tubes.length; j++) {
        if (i == j) continue;

        if (_gameController.canPour(i, j)) {
          fromTube = i;
          toTube = j;
          break;
        }
      }
      if (fromTube != null) break;
    }

    if (fromTube != null && toTube != null) {
      // Deduct coins for using hint
      setState(() {
        _gameController.coins -= 10;
      });

      // Highlight the suggested move
      final sourceTubeContext =
          _gameController.tubeKeys[fromTube]!.currentContext;
      final targetTubeContext =
          _gameController.tubeKeys[toTube]!.currentContext;

      if (sourceTubeContext != null && targetTubeContext != null) {
        final sourceTubeRenderBox =
            sourceTubeContext.findRenderObject() as RenderBox;
        final targetTubeRenderBox =
            targetTubeContext.findRenderObject() as RenderBox;

        final sourcePosition = sourceTubeRenderBox.localToGlobal(Offset.zero);
        final targetPosition = targetTubeRenderBox.localToGlobal(Offset.zero);

        // Show hint animation
        _showHintAnimation(
          sourcePosition.translate(sourceTubeRenderBox.size.width / 2,
              sourceTubeRenderBox.size.height / 2),
          targetPosition.translate(targetTubeRenderBox.size.width / 2,
              targetTubeRenderBox.size.height / 2),
        );
      }
    } else {
      _showErrorPopup("No valid moves available!");
    }
  }

  void _showHintAnimation(Offset start, Offset end) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black26,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: HintArrowPainter(
                  startPoint: start,
                  endPoint: end,
                  progress: animation,
                ),
              ),
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: 'Hint',
      barrierColor: Colors.transparent,
    );
  }

  void _removeSplashEffect(SplashEffectInfo effect) {
    setState(() {
      _splashEffects.remove(effect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // New background pattern
          const BackgroundPattern(),

          Column(
            children: [
              // Enhanced header at the top
              GameHeader(
                currentLevel: _gameController.currentLevel,
                coins: _gameController.coins,
                onSettingsPressed: _showSettings,
                onStorePressed: _showStore,
                onHintPressed: _showHint,
              ),

              // Game stats with animations
              GameStats(
                score: _gameController.score,
                movesCount: _gameController.movesCount,
                coinsEarned: _gameController.coinsEarned,
              ),

              // Main game area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Tubes grid with improved layout
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: MediaQuery.of(context).size.height * 0.05,
                      ),
                      child: TubesGrid(
                        gameController: _gameController,
                        selectedTube: _selectedTube,
                        liftedTube: _liftedTube,
                        receivingTube: _targetTubeReceiving,
                        liftedTubeAngle: _liftedTubeAngle,
                        liftAnimation: _liftController,
                        rotateAnimation: _rotateController,
                        dropAnimation: _dropController,
                        pourAnimation: _pourController,
                        splashEffects: _splashEffects,
                        onTubeSelected: _handleTubeSelection,
                        onPourAction: _handlePourAction,
                        onAddExtraTube: () {
                          if (_gameController.addExtraTube()) {
                            setState(() {});
                          } else {
                            _showErrorPopup("Not enough coins to add a tube!");
                          }
                        },
                      ),
                    ),

                    // Enhanced pouring animation overlay
                    if (_pouringColor != null &&
                        _pourStart != null &&
                        _pourEnd != null)
                      LiquidPouringAnimation(
                        pouringColor: _pouringColor!,
                        pourStart: _pourStart!,
                        pourEnd: _pourEnd!,
                        pourAnimation: _pourController,
                      ),

                    // Improved splash effects
                    ..._splashEffects.map((effect) => SplashEffect(
                          offset: effect.offset,
                          color: effect.color,
                          size: effect.size,
                          onComplete: () => _removeSplashEffect(effect),
                          isColorMixing: effect.isColorMixing,
                        )),
                  ],
                ),
              ),

              // Modern bottom controls
              GameControls(
                onUndo: () {
                  if (_gameController.undoMove()) {
                    setState(() {
                      _selectedTube = null;
                    });
                  } else if (_gameController.undoMovesLeft <= 0 &&
                      _gameController.history.isNotEmpty) {
                    _showErrorPopup("No free undo moves left!");
                  }
                },
                onReset: () {
                  setState(() {
                    _gameController.initializeLevel();
                    _selectedTube = null;
                  });
                },
                onAddTube: () {
                  if (_gameController.addExtraTube()) {
                    setState(() {});
                  } else {
                    _showErrorPopup("Not enough coins to add a tube!");
                  }
                },
                canUndo: _gameController.canUndo,
                canAddTube: _gameController.canAddTube,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
