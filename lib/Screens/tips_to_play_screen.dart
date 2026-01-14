import 'package:flutter/material.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  int _currentTipIndex = 0;
  final PageController _pageController = PageController();

  final List<TipCategory> tips = [
    TipCategory(
      title: 'Getting Started',
      icon: Icons.play_arrow,
      color: Color(0xFFFF8C00),
      tips: [
        'Choose your player avatar from 8 unique characters',
        'Add 2-4 players for a competitive match',
        'Select 9 or 18 holes depending on game duration',
        'Make sure all players understand the basic rules',
      ],
    ),
    TipCategory(
      title: 'Basic Rules',
      icon: Icons.gavel,
      color: Color(0xFF00B4D8),
      tips: [
        'Lowest total strokes after all holes wins',
        'Ties are possible - multiple players can win',
        'Each stroke counts - be accurate with your inputs',
        'Track scores hole by hole for better strategy',
      ],
    ),
    TipCategory(
      title: 'Scoring Strategy',
      icon: Icons.insights,
      color: Color(0xFF7B2CBF),
      tips: [
        'Aim for consistency rather than risky shots',
        'Keep track of opponent scores to adjust strategy',
        'Par for most mini golf holes is 2-3 strokes',
        'Plan your approach - some holes require strategy over power',
      ],
    ),
    TipCategory(
      title: 'Game Features',
      icon: Icons.featured_play_list,
      color: Color(0xFFE63946),
      tips: [
        'Use the scorecard to track all players simultaneously',
        'Scroll horizontally to view all 18 holes',
        'Tap on any cell to enter stroke counts',
        'Automatic total calculation after each input',
      ],
    ),
    TipCategory(
      title: 'Advanced Tips',
      icon: Icons.star,
      color: Color(0xFF4CAF50),
      tips: [
        'Practice reading greens before putting',
        'Bank shots off walls can save strokes',
        'Use obstacles strategically, not as hindrances',
        'Stay calm under pressure - rushing leads to mistakes',
      ],
    ),
    TipCategory(
      title: 'Match Management',
      icon: Icons.settings,
      color: Color(0xFFFFB347),
      tips: [
        'Review match history in the scoreboard',
        'View winners and leaderboards for statistics',
        'Each match is saved automatically',
        'You can delete matches from history if needed',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
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
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                              ).createShader(bounds),
                              child: const Text(
                                'Tips to Play',
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
                      const SizedBox(height: 20),

                      // Category Indicators
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tips.length,
                          itemBuilder: (context, index) {
                            final category = tips[index];
                            final isSelected = index == _currentTipIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentTipIndex = index;
                                });
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [category.color, category.color.withValues(alpha:0.8)]
                                        : [
                                      const Color(0xFF2D2D44).withValues(alpha:0.6),
                                      const Color(0xFF1F1F2E).withValues(alpha:0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? category.color.withValues(alpha:0.8)
                                        : Colors.white.withValues(alpha:0.1),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: category.color.withValues(alpha:0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      category.icon,
                                      color: isSelected ? Colors.white : Colors.white70,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category.title,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tips Content
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: tips.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentTipIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final category = tips[index];

                            return AnimatedBuilder(
                              animation: _slideController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _slideAnimation.value),
                                  child: Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF2D2D44).withValues(alpha:0.8),
                                      const Color(0xFF1F1F2E).withValues(alpha:0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: category.color.withValues(alpha:0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category Header
                                    Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                category.color,
                                                category.color.withValues(alpha:0.7),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Icon(
                                            category.icon,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${category.tips.length} tips',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha:0.7),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),

                                    // Tips List
                                    Expanded(
                                      child: ListView.separated(
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: category.tips.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                                        itemBuilder: (context, tipIndex) {
                                          return AnimatedContainer(
                                            duration: Duration(milliseconds: 300 + (tipIndex * 100)),
                                            curve: Curves.easeOut,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF1A1A2E).withValues(alpha:0.8),
                                                  const Color(0xFF0A0A0F).withValues(alpha:0.6),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                              border: Border.all(
                                                color: category.color.withValues(alpha:0.2),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: category.color.withValues(alpha:0.2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${tipIndex + 1}',
                                                      style: TextStyle(
                                                        color: category.color,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    category.tips[tipIndex],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      height: 1.4,
                                                    ),
                                                  ),
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
                            );
                          },
                        ),
                      ),

                      // Navigation Dots
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          tips.length,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: index == _currentTipIndex ? 30 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == _currentTipIndex
                                  ? tips[index].color
                                  : Colors.white.withValues(alpha:0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Tip Button
                      GestureDetector(
                        onTap: () {
                          // Show random tip
                          setState(() {
                            _currentTipIndex = (_currentTipIndex + 1) % tips.length;
                          });
                          _pageController.animateToPage(
                            _currentTipIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF8C00).withValues(alpha:0.8),
                                const Color(0xFFE63946).withValues(alpha:0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF8C00).withValues(alpha:0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Next Tip Category',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}

class TipCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> tips;

  TipCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.tips,
  });
}