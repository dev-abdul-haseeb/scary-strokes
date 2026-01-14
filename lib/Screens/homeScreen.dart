import 'package:flutter/material.dart';
import 'package:scary_strokes/Screens/scorecard_screen.dart';
import 'package:scary_strokes/Screens/startGameScreen.dart';
import 'package:scary_strokes/Screens/tips_to_play_screen.dart';

import '../Widgets/homeScreenButtons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
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
            // Animated background circles
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

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      //Mini Golf Scorecard
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00).withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                          ),
                        ),
                        child: const Text(
                          'Mini Golf Scorecard',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFFB347),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Animated logo
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: Container(
                              width: 350,
                              height: 350,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
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
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'Assets/Logo.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),


                      const Spacer(),

                      // Enhanced buttons
                      EnhancedHomeButton(
                        title: 'Start Game',
                        icon: Icons.sports_golf,
                        gradientColors: const [Color(0xFFFF8C00), Color(0xFFE63946)],
                        glowColor: const Color(0xFFFF8C00),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>StartGameScreen()));
                        },
                        delay: 0,
                      ),

                      const SizedBox(height: 20),

                      EnhancedHomeButton(
                        title: 'Scoreboard',
                        icon: Icons.emoji_events,
                        gradientColors: const [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                        glowColor: const Color(0xFF7B2CBF),
                        onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => ScoreboardCard(
                            //       currentHole: 5,
                            //       totalHoles: 18,
                            //       players: [
                            //         PlayerScoreData(
                            //           name: "Sarah",
                            //           iconIndex: 0,
                            //           currentScore: 3,
                            //           totalScore: 18,
                            //           isLeader: true,
                            //         ),
                            //         PlayerScoreData(
                            //           name: "Mike",
                            //           iconIndex: 1,
                            //           currentScore: 4,
                            //           totalScore: 19,
                            //           isLeader: false,
                            //         ),
                            //         // Add more players...
                            //       ],
                            //     ),
                            //   ),
                            // );\
                        Navigator.push(context, MaterialPageRoute(builder: (_)=>LeaderboardScreen()));
                        },
                        delay: 100,
                      ),

                      const SizedBox(height: 20),

                      EnhancedHomeButton(
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
                      ),

                      const Spacer(),
                      const Spacer(),
                    ],
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

