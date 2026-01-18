import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/leaderboard_controller.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late LeaderboardController _leaderboardController;

  @override
  void initState() {
    super.initState();
    _leaderboardController = LeaderboardController(vsync: this);
  }

  @override
  void dispose() {
    _leaderboardController.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _leaderboardController,
      child: Scaffold(
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
                        const Color(0xFFFF8C00).withValues(alpha:0.1),
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
                        const Color(0xFF7B2CBF).withValues(alpha:0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Consumer<LeaderboardController>(
                  builder: (context, controller, child) {
                    return FadeTransition(
                      opacity: controller.fadeAnimation,
                      child: _buildContent(context, controller),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LeaderboardController controller) {
    return Column(
      children: [
        // Header
        _buildAppBar(context, controller),

        // Content
        Expanded(
          child: controller.isLoading
              ? _buildLoading()
              : controller.winners.isEmpty
              ? _buildEmptyState()
              : _buildLeaderboardList(controller),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, LeaderboardController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2D44).withValues(alpha:0.6),
                    const Color(0xFF1F1F2E).withValues(alpha:0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha:0.3),
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

          // Title and Stats
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00).withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                    ),
                  ),
                  child: Text(
                    '${controller.winners.length} Winners',
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

          // Refresh Button
          GestureDetector(
            onTap: controller.refresh,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2D44).withValues(alpha:0.6),
                    const Color(0xFF1F1F2E).withValues(alpha:0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha:0.3),
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
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              color: Colors.white.withValues(alpha:0.7),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Play your first match to see winners here!',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(LeaderboardController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: controller.winners.length,
      itemBuilder: (context, index) {
        final winner = controller.winners[index];
        final rank = index;
        final rankColor = controller.getRankColor(rank);
        final isTopThree = controller.isTopThree(rank);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTopThree
                  ? [rankColor.withValues(alpha:0.2), rankColor.withValues(alpha:0.05)]
                  : [
                const Color(0xFF2D2D44).withValues(alpha:0.6),
                const Color(0xFF1F1F2E).withValues(alpha:0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTopThree
                  ? rankColor.withValues(alpha:0.5)
                  : const Color(0xFFFF8C00).withValues(alpha:0.2),
              width: isTopThree ? 2 : 1,
            ),
            boxShadow: isTopThree
                ? [
              BoxShadow(
                color: rankColor.withValues(alpha:0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.3),
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
                    colors: [rankColor, rankColor.withValues(alpha:0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : const LinearGradient(
                    colors: [Color(0xFF2D2D44), Color(0xFF1F1F2E)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTopThree
                        ? rankColor.withValues(alpha:0.5)
                        : const Color(0xFFFF8C00).withValues(alpha:0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    isTopThree ? controller.getRankEmoji(rank) : '#${rank + 1}',
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
                        ? rankColor.withValues(alpha:0.6)
                        : const Color(0xFFFF8C00).withValues(alpha:0.4),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: winner.customImagePath != null
                      ? Image.file(
                    File(winner.customImagePath!),
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
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
                      controller.formatDate(winner.matchDate),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.6),
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
                      color: Colors.white.withValues(alpha:0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isTopThree
                          ? LinearGradient(
                        colors: [
                          rankColor.withValues(alpha:0.3),
                          rankColor.withValues(alpha:0.15),
                        ],
                      )
                          : LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E).withValues(alpha:0.8),
                          const Color(0xFF0A0A0F).withValues(alpha:0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTopThree
                            ? rankColor.withValues(alpha:0.4)
                            : Colors.white.withValues(alpha:0.1),
                      ),
                    ),
                    child: Text(
                      '${winner.totalStrokes}',
                      style: TextStyle(
                        color: isTopThree ? rankColor : Colors.white.withValues(alpha:0.7),
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
    );
  }
}