import 'package:flutter/material.dart';

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

  /// Side indicator circle (Left/Right)
  static Widget sideCircle(
    String label,
    String sideCode, {
    bool mini = false,
    Color? textColor,
  }) {
    if (sideCode.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(mini ? 5 : 6),
      decoration: BoxDecoration(
        color: sideCode == 'L' ? Colors.blue : Colors.red,
        shape: BoxShape.circle,
      ),
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
      case 'text':
        return Icons.text_fields;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
  }

  /// Category color mapping
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

  /// Get tab index for category (used in tab navigation)
  static int getTabIndexForCategory(String category) {
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
      case 'other':
        return 5;
      case 'text':
        return 6;
      default:
        return -1;
    }
  }
}
