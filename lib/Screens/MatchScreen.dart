import 'package:flutter/material.dart';
import 'package:scary_strokes/Screens/startGameScreen.dart';

class StartMatchScreen extends StatelessWidget {
  final List<PlayerData> players;

  const StartMatchScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_golf,
                size: 100,
                color: Color(0xFFFF8C00),
              ),
              const SizedBox(height: 20),
              const Text(
                'Match Screen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Players: ${players.map((p) => p.name).join(', ')}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}