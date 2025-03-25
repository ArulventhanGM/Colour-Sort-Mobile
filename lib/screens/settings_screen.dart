import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/haptic_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HapticService _hapticService = HapticService();
  bool _isCelebrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCelebrationEnabled = prefs.getBool('celebration_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('celebration_enabled', _isCelebrationEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Enable vibrations on actions'),
            value: _hapticService.isHapticEnabled,
            onChanged: (value) {
              setState(() {
                _hapticService.setHapticEnabled(value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Celebration Effects'),
            subtitle: const Text('Enable burst, confetti and fireworks effects'),
            value: _isCelebrationEnabled,
            onChanged: (value) {
              setState(() {
                _isCelebrationEnabled = value;
                _saveSettings();
              });
            },
          ),
        ],
      ),
    );
  }
}
