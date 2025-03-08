import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/game_home_page.dart';
import 'utils/audio_manager.dart';
import 'utils/dummy_audio.dart';

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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Sort Puzzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GameHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
