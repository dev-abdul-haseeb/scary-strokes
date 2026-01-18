import 'package:flutter/material.dart';

class HomeController extends ChangeNotifier {
  AnimationController? _floatController;
  AnimationController? _fadeController;
  Animation<double>? _floatAnimation;
  Animation<double>? _fadeAnimation;
  final TickerProvider vsync;

  HomeController({required this.vsync}) {
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    )..forward();

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController!, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut),
    );
  }

  // Getters for animations
  Animation<double>? get floatAnimation => _floatAnimation;
  Animation<double>? get fadeAnimation => _fadeAnimation;
  AnimationController? get floatController => _floatController;

  // Dispose method
  void disposeControllers() {
    _floatController?.dispose();
    _fadeController?.dispose();
  }

  // Restart animations if needed
  void restartAnimations() {
    _fadeController?.reset();
    _fadeController?.forward();
  }

  // Notify listeners for UI updates
  void updateUI() {
    notifyListeners();
  }
}