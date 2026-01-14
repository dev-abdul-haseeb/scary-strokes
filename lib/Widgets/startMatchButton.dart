import 'package:flutter/material.dart';

class StartMatchButton extends StatefulWidget {
  final VoidCallback onTap;

  const StartMatchButton({required this.onTap});

  @override
  State<StartMatchButton> createState() => _StartMatchButtonState();
}

class _StartMatchButtonState extends State<StartMatchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _scaleController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFE63946)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C00).withOpacity(_isPressed ? 0.4 : 0.3),
                blurRadius: _isPressed ? 20 : 25,
                offset: const Offset(0, 8),
                spreadRadius: _isPressed ? 0 : 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Start Match',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
