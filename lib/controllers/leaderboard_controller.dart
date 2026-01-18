import 'dart:io';
import 'package:flutter/material.dart';
import '../Database/database.dart';

class WinnerData {
  final String playerName;
  final int playerIconIndex;
  final String? customImagePath;
  final int totalStrokes;
  final String matchDate;
  final int matchId;

  WinnerData({
    required this.customImagePath,
    required this.playerName,
    required this.playerIconIndex,
    required this.totalStrokes,
    required this.matchDate,
    required this.matchId,
  });
}

class LeaderboardController extends ChangeNotifier {
  // State
  List<WinnerData> winners = [];
  bool isLoading = true;
  String? errorMessage;

  // Animation
  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  // Constructor
  LeaderboardController({required TickerProvider vsync}) {
    _initializeAnimations(vsync);
    loadWinners();
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
  Future<void> loadWinners() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final winnersList = await dbHelper.getAllWinners();

      List<WinnerData> loadedWinners = [];

      for (var winner in winnersList) {
        loadedWinners.add(WinnerData(
          customImagePath: winner['custom_image_path'] as String?,
          playerName: winner['player_name'] as String,
          playerIconIndex: winner['player_icon_index'] as int,
          totalStrokes: winner['total_strokes'] as int,
          matchDate: winner['date'] as String,
          matchId: winner['match_id'] as int,
        ));
      }

      // Sort by score (lowest first)
      loadedWinners.sort((a, b) => a.totalStrokes.compareTo(b.totalStrokes));

      setState(() {
        winners = loadedWinners;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading leaderboard: $e';
      });
    }
  }

  void refresh() => loadWinners();

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Color getRankColor(int rank) {
    switch (rank) {
      case 0: return const Color(0xFFFFD700); // Gold
      case 1: return const Color(0xFFC0C0C0); // Silver
      case 2: return const Color(0xFFCD7F32); // Bronze
      default: return const Color(0xFFFF8C00); // Orange
    }
  }

  String getRankEmoji(int rank) {
    switch (rank) {
      case 0: return '🥇';
      case 1: return '🥈';
      case 2: return '🥉';
      default: return '🏅';
    }
  }

  bool isTopThree(int rank) => rank < 3;

  // Helper for state updates
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // Cleanup
  void disposeControllers() {
    fadeController.dispose();
  }
}