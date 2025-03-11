import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'rewards_manager.dart';

/// Dialog that displays daily login rewards to the player
class DailyRewardDialog extends StatefulWidget {
  final GameController gameController;
  final DailyLoginReward reward;

  const DailyRewardDialog({
    Key? key,
    required this.gameController,
    required this.reward,
  }) : super(key: key);

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Play sound effect and start animation
    widget.gameController.playSound('select');
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
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
              // Header
              Text(
                'Daily Reward!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),

              const SizedBox(height: 5),

              // Login streak info
              Text(
                'Day ${widget.reward.day} (${widget.reward.streak} day streak)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Rewards section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Coins reward
                  _buildRewardItem(
                    icon: Icons.monetization_on_rounded,
                    value: '${widget.reward.coins}',
                    label: 'Coins',
                    color: Colors.amber.shade300,
                  ),

                  // Hints reward if applicable
                  if (widget.reward.hints > 0)
                    _buildRewardItem(
                      icon: Icons.lightbulb_outline,
                      value: '${widget.reward.hints}',
                      label: 'Hint',
                      color: Colors.green.shade300,
                    ),
                ],
              ),

              const SizedBox(height: 25),

              // Streak calendar for next rewards
              _buildWeekCalendar(),

              const SizedBox(height: 25),

              // Claim button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
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
                ),
                child: const Text(
                  'AWESOME!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        // Animated reward container
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween<double>(begin: 0.5, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, animValue, child) {
            return Transform.scale(
              scale: animValue,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar() {
    return Column(
      children: [
        const Text(
          'Keep playing for more rewards!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 10),

        // Calendar grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            // Calculate the day number (1-6)
            final day = index + 1;

            // Check if it's the current day or already collected
            final bool isCurrentDay = day == widget.reward.day;
            final bool isCollectedDay = day < widget.reward.day ||
                (day > widget.reward.day &&
                    day <= widget.reward.day - (widget.reward.streak % 6));

            // Get reward for this day
            final int dayCoins = RewardsManager.dailyRewards[day] ?? 10;
            final bool hasHint = day == 5;

            return Column(
              children: [
                // Day number
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrentDay
                        ? Colors.blue.shade700
                        : isCollectedDay
                            ? Colors.grey.shade400
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: isCurrentDay
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'D$day',
                      style: TextStyle(
                        color: isCurrentDay || isCollectedDay
                            ? Colors.white
                            : Colors.black87,
                        fontWeight:
                            isCurrentDay ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // Day reward
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.amber,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$dayCoins',
                      style: TextStyle(
                        fontSize: 10,
                        color: isCollectedDay
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                    if (hasHint) ...[
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.green,
                        size: 10,
                      ),
                    ],
                  ],
                ),

                // Check mark for collected days
                if (isCollectedDay || isCurrentDay) ...[
                  const SizedBox(height: 2),
                  Icon(
                    Icons.check_circle_outline,
                    color: isCurrentDay
                        ? Colors.blue.shade700
                        : Colors.grey.shade500,
                    size: 12,
                  ),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}
