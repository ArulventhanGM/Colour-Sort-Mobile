import 'package:flutter/material.dart';

/// Theme data model for the game
class GameTheme {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color tubeOutlineColor;
  final Color headerColor;
  final LinearGradient backgroundGradient;
  final bool isDark;

  const GameTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
    required this.tubeOutlineColor,
    required this.headerColor,
    required this.backgroundGradient,
    this.isDark = false,
  });

  // Predefined themes
  static const GameTheme classic = GameTheme(
    id: 'classic',
    name: 'Classic',
    description: 'The original color sort game theme',
    primaryColor: Color(0xFF3F51B5),
    secondaryColor: Color(0xFF303F9F),
    accentColor: Color(0xFFFFC107),
    backgroundColor: Color(0xFFF5F5F5),
    textColor: Color(0xFF212121),
    buttonColor: Color(0xFF4CAF50),
    tubeOutlineColor: Color(0xFF757575),
    headerColor: Color(0xFF3F51B5),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
    ),
    isDark: false,
  );

  static const GameTheme dark = GameTheme(
    id: 'dark',
    name: 'Dark Mode',
    description: 'Easy on the eyes, perfect for night play',
    primaryColor: Color(0xFF303030),
    secondaryColor: Color(0xFF212121),
    accentColor: Color(0xFF64FFDA),
    backgroundColor: Color(0xFF121212),
    textColor: Color(0xFFEEEEEE),
    buttonColor: Color(0xFF26A69A),
    tubeOutlineColor: Color(0xFF757575),
    headerColor: Color(0xFF212121),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1F2B3E), 
        Color(0xFF121725), 
        Color(0xFF0A0E18)
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    isDark: true,
  );

  static const GameTheme neon = GameTheme(
    id: 'neon',
    name: 'Neon',
    description: 'Vibrant colors that pop in the dark',
    primaryColor: Color(0xFF2E0854),
    secondaryColor: Color(0xFF1A0033),
    accentColor: Color(0xFFFF00FF),
    backgroundColor: Color(0xFF000033),
    textColor: Color(0xFFFFFFFF),
    buttonColor: Color(0xFF00FFFF),
    tubeOutlineColor: Color(0xFF00FFFF),
    headerColor: Color(0xFF4A0080),
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2E0854), Color(0xFF000033)],
    ),
    isDark: true,
  );

  static const GameTheme nature = GameTheme(
    id: 'nature',
    name: 'Nature',
    description: 'Calming colors inspired by the outdoors',
    primaryColor: Color(0xFF2E7D32),
    secondaryColor: Color(0xFF1B5E20),
    accentColor: Color(0xFFFFEB3B),
    backgroundColor: Color(0xFFE8F5E9),
    textColor: Color(0xFF33691E),
    buttonColor: Color(0xFF689F38),
    tubeOutlineColor: Color(0xFF558B2F),
    headerColor: Color(0xFF388E3C),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
    ),
    isDark: false,
  );

  // All available themes
  static const List<GameTheme> allThemes = [
    classic,
    dark,
    neon,
    nature,
  ];
}