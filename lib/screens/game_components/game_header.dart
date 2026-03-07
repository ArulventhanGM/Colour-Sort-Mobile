import 'package:flutter/material.dart';

/// AAA Casual Game Header
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Huge Glossy Level Badge
          _buildLevelBadge(),

          // Right: Coins and Controls
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Coins Pill
              _buildCoinsPill(),
              const SizedBox(height: 12),
              // Action Buttons Row
              Row(
                children: [
                  _buildGlossyButton(
                    icon: Icons.lightbulb_rounded,
                    color1: const Color(0xFFFFB75E),
                    color2: const Color(0xFFED8F03),
                    onPressed: onHintPressed,
                  ),
                  const SizedBox(width: 10),
                  _buildGlossyButton(
                    icon: Icons.shopping_cart_rounded,
                    color1: const Color(0xFFD66D75),
                    color2: const Color(0xFFE29587),
                    onPressed: onStorePressed,
                  ),
                  const SizedBox(width: 10),
                  _buildGlossyButton(
                    icon: Icons.settings_rounded,
                    color1: const Color(0xFF5AB6FF),
                    color2: const Color(0xFF2684FF),
                    onPressed: onSettingsPressed,
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Starburst/Scalloped background effect using simple circles
        Container(
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFDAB9), Color(0xFFFF8C00), Color(0xFFFF007F)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        // Inner Circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD8B5FF), Color(0xFF8B5CF6)],
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 5,
                spreadRadius: -2,
                offset: const Offset(0, -3),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: -2,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LEVEL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
                ),
              ),
              Text(
                '$currentLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  height: 1.0,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2))],
                ),
              ),
            ],
          ),
        ),
        // Crown Icon at top
        Positioned(
          top: -10,
          child: Icon(
            Icons.workspace_premium_rounded,
            color: const Color(0xFFFFD700),
            size: 30,
            shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
          ),
        ),
      ],
    );
  }

  Widget _buildCoinsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7B3B3B).withOpacity(0.5), // Semi-transparent dark bg
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coin Icon (Shiny Gold Circle)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF7A8), Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
              shadows: [Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 2))],
            ),
          ),
          const SizedBox(width: 12),
          // Green Plus button
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2)],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossyButton({
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color1, color2],
          ),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner glossy highlight
            Positioned(
              top: 2,
              child: Container(
                width: 20,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Icon(
              icon,
              color: Colors.white,
              size: 26,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 2))],
            ),
          ],
        ),
      ),
    );
  }
}
