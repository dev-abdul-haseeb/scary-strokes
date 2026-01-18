import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../Database/database.dart';
import '../Widgets/match_screen_dialouges.dart';
import '../model/player_model.dart';

class MatchController extends ChangeNotifier {
  // Data
  final List<PlayerData> players;
  final int totalHoles = 18;

  Map<int, Map<String, int>> holeScores = {};
  Map<String, Map<int, TextEditingController>> strokeControllers = {};

  // State
  bool isSaving = false;
  int _currentHoleIndex = 0;

  // Controllers
  late AnimationController _fadeController;
  late ConfettiController _confettiController;
  late ConfettiController _holeInOneConfettiController;

  // Par values
  final Map<int, int> holeParValues = {
    1: 3, 2: 2, 3: 3, 4: 2, 5: 2,
    6: 3, 7: 2, 8: 2, 9: 3, 10: 2,
    11: 2, 12: 3, 13: 2, 14: 2, 15: 3,
    16: 2, 17: 3, 18: 3,
  };

  // Scroll controller
  final ScrollController horizontalScrollController = ScrollController();

  MatchController({
    required this.players,
    required TickerProvider vsync,
  }) {
    _initializeControllers(vsync);
  }

  void _initializeControllers(TickerProvider vsync) {
    // Initialize text controllers
    for (var player in players) {
      strokeControllers[player.name] = {};
      for (int hole = 1; hole <= totalHoles; hole++) {
        strokeControllers[player.name]![hole] = TextEditingController();
      }
    }

    // Animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    )..forward();

    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _holeInOneConfettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  // Getters
  AnimationController get fadeController => _fadeController;
  ConfettiController get confettiController => _confettiController;
  ConfettiController get holeInOneConfettiController => _holeInOneConfettiController;
  int get currentHoleIndex => _currentHoleIndex;
  Animation<double> get fadeAnimation => Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
  );

  // Business Logic Methods
  void updateCurrentHole(int hole) {
    _currentHoleIndex = hole;
    notifyListeners();
  }

  int getTotalStrokes(String playerName) {
    int total = 0;
    for (int hole = 1; hole <= totalHoles; hole++) {
      final controller = strokeControllers[playerName]?[hole];
      if (controller != null) {
        String text = controller.text.trim();
        if (text.isNotEmpty) {
          total += int.tryParse(text) ?? 0;
        }
      }
    }
    return total;
  }

  // ✅ FIXED: Handle number selection with auto-pop and auto-scroll
  void handleNumberSelection(BuildContext context, int playerIndex, int hole, int number) {
    final player = players[playerIndex];
    final controller = strokeControllers[player.name]?[hole];

    if (controller != null) {
      controller.text = number.toString();
      notifyListeners();

      // ✅ Close dialog automatically
      Navigator.of(context).pop();

      // Check for hole in one
      if (number == 1) {
        // Trigger hole in one celebration
        showHoleInOneCelebration(context, player, hole);
        notifyListeners();
      }
      // ✅ Auto-scroll to next hole
      _autoScrollToHole(hole);
    }
  }

  // ✅ FIXED: Auto-scroll function with proper implementation
  void _autoScrollToHole(int currentHole) {
    bool allPlayersHaveScore = true;
    for (var player in players) {
      final controller = strokeControllers[player.name]?[currentHole];
      String score = controller?.text.trim() ?? '';
      if (score.isEmpty) {
        allPlayersHaveScore = false;
        break;
      }
    }

    if (allPlayersHaveScore && currentHole < totalHoles) {
      _currentHoleIndex = currentHole;

      // ✅ Scroll to the next hole
      WidgetsBinding.instance.addPostFrameCallback((_) {
        horizontalScrollController.animateTo(
          _currentHoleIndex * 70.0, // Adjust this value based on your cell width
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });

      notifyListeners();
    }
  }

  Future<void> saveMatchToDatabase() async {
    if (isSaving) return;

    // Validation
    for (var player in players) {
      for (int hole = 1; hole <= totalHoles; hole++) {
        final controller = strokeControllers[player.name]?[hole];
        if (controller == null || controller.text.trim().isEmpty) {
          throw Exception('Please enter strokes for ${player.name} on Hole $hole');
        }

        int? strokes = int.tryParse(controller.text.trim());
        if (strokes == null || strokes < 1) {
          throw Exception('Invalid stroke count for ${player.name}');
        }
      }
    }

    isSaving = true;
    notifyListeners();

    try {
      final dbHelper = DatabaseHelper.instance;
      int matchId = await dbHelper.createMatch(totalHoles);

      Map<String, int> playerTotals = {};

      // Calculate scores and fill holeScores
      for (var player in players) {
        int totalStrokes = 0;
        for (int hole = 1; hole <= totalHoles; hole++) {
          final controller = strokeControllers[player.name]?[hole];
          if (controller == null) continue;

          int strokes = int.tryParse(controller.text.trim()) ?? 0;
          totalStrokes += strokes;

          // Fill holeScores
          if (!holeScores.containsKey(hole)) {
            holeScores[hole] = {};
          }
          holeScores[hole]![player.name] = strokes;
        }
        playerTotals[player.name] = totalStrokes;
      }

      // Find winner
      var sortedPlayers = players.toList()
        ..sort((a, b) {
          final scoreA = playerTotals[a.name] ?? 0;
          final scoreB = playerTotals[b.name] ?? 0;
          return scoreA.compareTo(scoreB);
        });

      final winner = sortedPlayers.first;
      final winningScore = playerTotals[winner.name] ?? 0;

      // Save winner to database
      await dbHelper.addWinner(
        matchId: matchId,
        playerName: winner.name,
        playerIconIndex: winner.iconIndex,
        totalStrokes: winningScore,
        customImagePath: winner.customImagePath,
      );

      isSaving = false;
      notifyListeners();

      return;

    } catch (e) {
      isSaving = false;
      notifyListeners();
      rethrow;
    }
  }

  Map<String, int> calculateFinalScores() {
    Map<String, int> finalScores = {};

    for (var player in players) {
      int total = 0;
      for (int hole = 1; hole <= totalHoles; hole++) {
        final controller = strokeControllers[player.name]?[hole];
        if (controller != null) {
          String text = controller.text.trim();
          if (text.isNotEmpty) {
            total += int.tryParse(text) ?? 0;
          }
        }
      }
      finalScores[player.name] = total;
    }

    return finalScores;
  }

  List<PlayerData> getSortedPlayers() {
    final scores = calculateFinalScores();
    return players.toList()
      ..sort((a, b) {
        final scoreA = scores[a.name] ?? 0;
        final scoreB = scores[b.name] ?? 0;
        return scoreA.compareTo(scoreB);
      });
  }

  // ✅ Function to show number wheel
  void showNumberWheel(BuildContext context, int playerIndex, int hole) {
    final player = players[playerIndex];
    final controller = strokeControllers[player.name]?[hole];

    if (controller != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: NumberWheelDialog(
            currentValue: controller.text.isNotEmpty ? int.parse(controller.text) : null,
            onNumberSelected: (number) {
              handleNumberSelection(context, playerIndex, hole, number);
            },
          ),
        ),
      );
    }
  }

  // ✅ Function to show hole in one celebration
  void showHoleInOneCelebration(BuildContext context, PlayerData player, int hole) {
    _holeInOneConfettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _holeInOneConfettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.amber, Colors.yellow, Colors.orange, Colors.red, Colors.pink],
            ),
          ),
          Dialog(
            backgroundColor: Colors.transparent,
            child: HoleInOneCelebrationDialog(
              player: player,
              holeNumber: hole,
              onClose: () {
                _holeInOneConfettiController.stop();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Dispose
  void disposeControllers() {
    for (var playerControllers in strokeControllers.values) {
      for (var controller in playerControllers.values) {
        controller.dispose();
      }
    }
    _fadeController.dispose();
    _confettiController.dispose();
    _holeInOneConfettiController.dispose();
    horizontalScrollController.dispose();
  }
}