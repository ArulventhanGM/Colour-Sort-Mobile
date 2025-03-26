import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';

/// Header widget for the game screen showing level and coins
class GameHeader extends StatelessWidget {
  final int currentLevel;
  final int coins;
  final VoidCallback onSettingsPressed;
  final VoidCallback onStorePressed;
  final VoidCallback onHintPressed;

  const GameHeader({
    super.key,
    required this.currentLevel,
    required this.coins,
    required this.onSettingsPressed,
    required this.onStorePressed,
    required this.onHintPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
      decoration: BoxDecoration(
        color: currentTheme.headerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: currentTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'Level $currentLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Coins display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: currentTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: currentTheme.accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Hint button
              _HeaderButton(
                icon: Icons.lightbulb_outline,
                onPressed: onHintPressed,
                accentColor: currentTheme.accentColor,
                backgroundColor: currentTheme.secondaryColor,
              ),
              const SizedBox(width: 8),

              // Store button
              _HeaderButton(
                icon: Icons.shopping_cart_outlined,
                onPressed: onStorePressed,
                accentColor: currentTheme.accentColor,
                backgroundColor: currentTheme.secondaryColor,
              ),
              const SizedBox(width: 8),

              // Settings button
              _HeaderButton(
                icon: Icons.settings,
                onPressed: onSettingsPressed,
                accentColor: currentTheme.accentColor,
                backgroundColor: currentTheme.secondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Button widget for the header
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color accentColor;
  final Color backgroundColor;

  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    required this.accentColor, 
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
