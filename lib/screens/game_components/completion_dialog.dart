import 'package:flutter/material.dart';
import 'game_controller.dart';

class CompletionDialog extends StatelessWidget {
  final GameController gameController;
  final VoidCallback onNextLevel;

  const CompletionDialog({
    Key? key,
    required this.gameController,
    required this.onNextLevel,
  }) : super(key: key);

  int get _optimalMoves => 10 + gameController.currentLevel * 2;
  int get _stars {
    final moves = gameController.movesCount;
    if (moves <= _optimalMoves) return 3;
    if (moves <= _optimalMoves * 1.5) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level ${gameController.currentLevel} Complete!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < _stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              'Moves: ${gameController.movesCount}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Coins Earned: +${gameController.coinsEarned}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.amber.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onNextLevel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Next Level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
