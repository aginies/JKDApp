// Simple wrapper widget for glossary list
// Delegates all functionality to glossary_ui_builder.dart

import 'package:flutter/material.dart';
import '../glossary/glossary_ui_builder.dart';

/// Wrapper for GlossaryUIBuilder to simplify integration
class GlossaryListWidget extends StatelessWidget {
  final String category;
  final int? initialIndex;
  final bool isCounterMode;
  final Map<String, dynamic>? attackMove;
  final bool isSimultaneous;
  final dynamic pickerState;
  final List<dynamic> currentCombo;
  final Function()? onShowMediaGallery;
  final Function()? onActivateGlossaryItem;

  const GlossaryListWidget({
    super.key,
    required this.category,
    this.initialIndex,
    this.isCounterMode = false,
    this.attackMove,
    this.isSimultaneous = false,
    required this.pickerState,
    required this.currentCombo,
    this.onShowMediaGallery,
    this.onActivateGlossaryItem,
  });

  @override
  Widget build(BuildContext context) {
    return GlossaryUIBuilder.buildGlossaryList(
      context,
      category,
      (dynamic newState) {},
      initialIndex: initialIndex,
      isCounterMode: isCounterMode,
      attackMove: attackMove,
      isSimultaneous: isSimultaneous,
      pickerState: pickerState,
      currentCombo: currentCombo,
      onShowMediaGallery: onShowMediaGallery,
      onActivateGlossaryItem: onActivateGlossaryItem,
    );
  }
}
