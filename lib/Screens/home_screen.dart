import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scary_strokes/Screens/leaderboard_screen.dart';
import 'package:scary_strokes/Screens/startGameScreen.dart';
import 'package:scary_strokes/Screens/tips_to_play_screen.dart';
import '../Widgets/homeScreenButtons.dart';
import '../controllers/home_screen_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(vsync: this);
  }

  @override
  void dispose() {
    _homeController.disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isVerySmallScreen = screenWidth < 350;
    final isLargeScreen = screenWidth > 600;

    return ChangeNotifierProvider.value(
      value: _homeController,
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
              // Animated background circles - RESPONSIVE
              Positioned(
                top: -screenWidth * 0.25,
                right: -screenWidth * 0.25,
                child: Container(
                  width: screenWidth * 0.8,
                  height: screenWidth * 0.8,
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
                bottom: -screenWidth * 0.35,
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

              // Main content
              SafeArea(
                child: Consumer<HomeController>(
                  builder: (context, controller, child) {
                    return FadeTransition(
                      opacity: controller.fadeAnimation ?? AlwaysStoppedAnimation(1.0),
                      child: _buildMainContent(
                        context,
                        controller,
                        screenWidth,
                        screenHeight,
                        isSmallScreen,
                        isVerySmallScreen,
                        isLargeScreen,
                      ),
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

  Widget _buildMainContent(
      BuildContext context,
      HomeController controller,
      double screenWidth,
      double screenHeight,
      bool isSmallScreen,
      bool isVerySmallScreen,
      bool isLargeScreen,
      ) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isSmallScreen ? 5.0 : 10.0),

          _buildHeader(isSmallScreen, screenWidth),

          SizedBox(height: isSmallScreen ? 15.0 : 30.0),

          _buildAnimatedLogo(controller, screenWidth, isSmallScreen, isVerySmallScreen, isLargeScreen),

          SizedBox(height: isSmallScreen ? 15.0 : 20.0),

          const Spacer(),

          _buildActionButtons(context, screenWidth, screenHeight, isSmallScreen, isVerySmallScreen),

          SizedBox(height: isSmallScreen ? 8.0 : 16.0),

          const Spacer(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.0 : 16.0,
        vertical: isSmallScreen ? 4.0 : 6.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00).withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(isSmallScreen ? 15.0 : 20.0),
        border: Border.all(
          color: const Color(0xFFFF8C00).withValues(alpha:0.3),
        ),
      ),
      child: Text(
        'Mini Golf Scorecard',
        style: TextStyle(
          fontSize: isSmallScreen ? 12.0 : 14.0,
          color: const Color(0xFFFFB347),
          fontWeight: FontWeight.w500,
          letterSpacing: isSmallScreen ? 1.0 : 1.2,
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(
      HomeController controller,
      double screenWidth,
      bool isSmallScreen,
      bool isVerySmallScreen,
      bool isLargeScreen,
      ) {
    // RESPONSIVE logo size
    double logoSize;
    if (isVerySmallScreen) {
      logoSize = screenWidth * 0.85;
    } else if (isSmallScreen) {
      logoSize = screenWidth * 0.9;
    } else if (isLargeScreen) {
      logoSize = 400.0;
    } else {
      logoSize = 350.0;
    }

    return AnimatedBuilder(
      animation: controller.floatAnimation ?? AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, controller.floatAnimation?.value ?? 0),
          child: Container(
            width: logoSize,
            height: logoSize,
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isSmallScreen ? 20.0 : 30.0),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D2D44).withValues(alpha:0.6),
                  const Color(0xFF1F1F2E).withValues(alpha:0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8C00).withValues(alpha:0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSmallScreen ? 15.0 : 20.0),
              child: Image.asset(
                'Assets/Splash.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFFF8C00),
                    child: const Center(
                      child: Icon(
                        Icons.golf_course,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      double screenWidth,
      double screenHeight,
      bool isSmallScreen,
      bool isVerySmallScreen,
      ) {
    // RESPONSIVE button spacing
    final buttonSpacing = isSmallScreen ? 12.0 : 20.0;
    final buttonHeight = isSmallScreen ? screenHeight * 0.07 : screenHeight * 0.08;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Start Game Button
        Container(
          height: buttonHeight,
          margin: EdgeInsets.only(bottom: buttonSpacing),
          child: EnhancedHomeButton(
            title: 'Start Game',
            icon: Icons.sports_golf,
            gradientColors: const [Color(0xFFFF8C00), Color(0xFFE63946)],
            glowColor: const Color(0xFFFF8C00),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StartGameScreen()),
              );
            },
            delay: 0,
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
        ),

        // Scoreboard Button
        Container(
          height: buttonHeight,
          margin: EdgeInsets.only(bottom: buttonSpacing),
          child: EnhancedHomeButton(
            title: 'Scoreboard',
            icon: Icons.emoji_events,
            gradientColors: const [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
            glowColor: const Color(0xFF7B2CBF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
            delay: 100,
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
        ),

        // Tips to Play Button - FIXED: Won't overflow
        SizedBox(
          height: buttonHeight,
          child: EnhancedHomeButton(
            title: 'Tips to Play',
            icon: Icons.lightbulb_outline,
            gradientColors: const [Color(0xFF00B4D8), Color(0xFF48CAE4)],
            glowColor: const Color(0xFF00B4D8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TipsScreen()),
              );
            },
            delay: 200,
            isSmallScreen: isSmallScreen,
            isVerySmallScreen: isVerySmallScreen,
          ),
        ),
      ],
    );
  }
}