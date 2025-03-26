import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_theme.dart';

class ThemeService extends ChangeNotifier {
  // The current active theme
  GameTheme _currentTheme = GameTheme.classic;
  
  // Key for storing theme preference
  static const String _themePreferenceKey = 'selected_theme_id';
  
  // Get the current theme
  GameTheme get currentTheme => _currentTheme;
  
  // Initialize theme from stored preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedThemeId = prefs.getString(_themePreferenceKey);
    
    if (storedThemeId != null) {
      // Find the theme with the stored ID
      for (final theme in GameTheme.allThemes) {
        if (theme.id == storedThemeId) {
          _currentTheme = theme;
          break;
        }
      }
    }
    
    // Notify listeners even if the theme is the default one
    notifyListeners();
  }
  
  // Set a new theme and save the preference
  Future<void> setTheme(GameTheme theme) async {
    if (_currentTheme.id != theme.id) {
      _currentTheme = theme;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, theme.id);
      
      // Notify listeners to update UI
      notifyListeners();
    }
  }
}