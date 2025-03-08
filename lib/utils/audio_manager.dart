import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  
  factory AudioManager() => _instance;
  
  AudioManager._internal();
  
  // Sound players
  final AudioPlayer _selectPlayer = AudioPlayer();
  final AudioPlayer _pourPlayer = AudioPlayer();
  final AudioPlayer _completePlayer = AudioPlayer();
  final AudioPlayer _bubblePlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  // Sound state
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.5;
  
  // Initialization flag
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Try to load sound assets, but don't crash if they're missing
      await _safelyLoadAudio(_selectPlayer, 'sounds/select.mp3');
      await _safelyLoadAudio(_pourPlayer, 'sounds/pour.mp3');
      await _safelyLoadAudio(_completePlayer, 'sounds/level_complete.mp3');
      await _safelyLoadAudio(_bubblePlayer, 'sounds/bubble.mp3');
      await _safelyLoadAudio(_errorPlayer, 'sounds/error.mp3');
      
      // Background music setup
      await _safelyLoadAudio(_bgmPlayer, 'sounds/background.mp3');
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Set volumes
      _updateVolumes();
      
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing audio: $e');
      }
      // Continue even if audio initialization fails
      _initialized = true;
    }
  }
  
  Future<void> _safelyLoadAudio(AudioPlayer player, String asset) async {
    try {
      await player.setSource(AssetSource(asset));
    } catch (e) {
      if (kDebugMode) {
        print('Could not load audio asset: $asset - $e');
      }
      // We'll continue without this sound rather than crashing
    }
  }
  
  void _updateVolumes() {
    // Apply sound volume
    _selectPlayer.setVolume(_soundEnabled ? _soundVolume : 0.0);
    _pourPlayer.setVolume(_soundEnabled ? _soundVolume : 0.0);
    _completePlayer.setVolume(_soundEnabled ? _soundVolume : 0.0);
    _bubblePlayer.setVolume(_soundEnabled ? _soundVolume : 0.0);
    _errorPlayer.setVolume(_soundEnabled ? _soundVolume : 0.0);
    
    // Apply music volume
    _bgmPlayer.setVolume(_musicEnabled ? _musicVolume : 0.0);
  }
  
  void playSelect() {
    if (!_soundEnabled || !_initialized) return;
    _selectPlayer.seek(Duration.zero);
    _selectPlayer.resume();
  }
  
  void playPour() {
    if (!_soundEnabled || !_initialized) return;
    _pourPlayer.seek(Duration.zero);
    _pourPlayer.resume();
  }
  
  void playBubble() {
    if (!_soundEnabled || !_initialized) return;
    _bubblePlayer.seek(Duration.zero);
    _bubblePlayer.resume();
  }
  
  void playComplete() {
    if (!_soundEnabled || !_initialized) return;
    _completePlayer.seek(Duration.zero);
    _completePlayer.resume();
  }
  
  void playError() {
    if (!_soundEnabled || !_initialized) return;
    _errorPlayer.seek(Duration.zero);
    _errorPlayer.resume();
  }
  
  void startMusic() {
    if (!_musicEnabled || !_initialized) return;
    _bgmPlayer.seek(Duration.zero);
    _bgmPlayer.resume();
  }
  
  void pauseMusic() {
    if (!_initialized) return;
    _bgmPlayer.pause();
  }
  
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _updateVolumes();
  }
  
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    _updateVolumes();
    
    if (_musicEnabled) {
      _bgmPlayer.resume();
    } else {
      _bgmPlayer.pause();
    }
  }
  
  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
    _updateVolumes();
  }
  
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _updateVolumes();
  }
  
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  
  void dispose() {
    _selectPlayer.dispose();
    _pourPlayer.dispose();
    _completePlayer.dispose();
    _bubblePlayer.dispose();
    _errorPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
