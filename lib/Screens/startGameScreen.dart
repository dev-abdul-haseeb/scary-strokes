import 'package:flutter/material.dart';
import 'package:scary_strokes/Screens/MatchScreen.dart';

import '../Widgets/homeScreenButtons.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<StartGameScreen> with TickerProviderStateMixin {
  List<PlayerData> players = [
    PlayerData(name: 'Player 1', iconIndex: 0),
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (players.length < 6) {
      setState(() {
        players.add(PlayerData(
          name: 'Player ${players.length + 1}',
          iconIndex: players.length % 4,
        ));
      });
    }
  }

  void _removePlayer(int index) {
    if (players.length > 1) {
      setState(() {
        players.removeAt(index);
      });
    }
  }

  void _updatePlayerName(int index, String name) {
    setState(() {
      players[index].name = name;
    });
  }

  void _updatePlayerIcon(int index, int iconIndex, String? customImagePath) {
    if (customImagePath != null) {
      setState(() {
        players[index].customImagePath = customImagePath;
      });
      return;
    }

    setState(() {
      players[index].iconIndex = iconIndex;
    });
  }

  void _startMatch() {
    // Validate that all players have names
    bool allNamesValid = players.every((p) => p.name.trim().isNotEmpty);
    if (!allNamesValid) {
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
        builder: (context) => StartMatchScreen(players: players),
      ),
    );
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
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFFFF8C00), Color(0xFFFFB347)],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Setup Game',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8C00).withValues(alpha:0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${players.length} Player${players.length > 1 ? 's' : ''}',
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
                        ],
                      ),
                    ),

                    // Players list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          return PlayerCard(
                            player: players[index],
                            index: index,
                            canRemove: players.length > 1,
                            onRemove: () => _removePlayer(index),
                            onNameChanged: (name) => _updatePlayerName(index, name),
                            onIconChanged: (iconIndex, customImagePath) => _updatePlayerIcon(index, iconIndex, customImagePath),
                          );
                        },
                      ),
                    ),

                    // Bottom actions
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (players.length < 6)
                            GestureDetector(
                              onTap: _addPlayer,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF2D2D44).withValues(alpha:0.6),
                                      const Color(0xFF1F1F2E).withValues(alpha:0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
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
                                    const Icon(
                                      Icons.add_circle_outline,
                                      color: Color(0xFF9D4EDD),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Add Player (${players.length}/6)',
                                      style: const TextStyle(
                                        color: Color(0xFF9D4EDD),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Start Match Button
                          EnhancedHomeButton(
                            title: 'Start Match',
                            icon: Icons.play_arrow_rounded,
                            gradientColors: const [Color(0xFFFF8C00), Color(0xFFE63946)],
                            glowColor: const Color(0xFFFF8C00),
                            onTap: () {
                              _startMatch();
                            },
                            delay: 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerData {
  String name;
  int iconIndex;
  String? customImagePath; // Add this for custom images

  PlayerData({
    required this.name,
    required this.iconIndex,
    this.customImagePath,
  });

  // Helper method to get display image
  String? get displayImagePath {
    return customImagePath;
  }
}



class PlayerCard extends StatefulWidget {
  final PlayerData player;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final Function(String) onNameChanged;
  final Function(int, String?) onIconChanged; // Updated function

  const PlayerCard({
    super.key,
    required this.player,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onNameChanged,
    required this.onIconChanged,
  });

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  bool _showIconPicker = false;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  final ImagePicker _picker = ImagePicker();
  File? _customImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleIconPicker() {
    setState(() {
      _showIconPicker = !_showIconPicker;
      if (_showIconPicker) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (pickedFile != null) {
        setState(() {
          _customImage = File(pickedFile.path);
        });
        widget.onIconChanged(-1, pickedFile.path); // -1 indicates custom image
        _toggleIconPicker();
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
      print('Error picking image: $e');
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE63946) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D44).withValues(alpha:0.6),
            const Color(0xFF1F1F2E).withValues(alpha:0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF8C00).withValues(alpha:0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Player icon - Show custom image if available
                GestureDetector(
                  onTap: _toggleIconPicker,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E).withValues(alpha:0.8),
                          const Color(0xFF0A0A0F).withValues(alpha:0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFF8C00).withValues(alpha:0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withValues(alpha:0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _customImage != null
                              ? Image.file(
                            _customImage!,
                            fit: BoxFit.cover,
                            width: 75,
                            height: 75,
                          )
                              : Image.asset(
                            'Assets/${widget.player.iconIndex + 1}.png',
                            fit: BoxFit.cover,
                            width: 75,
                            height: 75,
                          ),
                        ),
                        // Tap indicator
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0A0F).withValues(alpha:0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _showIconPicker ? Icons.expand_less : Icons.expand_more,
                              color: const Color(0xFFFF8C00),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Player name input
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Player ${widget.index + 1}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        onChanged: widget.onNameChanged,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter name',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha:0.3),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove button
                if (widget.canRemove)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE63946).withValues(alpha:0.3),
                            const Color(0xFFE63946).withValues(alpha:0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE63946).withValues(alpha:0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFFE63946),
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Icon picker with animation
          SizeTransition(
            sizeFactor: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A1A2E).withValues(alpha:0.6),
                      const Color(0xFF0A0A0F).withValues(alpha:0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFFF8C00).withValues(alpha:0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Avatar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Camera and Gallery Options
                    Row(
                      children: [
                        // Camera Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF8C00).withValues(alpha:0.2),
                                    const Color(0xFFFF8C00).withValues(alpha:0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: const Color(0xFFFF8C00),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Camera',
                                    style: TextStyle(
                                      color: Color(0xFFFF8C00),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Gallery Option
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF7B2CBF).withValues(alpha:0.2),
                                    const Color(0xFF7B2CBF).withValues(alpha:0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF7B2CBF).withValues(alpha:0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.photo_library_rounded,
                                    color: const Color(0xFF7B2CBF),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Gallery',
                                    style: TextStyle(
                                      color: Color(0xFF7B2CBF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),

                    Text(
                      'Default Icons',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Default icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        bool isSelected = widget.player.iconIndex == index && _customImage == null;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _customImage = null;
                            });
                            widget.onIconChanged(index, null);
                            Future.delayed(const Duration(milliseconds: 200), () {
                              _toggleIconPicker();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0A0A0F).withValues(alpha:0.8),
                                  const Color(0xFF1A1A2E).withValues(alpha:0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF8C00)
                                    : Colors.white.withValues(alpha:0.2),
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFFFF8C00).withValues(alpha:0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.asset(
                                'Assets/${index + 1}.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


