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
      // Set global options for better performance
      AudioPlayer.global.setGlobalAudioContext(AudioContext());

      // Configure background music player for looping
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.setVolume(_musicVolume);

      // Set volume for all players
      await Future.wait([
        _selectPlayer.setVolume(0.5),
        _pourPlayer.setVolume(0.7),
        _bubblePlayer.setVolume(0.6),
        _completePlayer.setVolume(0.8),
        _errorPlayer.setVolume(0.6),
      ]);

      _initialized = true;

      // Pre-load sound effects to avoid first-time delay
      await Future.wait([
        _preloadSound(_selectPlayer, 'sounds/select.mp3'),
        _preloadSound(_pourPlayer, 'sounds/pour.mp3'),
        _preloadSound(_bubblePlayer, 'sounds/bubble.mp3'),
        _preloadSound(_completePlayer, 'sounds/level_complete.mp3'),
        _preloadSound(_errorPlayer, 'sounds/error.mp3'),
        _preloadSound(_backgroundMusicPlayer, 'sounds/background.mp3'),
      ]);

      // Start background music
      await playBackgroundMusic();

      debugPrint('AudioManager: All sounds initialized and pre-loaded');
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  /// Pre-load a sound for instant playback
  Future<void> _preloadSound(AudioPlayer player, String assetPath) async {
    try {
      // Just load the source but don't play
      await player.setSource(AssetSource(assetPath));
      await player.stop(); // Ensure it's ready but not playing
    } catch (e) {
      debugPrint('Error preloading $assetPath: $e');
    }
  }

  /// Set whether sound effects are enabled
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;

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
      await _backgroundMusicPlayer.resume();
    } catch (e) {
      debugPrint('Error playing background music: $e');
      // Attempt to restart the music if resuming fails
      try {
        await _backgroundMusicPlayer.play(AssetSource('sounds/background.mp3'));
      } catch (e) {
        debugPrint('Error restarting background music: $e');
      }
    }
  }

  /// Play the selection sound effect
  Future<void> playSelect() async {
    if (!_soundEnabled) return;

    try {
      // Release previous resources to ensure sound plays every time
      await _selectPlayer.stop();
      await _selectPlayer.play(AssetSource('sounds/select.mp3'));
    } catch (e) {
      debugPrint('Error playing select sound: $e');
    }
  }

  /// Play the pouring sound effect
  Future<void> playPour() async {
    if (!_soundEnabled) return;

    try {
      await _pourPlayer.stop();
      await _pourPlayer.play(AssetSource('sounds/pour.mp3'));
    } catch (e) {
      debugPrint('Error playing pour sound: $e');
    }
  }

  /// Play the bubble sound effect
  Future<void> playBubble() async {
    if (!_soundEnabled) return;

    try {
      await _bubblePlayer.stop();
      await _bubblePlayer.play(AssetSource('sounds/bubble.mp3'));
    } catch (e) {
      debugPrint('Error playing bubble sound: $e');
    }
  }

  /// Play the level completion sound
  Future<void> playComplete() async {
    if (!_soundEnabled) return;

    try {
      await _completePlayer.stop();
      await _completePlayer.play(AssetSource('sounds/level_complete.mp3'));
    } catch (e) {
      debugPrint('Error playing complete sound: $e');
    }
  }

  /// Play the error sound
  Future<void> playError() async {
    if (!_soundEnabled) return;

    try {
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
