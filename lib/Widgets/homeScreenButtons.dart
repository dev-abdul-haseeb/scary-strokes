import 'package:flutter/material.dart';

class EnhancedHomeButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final VoidCallback onTap;
  final int delay;
  final bool isSmallScreen;
  final bool isVerySmallScreen;

  const EnhancedHomeButton({
    super.key,
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.onTap,
    required this.delay,
    this.isSmallScreen = false,
    this.isVerySmallScreen = false,
  });

  @override
  State<EnhancedHomeButton> createState() => _EnhancedHomeButtonState();
}

class _EnhancedHomeButtonState extends State<EnhancedHomeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation after delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _controller.reverse();
  }

  void _onTapUp() {
    _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {

    // RESPONSIVE sizes
    final iconSize = widget.isVerySmallScreen ? 20.0 :
    widget.isSmallScreen ? 24.0 : 28.0;
    final fontSize = widget.isVerySmallScreen ? 14.0 :
    widget.isSmallScreen ? 16.0 : 18.0;
    final paddingHorizontal = widget.isVerySmallScreen ? 16.0 :
    widget.isSmallScreen ? 20.0 : 24.0;
    final paddingVertical = widget.isVerySmallScreen ? 12.0 :
    widget.isSmallScreen ? 14.0 : 16.0;
    final borderRadius = widget.isSmallScreen ? 15.0 : 20.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: widget.isSmallScreen ? 4.0 : 8.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha:0.4 * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                onTapDown: (_) => _onTapDown(),
                onTapUp: (_) => _onTapUp(),
                onTapCancel: () => _controller.forward(),
                onHover: (hovering) {
                  setState(() {
                    _isHovering = hovering;
                  });
                  if (hovering) {
                    _controller.forward();
                  } else {
                    _controller.reverse();
                  }
                },
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal,
                    vertical: paddingVertical,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      SizedBox(width: widget.isSmallScreen ? 8.0 : 12.0),
                      Flexible(
                        child: Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: widget.isSmallScreen ? 0.5 : 1.0,
                            shadows: _isHovering
                                ? [
                              const Shadow(
                                blurRadius: 10,
                                color: Colors.white,
                              ),
                            ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}