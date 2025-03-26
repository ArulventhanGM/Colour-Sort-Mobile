import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../widgets/control_button.dart';

/// Bottom controls bar for game actions
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
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: currentTheme.headerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo button
          ControlButton(
            icon: Icons.undo,
            label: 'Undo',
            onPressed: canUndo ? onUndo : null,
            primaryColor: currentTheme.buttonColor,
            accentColor: currentTheme.accentColor,
            size: 50,
            isEnabled: canUndo,
          ),
          
          // Reset button
          ControlButton(
            icon: Icons.refresh,
            label: 'Reset',
            onPressed: onReset,
            primaryColor: currentTheme.buttonColor,
            accentColor: currentTheme.accentColor,
            size: 50,
          ),
          
          // Add tube button
          ControlButton(
            icon: Icons.add_circle_outline,
            label: 'Add Tube',
            onPressed: canAddTube ? onAddTube : null,
            primaryColor: currentTheme.buttonColor,
            accentColor: currentTheme.accentColor,
            size: 50,
            isEnabled: canAddTube,
          ),
        ],
      ),
    );
  }
}
