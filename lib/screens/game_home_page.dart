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
import 'game_components/achievement_dialog.dart';
import 'game_components/daily_reward_dialog.dart';
import 'game_components/hint_arrow_painter.dart';
import 'game_components/hint_manager.dart';

import '../widgets/splash_effect.dart';

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage>
    with TickerProviderStateMixin {
  // Game state and logic controller
  late GameController _gameController;

  // UI state variables
  int? _selectedTube;
  bool _animating = false;
  bool _achievementsChecked = false; // Flag to track if achievements checked

  // Animation controllers
  late AnimationController _popupController;
  late AnimationController _pourController;
  late AnimationController _liftController;
  late AnimationController _rotateController;
  late AnimationController _dropController;
  late AnimationController _hintController; // New animation controller for hints

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

  // Hint animation state
  bool _showingHintAnimation = false;
  Offset? _hintFromPosition;
  Offset? _hintToPosition;
  HintMove? _currentHintMove;

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
    
    // Initialize hint animation controller
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Loop the animation continuously while hint is showing
        if (_showingHintAnimation) {
          _hintController.reset();
          _hintController.forward();
        }
      }
    });

    _loadSoundEffects();

    // Check for daily rewards on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });
  }

  @override
  void dispose() {
    _popupController.dispose();
    _pourController.dispose();
    _liftController.dispose();
    _rotateController.dispose();
    _dropController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  /// Initialize audio for the game
  Future<void> _loadSoundEffects() async {
    try {
      debugPrint('Initializing audio in GameHomePage...');

      // Make sure AudioManager is properly initialized
      final audioManager = AudioManager();
      await audioManager.initialize();

      // Play a test sound to ensure everything is working
      if (_gameController.soundEnabled) {
        Future.delayed(Duration(milliseconds: 500), () {
          _gameController.playSound('select');
        });
      }

      debugPrint('Audio initialization complete in GameHomePage');
    } catch (e) {
      debugPrint('Error initializing audio in GameHomePage: $e');
    }
  }

  /// Check for daily login rewards
  void _checkDailyReward() {
    final dailyReward = _gameController.dailyLoginReward;

    if (dailyReward != null) {
      // Show the daily reward dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DailyRewardDialog(
          gameController: _gameController,
          reward: dailyReward,
        ),
      );
    }
  }

  /// Check for pending achievements
  void _checkAchievements() {
    if (_achievementsChecked) return;

    if (_gameController.pendingAchievements.isNotEmpty) {
      // Mark as checked so we don't show multiple dialogs
      _achievementsChecked = true;

      // Show achievement dialog for the first achievement
      final achievement = _gameController.pendingAchievements.first;

      // Show after a short delay to let level completion dialog close
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AchievementDialog(
              gameController: _gameController,
              achievement: achievement,
            ),
          ).then((_) {
            // Check if there are more achievements to show
            if (_gameController.pendingAchievements.isNotEmpty) {
              _achievementsChecked = false;
              _checkAchievements();
            }
          });
        }
      });
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
    // Reset achievement check flag for next level
    _achievementsChecked = false;

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

                // Check for achievement unlocks after level completion
                _checkAchievements();
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
          setState(() {
            _gameController.hints += 5;
            _gameController.coins -= 50;
          });
        },
        onCoinPurchase: () {
          setState(() {
            _gameController.coins += 100;
          });
        },
      ),
    );
  }

  /// Show hint for the next best move
  void _showHint() {
    // First check if we have any hints left
    if (_gameController.hints <= 0) {
      _showHintUnavailableDialog();
      return;
    }

    // Get a hint move from the game controller
    final hintMove = _gameController.useHint();
    
    if (hintMove == null) {
      _showErrorPopup("No valid moves found! Try adding a tube or restarting.");
      return;
    }

    // Find the source and destination tube positions for the animation
    final fromTube = hintMove.fromTube;
    final toTube = hintMove.toTube;
    
    _currentHintMove = hintMove;

    // Get positions of the tubes for the animation
    if (_gameController.tubeKeys[fromTube] == null || 
        _gameController.tubeKeys[toTube] == null) {
      _showErrorPopup("Cannot show hint right now. Try again later.");
      return;
    }

    final sourceContext = _gameController.tubeKeys[fromTube]!.currentContext;
    final targetContext = _gameController.tubeKeys[toTube]!.currentContext;

    if (sourceContext == null || targetContext == null) {
      _showErrorPopup("Cannot show hint right now. Try again later.");
      return;
    }

    final sourceRenderBox = sourceContext.findRenderObject() as RenderBox?;
    final targetRenderBox = targetContext.findRenderObject() as RenderBox?;

    if (sourceRenderBox == null || targetRenderBox == null) {
      _showErrorPopup("Cannot show hint right now. Try again later.");
      return;
    }

    // Calculate center points of tubes for arrow
    final sourcePosition = sourceRenderBox.localToGlobal(Offset.zero);
    final targetPosition = targetRenderBox.localToGlobal(Offset.zero);

    final sourceCenter = Offset(
      sourcePosition.dx + sourceRenderBox.size.width / 2,
      sourcePosition.dy + sourceRenderBox.size.height * 0.25,
    );

    final targetCenter = Offset(
      targetPosition.dx + targetRenderBox.size.width / 2,
      targetPosition.dy + targetRenderBox.size.height * 0.25,
    );

    // Store these positions for the hint animation
    _hintFromPosition = sourceCenter;
    _hintToPosition = targetCenter;

    // Show hint animation
    setState(() {
      _showingHintAnimation = true;
      _gameController.playSound('select');
    });

    // Start the animation
    _hintController.forward(from: 0);

    // Apply highlights to the tubes
    _highlightHintTubes(fromTube, toTube);

    // Hide the hint automatically after some time
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showingHintAnimation = false;
          _hintFromPosition = null;
          _hintToPosition = null;
          _currentHintMove = null;
        });
      }
    });
  }

  /// Show dialog when hints are unavailable
  void _showHintUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Hints Left!'),
        content: const Text(
          'You have no hints remaining.\n\nYou can earn more hints by:\n'
          '• Completing daily login rewards\n'
          '• Purchasing them in the store\n'
          '• Completing certain achievements',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showStore();
            },
            child: const Text('Go to Store'),
          ),
        ],
      ),
    );
  }

  /// Highlight the tubes involved in a hint
  void _highlightHintTubes(int fromTube, int toTube) {
    // This method would add highlighting effects to the tubes
    // (we'll leave this empty for now since the arrow visual is the main hint)
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
                        
                    // Hint arrow animation overlay
                    if (_showingHintAnimation && 
                        _hintFromPosition != null && 
                        _hintToPosition != null)
                      CustomPaint(
                        painter: HintArrowPainter(
                          startPoint: _hintFromPosition!,
                          endPoint: _hintToPosition!,
                          animation: _hintController,
                          arrowColor: Colors.amber.shade600,
                          arrowWidth: 6.0,
                        ),
                        size: Size.infinite,
                      ),
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
