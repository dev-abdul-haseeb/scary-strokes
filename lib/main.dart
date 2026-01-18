import 'package:flutter/material.dart';
import 'package:scary_strokes/Screens/splash_screen.dart';
import 'Screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scary Strokes',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}