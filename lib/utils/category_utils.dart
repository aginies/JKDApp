import 'package:flutter/material.dart';

/// Utility class for category-related operations across the app
class CategoryUtils {
  /// Get icon for a category
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'punch':
        return Icons.sports_mma;
      case 'kick':
        return Icons.sports_martial_arts;
      case 'packs':
        return Icons.front_hand;
      case 'trapping':
        return Icons.sports_kabaddi;
      case 'move':
        return Icons.directions_walk;
      case 'kali':
        return Icons.change_history;
      case 'text':
        return Icons.text_fields;
      case 'other':
        return Icons.more_horiz;
      case 'simultaneous':
        return Icons.add_circle_outline;
      case 'chain':
        return Icons.arrow_forward;
      default:
        return Icons.help_outline;
    }
  }

  /// Get color for a category
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'punch':
        return Colors.purple;
      case 'kick':
        return Colors.red;
      case 'packs':
        return Colors.green;
      case 'trapping':
        return Colors.blue;
      case 'move':
        return Colors.pink;
      case 'kali':
        return Colors.brown;
      case 'text':
        return Colors.teal;
      case 'combo':
        return Colors.orange;
      case 'other':
        return Colors.blueGrey;
      case 'simultaneous':
        return Colors.deepPurple;
      case 'chain':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Get directory name for a category
  /// Capitalizes first letter: punches -> Punches
  static String getCategoryDirName(String category) {
    if (category.isEmpty) return 'Other';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }
}
