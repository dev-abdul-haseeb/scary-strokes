import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Widgets/match_screen_dialouges.dart';
import '../controllers/match_controller.dart';
import '../model/player_model.dart';
import 'package:confetti/confetti.dart';

import 'home_screen.dart';

class StartMatchScreen extends StatefulWidget {
  final List<PlayerData> players;
  const StartMatchScreen({super.key, required this.players});

  @override
  State<StartMatchScreen> createState() => _StartMatchScreenState();
}

class _StartMatchScreenState extends State<StartMatchScreen> with TickerProviderStateMixin {
  late MatchController _matchController;

  @override
  void initState() {
    super.initState();
    _matchController = MatchController(
      players: widget.players,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _matchController.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _matchController,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Consumer<MatchController>(
              builder: (context, controller, child) {
                return FadeTransition(
                  opacity: controller.fadeAnimation,
                  child: _buildContent(context, controller),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MatchController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    final cellWidth = screenWidth > 600 ? 80.0 : (isSmallScreen ? 65.0 : 70.0);
    final playerColumnWidth = screenWidth > 600 ? 140.0 : (isSmallScreen ? 100.0 : 110.0);
    final totalColumnWidth = screenWidth > 600 ? 80.0 : (isSmallScreen ? 65.0 : 60.0);
    final cellHeight = screenWidth > 600 ? 115.0 : (isSmallScreen ? 90.0 : 106.0);

    return Stack(
      children: [
        Column(
          children: [
            _buildAppBar(context, screenWidth, screenHeight),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: screenHeight * 0.25),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2D2D44).withValues(alpha:0.8),
                        const Color(0xFF1F1F2E).withValues(alpha:0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha:0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Players Column
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
                                  const Color(0xFFFFD700).withValues(alpha:0.4),
                                  const Color(0xFFFFB347).withValues(alpha:0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(screenWidth * 0.05),
                              ),
                              border: Border(
                                right: BorderSide(
                                  color: const Color(0xFFFFD700).withValues(alpha:0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Player',
                                style: TextStyle(
                                  color: const Color(0xFFFFB347),
                                  fontSize: screenWidth > 600 ? 20.0 : 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          ...controller.players.asMap().entries.map((entry) {
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
                                    color: const Color(0xFFFFD700).withValues(alpha:0.25),
                                    width: 1.5,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha:0.15),
                                    width: 1,
                                  ),
                                ),
                                gradient: playerIndex.isEven
                                    ? LinearGradient(
                                  colors: [
                                    const Color(0xFF1A1A2E).withValues(alpha:0.4),
                                    const Color(0xFF16213E).withValues(alpha:0.3),
                                  ],
                                )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: screenWidth > 600 ? 65.0 : (isSmallScreen ? 45.0 : 55.0),
                                    height: screenWidth > 600 ? 65.0 : (isSmallScreen ? 45.0 : 55.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withValues(alpha:0.6),
                                        width: 2.5,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildPlayerIcon(player),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.008),
                                  Text(
                                    player.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth > 600 ? 16.0 : (isSmallScreen ? 12.0 : 14.0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),

                      // Holes Scores
                      Expanded(
                        child: SingleChildScrollView(
                          controller: controller.horizontalScrollController, // ✅ Fixed: Added controller
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFFD700).withValues(alpha:0.4),
                                      const Color(0xFFFFB347).withValues(alpha:0.3),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: List.generate(controller.totalHoles, (index) {
                                    return SizedBox(
                                      width: cellWidth,
                                      child: Center(
                                        child: Text(
                                          'Hole ${index + 1}',
                                          style: TextStyle(
                                            color: const Color(0xFFFFB347),
                                            fontSize: screenWidth > 600 ? 14.0 : (isSmallScreen ? 11.0 : 12.0),
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
                                      const Color(0xFF4CAF50).withValues(alpha:0.3),
                                      const Color(0xFF2E7D32).withValues(alpha:0.2),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: List.generate(controller.totalHoles, (index) {
                                    final hole = index + 1;
                                    final parValue = controller.holeParValues[hole] ?? 2;
                                    return Container(
                                      width: cellWidth,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.white.withValues(alpha:0.15),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'PAR: $parValue',
                                          style: TextStyle(
                                            color: const Color(0xFF4CAF50),
                                            fontSize: screenWidth > 600 ? 12.0 : (isSmallScreen ? 9.0 : 10.0),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              ...controller.players.asMap().entries.map((entry) {
                                final playerIndex = entry.key;
                                final player = entry.value;
                                return Container(
                                  height: cellHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white.withValues(alpha:0.15),
                                        width: 1,
                                      ),
                                    ),
                                    gradient: playerIndex.isEven
                                        ? LinearGradient(
                                      colors: [
                                        const Color(0xFF1A1A2E).withValues(alpha:0.4),
                                        const Color(0xFF16213E).withValues(alpha:0.3),
                                      ],
                                    )
                                        : null,
                                  ),
                                  child: Row(
                                    children: List.generate(controller.totalHoles, (holeIndex) {
                                      final hole = holeIndex + 1;
                                      return Stack(
                                        children: [
                                          // ✅ FIXED: Direct tap calls controller method
                                          GestureDetector(
                                            onTap: () => controller.showNumberWheel(context, playerIndex, hole),
                                            child: Container(
                                              width: cellWidth,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: screenWidth * 0.035,
                                                vertical: screenHeight * 0.028,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Colors.white.withValues(alpha:0.08),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                                  border: Border.all(
                                                    color: const Color(0xFFFFD700).withValues(alpha:0.2),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    controller.strokeControllers[player.name]![hole]!.text.isNotEmpty
                                                        ? controller.strokeControllers[player.name]![hole]!.text
                                                        : '-',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: screenWidth > 600 ? 24.0 : (isSmallScreen ? 18.0 : 22.0),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: GestureDetector(
                                              onTap: () => _showMischiefWheel(playerIndex, hole, player.name),
                                              child: Container(
                                                width: screenWidth * 0.05,
                                                height: screenWidth * 0.05,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFFD700),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.casino,
                                                  color: Colors.white,
                                                  size: screenWidth * 0.03,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // Total Column
                      Column(
                        children: [
                          Container(
                            width: totalColumnWidth,
                            height: 80.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFD700).withValues(alpha:0.4),
                                  const Color(0xFFFFB347).withValues(alpha:0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(screenWidth * 0.05),
                              ),
                              border: Border(
                                left: BorderSide(
                                  color: const Color(0xFFFFD700).withValues(alpha:0.3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    color: const Color(0xFFFFB347),
                                    fontSize: screenWidth > 600 ? 18.0 : 15.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Column(
                                  children: [
                                    Text(
                                      'PAR 18: 43',
                                      style: TextStyle(
                                        color: const Color(0xFF4CAF50),
                                        fontSize: screenWidth > 600 ? 12.0 : (isSmallScreen ? 9.0 : 10.0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ...controller.players.asMap().entries.map((entry) {
                            final player = entry.value;
                            return Container(
                              height: cellHeight,
                              width: totalColumnWidth,
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: const Color(0xFFFFD700).withValues(alpha:0.25),
                                    width: 1.5,
                                  ),
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha:0.15),
                                    width: 1,
                                  ),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFFD700).withValues(alpha:0.2),
                                    const Color(0xFFFFB347).withValues(alpha:0.1),
                                  ],
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
                                        const Color(0xFFFFD700).withValues(alpha:0.3),
                                        const Color(0xFFFFB347).withValues(alpha:0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700).withValues(alpha:0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '${controller.getTotalStrokes(player.name)}',
                                    style: TextStyle(
                                      color: const Color(0xFFFFB347),
                                      fontSize: screenWidth > 600 ? 32.0 : (isSmallScreen ? 24.0 : 28.0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildBottomSection(context, controller, screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitDialog(context, screenWidth),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2D44).withValues(alpha:0.6),
                    const Color(0xFF1F1F2E).withValues(alpha:0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha:0.3),
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
    );
  }

  Widget _buildPlayerIcon(PlayerData player) {
    if (player.customImagePath == null || player.customImagePath!.isEmpty) {
      return Image.asset('Assets/${player.iconIndex + 1}.png', fit: BoxFit.cover);
    }
    return FutureBuilder<bool>(
      future: _checkFileExists(player.customImagePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        if (snapshot.hasData && snapshot.data == true) {
          return Image.file(File(player.customImagePath!), fit: BoxFit.cover);
        } else {
          return Image.asset('Assets/${player.iconIndex + 1}.png', fit: BoxFit.cover);
        }
      },
    );
  }

  Future<bool> _checkFileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  Widget _buildBottomSection(
      BuildContext context,
      MatchController controller,
      double screenWidth,
      double screenHeight,
      ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF0A0A0F).withValues(alpha:0.95),
              const Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
                horizontal: screenWidth * 0.05,
              ),
              color: Colors.black.withValues(alpha:0.5),
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
                      Icon(Icons.facebook, color: Colors.blue, size: screenWidth * 0.04),
                      SizedBox(width: screenWidth * 0.02),
                      Text('facebook.com/scarystrokes', style: TextStyle(color: Colors.blue, fontSize: screenWidth * 0.025)),
                      SizedBox(width: screenWidth * 0.04),
                      Icon(Icons.flag, color: Colors.red, size: screenWidth * 0.04),
                      SizedBox(width: screenWidth * 0.02),
                      Text('@ScaryStrokes', style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.025)),
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
              child: Consumer<MatchController>(
                builder: (context, controller, child) {
                  return GestureDetector(
                    onTap: controller.isSaving ? null : () => _handleFinishMatch(controller, context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: controller.isSaving
                              ? [const Color(0xFF666666), const Color(0xFF444444)]
                              : [const Color(0xFFFFD700), const Color(0xFFE63946)],
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (controller.isSaving)
                            SizedBox(
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          else
                            Icon(Icons.flag, color: Colors.white, size: screenWidth * 0.06),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            controller.isSaving ? 'Saving...' : 'Finish Match',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, double screenWidth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
              style: TextStyle(fontSize: screenWidth * 0.04),
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
  }

  void _showMischiefWheel(int playerIndex, int hole, String playerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MischiefWheelDialog(
        holeNumber: hole,
        playerName: playerName,
      ),
    );
  }

  void _handleFinishMatch(MatchController controller, BuildContext context) async {
    if (controller.isSaving) return;

    try {
      await controller.saveMatchToDatabase();
      _showWinnerCelebration(controller, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFE63946),
        ),
      );
    }
  }

  void _showWinnerCelebration(MatchController controller, BuildContext context) {
    final sortedPlayers = controller.getSortedPlayers();
    final scores = controller.calculateFinalScores();
    final winningScore = scores[sortedPlayers.first.name] ?? 0;
    final winners = sortedPlayers.where((player) => scores[player.name] == winningScore).toList();

    controller.confettiController.play();

    if (winners.length > 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: controller.confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
            Dialog(
              backgroundColor: Colors.transparent,
              child: MultipleWinnersCelebrationDialog(
                winners: winners,
                winnerScore: winningScore,
                onClose: () {
                  controller.confettiController.stop();
                  Navigator.pop(context);
                  _showFinalLeaderboard(sortedPlayers, scores, context);
                },
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: ConfettiWidget(
                confettiController: controller.confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
            Dialog(
              backgroundColor: Colors.transparent,
              child: WinnerCelebrationDialog(
                winner: winners.first,
                winnerScore: winningScore,
                onClose: () {
                  controller.confettiController.stop();
                  Navigator.pop(context);
                  _showFinalLeaderboard(sortedPlayers, scores, context);
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showFinalLeaderboard(List<PlayerData> sortedPlayers, Map<String, int> scores, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinalLeaderboardDialog(
        players: sortedPlayers,
        finalScores: scores,
        onFinish: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        },
      ),
    );
  }
}