import 'package:flutter/material.dart';
import '../model/player_model.dart';

class StartGameController extends ChangeNotifier {
  // State
  List<PlayerData> players = [
    PlayerData(name: 'Player 1', iconIndex: 0),
  ];

  // Animation
  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  // Constructor
  StartGameController({required TickerProvider vsync}) {
    _initializeAnimations(vsync);
  }

  void _initializeAnimations(TickerProvider vsync) {
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    )..forward();

    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeOut),
    );
  }

  // Business Logic Methods
  void addPlayer() {
    if (players.length < 6) {
      players.add(PlayerData(
        name: 'Player ${players.length + 1}',
        iconIndex: players.length % 4,
      ));
      notifyListeners();
    }
  }

  void removePlayer(int index) {
    if (players.length > 1) {
      players.removeAt(index);
      notifyListeners();
    }
  }

  void updatePlayerName(int index, String name) {
    players[index].name = name;
    notifyListeners();
  }

  void updatePlayerIcon(int index, int iconIndex, String? customImagePath) {
    if (customImagePath != null) {
      players[index].customImagePath = customImagePath;
    } else {
      players[index].iconIndex = iconIndex;
      players[index].customImagePath = null;
    }
    notifyListeners();
  }

  bool validatePlayers() {
    return players.every((p) => p.name.trim().isNotEmpty);
  }

  String getPlayersCountText() {
    return '${players.length} Player${players.length > 1 ? 's' : ''}';
  }

  // Cleanup
  void disposeControllers() {
    fadeController.dispose();
  }
}