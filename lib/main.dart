import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/game_home_page.dart';
import 'utils/audio_manager.dart';
import 'utils/dummy_audio.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set up audio (with fallback to prevent crashes)
  try {
    await DummyAudio.setupDummyAudio();
    await AudioManager().initialize();
  } catch (e) {
    debugPrint('Error initializing audio: $e');
    // Continue without audio rather than crashing
  }
  
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();
  
  runApp(
    ChangeNotifierProvider<ThemeService>.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current theme from provider
    final themeService = Provider.of<ThemeService>(context);
    final currentTheme = themeService.currentTheme;
    
    return MaterialApp(
      title: 'Magic Pour',
      theme: ThemeData(
        primaryColor: currentTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: currentTheme.primaryColor,
          primary: currentTheme.primaryColor,
          secondary: currentTheme.secondaryColor,
          brightness: currentTheme.isDark ? Brightness.dark : Brightness.light,
        ),
        canvasColor: currentTheme.backgroundColor,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: currentTheme.backgroundColor,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: currentTheme.textColor),
          bodyMedium: TextStyle(color: currentTheme.textColor),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: currentTheme.backgroundColor,
          titleTextStyle: TextStyle(
            color: currentTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: currentTheme.buttonColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const GameHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
