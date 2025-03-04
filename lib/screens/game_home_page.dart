import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../painters/tube_painter.dart';
import '../utils/game_logic.dart';
import '../widgets/control_button.dart';
import '../models/level_data.dart';

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
    _initializeLevel();
  }

  @override
  void dispose() {
    _popupController.dispose();
    _pourController.dispose();
    super.dispose();
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
        
        // Calculate start and end positions for the pouring animation
        final sourceGlobalPosition = sourceTubeRenderBox.localToGlobal(Offset.zero);
        final targetGlobalPosition = targetTubeRenderBox.localToGlobal(Offset.zero);
        
        // Calculate accurate pouring positions
        _pourStart = Offset(
          sourceGlobalPosition.dx + sourceTubeRenderBox.size.width / 2,
          sourceGlobalPosition.dy + 10 // Just below top edge
        );
        
        _pourEnd = Offset(
          targetGlobalPosition.dx + targetTubeRenderBox.size.width / 2,
          targetGlobalPosition.dy + 10 // Just below top edge
        );
        
        // Actually remove the colors now
        for (int i = 0; i < colorCount; i++) {
          if (_tubes[fromTube].isNotEmpty) {
            colorsToPour.add(_tubes[fromTube].removeLast());
          }
        }
        
        // Add to history and update moves count before animation
        _history.add(_tubes.map((tube) => List<Color>.from(tube)).toList());
        _moves++;
        _updateStars();
        
        // Animate the pouring
        _pourController.forward(from: 0).then((_) {
          if (mounted) {  // Check if the widget is still mounted before setState
            setState(() {
              _tubes[toTube].addAll(colorsToPour);
              // Check if game is complete after adding the colors
              if (GameLogic.isGameComplete(_tubes)) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {  // Check again before showing dialog
                    _showCompletionPopup();
                  }
                });
              }
            });
          }
        });
      });
    } catch (e) {
      print("Error during pour animation: $e");
      // Fall back to basic pour if anything goes wrong
      _performBasicPour(fromTube, toTube);
    }
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
        _moves++;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Level $_level - Color Sort'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.lightBlue[50]!],
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
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              const Text(
                                'MOVES',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$_moves',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(3, (index) {
                          return Icon(
                            Icons.star,
                            size: 30,
                            color: index < _stars ? Colors.amber : Colors.grey[300],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double tubeWidth = constraints.maxWidth / (_tubes.length + 1);
                        tubeWidth = min(tubeWidth, 60.0);
                        double tubeHeight = tubeWidth * 3;
                        
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 20,
                          children: List.generate(_tubes.length, (index) {
                            return GestureDetector(
                              key: _tubeKeys[index],
                              onTap: () {
                                if (_animating) return;
                                
                                setState(() {
                                  if (_selectedTube == null) {
                                    if (_tubes[index].isNotEmpty) {
                                      _selectedTube = index;
                                    }
                                  } else {
                                    // If same tube is tapped, deselect it
                                    if (_selectedTube == index) {
                                      _selectedTube = null;
                                    } else {
                                      _pourWater(_selectedTube!, index);
                                      _selectedTube = null;
                                    }
                                  }
                                });
                              },
                              child: AnimatedScale(
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
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_pouringColor != null && _pourStart != null && _pourEnd != null)
              AnimatedBuilder(
                animation: _pourController,
                builder: (context, child) {
                  final path = Path();
                  path.moveTo(_pourStart!.dx, _pourStart!.dy);
                  
                  // Create a more natural pouring arc
                  final midY = _pourStart!.dy + (_pourEnd!.dy - _pourStart!.dy) / 2;
                  final controlPoint1 = Offset(_pourStart!.dx, midY);
                  final controlPoint2 = Offset(_pourEnd!.dx, midY);
                  
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
                      // No metrics available, return empty container
                      return const SizedBox.shrink();
                    }
                    
                    // Safely get first metric
                    PathMetric? metric;
                    for (final m in metrics) {
                      metric = m;
                      break;
                    }
                    
                    if (metric == null) {
                      return const SizedBox.shrink();
                    }
                    
                    final currentDistance = metric.length * _pourController.value;
                    
                    // Check that currentDistance is valid
                    if (currentDistance <= 0 || currentDistance > metric.length) {
                      return const SizedBox.shrink();
                    }
                    
                    final tangent = metric.getTangentForOffset(currentDistance);
                    if (tangent == null) {
                      return const SizedBox.shrink();
                    }
                    
                    return Stack(
                      children: [
                        // Trail effect
                        for (int i = 0; i < 6; i++) ...[
                          Builder(builder: (context) {
                            final trailFactor = i / 6;
                            final trailDistance = (currentDistance - trailFactor * metric!.length * 0.05)
                                .clamp(0.0, metric.length);
                            
                            final trailTangent = metric.getTangentForOffset(trailDistance);
                            if (trailTangent == null) return const SizedBox.shrink();
                            
                            return Positioned(
                              left: trailTangent.position.dx - (3 * (1-trailFactor)),
                              top: trailTangent.position.dy - (3 * (1-trailFactor)),
                              child: Container(
                                width: 6 * (1-trailFactor),
                                height: 6 * (1-trailFactor),
                                decoration: BoxDecoration(
                                  color: _pouringColor!.withOpacity(0.3 * (1-trailFactor)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }),
                        ],
                        
                        // Main drop
                        Positioned(
                          left: tangent.position.dx - 6,
                          top: tangent.position.dy - 6,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _pouringColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ],
                            ),
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
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        padding: EdgeInsets.zero,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ControlButton(
              icon: Icons.refresh,
              label: 'Restart',
              onPressed: _restartGame,
            ),
            ControlButton(
              icon: Icons.undo,
              label: 'Undo',
              onPressed: _undoMove,
            ),
            ControlButton(
              icon: Icons.lightbulb_outline,
              label: 'Hint',
              onPressed: _showHint,
            ),
          ],
        ),
      ),
    );
  }
}
