import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _burstPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  bool _initialized = false;
  final bool _isSoundEnabled = true; // Default to true or use a setting

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Pre-load sound effects
      await _burstPlayer.setSource(AssetSource('audio/burst.mp3'));
      await _winPlayer.setSource(AssetSource('sounds/level_complete.mp3'));
      
      _initialized = true;
      debugPrint('Audio service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
    }
  }

  void playBurstSound() {
    if (!_isSoundEnabled) return;

    try {
      _burstPlayer.resume();
    } catch (e) {
      debugPrint('Error playing burst sound: $e');
    }
  }

  void playWinSound() {
    try {
      _winPlayer.resume();
    } catch (e) {
      debugPrint('Error playing win sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _burstPlayer.dispose();
    _winPlayer.dispose();
  }
}
