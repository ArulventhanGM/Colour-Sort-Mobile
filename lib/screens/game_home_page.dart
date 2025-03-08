import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../painters/tube_painter.dart';
import '../utils/game_logic.dart';
import '../widgets/control_button.dart';
import '../models/level_data.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../utils/audio_manager.dart'; // Add this import

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage> with TickerProviderStateMixin {
  late List<List<Color>> _tubes;
  int? _selectedTube;
  final List<List<List<Color>>> _history = [];
  int _level = 1;
  int _moves = 0;
  int _stars = 3;
  bool _animating = false;
  late AnimationController _popupController;
  late AnimationController _pourController;
  Color? _pouringColor;
  Offset? _pourStart;
  Offset? _pourEnd;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<int, GlobalKey> _tubeKeys = {};
  int _coins = 40; // Starting coins
  int _undoMovesLeft = 4; // Available free undo moves
  int _extraTubePrice = 20; // Cost to add an extra tube

  // Audio players for sound effects
  final AudioPlayer _bubblePlayer = AudioPlayer();
  final AudioPlayer _pourPlayer = AudioPlayer();
  final AudioPlayer _completePlayer = AudioPlayer();
  final AudioPlayer _selectPlayer = AudioPlayer();
  
  // Additional animation controllers
  late AnimationController _liftController;
  late AnimationController _rotateController;
  late AnimationController _dropController;
  
  // Animation tracking variables
  int? _liftedTube;
  
  int? _targetTube;
  Offset? _liftedTubeStartPosition;
  Offset? _targetTubePosition;
  double? _liftedTubeAngle;
  bool _vibrateEnabled = true;

  @override
  void initState() {
    super.initState();
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pourController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {  // Check if mounted
          setState(() {
            _animating = false;
            _pouringColor = null;
          });
        }
      });
      
    // Initialize new animation controllers
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
    
    _initializeLevel();
    _loadSoundEffects();
  }

  @override
  void dispose() {
    _popupController.dispose();
    _pourController.dispose();
    _liftController.dispose();
    _rotateController.dispose();
    _dropController.dispose();
    _bubblePlayer.dispose();
    _pourPlayer.dispose();
    _completePlayer.dispose();
    _selectPlayer.dispose();
    super.dispose();
  }
  
  Future<void> _loadSoundEffects() async {
    try {
      // Use AudioManager instead of individual AudioPlayers
      await AudioManager().initialize();
    } catch (e) {
      print('Error loading sound effects: $e');
      // Don't let sound loading failures crash the app
    }
  }

  void _playSound(AudioPlayer player) {
    try {
      // Use AudioManager's methods instead
      if (player == _selectPlayer) {
        AudioManager().playSelect();
      } else if (player == _pourPlayer) {
        AudioManager().playPour();
      } else if (player == _completePlayer) {
        AudioManager().playComplete();
      } else if (player == _bubblePlayer) {
        AudioManager().playBubble();
      }
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
  
  void _vibrateDevice() {
    if (_vibrateEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void _initializeLevel() {
    // Create tubes with proper initialization
    int attempts = 0;
    do {
      _tubes = LevelData.getLevelTubes(_level);
      attempts++;
      
      // After 3 attempts, force a valid configuration
      if (attempts > 3) {
        _tubes = [
          [Colors.red, Colors.green, Colors.blue],
          [Colors.blue, Colors.red, Colors.green],
          [Colors.green, Colors.blue, Colors.red],
          [], // Empty tube 1
          [], // Empty tube 2
        ];
        break;
      }
    } while (!GameLogic.validateInitialTubes(_tubes));
    
    // Print debug information
    print("Level $_level initialized with ${_tubes.length} tubes");
    for (int i = 0; i < _tubes.length; i++) {
      print("Tube $i: ${_tubes[i].length} colors");
    }
    
    _moves = 0;
    _stars = 3;
    _history.clear();
    
    // Initialize tube keys
    _tubeKeys.clear();
    for (int i = 0; i < _tubes.length; i++) {
      _tubeKeys[i] = GlobalKey();
    }
  }

  bool _canPour(int fromTube, int toTube) {
    return GameLogic.canPour(_tubes, fromTube, toTube);
  }

  void _pourWater(int fromTube, int toTube) {
    if (_animating) return;
    
    if (_canPour(fromTube, toTube)) {
      _animatePouring(fromTube, toTube);
    } else {
      _showErrorPopup("Invalid move! Cannot pour water.\n" "Make sure destination tube isn't full and colors match.");
    }
  }

  void _animatePouring(int fromTube, int toTube) {
    try {
      // Make sure we have the correct tube keys
      if (_tubeKeys[fromTube] == null || _tubeKeys[toTube] == null) {
        _performBasicPour(fromTube, toTube);
        return;
      }

      // Try to get contexts for both tubes
      final sourceTubeContext = _tubeKeys[fromTube]!.currentContext;
      final targetTubeContext = _tubeKeys[toTube]!.currentContext;
      
      if (sourceTubeContext == null || targetTubeContext == null) {
        _performBasicPour(fromTube, toTube);
        return;
      }

      // Try to get render boxes for both tubes
      final sourceTubeRenderBox = sourceTubeContext.findRenderObject() as RenderBox?;
      final targetTubeRenderBox = targetTubeContext.findRenderObject() as RenderBox?;
      
      if (sourceTubeRenderBox == null || targetTubeRenderBox == null) {
        _performBasicPour(fromTube, toTube);
        return;
      }
      
      // Ensure source tube has colors to pour
      if (_tubes[fromTube].isEmpty) {
        return;
      }
      
      // Get the colors to pour before starting animation
      List<Color> colorsToPour = [];
      Color colorToPour = _tubes[fromTube].last;
      
      // Count how many colors we'll be pouring (don't actually remove them yet)
      int colorCount = 0;
      for (int i = _tubes[fromTube].length - 1; i >= 0; i--) {
        if (_tubes[fromTube][i] == colorToPour && colorCount + _tubes[toTube].length < 4) {
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
        _pouringColor = colorToPour;
        _liftedTube = fromTube;
        _targetTube = toTube;
        
        // Calculate global positions for animation
        final sourcePosition = sourceTubeRenderBox.localToGlobal(Offset.zero);
        final targetPosition = targetTubeRenderBox.localToGlobal(Offset.zero);
        
        _liftedTubeStartPosition = sourcePosition;
        _targetTubePosition = targetPosition;
        
        // Calculate pour start and end positions more accurately
        _pourStart = Offset(
          sourcePosition.dx + sourceTubeRenderBox.size.width / 2,
          sourcePosition.dy + 10
        );
        
        _pourEnd = Offset(
          targetPosition.dx + targetTubeRenderBox.size.width / 2,
          targetPosition.dy + 10
        );
        
        // Remove the colors to pour
        for (int i = 0; i < colorCount; i++) {
          if (_tubes[fromTube].isNotEmpty) {
            colorsToPour.add(_tubes[fromTube].removeLast());
          }
        }
        
        // Add to history and update moves
        _history.add(_tubes.map((tube) => List<Color>.from(tube)).toList());
        _moves++;
        _updateStars();
      });
      
      // Begin lift animation sequence
      _vibrateDevice();
      _playSound(_selectPlayer);

      _liftController.forward(from: 0).then((_) {
        // Rotate tube to pour
        _liftedTubeAngle = _calculatePouringAngle(fromTube, toTube);
        _playSound(_pourPlayer);
        
        _rotateController.forward(from: 0).then((_) {
          // Run pouring animation
          _pourController.forward(from: 0).then((_) {
            // Return tube to upright position
            _rotateController.reverse().then((_) {
              // Return tube to original position
              _dropController.forward(from: 0).then((_) {
                if (mounted) {
                  setState(() {
                    _tubes[toTube].addAll(colorsToPour);
                    _animating = false;
                    _pouringColor = null;
                    _liftedTube = null;
                    _targetTube = null;
                    _liftedTubeStartPosition = null;
                    _targetTubePosition = null;
                    _liftedTubeAngle = null;
                    
                    // Reset animation controllers
                    _liftController.reset();
                    _rotateController.reset();
                    _dropController.reset();
                    
                    // Check if game is complete
                    if (GameLogic.isGameComplete(_tubes)) {
                      _playSound(_completePlayer);
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
    } catch (e) {
      print("Error during pour animation: $e");
      _performBasicPour(fromTube, toTube);
    }
  }
  
  double _calculatePouringAngle(int fromTube, int toTube) {
    // Calculate which direction to pour based on tube positions
    if (_liftedTubeStartPosition != null && _targetTubePosition != null) {
      // Pour to the right
      if (_liftedTubeStartPosition!.dx < _targetTubePosition!.dx) {
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

  void _updateStars() {
    if (_moves > 10) {
      _stars = 1;
    } else if (_moves > 5) _stars = 2;
  }

  void _performBasicPour(int fromTube, int toTube) {
    setState(() {
      List<Color> colorsToPour = [];
      Color colorToPour = _tubes[fromTube].last;
      
      // Count matching colors to pour from the top
      int matchingColors = 0;
      for (int i = _tubes[fromTube].length - 1; i >= 0; i--) {
        if (_tubes[fromTube][i] == colorToPour && 
            matchingColors + _tubes[toTube].length < 4) {
          matchingColors++;
        } else {
          break;
        }
      }
      
      // Remove colors from source tube
      for (int i = 0; i < matchingColors; i++) {
        if (_tubes[fromTube].isNotEmpty) {
          colorsToPour.add(_tubes[fromTube].removeLast());
        }
      }
      
      // Save history
      _history.add(_tubes.map((tube) => List<Color>.from(tube)).toList());
      _moves++;
      _updateStars();
      
      // Add colors to destination tube
      _tubes[toTube].addAll(colorsToPour);
      
      // Check for completion
      if (GameLogic.isGameComplete(_tubes)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showCompletionPopup();
          }
        });
      }
    });
  }

  void _showCompletionPopup() {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.green[100],
            title: const Text(
              'Level Complete!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You successfully sorted all colors!',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Icon(
                      Icons.star,
                      size: 40,
                      color: index < _stars ? Colors.amber : Colors.grey[400],
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  'Moves: $_moves',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _nextLevel();
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Next Level',
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: false,
      barrierLabel: 'Level complete',
    );
  }

  void _showErrorPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[300],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 20,
          right: 20
        ),
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _initializeLevel();
    });
  }

  void _undoMove() {
    if (_history.isNotEmpty && !_animating) {
      setState(() {
        _tubes = _history.removeLast().map((tube) => List<Color>.from(tube)).toList();
        
        // Only decrement undo counter if we're not using unlimited undos
        if (_undoMovesLeft > 0) {
          _undoMovesLeft--;
        }
      });
    } else if (_undoMovesLeft <= 0 && _history.isNotEmpty) {
      _showErrorPopup("No free undo moves left!");
    }
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _initializeLevel();
    });
  }

  void _showHint() {
    final hint = GameLogic.getHint(_tubes);
    if (hint != null) {
      setState(() {
        _selectedTube = hint;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Try moving from the highlighted tube'),
          backgroundColor: Colors.blue[300],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.7,
            left: 20,
            right: 20
          ),
        ),
      );
    } else {
      _showErrorPopup("No hints available at the moment");
    }
  }

  void _addExtraTube() {
    if (_coins >= _extraTubePrice) {
      setState(() {
        _coins -= _extraTubePrice;
        
        // Create a new empty tube
        _tubes.add([]);
        _tubeKeys[_tubes.length - 1] = GlobalKey();
        
        // Increase price for next tube
        _extraTubePrice = (_extraTubePrice * 1.5).round();
      });
    } else {
      _showErrorPopup("Not enough coins to add a tube!");
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Music'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement music settings
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Sound Effects'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement sound settings
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.vibration),
              title: const Text('Vibration'),
              trailing: Switch(
                value: _vibrateEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrateEnabled = value;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStore() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.blue),
              title: const Text('10 Undo Moves'),
              subtitle: const Text('Never get stuck again'),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Implement purchase
                  setState(() {
                    _undoMovesLeft += 10;
                    _coins -= 30; // Cost for 10 undo moves
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('30 🪙'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb, color: Colors.amber),
              title: const Text('5 Hints'),
              subtitle: const Text('Get unstuck with smart suggestions'),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Implement hint purchase
                  Navigator.of(context).pop();
                },
                child: const Text('20 🪙'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.orange),
              title: const Text('100 Coins'),
              subtitle: const Text('Currency pack'),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Implement coin purchase
                  Navigator.of(context).pop();
                },
                child: const Text('\$1.99'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // Replace AppBar with custom header - remove undo counter
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: _showSettings,
                      tooltip: 'Settings',
                    ),
                    IconButton(
                      icon: const Icon(Icons.store, color: Colors.white),
                      onPressed: _showStore,
                      tooltip: 'Store',
                    ),
                  ],
                ),
                
                // Center - Level display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 3.0,
                      ),
                    ],
                  ),
                  child: Text(
                    'LEVEL $_level',
                    style: const TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                // Right side - just coins indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$_coins',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[200]!], // Deeper gradient for more contrast
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Card(
                        elevation: 5,
                        color: Colors.white.withOpacity(0.9),
                        shadowColor: Colors.black.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              Text(
                                'MOVES',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.blue[900]
                                ),
                              ),
                              Text(
                                '$_moves',
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800]
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Stars rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: Row(
                          children: List.generate(3, (index) {
                            return Icon(
                              Icons.star,
                              size: 30,
                              color: index < _stars ? Colors.amber : Colors.grey[300],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double tubeWidth = constraints.maxWidth / (_tubes.length + 2);
                        tubeWidth = min(tubeWidth, 60.0);
                        double tubeHeight = tubeWidth * 3;
                        
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 20,
                          children: [
                            // Tubes
                            ...List.generate(_tubes.length, (index) {
                              return GestureDetector(
                                key: _tubeKeys[index],
                                onTap: () {
                                  if (_animating) return;
                                  
                                  setState(() {
                                    if (_selectedTube == null) {
                                      if (_tubes[index].isNotEmpty) {
                                        _selectedTube = index;
                                        _playSound(_selectPlayer);
                                        _vibrateDevice();
                                      }
                                    } else {
                                      // If same tube is tapped, deselect it
                                      if (_selectedTube == index) {
                                        _selectedTube = null;
                                        _playSound(_selectPlayer);
                                      } else {
                                        _pourWater(_selectedTube!, index);
                                        _selectedTube = null;
                                      }
                                    }
                                  });
                                },
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _liftController, 
                                    _rotateController,
                                    _dropController
                                  ]),
                                  builder: (context, child) {
                                    // If this is not the tube being animated, render normally
                                    if (index != _liftedTube) {
                                      return AnimatedScale(
                                        scale: _selectedTube == index ? 1.1 : 1.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: CustomPaint(
                                          painter: TubePainter(
                                            colors: _tubes[index],
                                            isSelected: _selectedTube == index,
                                            maxCapacity: 4,
                                          ),
                                          child: SizedBox(
                                            width: tubeWidth,
                                            height: tubeHeight,
                                          ),
                                        ),
                                      );
                                    }
                                    
                                    // Calculate lift, rotation and position for animated tube
                                    double liftValue = _liftController.value * 30.0;
                                    double translateY = -liftValue + (_dropController.value * liftValue);
                                    
                                    // Calculate rotation angle
                                    double rotationAngle = _liftedTubeAngle != null 
                                        ? _rotateController.value * _liftedTubeAngle!
                                        : 0.0;
                                        
                                    // Calculate horizontal movement (if any)
                                    double horizontalShift = 0.0;
                                    if (_liftedTubeStartPosition != null && 
                                        _targetTubePosition != null && 
                                        _rotateController.value > 0.3) {
                                      horizontalShift = (_targetTubePosition!.dx - _liftedTubeStartPosition!.dx) * 
                                          (_rotateController.value - 0.3) / 0.7 * 0.3; // Just a subtle shift, not full movement
                                    }
                                    
                                    return Transform.translate(
                                      offset: Offset(horizontalShift, translateY),
                                      child: Transform(
                                        alignment: Alignment.topCenter,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001) // Perspective
                                          ..rotateZ(rotationAngle),
                                        child: CustomPaint(
                                          painter: TubePainter(
                                            colors: _tubes[index],
                                            isSelected: true,
                                            maxCapacity: 4,
                                            pouringAnimation: _rotateController.value > 0.5,
                                            pouringProgress: _pourController.value,
                                          ),
                                          child: SizedBox(
                                            width: tubeWidth,
                                            height: tubeHeight,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                            
                            // Add Tube Button
                            GestureDetector(
                              onTap: _addExtraTube,
                              child: Container(
                                width: tubeWidth,
                                height: tubeHeight,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '+',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    Text(
                                      'Add Tube',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[700],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$_extraTubePrice',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.monetization_on,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // Animation for pouring - enhanced version
            if (_pouringColor != null && _pourStart != null && _pourEnd != null && _rotateController.value > 0.5)
              AnimatedBuilder(
                animation: _pourController,
                builder: (context, child) {
                  final path = Path();
                  
                  // The pour path now comes from the source tube at an angle
                  final adjustedStart = Offset(
                    _pourStart!.dx + (_liftedTubeAngle != null && _liftedTubeAngle! > 0 ? 15 : -15),
                    _pourStart!.dy + 5
                  );
                  
                  path.moveTo(adjustedStart.dx, adjustedStart.dy);
                  
                  // Create a more realistic pouring arc with gravity effect
                  final midY = adjustedStart.dy + (_pourEnd!.dy - adjustedStart.dy) * 0.3; // Higher drop for more realistic curve
                  
                  // Control points for a more realistic water flow
                  final controlPoint1 = Offset(
                    adjustedStart.dx + (_pourEnd!.dx - adjustedStart.dx) * 0.2,
                    midY - 20
                  );
                  
                  final controlPoint2 = Offset(
                    adjustedStart.dx + (_pourEnd!.dx - adjustedStart.dx) * 0.8,
                    _pourEnd!.dy - 10
                  );
                  
                  path.cubicTo(
                    controlPoint1.dx, 
                    controlPoint1.dy,
                    controlPoint2.dx,
                    controlPoint2.dy,
                    _pourEnd!.dx,
                    _pourEnd!.dy,
                  );
                  
                  try {
                    final metrics = path.computeMetrics();
                    if (metrics.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    PathMetric? metric;
                    for (final m in metrics) {
                      metric = m;
                      break;
                    }
                    
                    if (metric == null) {
                      return const SizedBox.shrink();
                    }
                    
                    final currentDistance = metric.length * _pourController.value;
                    
                    if (currentDistance <= 0 || currentDistance > metric.length) {
                      return const SizedBox.shrink();
                    }
                    
                    return Stack(
                      children: [
                        // Water stream - main path
                        ClipPath(
                          clipper: WaterStreamClipper(
                            path: path,
                            progress: _pourController.value,
                            width: 8.0,
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            color: _pouringColor!.withOpacity(0.7),
                          ),
                        ),
                        
                        // Water droplets for realism
                        ...List.generate(10, (index) {
                          if (_pourController.value < 0.1 || _pourController.value > 0.9) {
                            return const SizedBox.shrink();
                          }
                          
                          // Random offsets for droplets
                          final random = Random();
                          final dropletOffset = random.nextDouble() * metric!.length * 0.7;
                          final sideOffset = (random.nextDouble() - 0.5) * 15;
                          
                          // Only show droplets in the middle section of the pour
                          if (dropletOffset < currentDistance * 0.2 || 
                              dropletOffset > currentDistance * 0.8) {
                            return const SizedBox.shrink();
                          }
                          
                          final dropletPosition = metric.getTangentForOffset(dropletOffset);
                          if (dropletPosition == null) {
                            return const SizedBox.shrink();
                          }
                          
                          return Positioned(
                            left: dropletPosition.position.dx + sideOffset,
                            top: dropletPosition.position.dy + random.nextDouble() * 10,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1000),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, value * 15),
                                  child: Opacity(
                                    opacity: 1.0 - value,
                                    child: Container(
                                      width: 3 + random.nextDouble() * 4,
                                      height: 3 + random.nextDouble() * 4,
                                      decoration: BoxDecoration(
                                        color: _pouringColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                        
                        // Splash effect at destination
                        if (_pourController.value > 0.4)
                          Positioned(
                            left: _pourEnd!.dx - 20,
                            top: _pourEnd!.dy - 5,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.0, end: _pourController.value > 0.7 ? 1.0 : _pourController.value),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value < 0.7 ? value : 1.0 - ((value - 0.7) / 0.3),
                                  child: Container(
                                    width: 40 * value,
                                    height: 10 * value,
                                    decoration: BoxDecoration(
                                      color: _pouringColor!.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  } catch (e) {
                    print("Animation error: $e");
                    return const SizedBox.shrink();
                  }
                },
              ),
          ],
        ),
      ),
      
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[900]!, Colors.blue[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5.0,
              spreadRadius: 0.5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Restart button
            ControlButton(
              icon: Icons.refresh,
              label: 'Restart',
              onPressed: _restartGame,
              color: Colors.white,
            ),
            
            // Undo button with counter
            Stack(
              clipBehavior: Clip.none,
              children: [
                ControlButton(
                  icon: Icons.arrow_back,
                  label: 'Undo',
                  onPressed: _undoMove,
                  color: _undoMovesLeft > 0 ? Colors.white : Colors.grey[400]!,
                ),
                if (_undoMovesLeft > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_undoMovesLeft',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Hint button
            ControlButton(
              icon: Icons.lightbulb_outline,
              label: 'Hint',
              onPressed: _showHint,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

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