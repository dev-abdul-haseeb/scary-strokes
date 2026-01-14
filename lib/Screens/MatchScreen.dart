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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

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
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.9,
            maxHeight: screenHeight * 0.85,
          ),
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D2D44).withOpacity(0.95),
                const Color(0xFF1F1F2E).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.06),
            border: Border.all(
              color: const Color(0xFFFF8C00).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                color: const Color(0xFFFFB347),
                size: screenWidth * 0.15,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Match Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.07,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF8C00).withOpacity(0.2),
                      const Color(0xFFFFB347).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  border: Border.all(
                    color: const Color(0xFFFF8C00).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: screenWidth * 0.13,
                      height: screenWidth * 0.13,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(
                          color: const Color(0xFFFF8C00),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        child: Image.asset(
                          'Assets/${sortedPlayers[0].iconIndex + 1}.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏆 Winner',
                            style: TextStyle(
                              color: const Color(0xFFFFB347),
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            sortedPlayers[0].name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${finalScores[sortedPlayers[0].name]}',
                      style: TextStyle(
                        color: const Color(0xFFFFB347),
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: sortedPlayers.skip(1).map((player) {
                      return Container(
                        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1A1A2E).withOpacity(0.6),
                              const Color(0xFF0A0A0F).withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: screenWidth * 0.1,
                              height: screenWidth * 0.1,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                child: Image.asset(
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
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${finalScores[player.name]}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFE63946)],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8C00).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    'Finish',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
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
    final screenWidth = MediaQuery.of(context).size.width;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        backgroundColor: isError ? const Color(0xFFE63946) : const Color(0xFF4CAF50),
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
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF2D2D44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                              ),
                              title: Text(
                                'Exit Match?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.05,
                                ),
                              ),
                              content: Text(
                                'All progress will be lost.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
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
                                      fontSize: MediaQuery.of(context).size.width * 0.04,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2D2D44).withOpacity(0.6),
                                const Color(0xFF1F1F2E).withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.04),
                            border: Border.all(
                              color: const Color(0xFFFF8C00).withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: const Color(0xFFFF8C00),
                            size: MediaQuery.of(context).size.width * 0.06,
                          ),
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                          ).createShader(bounds),
                          child: Text(
                            'Scorecard',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.07,
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
                    margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.025),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2D2D44).withOpacity(0.8),
                          const Color(0xFF1F1F2E).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
                      border: Border.all(
                        color: const Color(0xFFFF8C00).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Player Column
                        Column(
                          children: [
                            // Player Header
                            Container(
                              width: MediaQuery.of(context).size.width > 600 ? 140.0 : (MediaQuery.of(context).size.width < 360 ? 90.0 : 110.0),
                              height: MediaQuery.of(context).size.width > 600 ? 70.0 : 60.0,
                              padding: EdgeInsets.symmetric(
                                vertical: MediaQuery.of(context).size.height * 0.015,
                                horizontal: MediaQuery.of(context).size.width * 0.03,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF8C00).withOpacity(0.4),
                                    const Color(0xFFFFB347).withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(MediaQuery.of(context).size.width * 0.05),
                                ),
                                border: Border(
                                  right: BorderSide(
                                    color: const Color(0xFFFF8C00).withOpacity(0.3),
                                    width: 1.5,
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
                              child: Center(
                                child: Text(
                                  'Player',
                                  style: TextStyle(
                                    color: const Color(0xFFFFB347),
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 20.0 : 18.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            // Player names list
                            Expanded(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width > 600 ? 140.0 : (MediaQuery.of(context).size.width < 360 ? 90.0 : 110.0),
                                child: ListView.builder(
                                  itemCount: widget.players.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, playerIndex) {
                                    final player = widget.players[playerIndex];
                                    return Container(
                                      height: MediaQuery.of(context).size.width > 600 ? 115.0 : (MediaQuery.of(context).size.width < 360 ? 90.0 : 106.0),
                                      padding: EdgeInsets.symmetric(
                                        vertical: MediaQuery.of(context).size.height * 0.01,
                                        horizontal: MediaQuery.of(context).size.width * 0.025,
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
                                            width: MediaQuery.of(context).size.width > 600 ? 65.0 : (MediaQuery.of(context).size.width < 360 ? 45.0 : 55.0),
                                            height: MediaQuery.of(context).size.width > 600 ? 65.0 : (MediaQuery.of(context).size.width < 360 ? 45.0 : 55.0),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular((MediaQuery.of(context).size.width > 600 ? 65.0 : (MediaQuery.of(context).size.width < 360 ? 45.0 : 55.0)) * 0.25),
                                              border: Border.all(
                                                color: const Color(0xFFFF8C00).withOpacity(0.6),
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFF8C00).withOpacity(0.4),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular((MediaQuery.of(context).size.width > 600 ? 65.0 : (MediaQuery.of(context).size.width < 360 ? 45.0 : 55.0)) * 0.2),
                                              child: Image.asset(
                                                'Assets/${player.iconIndex + 1}.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: MediaQuery.of(context).size.height * 0.008),
                                          Text(
                                            player.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: MediaQuery.of(context).size.width > 600 ? 16.0 : (MediaQuery.of(context).size.width < 360 ? 12.0 : 14.0),
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
                                  height: MediaQuery.of(context).size.width > 600 ? 70.0 : 60.0,
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
                                        width: MediaQuery.of(context).size.width > 600 ? 80.0 : (MediaQuery.of(context).size.width < 360 ? 60.0 : 70.0),
                                        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
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
                                            style: TextStyle(
                                              color: const Color(0xFFFFB347),
                                              fontSize: MediaQuery.of(context).size.width > 600 ? 18.0 : 16.0,
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
                                    height: MediaQuery.of(context).size.width > 600 ? 115.0 : (MediaQuery.of(context).size.width < 360 ? 90.0 : 106.0),
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
                                          width: MediaQuery.of(context).size.width > 600 ? 80.0 : (MediaQuery.of(context).size.width < 360 ? 60.0 : 70.0),
                                          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
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
                                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
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
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: MediaQuery.of(context).size.width > 600 ? 24.0 : (MediaQuery.of(context).size.width < 360 ? 18.0 : 22.0),
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: '-',
                                                hintStyle: TextStyle(
                                                  color: Colors.white30,
                                                  fontSize: MediaQuery.of(context).size.width > 600 ? 24.0 : (MediaQuery.of(context).size.width < 360 ? 18.0 : 22.0),
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
                              width: MediaQuery.of(context).size.width > 600 ? 80.0 : (MediaQuery.of(context).size.width < 360 ? 55.0 : 60.0),
                              height: MediaQuery.of(context).size.width > 600 ? 70.0 : 60.0,
                              padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.015),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF8C00).withOpacity(0.4),
                                    const Color(0xFFFFB347).withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(MediaQuery.of(context).size.width * 0.05),
                                ),
                                border: Border(
                                  left: BorderSide(
                                    color: const Color(0xFFFF8C00).withOpacity(0.3),
                                    width: 1.5,
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
                              child: Center(
                                child: Text(
                                  'Total',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFFFB347),
                                    fontSize: MediaQuery.of(context).size.width > 600 ? 20.0 : 18.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            // Total scores list
                            Expanded(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width > 600 ? 80.0 : (MediaQuery.of(context).size.width < 360 ? 55.0 : 60.0),
                                child: ListView.builder(
                                  itemCount: widget.players.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, playerIndex) {
                                    final player = widget.players[playerIndex];
                                    return Container(
                                      height: MediaQuery.of(context).size.width > 600 ? 115.0 : (MediaQuery.of(context).size.width < 360 ? 90.0 : 106.0),
                                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
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
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context).size.width * 0.02,
                                            vertical: MediaQuery.of(context).size.height * 0.002,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFF8C00).withOpacity(0.3),
                                                const Color(0xFFFFB347).withOpacity(0.2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
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
                                            style: TextStyle(
                                              color: const Color(0xFFFFB347),
                                              fontSize: MediaQuery.of(context).size.width > 600 ? 32.0 : (MediaQuery.of(context).size.width < 360 ? 24.0 : 28.0),
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
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
                  child: GestureDetector(
                    onTap: isSaving ? null : _saveMatchToDatabase,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.022),
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
                        borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
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
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.05,
                              height: MediaQuery.of(context).size.width * 0.05,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.flag,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width * 0.06,
                            ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                          Text(
                            isSaving ? 'Saving...' : 'Finish Match',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width * 0.045,
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