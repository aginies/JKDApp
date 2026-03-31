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
        return Icons.back_hand;
      case 'move':
        return Icons.directions_run;
      case 'jkd_moves':
        return Icons.directions_run;
      case 'text':
        return Icons.text_fields;
      case 'other':
        return Icons.more_horiz;
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
      case 'jkd_moves':
        return Colors.blue;
      case 'text':
        return Colors.teal;
      case 'combo':
        return Colors.orange;
      case 'other':
        return Colors.blueGrey;
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
