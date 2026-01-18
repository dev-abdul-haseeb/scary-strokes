import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../model/player_model.dart';

// Hole in One Celebration Dialog
class HoleInOneCelebrationDialog extends StatelessWidget {
  final PlayerData player;
  final int holeNumber;
  final VoidCallback onClose;

  const HoleInOneCelebrationDialog({
    super.key,
    required this.player,
    required this.holeNumber,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.85,
        maxHeight: screenHeight * 0.7,
      ),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha:0.95),
            Colors.orange.withValues(alpha:0.95),
            Colors.deepOrange.withValues(alpha:0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.08),
        border: Border.all(color: Colors.yellow, width: 4),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                '⛳ HOLE IN ONE! ⛳',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.09,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha:0.3),
                    Colors.white.withValues(alpha:0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                children: [
                  FittedBox(
                    child: Text(
                      'AMAZING SHOT!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: screenWidth * 0.25,
                    height: screenWidth * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.125),
                      border: Border.all(color: Colors.yellow, width: 5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.12),
                      child: player.customImagePath != null
                          ? Image.file(File(player.customImagePath!), fit: BoxFit.cover)
                          : Image.asset('Assets/${player.iconIndex + 1}.png', fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  FittedBox(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      child: Text(
                        player.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  FittedBox(
                    child: Text(
                      'scored a perfect shot on',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    child: Text(
                      'HOLE $holeNumber',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.12,
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.green, Colors.lightGreen]),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: FittedBox(
                  child: Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
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

class NumberWheelDialog extends StatefulWidget {
  final int? currentValue;
  final Function(int) onNumberSelected;
  const NumberWheelDialog({
    super.key,
    this.currentValue,
    required this.onNumberSelected,
  });

  @override
  State<NumberWheelDialog> createState() => _NumberWheelDialogState();
}

class _NumberWheelDialogState extends State<NumberWheelDialog> {
  int _selectedNumber = 1;
  List<int> _numbers = [];

  @override
  void initState() {
    super.initState();
    _selectedNumber = widget.currentValue ?? 1;
    _numbers = List.generate(6, (index) => index + 1);
  }

  void _handleTap(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double dx = localPosition.dx - center.dx;
    final double dy = localPosition.dy - center.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);

    if (distance < size.width * 0.15) return;

    double angle = math.atan2(dy, dx);
    angle = angle * 180 / math.pi;

    if (angle < 0) angle += 360;
    angle = (angle + 90) % 360;

    final double segmentAngle = 360 / _numbers.length;
    int selectedIndex = (angle / segmentAngle).floor();
    if (selectedIndex >= _numbers.length) selectedIndex = 0;

    setState(() {
      _selectedNumber = _numbers[selectedIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth * 0.8;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        _handleTap(localPosition, Size(size, size));
      },
      onTap: () => widget.onNumberSelected(_selectedNumber),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D44).withValues(alpha:0.95),
              const Color(0xFF1F1F2E).withValues(alpha:0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.1),
          border: Border.all(color: const Color(0xFFFF8C00).withValues(alpha:0.5), width: 3),
        ),
        child: Stack(
          children: [
            ..._buildPieSegments(size),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFE63946)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_selectedNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPieSegments(double size) {
    final List<Color> colors = [
      const Color(0xFFFF5252),
      const Color(0xFFFF9800),
      const Color(0xFFFFEB3B),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];

    return _numbers.asMap().entries.map((entry) {
      final index = entry.key;
      final number = entry.value;
      final angle = 2 * math.pi / _numbers.length;
      final startAngle = index * angle - math.pi / 2;
      final isSelected = _selectedNumber == number;
      final color = colors[index % colors.length];

      return Positioned.fill(
        child: CustomPaint(
          painter: PieSegmentPainter(
            startAngle: startAngle,
            sweepAngle: angle,
            color: color.withValues(alpha:isSelected ? 1.0 : 0.7),
            isSelected: isSelected,
            segmentIndex: index,
            number: number,
            size: size,
          ),
        ),
      );
    }).toList();
  }
}

class PieSegmentPainter extends CustomPainter {
  final double startAngle;
  final double sweepAngle;
  final Color color;
  final bool isSelected;
  final int segmentIndex;
  final int number;
  final double size;

  PieSegmentPainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
    required this.isSelected,
    required this.segmentIndex,
    required this.number,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );

    if (isSelected) {
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: this.size * 0.08,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final double textRadius = radius * 0.6;
    final double textAngle = startAngle + sweepAngle / 2;
    final Offset textPosition = Offset(
      center.dx + textRadius * math.cos(textAngle),
      center.dy + textRadius * math.sin(textAngle),
    );

    canvas.save();
    canvas.translate(textPosition.dx, textPosition.dy);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WinnerCelebrationDialog extends StatelessWidget {
  final PlayerData winner;
  final int winnerScore;
  final VoidCallback onClose;
  const WinnerCelebrationDialog({
    super.key,
    required this.winner,
    required this.winnerScore,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.85,
        maxHeight: screenHeight * 0.8,
      ),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha:0.9),
            Colors.blue.withValues(alpha:0.9),
            Colors.green.withValues(alpha:0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.08),
        border: Border.all(color: const Color(0xFFFFD700), width: 3),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: const Color(0xFFFFD700),
              size: screenWidth * 0.15,
            ),
            SizedBox(height: screenHeight * 0.015),
            FittedBox(
              child: Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha:0.3),
                    const Color(0xFFFFD700).withValues(alpha:0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                children: [
                  FittedBox(
                    child: Text(
                      'The Winner is',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Container(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.1),
                      border: Border.all(color: const Color(0xFFFFD700), width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.1),
                      child: winner.customImagePath != null
                          ? Image.file(File(winner.customImagePath!), fit: BoxFit.cover)
                          : Image.asset('Assets/${winner.iconIndex + 1}.png', fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  FittedBox(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      child: Text(
                        winner.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  FittedBox(
                    child: Text(
                      'with a score of',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  Text(
                    '$winnerScore',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.018,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.green, Colors.lightGreen]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  child: Text(
                    'VIEW LEADERBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
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

class FinalLeaderboardDialog extends StatelessWidget {
  final List<PlayerData> players;
  final Map<String, int> finalScores;
  final VoidCallback onFinish;
  const FinalLeaderboardDialog({
    super.key,
    required this.players,
    required this.finalScores,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    List<PlayerData> topThree = players.length >= 3 ? players.sublist(0, 3) : players;
    List<PlayerData> otherPlayers = players.length > 3 ? players.sublist(3) : [];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.9,
          maxHeight: screenHeight * 0.9,
        ),
        padding: EdgeInsets.all(screenWidth * 0.06),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D44).withValues(alpha:0.95),
              const Color(0xFF1F1F2E).withValues(alpha:0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.08),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha:0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FINAL LEADERBOARD',
              style: TextStyle(
                color: const Color(0xFFFFB347),
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (topThree.length >= 2)
                  _buildPodiumPlayer(
                    player: topThree[1],
                    score: finalScores[topThree[1].name]!,
                    place: 2,
                    medalColor: Colors.grey,
                    height: screenHeight * 0.15,
                    screenWidth: screenWidth,
                  ),
                if (topThree.isNotEmpty)
                  _buildPodiumPlayer(
                    player: topThree[0],
                    score: finalScores[topThree[0].name]!,
                    place: 1,
                    medalColor: const Color(0x00ffd100),
                    height: screenHeight * 0.2,
                    screenWidth: screenWidth,
                  ),
                if (topThree.length >= 3)
                  _buildPodiumPlayer(
                    player: topThree[2],
                    score: finalScores[topThree[2].name]!,
                    place: 3,
                    medalColor: const Color(0xFFCD7F32),
                    height: screenHeight * 0.12,
                    screenWidth: screenWidth,
                  ),
              ],
            ),
            SizedBox(height: screenHeight * 0.04),
            if (otherPlayers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other Players',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ...otherPlayers.map((player) {
                    return Container(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A1A2E).withValues(alpha:0.6),
                            const Color(0xFF0A0A0F).withValues(alpha:0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              border: Border.all(color: Colors.white.withValues(alpha:0.3)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              child: player.customImagePath != null
                                  ? Image.file(File(player.customImagePath!), fit: BoxFit.cover)
                                  : Image.asset('Assets/${player.iconIndex + 1}.png', fit: BoxFit.cover),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Text(
                              player.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${finalScores[player.name]}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.7),
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            '#${players.indexOf(player) + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.5),
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            SizedBox(height: screenHeight * 0.04),
            GestureDetector(
              onTap: onFinish,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFE63946)]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'FINISH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumPlayer({
    required PlayerData player,
    required int score,
    required int place,
    required Color medalColor,
    required double height,
    required double screenWidth,
  }) {
    return Column(
      children: [
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.1,
          decoration: BoxDecoration(
            color: medalColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              place == 1 ? '🥇' : place == 2 ? '🥈' : '🥉',
              style: TextStyle(fontSize: screenWidth * 0.05),
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Container(
          width: screenWidth * 0.2,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                medalColor.withValues(alpha:0.3),
                medalColor.withValues(alpha:0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(color: medalColor.withValues(alpha:0.5), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  border: Border.all(color: medalColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: player.customImagePath != null
                      ? Image.file(File(player.customImagePath!), fit: BoxFit.cover)
                      : Image.asset('Assets/${player.iconIndex + 1}.png', fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                player.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                '$score',
                style: TextStyle(
                  color: medalColor,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MultipleWinnersCelebrationDialog extends StatelessWidget {
  final List<PlayerData> winners;
  final int winnerScore;
  final VoidCallback onClose;

  const MultipleWinnersCelebrationDialog({
    super.key,
    required this.winners,
    required this.winnerScore,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.9,
        maxHeight: screenHeight * 0.85,
      ),
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha:0.9),
            Colors.blue.withValues(alpha:0.9),
            Colors.green.withValues(alpha:0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.08),
        border: Border.all(color: const Color(0xFFFFD700), width: 3),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: const Color(0xFFFFD700),
              size: screenWidth * 0.15,
            ),
            SizedBox(height: screenHeight * 0.015),
            FittedBox(
              child: Text(
                "IT'S A TIE!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.09,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            FittedBox(
              child: Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha:0.3),
                    const Color(0xFFFFD700).withValues(alpha:0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                children: [
                  FittedBox(
                    child: Text(
                      winners.length == 2 ? 'The Winners are' : 'The Winners are',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ...winners.map((winner) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                      child: Column(
                        children: [
                          Container(
                            width: screenWidth * 0.18,
                            height: screenWidth * 0.18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(screenWidth * 0.09),
                              border: Border.all(color: const Color(0xFFFFD700), width: 4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(screenWidth * 0.09),
                              child: winner.customImagePath != null
                                  ? Image.file(File(winner.customImagePath!), fit: BoxFit.cover)
                                  : Image.asset('Assets/${winner.iconIndex + 1}.png', fit: BoxFit.cover),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          FittedBox(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                              child: Text(
                                winner.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: screenHeight * 0.01),
                  FittedBox(
                    child: Text(
                      'with a score of',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  Text(
                    '$winnerScore',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.018,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.green, Colors.lightGreen]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  child: Text(
                    'VIEW LEADERBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
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

class MischiefWheelDialog extends StatefulWidget {
  final int holeNumber;
  final String playerName;
  const MischiefWheelDialog({
    super.key,
    required this.holeNumber,
    required this.playerName,
  });

  @override
  State<MischiefWheelDialog> createState() => _MischiefWheelDialogState();
}

class _MischiefWheelDialogState extends State<MischiefWheelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  double _wheelAngle = 0.0;
  bool _isSpinning = false;
  String _selectedAction = '';

  final List<String> _wheelActions = [
    'PUTT WITH YOUR EYES CLOSED',
    'PUTT BACKWARDS',
    'USE YOUR OPPOSITE HAND',
    'USE A HOCKEY STICK MOTION',
    'PUTT WITH ONE HAND',
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _selectedAction = '';
    });

    final random = math.Random();
    final rotations = 3 + random.nextInt(3);
    final segmentAngle = 360 / _wheelActions.length;
    final randomSegment = random.nextInt(_wheelActions.length);
    final targetAngle = (rotations * 360) + (randomSegment * segmentAngle);

    _spinController.reset();
    final spinAnimation = Tween<double>(
      begin: _wheelAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    ));

    spinAnimation.addListener(() {
      setState(() {
        _wheelAngle = spinAnimation.value % 360;
      });
    });

    spinAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final normalizedAngle = _wheelAngle % 360;
        final segmentAngle = 360 / _wheelActions.length;
        int selectedIndex = ((360 - normalizedAngle) / segmentAngle).floor() % _wheelActions.length;

        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _selectedAction = _wheelActions[selectedIndex];
            _isSpinning = false;
          });
        });
      }
    });

    _spinController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 380;
    final wheelSize = isSmallScreen ? screenWidth * 0.7 : screenWidth * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isSmallScreen ? 10 : 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenWidth * 0.95 : screenWidth * 0.9,
          maxHeight: screenHeight * 0.85,
        ),
        width: wheelSize,
        padding: EdgeInsets.all(isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.05),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E).withValues(alpha:0.95),
              const Color(0xFF0F3460).withValues(alpha:0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.08),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha:0.7), width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(
                    Icons.casino,
                    color: Colors.white,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCARY STROKES',
                        style: TextStyle(
                          color: const Color(0xFFFFD700),
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Wheel of Mischief',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text('PLAYER', style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.03)),
                      Text(widget.playerName, style: TextStyle(color: const Color(0xFFFFD700), fontSize: screenWidth * 0.04)),
                    ],
                  ),
                  SizedBox(width: screenWidth * 0.08),
                  Column(
                    children: [
                      Text('HOLE', style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.03)),
                      Text('${widget.holeNumber}', style: TextStyle(color: const Color(0xFFFFD700), fontSize: screenWidth * 0.04)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: wheelSize * 0.9,
                  height: wheelSize * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha:0.3),
                        const Color(0xFFE63946).withValues(alpha:0.2),
                      ],
                    ),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha:0.5), width: 5),
                  ),
                ),
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _wheelAngle * (math.pi / 180),
                      child: CustomPaint(
                        size: Size(wheelSize * 0.8, wheelSize * 0.8),
                        painter: WheelPainter(
                          actions: _wheelActions,
                          selectedIndex: _selectedAction.isNotEmpty ? _wheelActions.indexOf(_selectedAction) : -1,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: wheelSize * 0.25,
                  height: wheelSize * 0.25,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFE63946)]),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Text(
                      'SPIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: wheelSize * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: wheelSize * 0.05,
                  child: Container(
                    width: wheelSize * 0.1,
                    height: wheelSize * 0.15,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE63946),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            if (_selectedAction.isNotEmpty)
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFF4CAF50)]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text('YOUR CHALLENGE:', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
                    SizedBox(height: screenHeight * 0.01),
                    Text(_selectedAction, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045)),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Spin the wheel for a random challenge!',
                  style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.04),
                ),
              ),
            SizedBox(height: screenHeight * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.015),
                  ),
                  child: Text('CLOSE', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035)),
                ),
                ElevatedButton(
                  onPressed: _isSpinning ? null : _spinWheel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.015),
                  ),
                  child: Text(
                    _isSpinning ? 'SPINNING...' : 'SPIN WHEEL',
                    style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> actions;
  final int selectedIndex;

  WheelPainter({
    required this.actions,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / actions.length;

    final colors = [
      const Color(0xFFFF5252),
      const Color(0xFFFF9800),
      const Color(0xFFFFEB3B),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];

    for (int i = 0; i < actions.length; i++) {
      final startAngle = i * segmentAngle;
      final paint = Paint()
        ..color = selectedIndex == i
            ? colors[i % colors.length].withValues(alpha:1.0)
            : colors[i % colors.length].withValues(alpha:0.7)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha:0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.7;
      final textPosition = Offset(
        center.dx + textRadius * math.cos(textAngle),
        center.dy + textRadius * math.sin(textAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: actions[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(textPosition.dx, textPosition.dy);
      canvas.rotate(textAngle + math.pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}