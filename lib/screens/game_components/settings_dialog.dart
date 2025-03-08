import 'package:flutter/material.dart';
import 'game_controller.dart';

/// Dialog for game settings
class SettingsDialog extends StatelessWidget {
  final GameController gameController;
  final ValueChanged<bool> onSoundToggled;
  final ValueChanged<bool> onVibrationToggled;

  const SettingsDialog({
    Key? key,
    required this.gameController,
    required this.onSoundToggled,
    required this.onVibrationToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Music'),
            trailing: Switch(
              value: true, // Music not implemented yet
              onChanged: (value) {
                // TODO: Implement music settings
                Navigator.of(context).pop();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Sound Effects'),
            trailing: Switch(
              value: gameController.soundEnabled,
              onChanged: (value) {
                onSoundToggled(value);
                Navigator.of(context).pop();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vibration),
            title: const Text('Vibration'),
            trailing: Switch(
              value: gameController.vibrateEnabled,
              onChanged: (value) {
                onVibrationToggled(value);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
