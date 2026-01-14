
import 'package:flutter/material.dart';
import 'package:scary_strokes/Screens/startGameScreen.dart';

import '../Database/database.dart';

class StartMatchScreen extends StatefulWidget {
  final List<PlayerData> players;

  const StartMatchScreen({super.key, required this.players});

  @override
  State<StartMatchScreen> createState() => _StartMatchScreenState();
}

class _StartMatchScreenState extends State<StartMatchScreen> with TickerProviderStateMixin {
  int currentHole = 1;
  final int totalHoles = 18;
  Map<int, Map<String, int>> holeScores = {}; // {holeNumber: {playerName: strokes}}
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Map<String, TextEditingController> strokeControllers = {};
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers for each player
    for (var player in widget.players) {
      strokeControllers[player.name] = TextEditingController();
    }

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    for (var controller in strokeControllers.values) {
      controller.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  void _saveHoleScore() {
    // Validate all inputs
    Map<String, int> currentHoleScores = {};
    for (var player in widget.players) {
      String strokeText = strokeControllers[player.name]!.text.trim();
      if (strokeText.isEmpty) {
        _showSnackBar('Please enter strokes for ${player.name}', isError: true);
        return;
      }

      int? strokes = int.tryParse(strokeText);
      if (strokes == null || strokes < 1) {
        _showSnackBar('Invalid stroke count for ${player.name}. Must be at least 1.', isError: true);
        return;
      }

      // Additional check to prevent zero values
      if (strokes == 0) {
        _showSnackBar('Stroke count cannot be 0 for ${player.name}', isError: true);
        return;
      }

      currentHoleScores[player.name] = strokes;
    }

    // Save scores for current hole
    setState(() {
      holeScores[currentHole] = currentHoleScores;

      if (currentHole < totalHoles) {
        currentHole++;
        // Clear inputs for next hole
        for (var controller in strokeControllers.values) {
          controller.clear();
        }
        _showSnackBar('Hole ${currentHole-1} recorded', isError: false);
      } else {
        // Game finished
        _saveMatchToDatabase();
      }
    });
  }
  Future<void> _saveMatchToDatabase() async {
    setState(() {
      isSaving = true;
    });

    try {
      final dbHelper = DatabaseHelper.instance;

      // Create match record
      int matchId = await dbHelper.createMatch(totalHoles);

      // Save player scores
      for (var player in widget.players) {
        int totalStrokes = 0;
        for (int hole = 1; hole <= totalHoles; hole++) {
          totalStrokes += holeScores[hole]![player.name]!;
        }

        int playerId = await dbHelper.createPlayerScore(
          matchId: matchId,
          playerName: player.name,
          playerIconIndex: player.iconIndex,
          totalStrokes: totalStrokes,
        );

        // Save hole-by-hole scores
        for (int hole = 1; hole <= totalHoles; hole++) {
          await dbHelper.createHoleScore(
            playerScoreId: playerId,
            holeNumber: hole,
            strokes: holeScores[hole]![player.name]!,
          );
        }
      }

      setState(() {
        isSaving = false;
      });

      _showMatchSummary();
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      _showSnackBar('Error saving match: $e', isError: true);
    }
  }

  void _showMatchSummary() {
    // Calculate final scores
    Map<String, int> finalScores = {};
    for (var player in widget.players) {
      int total = 0;
      for (int hole = 1; hole <= totalHoles; hole++) {
        total += holeScores[hole]![player.name]!;
      }
      finalScores[player.name] = total;
    }

    // Sort players by score (lowest first)
    var sortedPlayers = widget.players.toList()
      ..sort((a, b) => finalScores[a.name]!.compareTo(finalScores[b.name]!));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D2D44).withOpacity(0.95),
                const Color(0xFF1F1F2E).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF8C00).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFB347),
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Match Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Winner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF8C00).withOpacity(0.2),
                      const Color(0xFFFFB347).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF8C00).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF8C00),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'Assets/${sortedPlayers[0].iconIndex + 1}.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏆 Winner',
                            style: TextStyle(
                              color: Color(0xFFFFB347),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            sortedPlayers[0].name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${finalScores[sortedPlayers[0].name]}',
                      style: const TextStyle(
                        color: Color(0xFFFFB347),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Other players
              ...sortedPlayers.skip(1).map((player) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1A2E).withOpacity(0.6),
                        const Color(0xFF0A0A0F).withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'Assets/${player.iconIndex + 1}.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${finalScores[player.name]}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to start screen
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFE63946)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C00).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Finish',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE63946) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int _getTotalStrokes(String playerName) {
    int total = 0;
    for (int hole = 1; hole < currentHole; hole++) {
      total += holeScores[hole]![playerName] ?? 0;
    }
    return total;
  }

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
        child: Stack(
          children: [
            // Background effects
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF8C00).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7B2CBF).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF2D2D44),
                                  title: const Text(
                                    'Exit Match?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'All progress will be lost.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Exit',
                                        style: TextStyle(color: Color(0xFFE63946)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2D2D44).withOpacity(0.6),
                                    const Color(0xFF1F1F2E).withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFFFF8C00).withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFFFF8C00),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Hole $currentHole',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8C00).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '$currentHole of $totalHoles',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFFB347),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Progress indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (currentHole - 1) / totalHoles,
                          backgroundColor: const Color(0xFF2D2D44),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF8C00),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Player stroke inputs
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: widget.players.length,
                        itemBuilder: (context, index) {
                          final player = widget.players[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF2D2D44).withOpacity(0.6),
                                  const Color(0xFF1F1F2E).withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF8C00).withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Player avatar
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color(0xFFFF8C00).withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.asset(
                                      'Assets/${player.iconIndex + 1}.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Player info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total: ${_getTotalStrokes(player.name)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Stroke input
                                Container(
                                  width: 80,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF1A1A2E).withOpacity(0.8),
                                        const Color(0xFF0A0A0F).withOpacity(0.6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: strokeControllers[player.name],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                        color: Colors.white30,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Submit button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: GestureDetector(
                        onTap: isSaving ? null : _saveHoleScore,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSaving
                                  ? [
                                const Color(0xFF666666),
                                const Color(0xFF444444),
                              ]
                                  : [
                                const Color(0xFFFF8C00),
                                const Color(0xFFE63946),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSaving)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  currentHole == totalHoles
                                      ? Icons.flag
                                      : Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              const SizedBox(width: 12),
                              Text(
                                isSaving
                                    ? 'Saving...'
                                    : currentHole == totalHoles
                                    ? 'Finish Match'
                                    : 'Next Hole',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}