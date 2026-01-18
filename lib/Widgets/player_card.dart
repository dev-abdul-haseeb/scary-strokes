import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/player_model.dart';

class PlayerCard extends StatefulWidget {
  final PlayerData player;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final Function(String) onNameChanged;
  final Function(int, String?) onIconChanged;
  final double screenWidth;
  final bool isSmallScreen;

  const PlayerCard({
    super.key,
    required this.player,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onNameChanged,
    required this.onIconChanged,
    required this.screenWidth,
    required this.isSmallScreen,
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
        widget.onIconChanged(-1, pickedFile.path);
        _toggleIconPicker();
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
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
    final avatarSize = widget.isSmallScreen ? 60.0 : 75.0;
    final cardPadding = widget.isSmallScreen ? 12.0 : 16.0;
    final iconSize = widget.isSmallScreen ? 20.0 : 24.0;
    final fontSize = widget.isSmallScreen ? 16.0 : 20.0;
    final smallIconSize = widget.isSmallScreen ? 14.0 : 16.0;

    return Container(
      margin: EdgeInsets.only(bottom: widget.isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D44).withValues(alpha:0.6),
            const Color(0xFF1F1F2E).withValues(alpha:0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(widget.isSmallScreen ? 15.0 : 20.0),
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
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // Player icon - RESPONSIVE
                GestureDetector(
                  onTap: _toggleIconPicker,
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E).withValues(alpha:0.8),
                          const Color(0xFF0A0A0F).withValues(alpha:0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.isSmallScreen ? 12.0 : 18.0),
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
                          borderRadius: BorderRadius.circular(widget.isSmallScreen ? 10.0 : 15.0),
                          child: _customImage != null
                              ? Image.file(
                            _customImage!,
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                          )
                              : Image.asset(
                            'Assets/${widget.player.iconIndex + 1}.png',
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                          ),
                        ),
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
                              size: smallIconSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: widget.isSmallScreen ? 12.0 : 16.0),

                // Player name input - RESPONSIVE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Player ${widget.index + 1}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha:0.5),
                          fontSize: widget.isSmallScreen ? 10.0 : 12.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: widget.isSmallScreen ? 4.0 : 6.0),
                      TextField(
                        controller: _nameController,
                        onChanged: widget.onNameChanged,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter name',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha:0.3),
                            fontWeight: FontWeight.w500,
                            fontSize: widget.isSmallScreen ? 14.0 : 16.0,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove button - RESPONSIVE
                if (widget.canRemove)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: EdgeInsets.all(widget.isSmallScreen ? 8.0 : 10.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE63946).withValues(alpha:0.3),
                            const Color(0xFFE63946).withValues(alpha:0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(widget.isSmallScreen ? 8.0 : 12.0),
                        border: Border.all(
                          color: const Color(0xFFE63946).withValues(alpha:0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        color: const Color(0xFFE63946),
                        size: iconSize,
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
              padding: EdgeInsets.fromLTRB(
                cardPadding,
                0,
                cardPadding,
                cardPadding,
              ),
              child: Container(
                padding: EdgeInsets.all(widget.isSmallScreen ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A1A2E).withValues(alpha:0.6),
                      const Color(0xFF0A0A0F).withValues(alpha:0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.isSmallScreen ? 10.0 : 15.0),
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
                        fontSize: widget.isSmallScreen ? 10.0 : 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: widget.isSmallScreen ? 8.0 : 12.0),

                    // Camera and Gallery Options - RESPONSIVE
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: widget.isSmallScreen ? 10.0 : 12.0,
                              ),
                              margin: EdgeInsets.only(right: widget.isSmallScreen ? 4.0 : 6.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF8C00).withValues(alpha:0.2),
                                    const Color(0xFFFF8C00).withValues(alpha:0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(widget.isSmallScreen ? 8.0 : 12.0),
                                border: Border.all(
                                  color: const Color(0xFFFF8C00).withValues(alpha:0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: const Color(0xFFFF8C00),
                                    size: widget.isSmallScreen ? 22.0 : 28.0,
                                  ),
                                  SizedBox(height: widget.isSmallScreen ? 4.0 : 6.0),
                                  Text(
                                    'Camera',
                                    style: TextStyle(
                                      color: const Color(0xFFFF8C00),
                                      fontSize: widget.isSmallScreen ? 10.0 : 12.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: widget.isSmallScreen ? 10.0 : 12.0,
                              ),
                              margin: EdgeInsets.only(left: widget.isSmallScreen ? 4.0 : 6.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF7B2CBF).withValues(alpha:0.2),
                                    const Color(0xFF7B2CBF).withValues(alpha:0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(widget.isSmallScreen ? 8.0 : 12.0),
                                border: Border.all(
                                  color: const Color(0xFF7B2CBF).withValues(alpha:0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.photo_library_rounded,
                                    color: const Color(0xFF7B2CBF),
                                    size: widget.isSmallScreen ? 22.0 : 28.0,
                                  ),
                                  SizedBox(height: widget.isSmallScreen ? 4.0 : 6.0),
                                  Text(
                                    'Gallery',
                                    style: TextStyle(
                                      color: const Color(0xFF7B2CBF),
                                      fontSize: widget.isSmallScreen ? 10.0 : 12.0,
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

                    SizedBox(height: widget.isSmallScreen ? 12.0 : 16.0),
                    Divider(color: Colors.white24, height: 1),
                    SizedBox(height: widget.isSmallScreen ? 12.0 : 16.0),

                    Text(
                      'Default Icons',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.7),
                        fontSize: widget.isSmallScreen ? 10.0 : 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: widget.isSmallScreen ? 8.0 : 12.0),

                    // Default icons - RESPONSIVE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        bool isSelected = widget.player.iconIndex == index && _customImage == null;
                        final defaultIconSize = widget.isSmallScreen ? 50.0 : 65.0;

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
                            width: defaultIconSize,
                            height: defaultIconSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0A0A0F).withValues(alpha:0.8),
                                  const Color(0xFF1A1A2E).withValues(alpha:0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(widget.isSmallScreen ? 10.0 : 15.0),
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
                              borderRadius: BorderRadius.circular(widget.isSmallScreen ? 8.0 : 13.0),
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