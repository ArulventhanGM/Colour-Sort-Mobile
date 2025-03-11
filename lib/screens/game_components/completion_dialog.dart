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

  @override
  Widget build(BuildContext context) {
    // Calculate rewards before showing dialog
    gameController.calculateLevelRewards();

    // Extract reward values for easier access
    final timeSeconds = gameController.completionTimeSeconds;
    final timeBonus = gameController.timeBonus;
    final perfectBonus = gameController.perfectBonus;
    final isPerfect = gameController.isPerfectComplete;
    final isQuick = gameController.isQuickComplete;
    final rewardMessage = gameController.rewardMessage;
    final baseCoins = gameController.coinsEarned - timeBonus - perfectBonus;
    final totalCoins = gameController.coinsEarned;
    final moves = gameController.movesCount;
    final optimalMoves = 10 + gameController.currentLevel * 2;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level completion header with celebration animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Column(
                children: [
                  Text(
                    'Level ${gameController.currentLevel} Complete!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  if (rewardMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        rewardMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Stars
            _buildStarsRow(gameController.score),

            const SizedBox(height: 20),

            // Performance Stats Box
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Move count
                  _buildStatRow(
                    'Moves',
                    '$moves${moves <= optimalMoves ? ' (Perfect!)' : ''}',
                    icon: Icons.swap_horiz,
                    highlight: isPerfect,
                    optimalValue: '$optimalMoves',
                  ),

                  const SizedBox(height: 8),

                  // Completion time
                  _buildStatRow(
                    'Time',
                    '$timeSeconds sec',
                    icon: Icons.timer,
                    highlight: isQuick,
                  ),

                  const Divider(height: 20),

                  // Rewards section
                  _buildRewardRow(
                    'Base Reward',
                    '+$baseCoins',
                    Colors.blue.shade700,
                  ),

                  if (perfectBonus > 0)
                    _buildRewardRow(
                      'Perfect Moves Bonus',
                      '+$perfectBonus',
                      Colors.green,
                      icon: Icons.verified,
                    ),

                  if (timeBonus > 0)
                    _buildRewardRow(
                      'Speed Bonus',
                      '+$timeBonus',
                      Colors.amber.shade700,
                      icon: Icons.bolt,
                    ),

                  if (gameController.currentLevel % 10 == 0)
                    _buildRewardRow(
                      'Milestone Bonus',
                      '+${gameController.currentLevel}',
                      Colors.purple,
                      icon: Icons.emoji_events,
                    ),

                  const SizedBox(height: 10),

                  // Total coins
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Coins:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      _buildCoinCounter(totalCoins),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Next level button with animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onNextLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Next Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarsRow(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index < stars;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + (index * 300)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  isActive ? Icons.star : Icons.star_border,
                  color: isActive ? Colors.amber : Colors.grey.shade400,
                  size: 40,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildStatRow(
    String label,
    String value, {
    IconData? icon,
    bool highlight = false,
    String? optimalValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 18,
                color: highlight ? Colors.green : Colors.blueGrey,
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: highlight ? Colors.green.shade800 : Colors.black87,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (optimalValue != null)
              Text(
                '($optimalValue optimal) ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.green.shade800 : Colors.black87,
              ),
            ),
            if (highlight) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green.shade800,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRewardRow(String label, String value, Color color,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.monetization_on,
                color: color,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinCounter(int coins) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade300,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade100.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '+$coins',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.monetization_on,
                  color: Colors.amber.shade900,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
