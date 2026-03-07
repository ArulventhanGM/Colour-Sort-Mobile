import 'package:flutter/material.dart';

/// Bottom controls bar for game actions (AAA Casual Game Style)
class GameControls extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final VoidCallback onAddTube;
  final bool canUndo;
  final bool canAddTube;

  const GameControls({
    super.key,
    required this.onUndo,
    required this.onReset,
    required this.onAddTube,
    required this.canUndo,
    required this.canAddTube,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 30.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Undo button (Pink/Magenta gradient)
          _buildGlossyControlButton(
            icon: Icons.reply_rounded,
            label: 'UNDO',
            subLabel: '5',
            badgeText: '5',
            color1: const Color(0xFFFF7EB3),
            color2: const Color(0xFFFF1493),
            onPressed: canUndo ? onUndo : null,
            isEnabled: canUndo,
          ),
          
          // Reset button (Orange/Yellow gradient)
          _buildGlossyControlButton(
            icon: Icons.refresh_rounded,
            label: 'RESET',
            subLabel: 'FREE',
            badgeText: '', // No badge shown in image? Wait image didn't have one for reset, or it did? It had none.
            color1: const Color(0xFFFFE066),
            color2: const Color(0xFFFF9500),
            onPressed: onReset,
            isEnabled: true,
          ),
          
          // Add tube button (Green/Lime gradient)
          _buildGlossyControlButton(
            icon: Icons.add_rounded,
            label: 'ADD TUBE',
            subLabel: '1',
            badgeText: '1',
            color1: const Color(0xFF6EE7B7),
            color2: const Color(0xFF10B981),
            onPressed: canAddTube ? onAddTube : null,
            isEnabled: canAddTube,
          ),
        ],
      ),
    );
  }

  Widget _buildGlossyControlButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required String badgeText,
    required Color color1,
    required Color color2,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    final double size = 75.0; // Large size

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onPressed,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color1, color2],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      // Glow effect
                      BoxShadow(
                        color: color2.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                      // Inner shadow equivalent
                      const BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glossy highlight top
                      Positioned(
                        top: 4,
                        child: Container(
                          width: size * 0.6,
                          height: size * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(size),
                          ),
                        ),
                      ),
                      // Glossy rim at bottom
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: size * 0.7,
                          height: size * 0.15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 40,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ],
                  ),
                ),
              ),
              if (badgeText.isNotEmpty)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
              shadows: [Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2))],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}
