import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_controller.dart';
import '../../services/theme_service.dart';
import '../../widgets/theme_selection_dialog.dart';
import '../../models/game_theme.dart';

/// Settings dialog for the game
class SettingsDialog extends StatelessWidget {
  final GameController gameController;
  final void Function(bool) onSoundToggled;
  final void Function(bool) onVibrationToggled;

  const SettingsDialog({
    super.key,
    required this.gameController,
    required this.onSoundToggled,
    required this.onVibrationToggled,
  });

  @override
  Widget build(BuildContext context) {
    // Access the current theme
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return Dialog(
      backgroundColor: currentTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: currentTheme.accentColor,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: currentTheme.textColor,
              ),
            ),
            const SizedBox(height: 24.0),
            // Sound toggle
            _SettingsSwitch(
              title: 'Sound Effects',
              value: gameController.soundEnabled,
              onChanged: onSoundToggled,
              icon: Icons.music_note,
              theme: currentTheme,
            ),
            const SizedBox(height: 16.0),
            // Vibration toggle
            _SettingsSwitch(
              title: 'Vibration',
              value: gameController.vibrateEnabled,
              onChanged: onVibrationToggled,
              icon: Icons.vibration,
              theme: currentTheme,
            ),
            const SizedBox(height: 24.0),
            
            // Theme selection button
            ElevatedButton.icon(
              icon: Icon(Icons.color_lens, color: currentTheme.backgroundColor),
              label: Text(
                'Change Theme',
                style: TextStyle(color: currentTheme.backgroundColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 3,
              ),
              onPressed: () {
                // Close settings dialog first
                Navigator.of(context).pop();
                
                // Show theme selection dialog
                showDialog(
                  context: context,
                  builder: (context) => const ThemeSelectionDialog(),
                );
              },
            ),
            
            const SizedBox(height: 24.0),
            
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings switch with icon and label
class _SettingsSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final void Function(bool) onChanged;
  final IconData icon;
  final GameTheme theme;

  const _SettingsSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.textColor,
              size: 24.0,
            ),
            const SizedBox(width: 12.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.accentColor,
        ),
      ],
    );
  }
}
