import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'game_controller.dart';

class CompletionDialog extends StatefulWidget {
  final GameController gameController;
  final VoidCallback onNextLevel;

  const CompletionDialog({
    Key? key,
    required this.gameController,
    required this.onNextLevel,
  }) : super(key: key);

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    widget.gameController.calculateLevelRewards();
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    
    _animController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 800)
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    
    _animController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCoins = widget.gameController.coinsEarned;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Main Dialog Box
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0F2FE), Color(0xFFFDF4FF)],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, offset: Offset(0, 15), blurRadius: 30),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const SizedBox(height: 20),
                   
                   // 3 Stars Rating
                   _buildStarsRow(widget.gameController.score),
                   
                   const SizedBox(height: 30),
                   
                   // Coin Reward Animation
                   TweenAnimationBuilder<double>(
                     duration: const Duration(milliseconds: 1500),
                     tween: Tween<double>(begin: 0, end: totalCoins.toDouble()),
                     curve: Curves.easeOutCubic,
                     builder: (context, value, child) {
                       return Container(
                           padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                           decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(30),
                               boxShadow: [
                                   BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                               ]
                           ),
                           child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                   const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 36),
                                   const SizedBox(width: 10),
                                   Text(
                                       '+${value.toInt()}',
                                       style: const TextStyle(
                                           color: Color(0xFFFF9500),
                                           fontSize: 32,
                                           fontWeight: FontWeight.w900,
                                       ),
                                   )
                               ],
                           )
                       );
                     }
                   ),
                   
                   const SizedBox(height: 40),
                   
                   // Big Colorful Next Level Button
                   GestureDetector(
                       onTap: () {
                           Navigator.of(context).pop();
                           widget.onNextLevel();
                       },
                       child: Container(
                           width: double.infinity,
                           height: 70,
                           decoration: BoxDecoration(
                               gradient: const LinearGradient(
                                   colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
                                   begin: Alignment.topCenter,
                                   end: Alignment.bottomCenter,
                               ),
                               borderRadius: BorderRadius.circular(35),
                               border: Border.all(color: Colors.white, width: 2),
                               boxShadow: [
                                   BoxShadow(color: const Color(0xFF10B981).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8)),
                               ]
                           ),
                           alignment: Alignment.center,
                           child: const Text(
                               'NEXT LEVEL',
                               style: TextStyle(
                                   color: Colors.white,
                                   fontSize: 24,
                                   fontWeight: FontWeight.w900,
                                   letterSpacing: 2,
                                   shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]
                               ),
                           ),
                       ),
                   )
                ],
              ),
            ),
          ),
          
          // "Level Complete" Banner overlapping top edge
          Positioned(
             top: -30,
             child: ScaleTransition(
               scale: _scaleAnimation,
               child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                   decoration: BoxDecoration(
                       gradient: const LinearGradient(
                           colors: [Color(0xFFFF7EB3), Color(0xFFFF1493)],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(40),
                       border: Border.all(color: Colors.white, width: 3),
                       boxShadow: [
                           BoxShadow(color: const Color(0xFFFF1493).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))
                       ]
                   ),
                   child: const Text(
                       'LEVEL COMPLETE',
                       style: TextStyle(
                           color: Colors.white,
                           fontSize: 26,
                           fontWeight: FontWeight.w900,
                           letterSpacing: 1,
                           shadows: [Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)]
                       ),
                   ),
               ),
             )
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // fall vertically
              maxBlastForce: 15,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarsRow(int score) {
    // Determine stars to show
    int stars = score >= 80 ? 3 : (score >= 50 ? 2 : 1);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index < stars;
        // Middle star is bigger and higher
        final isMiddle = index == 1;
        
        return Padding(
          padding: EdgeInsets.only(
             bottom: isMiddle ? 25.0 : 0.0,
             left: 10,
             right: 10,
          ),
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600 + (index * 200)),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: isActive ? value : 1.0,
                child: Icon(
                  Icons.star_rounded,
                  color: isActive ? const Color(0xFFFFD700) : Colors.black12,
                  size: isMiddle ? 80 : 60,
                  shadows: isActive ? const [
                      Shadow(color: Colors.black26, offset: Offset(0, 5), blurRadius: 10),
                      Shadow(color: Color(0xFFFFD700), offset: Offset(0, 0), blurRadius: 15) // glow
                  ] : null,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
