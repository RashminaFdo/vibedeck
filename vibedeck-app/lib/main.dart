import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/vibe_theme.dart';
import 'ui/deck_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set immersive full screen and dark navigation styling
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VibeDeckApp());
}

class VibeDeckApp extends StatelessWidget {
  const VibeDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeDeck',
      debugShowCheckedModeBanner: false,
      theme: VibeTheme.darkTheme,
      home: const DeckScreen(),
    );
  }
}
