import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();
  
  bool _isHapticEnabled = true;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isHapticEnabled = prefs.getBool('haptic_enabled') ?? true;
  }
  
  void setHapticEnabled(bool value) async {
    _isHapticEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_enabled', value);
  }
  
  bool get isHapticEnabled => _isHapticEnabled;
  
  void lightImpact() {
    if (_isHapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }
  
  void mediumImpact() {
    if (_isHapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
  
  void heavyImpact() {
    if (_isHapticEnabled) {
      HapticFeedback.heavyImpact();
    }
  }
  
  void burstFeedback() {
    if (_isHapticEnabled) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.lightImpact();
      });
    }
  }
}
