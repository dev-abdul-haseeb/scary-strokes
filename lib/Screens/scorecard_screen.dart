import 'package:flutter/material.dart';
import '../Database/database.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class WinnerData {
  final String playerName;
  final int playerIconIndex;
  final int totalStrokes;
  final String matchDate;
  final int matchId;

  WinnerData({
    required this.playerName,
    required this.playerIconIndex,
    required this.totalStrokes,
    required this.matchDate,
    required this.matchId,
  });
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<WinnerData> winners = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _loadWinners();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadWinners() async {
    setState(() {
      isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final matches = await dbHelper.getAllMatches();

      List<WinnerData> loadedWinners = [];

      for (var match in matches) {
        final matchId = match['id'] as int;
        final matchDate = match['date'] as String;

        // ✅ Make list mutable
        final playerScores =
        List<Map<String, dynamic>>.from(
          await dbHelper.getPlayerScoresForMatch(matchId),
        );

        if (playerScores.isNotEmpty) {
          playerScores.sort((a, b) =>
              (a['total_strokes'] as int)
                  .compareTo(b['total_strokes'] as int));

          final winner = playerScores.first;

          loadedWinners.add(WinnerData(
            playerName: winner['player_name'] as String,
            playerIconIndex: winner['player_icon_index'] as int,
            totalStrokes: winner['total_strokes'] as int,
            matchDate: matchDate,
            matchId: matchId,
          ));
        }
      }

      // Sort winners by total strokes (ascending - lower is better)
      loadedWinners.sort((a, b) => a.totalStrokes.compareTo(b.totalStrokes));

      setState(() {
        winners = loadedWinners;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading leaderboard: $e', isError: true);
    }
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFFFF8C00); // Orange
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '🏅';
    }
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
                            onTap: () => Navigator.pop(context),
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
                                  child: const Text(
                                    'Leaderboard',
                                    style: TextStyle(
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
                                    '${winners.length} Winners',
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
                          // Refresh button
                          GestureDetector(
                            onTap: _loadWinners,
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
                                Icons.refresh,
                                color: Color(0xFFFF8C00),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: isLoading
                          ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF8C00),
                          ),
                        ),
                      )
                          : winners.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              size: 80,
                              color: Color(0xFFFF8C00),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matches yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Play your first match to see winners here!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: winners.length,
                        itemBuilder: (context, index) {
                          final winner = winners[index];
                          final rank = index;
                          final rankColor = _getRankColor(rank);
                          final isTopThree = rank < 3;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isTopThree
                                    ? [
                                  rankColor.withOpacity(0.2),
                                  rankColor.withOpacity(0.05),
                                ]
                                    : [
                                  const Color(0xFF2D2D44).withOpacity(0.6),
                                  const Color(0xFF1F1F2E).withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isTopThree
                                    ? rankColor.withOpacity(0.5)
                                    : const Color(0xFFFF8C00).withOpacity(0.2),
                                width: isTopThree ? 2 : 1,
                              ),
                              boxShadow: isTopThree
                                  ? [
                                BoxShadow(
                                  color: rankColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Rank Badge
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: isTopThree
                                        ? LinearGradient(
                                      colors: [
                                        rankColor,
                                        rankColor.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                        : LinearGradient(
                                      colors: [
                                        const Color(0xFF2D2D44),
                                        const Color(0xFF1F1F2E),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isTopThree
                                          ? rankColor.withOpacity(0.5)
                                          : const Color(0xFFFF8C00).withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isTopThree ? _getRankEmoji(rank) : '#${rank + 1}',
                                      style: TextStyle(
                                        fontSize: isTopThree ? 24 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: isTopThree ? Colors.white : const Color(0xFFFF8C00),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Player Avatar
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isTopThree
                                          ? rankColor.withOpacity(0.6)
                                          : const Color(0xFFFF8C00).withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.asset(
                                      'Assets/${winner.playerIconIndex + 1}.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Player Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        winner.playerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(winner.matchDate),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Score
                                Column(
                                  children: [
                                    Text(
                                      'Score',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isTopThree
                                            ? LinearGradient(
                                          colors: [
                                            rankColor.withOpacity(0.3),
                                            rankColor.withOpacity(0.15),
                                          ],
                                        )
                                            : LinearGradient(
                                          colors: [
                                            const Color(0xFF1A1A2E).withOpacity(0.8),
                                            const Color(0xFF0A0A0F).withOpacity(0.6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isTopThree
                                              ? rankColor.withOpacity(0.4)
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Text(
                                        '${winner.totalStrokes}',
                                        style: TextStyle(
                                          color: isTopThree
                                              ? rankColor
                                              : Colors.white.withOpacity(0.7),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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