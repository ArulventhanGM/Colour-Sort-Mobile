import 'package:flutter/material.dart';
import '../utils/audio_manager.dart';

import 'game_components/game_controller.dart';
import 'game_components/splash_effect_info.dart';
import 'game_components/liquid_pouring_animation.dart';
import 'game_components/game_header.dart';
import 'game_components/game_stats.dart';
import 'game_components/game_controls.dart';
import 'game_components/tubes_grid.dart';
import 'game_components/background_pattern.dart';
import 'game_components/hint_arrow_painter.dart';

// Import controller classes
import 'game_components/burst_celebration_controller.dart';
import 'game_components/tube_animation_controller.dart';
import 'game_components/hint_animation_controller.dart';
import 'game_components/splash_effect_manager.dart';
import 'game_components/dialog_manager.dart';
import 'game_components/tube_completion_manager.dart';

import '../widgets/splash_effect.dart';

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage>
    with TickerProviderStateMixin {
  // Game state and controller
  late GameController _gameController;
  late DialogManager _dialogManager;
  late SplashEffectManager _splashEffectManager;
  late BurstCelebrationController _burstController;
  late TubeAnimationController _tubeAnimationController;
  late HintAnimationController _hintAnimationController;
  late TubeCompletionManager _tubeCompletionManager;

  // UI state variables
  int? _selectedTube;
  bool _achievementsChecked = false;

  // Animation controllers
  late AnimationController _popupController;
  late AnimationController _pourController;
  late AnimationController _liftController;
  late AnimationController _rotateController;
  late AnimationController _dropController;
  late AnimationController _hintController;
  late AnimationController _burstAnimationController;

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
    );

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
    
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_hintAnimationController.showingHintAnimation) {
          _hintController.reset();
          _hintController.forward();
        }
      }
    });
    
    _burstAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize managers and controllers
    _splashEffectManager = SplashEffectManager(
      setState: (callback) => setState(callback),
    );
    
    _dialogManager = DialogManager(
      context: context,
      gameController: _gameController,
    );
    
    _burstController = BurstCelebrationController(
      context: context,
      addSplashEffect: _splashEffectManager.addSplashEffect,
      gameController: _gameController,
      burstController: _burstAnimationController,
    );
    
    _tubeAnimationController = TubeAnimationController(
      gameController: _gameController,
      liftController: _liftController,
      rotateController: _rotateController,
      pourController: _pourController,
      dropController: _dropController,
      addSplashEffect: _splashEffectManager.addSplashEffect,
    );
    
    _hintAnimationController = HintAnimationController(
      gameController: _gameController,
      hintController: _hintController,
      showErrorPopup: _showErrorPopup,
    );
    
    _tubeCompletionManager = TubeCompletionManager(
      addSplashEffect: _splashEffectManager.addSplashEffect,
    );

    _loadSoundEffects();

    // Check for daily rewards on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dialogManager.checkDailyReward();
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
    _burstAnimationController.dispose();
    super.dispose();
  }

  /// Initialize audio for the game
  Future<void> _loadSoundEffects() async {
    try {
      debugPrint('Initializing audio in GameHomePage...');
      final audioManager = AudioManager();
      await audioManager.initialize();

      if (_gameController.soundEnabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _gameController.playSound('select');
        });
      }
      debugPrint('Audio initialization complete in GameHomePage');
    } catch (e) {
      debugPrint('Error initializing audio in GameHomePage: $e');
    }
  }

  /// Handle tube selection
  void _handleTubeSelection(int index) {
    if (_tubeAnimationController.animating) return;

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
    if (_tubeAnimationController.animating) return;

    if (_gameController.canPour(fromTube, toTube)) {
      _animatePouring(fromTube, toTube);
      _selectedTube = null;
    } else {
      _showErrorPopup("Invalid move! Cannot pour water.\n"
          "Make sure destination tube isn't full and colors match.");
    }
  }

  /// Animate pouring between tubes with visual effects
  Future<void> _animatePouring(int fromTube, int toTube) async {
    // Use the tube animation controller to handle the animation
    final success = await _tubeAnimationController.animatePouring(
      fromTube,
      toTube,
      setState,
    );
    
    if (success) {
      // Check for tube completions after a successful pour
      _tubeCompletionManager.celebrateTubeCompletion(
        _gameController.tubes,
        _gameController.tubeKeys,
        GameController.maxColors,  // Using the correct constant from GameController
      );
      
      // Check if game is complete
      if (_gameController.isGameComplete()) {
        _gameController.playSound('complete');
        
        // Show burst animation celebration first
        _burstController.showCompletionBurst();
        
        // Then show completion popup after a short delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _showCompletionPopup();
          }
        });
      }
    }
  }

  /// Show error message to the user
  void _showErrorPopup(String message) {
    _dialogManager.showErrorPopup(message);
  }

  /// Show completion popup when level is finished
  void _showCompletionPopup() {
    // Reset achievement check flag for next level
    _achievementsChecked = false;

    _dialogManager.showCompletionPopup(() {
      setState(() {
        _gameController.nextLevel();
        // Reset tube completion tracking for the new level
        _tubeCompletionManager.reset();
        _checkAchievements();
      });
    });
  }

  /// Check for achievements
  void _checkAchievements() {
    _dialogManager.checkAchievements(_achievementsChecked, () {
      // After showing an achievement
      if (_gameController.pendingAchievements.isNotEmpty) {
        _achievementsChecked = false;
        _checkAchievements();
      } else {
        _achievementsChecked = true;
      }
    });
  }

  /// Show settings dialog
  void _showSettings() {
    _dialogManager.showSettings(
      (enabled) => setState(() => _gameController.setSoundEnabled(enabled)),
      (enabled) => setState(() => _gameController.setVibrationEnabled(enabled)),
    );
  }

  /// Show store dialog
  void _showStore() {
    _dialogManager.showStore(
      () => setState(() {
        _gameController.undoMovesLeft += 10;
        _gameController.coins -= 30;
      }),
      () => setState(() {
        _gameController.hints += 5;
        _gameController.coins -= 50;
      }),
      () => setState(() {
        _gameController.coins += 100;
      }),
    );
  }

  /// Show hint for the next best move
  void _showHint() {
    _hintAnimationController.showHint(
      context,
      setState,
      () => _dialogManager.showHintUnavailableDialog(_showStore),
    );
  }

  void _removeSplashEffect(SplashEffectInfo effect) {
    _splashEffectManager.removeSplashEffect(effect);
  }

  /// Reset the level and clear tracked tube completions
  void _resetLevel() {
    setState(() {
      _gameController.initializeLevel();
      _selectedTube = null;
      _tubeAnimationController.reset();
      _hintAnimationController.reset();
      _tubeCompletionManager.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background pattern
          const BackgroundPattern(),

          Column(
            children: [
              // Game header
              GameHeader(
                currentLevel: _gameController.currentLevel,
                coins: _gameController.coins,
                onSettingsPressed: _showSettings,
                onStorePressed: _showStore,
                onHintPressed: _showHint,
              ),

              // Game stats
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
                    // Tubes grid
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: MediaQuery.of(context).size.height * 0.05,
                      ),
                      child: TubesGrid(
                        gameController: _gameController,
                        selectedTube: _selectedTube,
                        liftedTube: _tubeAnimationController.liftedTube,
                        receivingTube: _tubeAnimationController.targetTubeReceiving,
                        liftedTubeAngle: _tubeAnimationController.liftedTubeAngle,
                        liftAnimation: _liftController,
                        rotateAnimation: _rotateController,
                        dropAnimation: _dropController,
                        pourAnimation: _pourController,
                        splashEffects: _splashEffectManager.splashEffects,
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

                    // Pouring animation overlay
                    if (_tubeAnimationController.pouringColor != null &&
                        _tubeAnimationController.pourStart != null &&
                        _tubeAnimationController.pourEnd != null)
                      LiquidPouringAnimation(
                        pouringColor: _tubeAnimationController.pouringColor!,
                        pourStart: _tubeAnimationController.pourStart!,
                        pourEnd: _tubeAnimationController.pourEnd!,
                        pourAnimation: _pourController,
                      ),

                    // Splash effects
                    ..._splashEffectManager.splashEffects.map((effect) => SplashEffect(
                          offset: effect.offset,
                          color: effect.color,
                          size: effect.size,
                          onComplete: () => _removeSplashEffect(effect),
                          isColorMixing: effect.isColorMixing,
                        )),
                        
                    // Hint arrow animation
                    if (_hintAnimationController.showingHintAnimation && 
                        _hintAnimationController.hintFromPosition != null && 
                        _hintAnimationController.hintToPosition != null)
                      CustomPaint(
                        painter: HintArrowPainter(
                          startPoint: _hintAnimationController.hintFromPosition!,
                          endPoint: _hintAnimationController.hintToPosition!,
                          animation: _hintController,
                          arrowColor: Colors.amber.shade600,
                          arrowWidth: 6.0,
                        ),
                        size: Size.infinite,
                      ),
                  ],
                ),
              ),

              // Game controls
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
                onReset: _resetLevel,
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
