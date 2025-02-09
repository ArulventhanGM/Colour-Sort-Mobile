import 'package:flutter/material.dart';
import 'dart:math';

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

  bool _canPour(int fromTube, int toTube) {
    if (_tubes[fromTube].isEmpty) return false;
    if (_tubes[toTube].length == 4) return false;
    return true;
  }

  void _pourWater(int fromTube, int toTube) {
    if (_canPour(fromTube, toTube)) {
      setState(() {
        if (_tubes[fromTube].length >= 2 && _tubes[fromTube].sublist(_tubes[fromTube].length - 2).toSet().length == 1) {
          Color colorToPour1 = _tubes[fromTube].removeLast();
          Color colorToPour2 = _tubes[fromTube].removeLast();
          _history.add(_tubes.map((tube) => List<Color>.from(tube)).toList());
          _animatePour(fromTube, toTube, [colorToPour2, colorToPour1]);
        } else {
          Color colorToPour = _tubes[fromTube].removeLast();
          _history.add(_tubes.map((tube) => List<Color>.from(tube)).toList());
          _animatePour(fromTube, toTube, [colorToPour]);
        }
      });
    } else {
      _showErrorPopup("Invalid move! Cannot pour water. The tube is already full.");
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
              _tubes[toTube].addAll(colors);
              if (_isGameComplete()) {
                _showCompletionPopup();
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
            onPressed: () {
              Navigator.of(context).pop();
              _nextLevel();
            },
            child: const Text(
              'Next Level',
              style: TextStyle(fontSize: 18, color: Colors.green),
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
    return _tubes.every((tube) => tube.isEmpty || (tube.length == 3 && tube.toSet().length == 1));
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
            onPressed: _undoMove,
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
          Container(
            color: Colors.lightBlue[50],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_isGameComplete())
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.green, blurRadius: 5),
                        ],
                      ),
                      child: const Text(
                        '🎉 Congratulations! You completed the level! 🎉',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_tubes.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedTube == null) {
                              _selectedTube = index;
                            } else {
                              _pourWater(_selectedTube!, index);
                              _selectedTube = null;
                            }
                          });
                        },
                        child: AnimatedScale(
                          scale: _selectedTube == index ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: CustomPaint(
                            painter: TubePainter(colors: _tubes[index]),
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
        ],
      ),
    );
  }
}

class TubePainter extends CustomPainter {
  final List<Color> colors;

  TubePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw the tube with straight top and thicker walls
    Path tubePath = Path();
    double tubeWidth = size.width - 10;
    tubePath.moveTo(5, 0);
    tubePath.lineTo(5 + tubeWidth, 0); // Straight top
    tubePath.lineTo(5 + tubeWidth, size.height);
    tubePath.lineTo(5, size.height);
    tubePath.close();
    canvas.drawPath(tubePath, paint);

    double colorHeight = size.height / 4;
    for (int i = 0; i < colors.length; i++) {
      paint
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(5, size.height - (i + 1) * colorHeight, size.width - 10, colorHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TubePainter oldDelegate) {
    return oldDelegate.colors != colors;
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

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _arcAnimation,
      builder: (context, child) {
        double angle = pi / 4 * _arcAnimation.value;
        double dx = (widget.toTubeIndex - widget.fromTubeIndex) * 60.0 * _arcAnimation.value;
        return Positioned(
          left: 50.0 + widget.fromTubeIndex * 60.0 + dx,
          top: 200.0 - (100 * sin(angle)),
          child: Opacity(
            opacity: 1.0 - _arcAnimation.value,
            child: Transform.rotate(
              angle: angle,
              child: Column(
                children: widget.colors.map((color) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4.0),
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
