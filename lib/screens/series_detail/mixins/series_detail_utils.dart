import 'package:flutter/material.dart';
import '../../../models/move.dart';
import '../../../services/database_service.dart';
import '../constants/series_detail_constants.dart';
import '../state/picker_state.dart';

/// Mixin containing utility methods for series detail screen functionality
mixin SeriesDetailUtils {
  // These properties should be provided by the class using this mixin
  List<Move> get moves;
  ScrollController get movesScrollController;
  PickerState get pickerState;

  /// Get available sub-letters for a move at the target index
  List<String> getAvailableSubLetters(int? targetIndex, int? editingIndex) {
    if (targetIndex == null) return 'abcdefg'.split('');

    // Calculate display numbers for current moves
    int currentMainNumber = 0;
    final List<int> displayNumbers = [];
    for (int i = 0; i < moves.length; i++) {
      if (moves[i].category != 'move') {
        if (moves[i].subLetter == null) {
          currentMainNumber++;
        }
        int effective = currentMainNumber;
        if (effective == 0) effective = 1;
        displayNumbers.add(effective);
      } else {
        displayNumbers.add(0);
      }
    }

    if (targetIndex < 0 || targetIndex >= displayNumbers.length) {
      return 'abcdefg'.split('');
    }

    final targetMainNumber = displayNumbers[targetIndex];
    final takenLetters = <String>{};

    for (int i = 0; i < moves.length; i++) {
      if (i == editingIndex) continue; // Exclude the one we are editing
      if (displayNumbers[i] == targetMainNumber && moves[i].subLetter != null) {
        takenLetters.add(moves[i].subLetter!);
      }
    }

    return 'abcdefg'.split('').where((l) => !takenLetters.contains(l)).toList();
  }

  /// Get display number for a move at the given index
  String getDisplayNumber(int index) {
    if (index < 0 || index >= moves.length) return '';

    int currentMainNumber = 0;
    for (int i = 0; i <= index; i++) {
      if (moves[i].category != 'move') {
        if (moves[i].subLetter == null) {
          currentMainNumber++;
        }
      }
    }

    int effectiveMain = currentMainNumber;
    if (effectiveMain == 0) effectiveMain = 1;

    final sub = moves[index].subLetter ?? '';
    if (moves[index].category == 'move') return '';
    return '$effectiveMain$sub';
  }

  /// Normalize sub-letters to be sequential (a, b, c, ...)
  List<Move> normalizeSubLetters(List<Move> movesList) {
    List<Move> normalizedMoves = List.from(movesList);
    int subIndex = 0;

    for (int i = 0; i < normalizedMoves.length; i++) {
      if (normalizedMoves[i].category == 'move') continue;

      if (normalizedMoves[i].subLetter == null) {
        subIndex = 0;
      } else {
        const letters = 'abcdefghijklmnopqrstuvwxyz';
        if (subIndex < letters.length) {
          normalizedMoves[i] = normalizedMoves[i].copyWith(
            subLetter: letters[subIndex],
          );
          subIndex++;
        }
      }
    }

    return normalizedMoves;
  }

  /// Scroll to a specific index in the moves list
  void scrollToIndex(int index) {
    if (!movesScrollController.hasClients) return;

    final double targetOffset =
        (index * SeriesDetailConstants.estimatedMoveItemHeight).clamp(
          0.0,
          movesScrollController.position.maxScrollExtent,
        );

    movesScrollController.animateTo(
      targetOffset,
      duration: const Duration(
        milliseconds: SeriesDetailConstants.scrollAnimationMs,
      ),
      curve: Curves.easeInOut,
    );
  }

  /// Get initial index for a category based on pending action item
  Future<int> getInitialIndexForCategory(String category) async {
    if (pickerState.pendingActionItemId == null) return -1;
    final items = await DatabaseService().getGlossaryByCategory(category);
    return items.indexWhere(
      (item) => item['id'] == pickerState.pendingActionItemId,
    );
  }

  /// Activate a glossary item in the picker state
  void activateGlossaryItem(int itemId) {
    pickerState.activateGlossaryItem(itemId);
  }
}
