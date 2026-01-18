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