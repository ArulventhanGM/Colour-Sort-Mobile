import 'package:flutter/material.dart';
import 'game_controller.dart';

/// Floating Puzzle Progress Bar
class GameStats extends StatelessWidget {
  final GameController gameController;

  const GameStats({
    super.key,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress
    int sortedTubes = 0;
    int targetTubes = gameController.tubes.length - 2; // Assuming 2 empty tubes base
    
    // To handle dynamic extra tubes gracefully, we simply check how many are currently correctly sorted.
    for (final tube in gameController.tubes) {
       if (tube.isNotEmpty && tube.length == 4 && tube.every((c) => c == tube.first)) {
           sortedTubes++;
       }
    }
    
    double progress = targetTubes > 0 ? (sortedTubes / targetTubes).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'PUZZLE PROGRESS',
            style: TextStyle(
              color: const Color(0xFF6F32A8),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2.0,
              shadows: [Shadow(color: Colors.white.withOpacity(0.8), offset: const Offset(0, 1), blurRadius: 2)],
            ),
          ),
          const SizedBox(height: 8),
          
          // Progress Bar Container
          Container(
            height: 28,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2), // Dark track
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
            child: Stack(
              children: [
                // Animated Fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  width: MediaQuery.of(context).size.width * progress, // Approximation for relative fill; better inside a LayoutBuilder or FractionallySizedBox
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
                    ),
                  ),
                ),
                
                // Better Fill using FractionallySizedBox to be perfectly accurate
                FractionallySizedBox(
                   widthFactor: progress,
                   child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFA7F3D0), Color(0xFF10B981)],
                          )
                      ),
                      child: Stack(
                         children: [
                            // Inner specular highlight
                            Positioned(
                               top: 2,
                               left: 4,
                               right: 4,
                               child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                     color: Colors.white.withOpacity(0.6),
                                     borderRadius: BorderRadius.circular(10)
                                  ),
                               )
                            )
                         ],
                      ),
                   ),
                ),
                
                // Star Icon at far right of track
                const Align(
                   alignment: Alignment.centerRight,
                   child: Padding(
                      padding: EdgeInsets.only(right: 6.0),
                      child: Icon(Icons.star_rounded, color: Colors.white38, size: 18),
                   ),
                ),
                
                // Text overlay showing numbers
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    '$sortedTubes / $targetTubes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
