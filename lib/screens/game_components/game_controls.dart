import 'package:flutter/material.dart';

class GameControls extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final VoidCallback onAddTube;
  final bool canUndo;
  final bool canAddTube;

  const GameControls({
    Key? key,
    required this.onUndo,
    required this.onReset,
    required this.onAddTube,
    required this.canUndo,
    required this.canAddTube,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            onPressed: canUndo ? onUndo : null,
            icon: Icons.undo_rounded,
            label: 'Undo',
            color: Colors.orange,
          ),
          _buildControlButton(
            onPressed: onReset,
            icon: Icons.refresh_rounded,
            label: 'Reset',
            color: Colors.red,
          ),
          _buildControlButton(
            onPressed: canAddTube ? onAddTube : null,
            icon: Icons.add_circle_outline_rounded,
            label: 'Add Tube',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required MaterialColor color,
  }) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isEnabled ? color.shade300 : Colors.grey.shade300,
                      isEnabled ? color.shade400 : Colors.grey.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? color.shade700 : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
