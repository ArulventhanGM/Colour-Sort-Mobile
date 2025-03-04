import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Color Sorting Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GameHomePage(),
    );
  }
}

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});

  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage> with TickerProviderStateMixin {
  List<List<Color>> _tubes = [
    [Colors.purple, Colors.red, Colors.green],
    [Colors.green, Colors.red, Colors.purple],
    [Colors.purple, Colors.green, Colors.red],
    [],
    []
  ];
  int? _selectedTube;
  final List<List<List<Color>>> _history = [];
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  bool _canPour(int fromTube, int toTube) {
    if (_tubes[fromTube].isEmpty) return false;
    if (_tubes[toTube].length == 4) return false;
    // Only allow pouring if the target tube is empty or the top colors match
    if (_tubes[toTube].isNotEmpty && _tubes[fromTube].last != _tubes[toTube].last) return false;
    return true;
  }

  void _pourWater(int fromTube, int toTube) {
    if (_canPour(fromTube, toTube)) {
      List<Color> colorsToPour = [];
      setState(() {
        // Get all matching colors from the top of the source tube
        Color topColor = _tubes[fromTube].last;
        while (_tubes[fromTube].isNotEmpty && 
               _tubes[fromTube].last == topColor && 
               _tubes[toTube].length < 4) {
          colorsToPour.add(_tubes[fromTube].removeLast());
          if (_tubes[toTube].length + colorsToPour.length >= 4) break;
        }
        
        // Save the move to history
        _history.add(_tubes.map((tube) => List<Color>.from(tube)).toList());
      });
      
      // Animate the pour effect
      _animatePour(fromTube, toTube, colorsToPour);
    } else {
      _showErrorPopup("Invalid move! Cannot pour water. Check if colors match or tube is full.");
    }
  }

  void _animatePour(int fromTube, int toTube, List<Color> colors) {
    OverlayEntry? overlayEntry;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayEntry = OverlayEntry(
        builder: (context) => AnimatedPour(
          fromTubeIndex: fromTube,
          toTubeIndex: toTube,
          colors: colors,
          onCompleted: () {
            setState(() {
              // Add the colors to the target tube
              _tubes[toTube].addAll(colors);
              
              // Check if the game is complete
              if (_isGameComplete()) {
                _confettiController.play();
                Future.delayed(const Duration(seconds: 1), () {
                  _showCompletionPopup();
                });
              }
            });
            overlayEntry?.remove();
          },
        ),
      );
      Overlay.of(context).insert(overlayEntry!);
    });
  }

  void _showCompletionPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green[100],
        title: const Text(
          'Congratulations!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        content: const Text(
          'You successfully sorted all colors! Moving to the next level...',
          style: TextStyle(fontSize: 20, color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _nextLevel();
            },
            child: const Text(
              'Next Level',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _tubes = [
        [Colors.purple, Colors.red, Colors.green],
        [Colors.green, Colors.red, Colors.purple],
        [Colors.purple, Colors.green, Colors.red],
        [],
        []
      ];
      _history.clear();
    });
  }

  void _undoMove() {
    if (_history.isNotEmpty) {
      setState(() {
        _tubes = _history.removeLast().map((tube) => List<Color>.from(tube)).toList();
      });
    }
  }

  void _nextLevel() {
    setState(() {
      _tubes = [
        [Colors.yellow, Colors.blue, Colors.orange],
        [Colors.orange, Colors.yellow, Colors.blue],
        [Colors.blue, Colors.orange, Colors.yellow],
        [],
        []
      ];
      _history.clear();
    });
  }

  bool _isGameComplete() {
    // Check if all non-empty tubes are sorted with same color and full or empty
    for (List<Color> tube in _tubes) {
      if (tube.isEmpty) continue; // Empty tubes are fine
      
      // Check if all colors in this tube are the same
      Set<Color> uniqueColors = tube.toSet();
      if (uniqueColors.length != 1) return false;
      
      // Check if tube is full (4 elements) or contains 3 elements for simplicity
      // Adjust this logic if your game has different rules
      if (tube.length != 3 && tube.length != 4) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Color Sorting Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _history.isNotEmpty ? _undoMove : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextLevel,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb),
            onPressed: () {
              _showErrorPopup("Try moving colors to find the best arrangement.");
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            color: Colors.lightBlue[50],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Tubes container with responsive layout
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 20,
                    children: List.generate(_tubes.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedTube == null) {
                              if (_tubes[index].isNotEmpty) {
                                _selectedTube = index;
                              }
                            } else {
                              if (_selectedTube != index) {
                                _pourWater(_selectedTube!, index);
                              }
                              _selectedTube = null;
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
                            ),
                            child: const SizedBox(width: 50, height: 150),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red, Colors.green, Colors.blue, 
                Colors.yellow, Colors.orange, Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TubePainter extends CustomPainter {
  final List<Color> colors;
  final bool isSelected;

  TubePainter({required this.colors, this.isSelected = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw tube with visual improvements
    Paint paint = Paint()
      ..color = isSelected ? Colors.amber : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4.0 : 3.0;
      
    // Create a rounded tube shape
    double tubeWidth = size.width - 10;
    double borderRadius = 10; // Radius for rounded bottom corners
    Path tubePath = Path();
    
    tubePath.moveTo(5, 0);
    tubePath.lineTo(5 + tubeWidth, 0); // Top
    tubePath.lineTo(5 + tubeWidth, size.height - borderRadius); // Right side
    
    // Bottom right corner rounded
    tubePath.arcToPoint(
      Offset(5 + tubeWidth - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
      clockwise: false,
    );
    
    tubePath.lineTo(5 + borderRadius, size.height); // Bottom
    
    // Bottom left corner rounded
    tubePath.arcToPoint(
      Offset(5, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: false,
    );
    
    tubePath.close(); // Back to start
    canvas.drawPath(tubePath, paint);
    
    // Draw water colors
    double colorHeight = size.height / 4;
    for (int i = 0; i < colors.length; i++) {
      paint
        ..color = colors[i]
        ..style = PaintingStyle.fill;
        
      // Create a path that respects the rounded bottom for the bottom-most color
      if (i == 0 && colors.length == 1) {
        // Only one color with rounded bottom
        Path colorPath = Path();
        colorPath.moveTo(5, size.height - colorHeight);
        colorPath.lineTo(5 + tubeWidth, size.height - colorHeight);
        colorPath.lineTo(5 + tubeWidth, size.height - borderRadius);
        colorPath.arcToPoint(
          Offset(5 + tubeWidth - borderRadius, size.height),
          radius: Radius.circular(borderRadius),
          clockwise: false,
        );
        colorPath.lineTo(5 + borderRadius, size.height);
        colorPath.arcToPoint(
          Offset(5, size.height - borderRadius),
          radius: Radius.circular(borderRadius),
          clockwise: false,
        );
        colorPath.close();
        canvas.drawPath(colorPath, paint);
      } else if (i == 0) {
        // Bottom color (may need rounded bottom)
        Path colorPath = Path();
        colorPath.moveTo(5, size.height - colorHeight);
        colorPath.lineTo(5 + tubeWidth, size.height - colorHeight);
        colorPath.lineTo(5 + tubeWidth, size.height - borderRadius);
        colorPath.arcToPoint(
          Offset(5 + tubeWidth - borderRadius, size.height),
          radius: Radius.circular(borderRadius),
          clockwise: false,
        );
        colorPath.lineTo(5 + borderRadius, size.height);
        colorPath.arcToPoint(
          Offset(5, size.height - borderRadius),
          radius: Radius.circular(borderRadius),
          clockwise: false,
        );
        colorPath.close();
        canvas.drawPath(colorPath, paint);
      } else {
        // Regular rectangular color segments
        canvas.drawRect(
          Rect.fromLTWH(
            5, 
            size.height - (i + 1) * colorHeight, 
            tubeWidth, 
            colorHeight
          ),
          paint,
        );
      }
      
      // Add highlight effect to liquid
      if (i == colors.length - 1) {
        paint
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
          
        canvas.drawLine(
          Offset(8, size.height - i * colorHeight - colorHeight / 2),
          Offset(size.width - 8, size.height - i * colorHeight - colorHeight / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(TubePainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.isSelected != isSelected;
  }
}

class AnimatedPour extends StatefulWidget {
  final int fromTubeIndex;
  final int toTubeIndex;
  final List<Color> colors;
  final VoidCallback onCompleted;

  const AnimatedPour({
    super.key,
    required this.fromTubeIndex,
    required this.toTubeIndex,
    required this.colors,
    required this.onCompleted,
  });

  @override
  _AnimatedPourState createState() => _AnimatedPourState();
}

class _AnimatedPourState extends State<AnimatedPour> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(); // Replace with your actual widget implementation
  }
  late AnimationController _controller;
  late Animation<double> _arcAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _arcAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted();
        }
            });
        }
      
        @override
        void dispose() {
          _controller.dispose();
          super.dispose();
        }
      }