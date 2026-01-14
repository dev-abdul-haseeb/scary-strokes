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
  final int totalHoles = 18;
  Map<int, Map<String, int>> holeScores = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Map<String, Map<int, TextEditingController>> strokeControllers = {};
  bool isSaving = false;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    for (var player in widget.players) {
      strokeControllers[player.name] = {};
      for (int hole = 1; hole <= totalHoles; hole++) {
        strokeControllers[player.name]![hole] = TextEditingController();
      }
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
    for (var playerControllers in strokeControllers.values) {
      for (var controller in playerControllers.values) {
        controller.dispose();
      }
    }
    _fadeController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _saveMatchToDatabase() async {
    for (var player in widget.players) {
      for (int hole = 1; hole <= totalHoles; hole++) {
        String strokeText = strokeControllers[player.name]![hole]!.text.trim();
        if (strokeText.isEmpty) {
          _showSnackBar('Please enter strokes for ${player.name} on Hole $hole', isError: true);
          return;
        }

        int? strokes = int.tryParse(strokeText);
        if (strokes == null || strokes < 1) {
          _showSnackBar('Invalid stroke count for ${player.name} on Hole $hole', isError: true);
          return;
        }
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      int matchId = await dbHelper.createMatch(totalHoles);

      for (var player in widget.players) {
        int totalStrokes = 0;
        for (int hole = 1; hole <= totalHoles; hole++) {
          int strokes = int.parse(strokeControllers[player.name]![hole]!.text.trim());
          totalStrokes += strokes;

          if (!holeScores.containsKey(hole)) {
            holeScores[hole] = {};
          }
          holeScores[hole]![player.name] = strokes;
        }

        int playerId = await dbHelper.createPlayerScore(
          matchId: matchId,
          playerName: player.name,
          playerIconIndex: player.iconIndex,
          totalStrokes: totalStrokes,
        );

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
    Map<String, int> finalScores = {};
    for (var player in widget.players) {
      int total = 0;
      for (int hole = 1; hole <= totalHoles; hole++) {
        total += holeScores[hole]![player.name]!;
      }
      finalScores[player.name] = total;
    }

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
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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
    for (int hole = 1; hole <= totalHoles; hole++) {
      String text = strokeControllers[playerName]![hole]!.text.trim();
      if (text.isNotEmpty) {
        total += int.tryParse(text) ?? 0;
      }
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
        child: SafeArea(
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
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                          ).createShader(bounds),
                          child: const Text(
                            'Scorecard',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table/Spreadsheet
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2D2D44).withOpacity(0.8),
                          const Color(0xFF1F1F2E).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF8C00).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            // Player Header
                            Container(
                              width: 110,
                              height: 60,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF8C00).withOpacity(0.4),
                                    const Color(0xFFFFB347).withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                ),
                                border: Border(
                                  right: BorderSide(
                                    color: const Color(0xFFFF8C00).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8C00).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Player',
                                  style: TextStyle(
                                    color: Color(0xFFFFB347),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            // Player names list
                            Expanded(
                              child: SizedBox(
                                width: 110,
                                child: ListView.builder(
                                  itemCount: widget.players.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, playerIndex) {
                                    final player = widget.players[playerIndex];
                                    return Container(
                                      height: 108,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: const Color(0xFFFF8C00).withOpacity(0.25),
                                            width: 1.5,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.white.withOpacity(0.15),
                                            width: 1,
                                          ),
                                        ),
                                        gradient: playerIndex.isEven
                                            ? LinearGradient(
                                          colors: [
                                            const Color(0xFF1A1A2E).withOpacity(0.4),
                                            const Color(0xFF16213E).withOpacity(0.3),
                                          ],
                                        )
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 55,
                                            height: 55,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFFFF8C00).withOpacity(0.6),
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF8C00).withOpacity(0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Image.asset(
                                                'Assets/${player.iconIndex + 1}.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            player.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Scrollable middle section (Hole headers + scores)
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              children: [
                                // Hole number headers
                                Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFF8C00).withOpacity(0.4),
                                        const Color(0xFFFFB347).withOpacity(0.3),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF8C00).withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: List.generate(totalHoles, (index) {
                                      return Container(
                                        width: 70,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Colors.white.withOpacity(0.15),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFFFFB347),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                // Player score rows
                                ...widget.players.asMap().entries.map((entry) {
                                  final playerIndex = entry.key;
                                  final player = entry.value;
                                  return Container(
                                    height: 108,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withOpacity(0.15),
                                          width: 1,
                                        ),
                                      ),
                                      gradient: playerIndex.isEven
                                          ? LinearGradient(
                                        colors: [
                                          const Color(0xFF1A1A2E).withOpacity(0.4),
                                          const Color(0xFF16213E).withOpacity(0.3),
                                        ],
                                      )
                                          : null,
                                    ),
                                    child: Row(
                                      children: List.generate(totalHoles, (holeIndex) {
                                        final hole = holeIndex + 1;
                                        return Container(
                                          width: 70,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: Colors.white.withOpacity(0.08),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF0A0A0F).withOpacity(0.7),
                                                  const Color(0xFF1A1A2E).withOpacity(0.5),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFFF8C00).withOpacity(0.2),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: TextField(
                                              controller: strokeControllers[player.name]![hole],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: '-',
                                                hintStyle: TextStyle(
                                                  color: Colors.white30,
                                                  fontSize: 22,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),

                        // Fixed right section (Total column)
                        Column(
                          children: [
                            // Total Header
                            Container(
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF8C00).withOpacity(0.4),
                                    const Color(0xFFFFB347).withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                ),
                                border: Border(
                                  left: BorderSide(
                                    color: const Color(0xFFFF8C00).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8C00).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Total',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFFFB347),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            // Total scores list
                            Expanded(
                              child: SizedBox(
                                width: 60,
                                child: ListView.builder(
                                  itemCount: widget.players.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, playerIndex) {
                                    final player = widget.players[playerIndex];
                                    return Container(
                                      height: 108,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: const Color(0xFFFF8C00).withOpacity(0.25),
                                            width: 1.5,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.white.withOpacity(0.15),
                                            width: 1,
                                          ),
                                        ),
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFF8C00).withOpacity(0.2),
                                            const Color(0xFFFFB347).withOpacity(0.1),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 0,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFF8C00).withOpacity(0.3),
                                                const Color(0xFFFFB347).withOpacity(0.2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFF8C00).withOpacity(0.4),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF8C00).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${_getTotalStrokes(player.name)}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFFFFB347),
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: isSaving ? null : _saveMatchToDatabase,
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
                            const Icon(
                              Icons.flag,
                              color: Colors.white,
                              size: 24,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            isSaving ? 'Saving...' : 'Finish Match',
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
      ),
    );
  }
}