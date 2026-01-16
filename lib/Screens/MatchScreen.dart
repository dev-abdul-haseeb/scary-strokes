import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scary_strokes/Screens/homeScreen.dart';
import 'package:scary_strokes/Screens/startGameScreen.dart';
import '../Database/database.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class StartMatchScreen extends StatefulWidget {
  final List<PlayerData> players;
  const StartMatchScreen({super.key, required this.players});

  @override
  State<StartMatchScreen> createState() => _StartMatchScreenState();
}

class _StartMatchScreenState extends State<StartMatchScreen>
    with TickerProviderStateMixin {
  final int totalHoles = 18;
  Map<int, Map<String, int>> holeScores = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;
  late ConfettiController _holeInOneConfettiController;

  final Map<int, int> holeParValues = {
    1: 3,
    2: 2,
    3: 3,
    4: 2,
    5: 2,
    6: 3,
    7: 2,
    8: 2,
    9: 3,
    10: 2,
    11: 2,
    12: 3,
    13: 2,
    14: 2,
    15: 3,
    16: 2,
    17: 3,
    18: 3,
  };

  Map<String, Map<int, TextEditingController>> strokeControllers = {};
  bool isSaving = false;
  final ScrollController _horizontalScrollController = ScrollController();
  int _currentHoleIndex = 0;

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
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _holeInOneConfettiController = ConfettiController(
      duration: const Duration(seconds: 3),
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
    _confettiController.dispose();
    _holeInOneConfettiController.dispose();
    super.dispose();
  }

  void _showNumberWheel(int playerIndex, int hole) {
    final player = widget.players[playerIndex];
    final controller = strokeControllers[player.name]![hole]!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NumberWheelDialog(
          currentValue: controller.text.isNotEmpty
              ? int.parse(controller.text)
              : null,
          onNumberSelected: (number) {
            controller.text = number.toString();
            setState(() {});
            Navigator.pop(context);

            // Check for hole in one
            if (number == 1) {
              _showHoleInOneCelebration(player, hole);
            }

            _autoScrollToHole(hole);
          },
        ),
      ),
    );
  }

  void _showHoleInOneCelebration(PlayerData player, int hole) {
    _holeInOneConfettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _holeInOneConfettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.yellow,
                Colors.orange,
                Colors.red,
                Colors.pink,
              ],
              numberOfParticles: 30,
            ),
          ),
          Dialog(
            backgroundColor: Colors.transparent,
            child: HoleInOneCelebrationDialog(
              player: player,
              holeNumber: hole,
              onClose: () {
                _holeInOneConfettiController.stop();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _autoScrollToHole(int currentHole) {
    bool allPlayersHaveScore = true;
    for (var player in widget.players) {
      String score = strokeControllers[player.name]![currentHole]!.text.trim();
      if (score.isEmpty) {
        allPlayersHaveScore = false;
        break;
      }
    }
    if (allPlayersHaveScore && currentHole < totalHoles) {
      _currentHoleIndex = currentHole;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _horizontalScrollController.animateTo(
          _currentHoleIndex * 70.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _saveMatchToDatabase() async {
    for (var player in widget.players) {
      for (int hole = 1; hole <= totalHoles; hole++) {
        String strokeText = strokeControllers[player.name]![hole]!.text.trim();
        if (strokeText.isEmpty) {
          _showSnackBar(
            'Please enter strokes for ${player.name} on Hole $hole',
            isError: true,
          );
          return;
        }
        int? strokes = int.tryParse(strokeText);
        if (strokes == null || strokes < 1) {
          _showSnackBar(
            'Invalid stroke count for ${player.name} on Hole $hole',
            isError: true,
          );
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
          int strokes = int.parse(
            strokeControllers[player.name]![hole]!.text.trim(),
          );
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
      _showWinnerCelebration();
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      _showSnackBar('Error saving match: $e', isError: true);
    }
  }

  void _showWinnerCelebration() {
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

    // Find all winners (players with the lowest score)
    final winningScore = finalScores[sortedPlayers.first.name]!;
    final winners = sortedPlayers.where((player) => finalScores[player.name] == winningScore).toList();

    _confettiController.play();

    // Check if there are multiple winners
    if (winners.length > 1) {
      // Show multiple winners dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
            Dialog(
              backgroundColor: Colors.transparent,
              child: MultipleWinnersCelebrationDialog(
                winners: winners,
                winnerScore: winningScore,
                onClose: () {
                  _confettiController.stop();
                  Navigator.pop(context);
                  _showFinalLeaderboard(sortedPlayers, finalScores);
                },
              ),
            ),
          ],
        ),
      );
    } else {
      // Show single winner dialog (original behavior)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
            Dialog(
              backgroundColor: Colors.transparent,
              child: WinnerCelebrationDialog(
                winner: winners.first,
                winnerScore: winningScore,
                onClose: () {
                  _confettiController.stop();
                  Navigator.pop(context);
                  _showFinalLeaderboard(sortedPlayers, finalScores);
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showFinalLeaderboard(
      List<PlayerData> sortedPlayers,
      Map<String, int> finalScores,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinalLeaderboardDialog(
        players: sortedPlayers,
        finalScores: finalScores,
        onFinish: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
        },
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    final screenWidth = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: screenWidth * 0.04)),
        backgroundColor: isError
            ? const Color(0xFFE63946)
            : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        margin: EdgeInsets.all(screenWidth * 0.04),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final cellWidth = screenWidth > 600 ? 80.0 : (isSmallScreen ? 65.0 : 70.0);
    final playerColumnWidth = screenWidth > 600
        ? 140.0
        : (isSmallScreen ? 100.0 : 110.0);
    final totalColumnWidth = screenWidth > 600
        ? 80.0
        : (isSmallScreen ? 65.0 : 60.0);
    final cellHeight = screenWidth > 600
        ? 115.0
        : (isSmallScreen ? 90.0 : 106.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF2D2D44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.04,
                                    ),
                                  ),
                                  title: Text(
                                    'Exit Match?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05,
                                    ),
                                  ),
                                  content: Text(
                                    'All progress will be lost.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Exit',
                                        style: TextStyle(
                                          color: const Color(0xFFE63946),
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2D2D44).withValues(alpha: 0.6),
                                    const Color(0xFF1F1F2E).withValues(alpha: 0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.04,
                                ),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: const Color(0xFFFFD700),
                                size: screenWidth * 0.06,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFB347)],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Scorecard',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.07,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  'Scary Strokes - Indoor Blacklight Mini-Golf',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: screenHeight * 0.25,
                        ),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2D2D44).withValues(alpha: 0.8),
                                const Color(0xFF1F1F2E).withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: playerColumnWidth,
                                    height: 80.0,
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.015,
                                      horizontal: screenWidth * 0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFFFD700).withValues(alpha: 0.4),
                                          const Color(0xFFFFB347).withValues(alpha: 0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(screenWidth * 0.05),
                                      ),
                                      border: Border(
                                        right: BorderSide(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Player',
                                        style: TextStyle(
                                          color: const Color(0xFFFFB347),
                                          fontSize: screenWidth > 600 ? 20.0 : 18.0,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...widget.players.asMap().entries.map((entry) {
                                    final playerIndex = entry.key;
                                    final player = entry.value;
                                    return Container(
                                      height: cellHeight,
                                      width: playerColumnWidth,
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.01,
                                        horizontal: screenWidth * 0.025,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                                            width: 1.5,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        gradient: playerIndex.isEven
                                            ? LinearGradient(
                                          colors: [
                                            const Color(0xFF1A1A2E).withValues(alpha: 0.4),
                                            const Color(0xFF16213E).withValues(alpha: 0.3),
                                          ],
                                        )
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: screenWidth > 600
                                                ? 65.0
                                                : (isSmallScreen ? 45.0 : 55.0),
                                            height: screenWidth > 600
                                                ? 65.0
                                                : (isSmallScreen ? 45.0 : 55.0),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                (screenWidth > 600 ? 65.0 : (isSmallScreen ? 45.0 : 55.0)) * 0.25,
                                              ),
                                              border: Border.all(
                                                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(
                                                (screenWidth > 600 ? 65.0 : (isSmallScreen ? 45.0 : 55.0)) * 0.2,
                                              ),
                                              child: _buildPlayerIcon(player),
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.008),
                                          Text(
                                            player.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth > 600
                                                  ? 16.0
                                                  : (isSmallScreen ? 12.0 : 14.0),
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
                                  }).toList(),
                                ],
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFFFFD700).withValues(alpha: 0.4),
                                              const Color(0xFFFFB347).withValues(alpha: 0.3),
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          children: List.generate(totalHoles, (index) {
                                            return SizedBox(
                                              width: cellWidth,
                                              child: Center(
                                                child: Text(
                                                  'Hole ${index + 1}',
                                                  style: TextStyle(
                                                    color: const Color(0xFFFFB347),
                                                    fontSize: screenWidth > 600
                                                        ? 14.0
                                                        : (isSmallScreen ? 11.0 : 12.0),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                              const Color(0xFF2E7D32).withValues(alpha: 0.2),
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          children: List.generate(totalHoles, (index) {
                                            final hole = index + 1;
                                            final parValue = holeParValues[hole] ?? 2;
                                            return Container(
                                              width: cellWidth,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Colors.white.withValues(alpha: 0.15),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        'PAR: $parValue',
                                                        style: TextStyle(
                                                          color: const Color(0xFF4CAF50),
                                                          fontSize: screenWidth > 600
                                                              ? 12.0
                                                              : (isSmallScreen ? 9.0 : 10.0),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      ...widget.players.asMap().entries.map((entry) {
                                        final playerIndex = entry.key;
                                        final player = entry.value;
                                        return Container(
                                          height: cellHeight,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.white.withValues(alpha: 0.15),
                                                width: 1,
                                              ),
                                            ),
                                            gradient: playerIndex.isEven
                                                ? LinearGradient(
                                              colors: [
                                                const Color(0xFF1A1A2E).withValues(alpha: 0.4),
                                                const Color(0xFF16213E).withValues(alpha: 0.3),
                                              ],
                                            )
                                                : null,
                                          ),
                                          child: Row(
                                            children: List.generate(totalHoles, (holeIndex) {
                                              final hole = holeIndex + 1;
                                              return GestureDetector(
                                                onTap: () => _showNumberWheel(playerIndex, hole),
                                                child: Container(
                                                  width: cellWidth,
                                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035, vertical: screenHeight*0.028),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color: Colors.white.withValues(alpha: 0.08),
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          const Color(0xFF0A0A0F).withValues(alpha: 0.7),
                                                          const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                                                        ],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                                      border: Border.all(
                                                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                                        width: 1.5,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withValues(alpha: 0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        strokeControllers[player.name]![hole]!.text.isNotEmpty
                                                            ? strokeControllers[player.name]![hole]!.text
                                                            : '-',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: screenWidth > 600
                                                              ? 24.0
                                                              : (isSmallScreen ? 18.0 : 22.0),
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
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
                              Column(
                                children: [
                                  Container(
                                    width: totalColumnWidth,
                                    height: 80.0,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFFFD700).withValues(alpha: 0.4),
                                          const Color(0xFFFFB347).withValues(alpha: 0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(screenWidth * 0.05),
                                      ),
                                      border: Border(
                                        left: BorderSide(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Total',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: const Color(0xFFFFB347),
                                            fontSize: screenWidth > 600 ? 18.0 : 15.0,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Column(
                                          children: [
                                            Text(
                                              'PAR 9: 20',
                                              style: TextStyle(
                                                color: const Color(0xFF4CAF50),
                                                fontSize: screenWidth > 600
                                                    ? 12.0
                                                    : (isSmallScreen ? 9.0 : 10.0),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'PAR 18: 43',
                                              style: TextStyle(
                                                color: const Color(0xFF4CAF50),
                                                fontSize: screenWidth > 600
                                                    ? 12.0
                                                    : (isSmallScreen ? 9.0 : 10.0),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...widget.players.asMap().entries.map((entry) {
                                    final playerIndex = entry.key;
                                    final player = entry.value;
                                    return Container(
                                      height: cellHeight,
                                      width: totalColumnWidth,
                                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                                            width: 1.5,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFFD700).withValues(alpha: 0.2),
                                            const Color(0xFFFFB347).withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.02,
                                            vertical: screenHeight * 0.002,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFFD700).withValues(alpha: 0.3),
                                                const Color(0xFFFFB347).withValues(alpha: 0.2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                            border: Border.all(
                                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${_getTotalStrokes(player.name)}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: const Color(0xFFFFB347),
                                              fontSize: screenWidth > 600
                                                  ? 32.0
                                                  : (isSmallScreen ? 24.0 : 28.0),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0A0A0F).withValues(alpha: 0.95),
                          const Color(0xFF0A0A0F),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.01,
                            horizontal: screenWidth * 0.05,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Scary Strokes - Southern Marylands ULTIMATE family fun experience!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: screenWidth * 0.025,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.facebook,
                                    color: Colors.blue,
                                    size: screenWidth * 0.04,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'facebook.com/scarystrokes',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: screenWidth * 0.025,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.04),
                                  Icon(
                                    Icons.flag,
                                    color: Colors.red,
                                    size: screenWidth * 0.04,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    '@ScaryStrokes',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: screenWidth * 0.025,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'VOTED #1 "Best Fun Things to Do" AND "Best Date Night Fun" in Waldorf MD',
                                style: TextStyle(
                                  color: const Color(0xFFFFD700),
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: GestureDetector(
                            onTap: isSaving ? null : _saveMatchToDatabase,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.022,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSaving
                                      ? [
                                    const Color(0xFF666666),
                                    const Color(0xFF444444),
                                  ]
                                      : [
                                    const Color(0xFFFFD700),
                                    const Color(0xFFE63946),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSaving)
                                    SizedBox(
                                      width: screenWidth * 0.05,
                                      height: screenWidth * 0.05,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.flag,
                                      color: Colors.white,
                                      size: screenWidth * 0.06,
                                    ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    isSaving ? 'Saving...' : 'Finish Match',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.045,
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
        ),
      ),
    );
  }

  Widget _buildPlayerIcon(PlayerData player) {
    if (player.customImagePath == null || player.customImagePath!.isEmpty) {
      return Image.asset(
        'Assets/${player.iconIndex + 1}.png',
        fit: BoxFit.cover,
      );
    }
    return FutureBuilder<bool>(
      future: _checkFileExists(player.customImagePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          return Image.file(
            File(player.customImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'Assets/${player.iconIndex + 1}.png',
                fit: BoxFit.cover,
              );
            },
          );
        } else {
          return Image.asset(
            'Assets/${player.iconIndex + 1}.png',
            fit: BoxFit.cover,
          );
        }
      },
    );
  }

  Future<bool> _checkFileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      print('Error checking file: $e');
      return false;
    }
  }
}

// Hole in One Celebration Dialog
class HoleInOneCelebrationDialog extends StatelessWidget {
  final PlayerData player;
  final int holeNumber;
  final VoidCallback onClose;

  const HoleInOneCelebrationDialog({
    super.key,
    required this.player,
    required this.holeNumber,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.85,
        maxHeight: screenHeight * 0.7,
      ),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.95),
            Colors.orange.withValues(alpha: 0.95),
            Colors.deepOrange.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.08),
        border: Border.all(color: Colors.yellow, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '⛳ HOLE IN ONE! ⛳',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.09,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: const [
                    Shadow(blurRadius: 10, color: Colors.black54),
                    Shadow(blurRadius: 20, color: Colors.black38),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'AMAZING SHOT!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: screenWidth * 0.25,
                    height: screenWidth * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.125),
                      border: Border.all(
                        color: Colors.yellow,
                        width: 5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withValues(alpha: 0.6),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.12),
                      child: player.customImagePath != null
                          ? Image.file(
                        File(player.customImagePath!),
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        'Assets/${player.iconIndex + 1}.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      child: Text(
                        player.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: const [
                            Shadow(blurRadius: 5, color: Colors.black45),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'scored a perfect shot on',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      'HOLE $holeNumber',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.12,
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberWheelDialog extends StatefulWidget {
  final int? currentValue;
  final Function(int) onNumberSelected;
  const NumberWheelDialog({
    super.key,
    this.currentValue,
    required this.onNumberSelected,
  });
  @override
  State<NumberWheelDialog> createState() => _NumberWheelDialogState();
}

class _NumberWheelDialogState extends State<NumberWheelDialog> {
  int _selectedNumber = 1;
  List<int> _numbers = [];

  @override
  void initState() {
    super.initState();
    _selectedNumber = widget.currentValue ?? 1;
    _numbers = List.generate(6, (index) => index + 1);
  }

  void _handleTap(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double dx = localPosition.dx - center.dx;
    final double dy = localPosition.dy - center.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);

    if (distance < size.width * 0.15) {
      return;
    }

    double angle = math.atan2(dy, dx);
    angle = angle * 180 / math.pi;

    if (angle < 0) angle += 360;
    angle = (angle + 90) % 360;

    final double segmentAngle = 360 / _numbers.length;
    int selectedIndex = (angle / segmentAngle).floor();
    if (selectedIndex >= _numbers.length) {
      selectedIndex = 0;
    }

    setState(() {
      _selectedNumber = _numbers[selectedIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth * 0.8;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        _handleTap(localPosition, Size(size, size));
      },
      onTap: () {
        widget.onNumberSelected(_selectedNumber);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D44).withValues(alpha: 0.95),
              const Color(0xFF1F1F2E).withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.1),
          border: Border.all(
            color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            ..._buildPieSegments(size),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFE63946)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_selectedNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPieSegments(double size) {
    final List<Color> colors = [
      const Color(0xFFFF5252),
      const Color(0xFFFF9800),
      const Color(0xFFFFEB3B),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];

    return _numbers.asMap().entries.map((entry) {
      final index = entry.key;
      final number = entry.value;
      final angle = 2 * math.pi / _numbers.length;
      final startAngle = index * angle - math.pi / 2;
      final isSelected = _selectedNumber == number;
      final color = colors[index % colors.length];

      return Positioned.fill(
        child: CustomPaint(
          painter: PieSegmentPainter(
            startAngle: startAngle,
            sweepAngle: angle,
            color: color.withValues(alpha: isSelected ? 1.0 : 0.7),
            isSelected: isSelected,
            segmentIndex: index,
            number: number,
            size: size,
          ),
        ),
      );
    }).toList();
  }
}

class PieSegmentPainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final bool isSelected;
  final int segmentIndex;
  final int number;
  final double size;

  PieSegmentPainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    required this.isSelected,
    required this.segmentIndex,
    required this.number,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );

    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: this.size * 0.08,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final double textRadius = radius * 0.6;
    final double textAngle = startAngle + sweepAngle / 2;
    final Offset textPosition = Offset(
      center.dx + textRadius * math.cos(textAngle),
      center.dy + textRadius * math.sin(textAngle),
    );

    canvas.save();
    canvas.translate(textPosition.dx, textPosition.dy);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WinnerCelebrationDialog extends StatelessWidget {
  final PlayerData winner;
  final int winnerScore;
  final VoidCallback onClose;
  const WinnerCelebrationDialog({
    super.key,
    required this.winner,
    required this.winnerScore,
    required this.onClose,
  });
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.85,
        maxHeight: screenHeight * 0.8,  // Changed from 0.7 to 0.8
      ),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.9),
            Colors.blue.withValues(alpha: 0.9),
            Colors.green.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.08),
        border: Border.all(color: const Color(0xFFFFD700), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(  // ADD THIS to make content scrollable
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: const Color(0xFFFFD700),
              size: screenWidth * 0.15,
            ),
            SizedBox(height: screenHeight * 0.015),  // Reduced from 0.02
            FittedBox(  // ADD THIS for responsive text
              fit: BoxFit.scaleDown,
              child: Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),  // Reduced from 0.03
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.3),
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                children: [
                  FittedBox(  // ADD THIS
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'The Winner is',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),  // Reduced from 0.02
                  Container(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.1),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.1),
                      child: winner.customImagePath != null
                          ? Image.file(
                        File(winner.customImagePath!),
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        'Assets/${winner.iconIndex + 1}.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),  // Reduced from 0.02
                  FittedBox(  // ADD THIS
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      child: Text(
                        winner.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),  // Reduced from 0.01
                  FittedBox(  // ADD THIS
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'with a score of',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),  // Reduced from 0.01
                  Text(
                    '$winnerScore',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.025),  // Reduced from 0.04
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.018,  // Reduced from 0.02
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: FittedBox(  // ADD THIS
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'VIEW LEADERBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinalLeaderboardDialog extends StatelessWidget {
  final List<PlayerData> players;
  final Map<String, int> finalScores;
  final VoidCallback onFinish;
  const FinalLeaderboardDialog({
    super.key,
    required this.players,
    required this.finalScores,
    required this.onFinish,
  });
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    List<PlayerData> topThree = players.length >= 3
        ? players.sublist(0, 3)
        : players;
    List<PlayerData> otherPlayers = players.length > 3
        ? players.sublist(3)
        : [];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.9,
          maxHeight: screenHeight * 0.9,
        ),
        padding: EdgeInsets.all(screenWidth * 0.06),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D44).withValues(alpha: 0.95),
              const Color(0xFF1F1F2E).withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.08),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FINAL LEADERBOARD',
              style: TextStyle(
                color: const Color(0xFFFFB347),
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (topThree.length >= 2)
                  _buildPodiumPlayer(
                    player: topThree[1],
                    score: finalScores[topThree[1].name]!,
                    place: 2,
                    medalColor: Colors.grey,
                    height: screenHeight * 0.15,
                    screenWidth: screenWidth,
                  ),
                if (topThree.isNotEmpty)
                  _buildPodiumPlayer(
                    player: topThree[0],
                    score: finalScores[topThree[0].name]!,
                    place: 1,
                    medalColor: Color(0x00ffd100), // Changed to Colors.gold
                    height: screenHeight * 0.2,
                    screenWidth: screenWidth,
                  ),
                if (topThree.length >= 3)
                  _buildPodiumPlayer(
                    player: topThree[2],
                    score: finalScores[topThree[2].name]!,
                    place: 3,
                    medalColor: const Color(0xFFCD7F32),
                    height: screenHeight * 0.12,
                    screenWidth: screenWidth,
                  ),
              ],
            ),
            SizedBox(height: screenHeight * 0.04),
            if (otherPlayers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other Players',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ...otherPlayers.map((player) {
                    return Container(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                            const Color(0xFF0A0A0F).withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.02,
                              ),
                              child: player.customImagePath != null
                                  ? Image.file(
                                File(player.customImagePath!),
                                fit: BoxFit.cover,
                              )
                                  : Image.asset(
                                'Assets/${player.iconIndex + 1}.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Text(
                              player.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${finalScores[player.name]}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            '#${players.indexOf(player) + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            SizedBox(height: screenHeight * 0.04),
            GestureDetector(
              onTap: onFinish,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFE63946)],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  'FINISH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumPlayer({
    required PlayerData player,
    required int score,
    required int place,
    required Color medalColor,
    required double height,
    required double screenWidth,
  }) {
    return Column(
      children: [
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.1,
          decoration: BoxDecoration(
            color: medalColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              place == 1
                  ? '🥇'
                  : place == 2
                  ? '🥈'
                  : '🥉',
              style: TextStyle(fontSize: screenWidth * 0.05),
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Container(
          width: screenWidth * 0.2,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                medalColor.withValues(alpha: 0.3),
                medalColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(
              color: medalColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  border: Border.all(color: medalColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: player.customImagePath != null
                      ? Image.file(
                    File(player.customImagePath!),
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    'Assets/${player.iconIndex + 1}.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                player.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                '$score',
                style: TextStyle(
                  color: medalColor,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MultipleWinnersCelebrationDialog extends StatelessWidget {
  final List<PlayerData> winners;
  final int winnerScore;
  final VoidCallback onClose;

  const MultipleWinnersCelebrationDialog({
    super.key,
    required this.winners,
    required this.winnerScore,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.9,
        maxHeight: screenHeight * 0.85,
      ),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.9),
            Colors.blue.withValues(alpha: 0.9),
            Colors.green.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.08),
        border: Border.all(color: const Color(0xFFFFD700), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: const Color(0xFFFFD700),
              size: screenWidth * 0.15,
            ),
            SizedBox(height: screenHeight * 0.015),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "IT'S A TIE!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.09,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: const [Shadow(blurRadius: 8, color: Colors.black45)],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.3),
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      winners.length == 2 ? 'The Winners are' : 'The Winners are',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Display all winners
                  ...winners.map((winner) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                      child: Column(
                        children: [
                          Container(
                            width: screenWidth * 0.18,
                            height: screenWidth * 0.18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(screenWidth * 0.09),
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(screenWidth * 0.09),
                              child: winner.customImagePath != null
                                  ? Image.file(
                                File(winner.customImagePath!),
                                fit: BoxFit.cover,
                              )
                                  : Image.asset(
                                'Assets/${winner.iconIndex + 1}.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                              child: Text(
                                winner.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: screenHeight * 0.01),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'with a score of',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  Text(
                    '$winnerScore',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.018,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'VIEW LEADERBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}