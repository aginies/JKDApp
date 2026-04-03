import 'package:flutter/material.dart';
import '../../../utils/category_utils.dart';

/// Common widgets for displaying move attributes
class MoveDisplayWidgets {
  /// Level indicator icon (High/Mid/Low)
  static Widget levelIcon(
    String level, {
    double? size,
    bool mini = false,
    Color? color,
  }) {
    if (level.isEmpty) return const SizedBox.shrink();
    IconData id = level.toLowerCase() == 'high'
        ? Icons.north_east
        : (level.toLowerCase() == 'low'
              ? Icons.south_east
              : Icons.arrow_forward);
    return Container(
      padding: EdgeInsets.all(mini ? 5 : 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        shape: BoxShape.circle,
      ),
      child: Icon(
        id,
        size: size ?? (mini ? 11 : 12),
        color: color ?? Colors.white,
      ),
    );
  }

  /// Draw/Feint indicator box
  static Widget drawBox({bool mini = false}) => Container(
    padding: EdgeInsets.symmetric(horizontal: mini ? 4 : 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.orange.shade800,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      'D',
      style: TextStyle(
        fontSize: mini ? 10 : 11,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  static Widget sideCircle(
    String label,
    String sideCode, {
    bool mini = false,
    Color? textColor,
  }) {
    if (sideCode.isEmpty) return const SizedBox.shrink();
    Color bgColor = Colors.blue;
    if (sideCode == 'R') {
      bgColor = Colors.red;
    } else if (sideCode == 'M') {
      bgColor = Colors.green;
    }

    return Container(
      padding: EdgeInsets.all(mini ? 5 : 6),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Text(
        label.substring(0, 1),
        style: TextStyle(
          fontSize: mini ? 11 : 12,
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Category icon mapping
  static IconData getCategoryIcon(String category) {
    return CategoryUtils.getCategoryIcon(category);
  }

  /// Category color mapping
  static Color getCategoryColor(String category) {
    return CategoryUtils.getCategoryColor(category);
  }

  /// Get tab index for category (used in tab navigation)
  static int getTabIndexForCategory(String category, {bool isCounter = false}) {
    if (isCounter) {
      switch (category) {
        case 'packs':
          return 0;
        case 'trapping':
          return 1;
        case 'move':
          return 2;
        case 'jkd_moves':
          return 3;
        case 'kali':
          return 4;
        case 'other':
          return 5;
        case 'text':
          return 6;
        default:
          return -1;
      }
    }

    switch (category) {
      case 'punch':
        return 0;
      case 'kick':
        return 1;
      case 'packs':
        return 2;
      case 'trapping':
        return 3;
      case 'move':
        return 4;
      case 'jkd_moves':
        return 5;
      case 'kali':
        return 6;
      case 'other':
        return 7;
      case 'text':
        return 8;
      default:
        return -1;
    }
  }
}
