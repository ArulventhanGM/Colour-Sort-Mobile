import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();

  factory AudioManager() => _instance;

  AudioManager._internal();

  // Sound players with separate instances for concurrent sound playback
  final AudioPlayer _selectPlayer = AudioPlayer();
  final AudioPlayer _pourPlayer = AudioPlayer();
  final AudioPlayer _bubblePlayer = AudioPlayer();
  final AudioPlayer _completePlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();

  // Keep track of sound sources to avoid reloading
  bool _initialized = false;

  // Options for controlling sounds
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _musicVolume = 0.3;

  /// Initialize all sound effects
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('Initializing AudioManager...');

      // Configure players with higher volume
      await Future.wait([
        _selectPlayer.setVolume(1.0),
        _pourPlayer.setVolume(1.0),
        _bubblePlayer.setVolume(1.0),
        _completePlayer.setVolume(1.0),
        _errorPlayer.setVolume(1.0),
        _backgroundMusicPlayer.setVolume(_musicVolume),
      ]);

      // Configure background music player for looping
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);

      _initialized = true;
      debugPrint('AudioManager initialized successfully');

      // Start background music
      if (_musicEnabled) {
        playBackgroundMusic();
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  /// Set whether sound effects are enabled
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    debugPrint('Sound effects ${enabled ? 'enabled' : 'disabled'}');

    // If disabling sounds, stop any that might be playing
    if (!enabled) {
      _selectPlayer.stop();
      _pourPlayer.stop();
      _bubblePlayer.stop();
      _completePlayer.stop();
      _errorPlayer.stop();
    }
  }

  /// Set whether background music is enabled
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    debugPrint('Background music ${enabled ? 'enabled' : 'disabled'}');

    if (enabled) {
      playBackgroundMusic();
    } else {
      _backgroundMusicPlayer.stop();
    }
  }

  /// Set background music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _backgroundMusicPlayer.setVolume(_musicVolume);
  }

  /// Play or resume background music
  Future<void> playBackgroundMusic() async {
    if (!_musicEnabled || !_initialized) return;

    try {
      debugPrint('Playing background music');
      // Always play from start to ensure it works
      await _backgroundMusicPlayer.stop();
      await _backgroundMusicPlayer.play(AssetSource('sounds/background.mp3'));
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  /// Play the selection sound effect
  Future<void> playSelect() async {
    if (!_soundEnabled || !_initialized) return;

    try {
      debugPrint('Playing select sound');
      // Always play fresh for more reliable playback
      await _selectPlayer.stop();
      await _selectPlayer.play(AssetSource('sounds/select.mp3'));
    } catch (e) {
      debugPrint('Error playing select sound: $e');
    }
  }

  /// Play the pouring sound effect
  Future<void> playPour() async {
    if (!_soundEnabled || !_initialized) return;

    try {
      debugPrint('Playing pour sound');
      await _pourPlayer.stop();
      await _pourPlayer.play(AssetSource('sounds/pour.mp3'));
    } catch (e) {
      debugPrint('Error playing pour sound: $e');
    }
  }

  /// Play the bubble sound effect
  Future<void> playBubble() async {
    if (!_soundEnabled || !_initialized) return;

    try {
      debugPrint('Playing bubble sound');
      await _bubblePlayer.stop();
      await _bubblePlayer.play(AssetSource('sounds/bubble.mp3'));
    } catch (e) {
      debugPrint('Error playing bubble sound: $e');
    }
  }

  /// Play the level completion sound
  Future<void> playComplete() async {
    if (!_soundEnabled || !_initialized) return;

    try {
      debugPrint('Playing complete sound');
      await _completePlayer.stop();
      await _completePlayer.play(AssetSource('sounds/level_complete.mp3'));
    } catch (e) {
      debugPrint('Error playing complete sound: $e');
    }
  }

  /// Play the error sound
  Future<void> playError() async {
    if (!_soundEnabled || !_initialized) return;

    try {
      debugPrint('Playing error sound');
      await _errorPlayer.stop();
      await _errorPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      debugPrint('Error playing error sound: $e');
    }
  }

  /// Dispose all audio players when no longer needed
  void dispose() {
    _selectPlayer.dispose();
    _pourPlayer.dispose();
    _bubblePlayer.dispose();
    _completePlayer.dispose();
    _errorPlayer.dispose();
    _backgroundMusicPlayer.dispose();
  }
}
