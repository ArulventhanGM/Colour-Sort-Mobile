import 'package:flutter/material.dart';

/// Button for game controls with icon and label
class ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color accentColor;
  final double size;
  final bool isEnabled;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.primaryColor,
    required this.accentColor,
    this.size = 60,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Define colors based on enabled state
    final buttonColor = isEnabled ? primaryColor : primaryColor.withOpacity(0.4);
    final iconColor = isEnabled ? Colors.white : Colors.white.withOpacity(0.5);
    final labelColor = isEnabled ? accentColor : accentColor.withOpacity(0.5);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The button
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? onPressed : null,
              borderRadius: BorderRadius.circular(size / 2),
              child: Ink(
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: size * 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Button label
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
