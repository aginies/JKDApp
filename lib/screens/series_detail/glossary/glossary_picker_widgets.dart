// Widget helper components for glossary picker UI
// These are reusable widgets used by the glossary picker

import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';

/// Helper widget collection for glossary picker
/// Contains reusable button and selection widgets
class GlossaryPickerWidgets {
  /// Build level selection button for counters
  static Widget counterLevelButton(
    BuildContext context,
    String level,
    int id,
    VoidCallback onActivate,
    String lang, {
    bool isSelected = false,
    bool withArrow = false,
  }) {
    IconData icon = level == 'High'
        ? Icons.north_east
        : (level == 'Low' ? Icons.south_east : Icons.arrow_forward);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(60, 32),
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      onPressed: onActivate,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocalizationService.translate(
              level.toLowerCase(),
              lang,
            ).substring(0, 1),
            style: const TextStyle(fontSize: 11),
          ),
          if (withArrow) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: isSelected ? Colors.white : null),
          ],
        ],
      ),
    );
  }

  /// Build side button with arrow for trapping/packs
  static Widget sideButtonWithArrow(
    String label,
    String side,
    Color color,
    VoidCallback onPressed,
    String lang,
    int id,
  ) {
    IconData icon = side == 'L' ? Icons.arrow_back : Icons.arrow_forward;

    return ActionChip(
      onPressed: onPressed,
      backgroundColor: color.withValues(alpha: 0.15),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (side == 'L') ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (side == 'R') ...[
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: color),
          ],
        ],
      ),
    );
  }

  /// Build picker side button with selection state
  static Widget pickerSideButton(
    String label,
    String side,
    String currentSide,
    Color color,
    int id,
    VoidCallback? onSelected,
    String lang, {
    bool withArrow = false,
  }) {
    final bool isSelected = currentSide == side;
    IconData icon = side == 'L' ? Icons.arrow_back : Icons.arrow_forward;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withArrow && side == 'L') ...[
            Icon(icon, size: 12, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (withArrow && side == 'R') ...[
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: isSelected ? Colors.white : color),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.7),
      backgroundColor: color.withValues(alpha: 0.15),
      onSelected: onSelected != null ? (selected) => onSelected() : null,
    );
  }

  /// Build level selection button for non-directional moves
  static Widget levelSelectionButton(
    BuildContext context,
    String level,
    int id,
    VoidCallback onActivate,
    String lang, {
    bool isSelected = false,
  }) {
    IconData icon = level == 'High'
        ? Icons.north_east
        : (level == 'Low' ? Icons.south_east : Icons.arrow_forward);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(60, 32),
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      onPressed: onActivate,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocalizationService.translate(
              level.toLowerCase(),
              lang,
            ).substring(0, 1),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: isSelected ? Colors.white : null),
        ],
      ),
    );
  }

  /// Build workflow buttons (next/+/chain/answer/finish/cancel)
  static Widget workflowButtons(
    BuildContext context,
    String actionLabel,
    bool isCounterMode,
    bool isEditing, {
    VoidCallback? onNext,
    VoidCallback? onSimultaneous,
    VoidCallback? onChain,
    VoidCallback? onAnswer,
    VoidCallback? onFinish,
    VoidCallback? onCancel,
    String? lang,
  }) {
    // Labels
    final String finishLabel = LocalizationService.translate(
      'finish',
      lang ?? 'en',
    );
    final String cancelButton = LocalizationService.translate(
      'cancel',
      lang ?? 'en',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Primary action button (Next/Update/Add)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: onNext,
              child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
            ),

            // Simultaneous (+) button - shown when not editing
            if (!isEditing && onSimultaneous != null) ...[
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: onSimultaneous,
                child: const Text(
                  '+',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],

            // Chain button (→) - shown when not editing
            if (!isEditing && onChain != null) ...[
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: onChain,
                child: const Icon(Icons.arrow_forward, size: 16),
              ),
            ],

            // Answer button (if not counter mode, not editing, and onAnswer provided)
            if (!isCounterMode && !isEditing && onAnswer != null) ...[
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: onAnswer,
                child: Text(
                  LocalizationService.translate('answer', lang ?? 'en'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),

        // Right-side buttons (Finish, Cancel)
        Row(
          children: [
            if (onFinish != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: onFinish,
                child: Text(finishLabel, style: const TextStyle(fontSize: 12)),
              ),
            if (onFinish != null && onCancel != null) const SizedBox(width: 6),
            if (onCancel != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: onCancel,
                child: Text(cancelButton, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }
}
