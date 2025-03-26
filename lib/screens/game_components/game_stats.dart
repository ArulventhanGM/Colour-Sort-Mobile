import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../models/game_theme.dart';

/// Widget displaying game statistics
class GameStats extends StatelessWidget {
  final int score;
  final int movesCount;
  final int coinsEarned;

  const GameStats({
    super.key,
    required this.score,
    required this.movesCount,
    required this.coinsEarned,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: currentTheme.secondaryColor.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Score
          _StatItem(
            label: 'Score',
            value: score.toString(),
            icon: Icons.stars,
            theme: currentTheme,
          ),
          
          // Moves
          _StatItem(
            label: 'Moves',
            value: movesCount.toString(),
            icon: Icons.swap_horiz,
            theme: currentTheme,
          ),
          
          // Coins earned
          _StatItem(
            label: 'Coins',
            value: '+$coinsEarned',
            icon: Icons.monetization_on,
            theme: currentTheme,
          ),
        ],
      ),
    );
  }
}

/// Individual stat item
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final GameTheme theme;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.accentColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
