import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scary_strokes/Screens/match_screen.dart';
import '../Widgets/homeScreenButtons.dart';
import '../Widgets/player_card.dart';
import '../controllers/startgame_controller.dart';

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<StartGameScreen> with TickerProviderStateMixin {
  late StartGameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StartGameController(vsync: this);
  }

  @override
  void dispose() {
    _controller.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isVerySmallScreen = screenWidth < 350;

    return ChangeNotifierProvider.value(
      value: _controller,
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
              // Background effects - RESPONSIVE
              Positioned(
                top: -screenWidth * 0.25,
                right: -screenWidth * 0.25,
                child: Container(
                  width: screenWidth * 0.75,
                  height: screenWidth * 0.75,
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
                bottom: -screenWidth * 0.3,
                left: -screenWidth * 0.25,
                child: Container(
                  width: screenWidth,
                  height: screenWidth,
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
                child: Consumer<StartGameController>(
                  builder: (context, controller, child) {
                    return FadeTransition(
                      opacity: controller.fadeAnimation,
                      child: _buildContent(context, controller, screenWidth, screenHeight, isSmallScreen, isVerySmallScreen),
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

  Widget _buildContent(
      BuildContext context,
      StartGameController controller,
      double screenWidth,
      double screenHeight,
      bool isSmallScreen,
      bool isVerySmallScreen,
      ) {
    return Column(
      children: [
        // Header - RESPONSIVE
        _buildAppBar(context, controller, screenWidth, screenHeight, isSmallScreen),

        // Players list - RESPONSIVE
        Expanded(
          child: _buildPlayersList(controller, screenWidth, isSmallScreen),
        ),

        // Bottom actions - RESPONSIVE
        _buildBottomSection(controller, context, screenWidth, screenHeight, isSmallScreen),
      ],
    );
  }

  Widget _buildAppBar(
      BuildContext context,
      StartGameController controller,
      double screenWidth,
      double screenHeight,
      bool isSmallScreen,
      ) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      child: Row(
        children: [
          // Back Button - RESPONSIVE
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2D44).withValues(alpha:0.6),
                    const Color(0xFF1F1F2E).withValues(alpha:0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 15.0),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                color: const Color(0xFFFF8C00),
                size: isSmallScreen ? 20.0 : 24.0,
              ),
            ),
          ),

          SizedBox(width: isSmallScreen ? 12.0 : 16.0),

          // Title and Stats - RESPONSIVE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                  ).createShader(bounds),
                  child: Text(
                    'Setup Game',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22.0 : 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2.0 : 4.0),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8.0 : 12.0,
                    vertical: isSmallScreen ? 2.0 : 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00).withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8.0 : 12.0),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                    ),
                  ),
                  child: Text(
                    controller.getPlayersCountText(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10.0 : 12.0,
                      color: const Color(0xFFFFB347),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(StartGameController controller, double screenWidth, bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 20.0),
      itemCount: controller.players.length,
      itemBuilder: (context, index) {
        return PlayerCard(
          player: controller.players[index],
          index: index,
          canRemove: controller.players.length > 1,
          onRemove: () => controller.removePlayer(index),
          onNameChanged: (name) => controller.updatePlayerName(index, name),
          onIconChanged: (iconIndex, customImagePath) => controller.updatePlayerIcon(index, iconIndex, customImagePath),
          screenWidth: screenWidth,
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  Widget _buildBottomSection(
      StartGameController controller,
      BuildContext context,
      double screenWidth,
      double screenHeight,
      bool isSmallScreen,
      ) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      child: Column(
        children: [
          // Add Player Button
          if (controller.players.length < 6)
            Column(
              children: [
                GestureDetector(
                  onTap: controller.addPlayer,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 14.0 : 18.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2D2D44).withValues(alpha:0.6),
                          const Color(0xFF1F1F2E).withValues(alpha:0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 15.0 : 20.0),
                      border: Border.all(
                        color: const Color(0xFF7B2CBF).withValues(alpha:0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2CBF).withValues(alpha:0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: const Color(0xFF9D4EDD),
                          size: isSmallScreen ? 20.0 : 24.0,
                        ),
                        SizedBox(width: isSmallScreen ? 8.0 : 12.0),
                        Text(
                          'Add Player (${controller.players.length}/6)',
                          style: TextStyle(
                            color: const Color(0xFF9D4EDD),
                            fontSize: isSmallScreen ? 14.0 : 18.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12.0 : 16.0),
              ],
            ),

          // Start Match Button
          EnhancedHomeButton(
            title: 'Start Match',
            icon: Icons.play_arrow_rounded,
            gradientColors: const [Color(0xFFFF8C00), Color(0xFFE63946)],
            glowColor: const Color(0xFFFF8C00),
            onTap: () => _startMatch(controller, context),
            delay: 0,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  void _startMatch(StartGameController controller, BuildContext context) {
    if (!controller.validatePlayers()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter names for all players'),
          backgroundColor: const Color(0xFFE63946),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartMatchScreen(players: controller.players),
      ),
    );
  }
}