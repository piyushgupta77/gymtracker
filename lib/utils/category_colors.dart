import 'package:flutter/material.dart';

/// Color mapping for workout categories
class CategoryColors {
  static const Map<String, Color> colors = {
    'Chest': Color(0xFFFFD54F), // Yellow
    'Back': Color(0xFF42A5F5), // Blue
    'Shoulder': Color(0xFFAB47BC), // Purple
    'Legs': Color(0xFF66BB6A), // Green
    'Arms': Color(0xFFFF9800), // Orange
    'Others': Color(0xFF90A4AE), // Grey
  };

  /// Get color for a workout category
  static Color getColor(String category) {
    return colors[category] ?? colors['Others']!;
  }

  /// Get a lighter shade of the category color for background
  static Color getLightColor(String category) {
    final color = getColor(category);
    return color.withValues(alpha: 0.1);
  }

  /// Get all categories with their colors
  static List<MapEntry<String, Color>> getColoredCategories() {
    return colors.entries.toList();
  }
}
