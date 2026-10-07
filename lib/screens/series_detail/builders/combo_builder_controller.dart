import 'package:flutter/services.dart';

import '../../../models/move.dart';
import '../../../services/usage_statistics_service.dart';
import 'builder_card_data.dart';
import 'move_converter.dart';

/// Structural mode of the combo builder — single enum replaces 5 booleans
/// and enforces mutual exclusivity (Improvement #1).
enum BuilderMode {
  none,
  defense,
  simultaneous,
  chain,
  counterSimultaneous,
  counterChain,
}

/// Plain (non-widget) controller holding the workspace state and all
/// mutation logic for the AdvancedComboBuilder.
///
/// The widget wraps state-mutating calls in `setState(...)`; read-only
/// helpers can be called directly.
class ComboBuilderController {
  // Current state of the workspace
  final List<BuilderCardData> workspaceCards = [];

  // Path-based selection for recursive structures
  List<int>? selectedPath;
  bool isCounterSelected = false;
  bool showAngleSelector = false;
  // Improvement #3: selectedCounterIndex removed — was always selectedCounterPath?.first.
  List<int>? selectedCounterPath;

  // Improvement #1: mode enum
  BuilderMode mode = BuilderMode.none;

  // History for undo/redo
  final List<BuilderHistoryEntry> _undoStack = [];
  final List<BuilderHistoryEntry> _redoStack = [];

  // Performance: single UsageStatisticsService instance reused across filter calls.
  final UsageStatisticsService _usageService = UsageStatisticsService();

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // ---------------------------------------------------------------------------
  // History (undo/redo)
  // ---------------------------------------------------------------------------

  void saveHistory() {
    _undoStack.add(
      BuilderHistoryEntry(
        cards: List.from(workspaceCards),
        selectedPath: selectedPath != null ? List.from(selectedPath!) : null,
        isCounterSelected: isCounterSelected,
        selectedCounterPath: selectedCounterPath != null
            ? List.from(selectedCounterPath!)
            : null,
      ),
    );
    _redoStack.clear();
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.mediumImpact();
    _redoStack.add(
      BuilderHistoryEntry(
        cards: List.from(workspaceCards),
        selectedPath: selectedPath != null ? List.from(selectedPath!) : null,
        isCounterSelected: isCounterSelected,
        selectedCounterPath: selectedCounterPath != null
            ? List.from(selectedCounterPath!)
            : null,
      ),
    );
    final entry = _undoStack.removeLast();
    workspaceCards.clear();
    workspaceCards.addAll(entry.cards);
    selectedPath = entry.selectedPath;
    isCounterSelected = entry.isCounterSelected;
    selectedCounterPath = entry.selectedCounterPath;
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    HapticFeedback.mediumImpact();
    _undoStack.add(
      BuilderHistoryEntry(
        cards: List.from(workspaceCards),
        selectedPath: selectedPath != null ? List.from(selectedPath!) : null,
        isCounterSelected: isCounterSelected,
        selectedCounterPath: selectedCounterPath != null
            ? List.from(selectedCounterPath!)
            : null,
      ),
    );
    final entry = _redoStack.removeLast();
    workspaceCards.clear();
    workspaceCards.addAll(entry.cards);
    selectedPath = entry.selectedPath;
    isCounterSelected = entry.isCounterSelected;
    selectedCounterPath = entry.selectedCounterPath;
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  bool isPathSelected(List<int> path) {
    if (selectedPath == null || selectedPath!.length != path.length) {
      return false;
    }
    for (int i = 0; i < path.length; i++) {
      if (selectedPath![i] != path[i]) return false;
    }
    return true;
  }

  bool isCounterPathSelected(List<int> path, List<int> counterPath) {
    if (!isPathSelected(path)) return false;
    if (selectedCounterPath == null ||
        selectedCounterPath!.length != counterPath.length) {
      return false;
    }
    for (int i = 0; i < counterPath.length; i++) {
      if (selectedCounterPath![i] != counterPath[i]) return false;
    }
    return true;
  }

  void selectPath(
    List<int> path, {
    bool isCounter = false,
    List<int>? counterPath,
  }) {
    selectedPath = List<int>.from(path);
    isCounterSelected = isCounter;
    showAngleSelector = false;
    selectedCounterPath = counterPath != null
        ? List<int>.from(counterPath)
        : null;
  }

  // ---------------------------------------------------------------------------
  // Path navigation (read-only)
  // ---------------------------------------------------------------------------

  /// Read-only helper: returns the BuilderCardData at the given path, or null.
  BuilderCardData? getDataAtPath(List<int> path) {
    if (path.isEmpty || path[0] >= workspaceCards.length) return null;
    BuilderCardData current = workspaceCards[path[0]];
    for (int i = 1; i < path.length; i++) {
      final idx = path[i];
      if (current.isChain && idx < current.chain.length) {
        current = current.chain[idx];
      } else if (current.isCombo && idx < current.subMoves.length) {
        current = current.subMoves[idx];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Returns the counter sub-item addressed by [counterPath] under [root],
  /// or null if the path is invalid.
  ///
  /// The first index always refers to [root]'s counter structure
  /// (counterSubMoves / counterChain), even when [root] is itself a chain
  /// or combo. Deeper indices navigate nested groups inside the answer
  /// (their subMoves / chain).
  BuilderCardData? getCounterSubItemAtPath(
    BuilderCardData root,
    List<int> counterPath,
  ) {
    if (counterPath.isEmpty) return null;
    BuilderCardData? current = root;
    for (int i = 0; i < counterPath.length; i++) {
      final idx = counterPath[i];
      if (i == 0) {
        if (current!.hasCounterCombo && idx < current.counterSubMoves.length) {
          current = current.counterSubMoves[idx];
        } else if (current.hasCounterChain &&
            idx < current.counterChain.length) {
          current = current.counterChain[idx];
        } else {
          return null;
        }
      } else if (current!.isChain && idx < current.chain.length) {
        current = current.chain[idx];
      } else if (current.isCombo && idx < current.subMoves.length) {
        current = current.subMoves[idx];
      } else {
        return null;
      }
    }
    return current;
  }

  // ---------------------------------------------------------------------------
  // Training-mode glossary filtering
  // ---------------------------------------------------------------------------

  Set<String> getRelevantCategories(Move move) {
    Set<String> cats = {move.category};
    if (move.counterCategory != null && move.counterCategory!.isNotEmpty) {
      cats.add(move.counterCategory!);
    }
    // If Kali is relevant, standard and custom angles are also relevant
    if (cats.contains('kali')) {
      cats.add('angles');
      cats.add('custom_angles');
    }
    for (var m in move.subMoves) {
      cats.addAll(getRelevantCategories(m));
    }
    for (var m in move.chain) {
      cats.addAll(getRelevantCategories(m));
    }
    for (var m in move.counterSubMoves) {
      cats.addAll(getRelevantCategories(m));
    }
    for (var m in move.counterChain) {
      cats.addAll(getRelevantCategories(m));
    }
    return cats;
  }

  Set<String> getTrainingMoves(Move move) {
    Set<String> names = {move.name.toLowerCase().trim()};
    if (move.counterName != null && move.counterName!.isNotEmpty) {
      names.add(move.counterName!.toLowerCase().trim());
    }
    for (var m in move.subMoves) {
      names.addAll(getTrainingMoves(m));
    }
    for (var m in move.chain) {
      names.addAll(getTrainingMoves(m));
    }
    for (var m in move.counterSubMoves) {
      names.addAll(getTrainingMoves(m));
    }
    for (var m in move.counterChain) {
      names.addAll(getTrainingMoves(m));
    }
    return names;
  }

  List<Map<String, dynamic>> filterGlossaryForTraining(
    List<Map<String, dynamic>> items,
    Move? trainingOriginalMove,
  ) {
    if (trainingOriginalMove == null) return items;

    final allowedNames = getTrainingMoves(trainingOriginalMove);
    final List<Map<String, dynamic>> correct = [];
    final List<Map<String, dynamic>> distractors = [];

    for (var item in items) {
      final name = item['name']?.toString().toLowerCase().trim() ?? '';
      if (allowedNames.contains(name)) {
        correct.add(item);
      } else {
        distractors.add(item);
      }
    }

    // Distractors are already sorted by usage in fetchGlossaryByCategory.
    // Pick up to 5 random ones from the top distractors to provide variety.
    // We shuffle the first 15 distractors and take 5.
    final topDistractors = distractors.take(15).toList();
    topDistractors.shuffle();
    final finalDistractors = topDistractors.take(5).toList();

    final result = [...correct, ...finalDistractors];
    // Re-sort result by usage count to maintain the UI triage
    result.sort((a, b) {
      final countA = _usageService.getCount(a['name'] ?? '');
      final countB = _usageService.getCount(b['name'] ?? '');
      if (countA != countB) {
        return countB.compareTo(countA);
      }
      // Deterministic tie-break (List.sort is not stable).
      return a['name'].toString().compareTo(b['name'].toString());
    });

    return result;
  }

  // ---------------------------------------------------------------------------
  // Toolbar visibility
  // ---------------------------------------------------------------------------

  bool shouldShowBottomToolbar() {
    if (selectedPath == null) return false;

    final data = getDataAtPath(selectedPath!);
    if (data == null) return false;

    if (isCounterSelected) {
      if (selectedCounterPath != null) {
        // Selecting a sub-item in a structured answer
        // Check if the SUB-ITEM is an action card (not a group)
        final sub = getCounterSubItemAtPath(data, selectedCounterPath!);
        if (sub == null) return false;
        // Don't show for container groups even inside counters
        return !sub.isChain && !sub.isCombo;
      }
      // Selecting the "whole" answer box. Only show if it's a simple answer (not structured).
      return !data.hasStructuredCounter;
    }

    // Action cards are NOT containers (Chain or Combo)
    if (data.isChain || data.isCombo) return false;

    return true;
  }

  // ---------------------------------------------------------------------------
  // Deletion
  // ---------------------------------------------------------------------------

  BuilderCardData? deleteNestedData(
    BuilderCardData root,
    List<int> counterPath, {
    bool inCounterStructure = true,
  }) {
    if (counterPath.length == 1) {
      // BASE CASE: We are at the parent of the item to remove
      final idx = counterPath[0];

      if (inCounterStructure) {
        // The item to remove lives in root's counter structure.
        if (root.hasCounterCombo && idx < root.counterSubMoves.length) {
          final newList = List<BuilderCardData>.from(root.counterSubMoves);
          newList.removeAt(idx);
          if (newList.isEmpty) {
            return root.copyWith(
              counterName: null,
              counterCategory: null,
              counterGlossaryId: null,
              counterSide: '',
              counterLevel: '',
              counterSubMoves: const [],
            );
          }
          if (newList.length == 1) {
            final rem = newList.first;
            return root.copyWith(
              counterName: rem.name,
              counterCategory: rem.category,
              counterGlossaryId: rem.glossaryId,
              counterSide: rem.side,
              counterLevel: rem.level,
              counterSubMoves: const [],
            );
          }
          return root.copyWith(
            counterSubMoves: newList,
            counterName: newList.map((m) => m.name).join(' + '),
          );
        } else if (root.hasCounterChain && idx < root.counterChain.length) {
          final newList = List<BuilderCardData>.from(root.counterChain);
          newList.removeAt(idx);
          if (newList.isEmpty) {
            return root.copyWith(
              counterName: null,
              counterCategory: null,
              counterGlossaryId: null,
              counterSide: '',
              counterLevel: '',
              counterChain: const [],
            );
          }
          if (newList.length == 1) {
            final rem = newList.first;
            return root.copyWith(
              counterName: rem.name,
              counterCategory: rem.category,
              counterGlossaryId: rem.glossaryId,
              counterSide: rem.side,
              counterLevel: rem.level,
              counterChain: const [],
            );
          }
          return root.copyWith(
            counterChain: newList,
            counterName: newList.map((m) => m.name).join(' -> '),
          );
        }
        return root;
      }

      if (root.isChain && idx < root.chain.length) {
        final newList = List<BuilderCardData>.from(root.chain);
        newList.removeAt(idx);
        if (newList.isEmpty) return null;
        if (newList.length == 1) return newList.first;
        return root.copyWith(chain: newList);
      } else if (root.isCombo && idx < root.subMoves.length) {
        final newList = List<BuilderCardData>.from(root.subMoves);
        newList.removeAt(idx);
        if (newList.isEmpty) return null;
        if (newList.length == 1) return newList.first;
        return root.copyWith(subMoves: newList);
      }
      return root;
    }

    // RECURSIVE CASE: Navigate deeper
    final idx = counterPath[0];
    final remainingPath = counterPath.sublist(1);

    if (inCounterStructure) {
      // First step: enter root's counter structure, even when root is
      // itself a chain or combo.
      if (root.hasCounterCombo && idx < root.counterSubMoves.length) {
        final newList = List<BuilderCardData>.from(root.counterSubMoves);
        final updated = deleteNestedData(
          newList[idx],
          remainingPath,
          inCounterStructure: false,
        );
        if (updated == null) {
          newList.removeAt(idx);
        } else {
          newList[idx] = updated;
        }
        // Answers don't disappear if empty, they just become simple counters again
        if (newList.isEmpty) {
          return root.copyWith(counterName: null, counterSubMoves: const []);
        }
        return root.copyWith(counterSubMoves: newList);
      } else if (root.hasCounterChain && idx < root.counterChain.length) {
        final newList = List<BuilderCardData>.from(root.counterChain);
        final updated = deleteNestedData(
          newList[idx],
          remainingPath,
          inCounterStructure: false,
        );
        if (updated == null) {
          newList.removeAt(idx);
        } else {
          newList[idx] = updated;
        }
        if (newList.isEmpty) {
          return root.copyWith(counterName: null, counterChain: const []);
        }
        return root.copyWith(counterChain: newList);
      }
      return root;
    }

    if (root.isChain && idx < root.chain.length) {
      final newList = List<BuilderCardData>.from(root.chain);
      final updated = deleteNestedData(
        newList[idx],
        remainingPath,
        inCounterStructure: false,
      );
      if (updated == null) {
        newList.removeAt(idx);
      } else {
        newList[idx] = updated;
      }
      if (newList.isEmpty) return null;
      if (newList.length == 1) return newList.first;
      return root.copyWith(chain: newList);
    } else if (root.isCombo && idx < root.subMoves.length) {
      final newList = List<BuilderCardData>.from(root.subMoves);
      final updated = deleteNestedData(
        newList[idx],
        remainingPath,
        inCounterStructure: false,
      );
      if (updated == null) {
        newList.removeAt(idx);
      } else {
        newList[idx] = updated;
      }
      if (newList.isEmpty) return null;
      if (newList.length == 1) return newList.first;
      return root.copyWith(subMoves: newList);
    }

    return root;
  }

  void deleteSelected() {
    if (selectedPath == null) return;
    HapticFeedback.lightImpact();
    saveHistory();

    if (isCounterSelected && selectedCounterPath != null) {
      // Nested deletion within structured counters
      updateDataAtPath(selectedPath!, (item) {
        return deleteNestedData(item, selectedCounterPath!) ?? item;
      });
      selectedCounterPath = null;
    } else if (isCounterSelected) {
      // DELETE ONLY THE ANSWER of the item at the selected path
      updateDataAtPath(selectedPath!, (item) {
        return item.copyWith(
          counterName: null,
          counterCategory: null,
          counterGlossaryId: null,
          counterSide: '',
          counterLevel: '',
          counterSubMoves: const [],
          counterChain: const [],
        );
      });
      isCounterSelected = false;
      selectedCounterPath = null;
    } else if (selectedPath!.length > 1) {
      // DELETE ONLY THE TARGETED SUB-ITEM
      final parentPath = selectedPath!.sublist(0, selectedPath!.length - 1);
      final indexToRemove = selectedPath!.last;

      updateDataAtPath(parentPath, (parent) {
        final isChain = parent.isChain;
        final List<BuilderCardData> subList = List.from(
          isChain ? parent.chain : parent.subMoves,
        );
        if (indexToRemove < subList.length) {
          subList.removeAt(indexToRemove);
        }

        if (subList.isEmpty) return null;

        if (subList.length == 1) {
          final remaining = subList.first;
          // Preserve counter from the parent wrapper if the remaining item has none
          if (parent.hasCounter && !remaining.hasCounter) {
            return remaining.copyWith(
              counterName: parent.counterName,
              counterCategory: parent.counterCategory,
              counterGlossaryId: parent.counterGlossaryId,
              counterSide: parent.counterSide,
              counterLevel: parent.counterLevel,
              counterSubMoves: parent.counterSubMoves,
              counterChain: parent.counterChain,
            );
          }
          return remaining;
        }

        if (isChain) {
          return parent.copyWith(chain: subList);
        } else {
          return parent.copyWith(subMoves: subList);
        }
      });

      selectedPath = null;
      selectedCounterPath = null;
    } else {
      // DELETE ENTIRE TOP-LEVEL CARD
      workspaceCards.removeAt(selectedPath![0]);
      selectedPath = null;
      selectedCounterPath = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  // Deep update helper
  void updateDataAtPath(
    List<int> path,
    BuilderCardData? Function(BuilderCardData) updater,
  ) {
    if (path.isEmpty) return;

    BuilderCardData? updateRecursive(
      BuilderCardData current,
      List<int> remainingPath,
    ) {
      if (remainingPath.isEmpty) return updater(current);

      final index = remainingPath[0];
      final nextRemaining = remainingPath.sublist(1);

      if (current.isChain) {
        final List<BuilderCardData> newList = List.from(current.chain);
        final result = updateRecursive(newList[index], nextRemaining);
        if (result == null) {
          newList.removeAt(index);
          if (newList.isEmpty) return null;
          // Unwrap if only 1 item remains
          if (newList.length == 1) {
            final remaining = newList.first;
            if (current.hasCounter && !remaining.hasCounter) {
              return remaining.copyWith(
                counterName: current.counterName,
                counterCategory: current.counterCategory,
                counterGlossaryId: current.counterGlossaryId,
                counterSide: current.counterSide,
                counterLevel: current.counterLevel,
                counterSubMoves: current.counterSubMoves,
                counterChain: current.counterChain,
              );
            }
            return remaining;
          }
          return current.copyWith(chain: newList);
        }
        newList[index] = result;
        return current.copyWith(chain: newList);
      } else if (current.isCombo) {
        final List<BuilderCardData> newList = List.from(current.subMoves);
        final result = updateRecursive(newList[index], nextRemaining);
        if (result == null) {
          newList.removeAt(index);
          if (newList.isEmpty) return null;
          // Unwrap if only 1 item remains
          if (newList.length == 1) {
            final remaining = newList.first;
            if (current.hasCounter && !remaining.hasCounter) {
              return remaining.copyWith(
                counterName: current.counterName,
                counterCategory: current.counterCategory,
                counterGlossaryId: current.counterGlossaryId,
                counterSide: current.counterSide,
                counterLevel: current.counterLevel,
                counterSubMoves: current.counterSubMoves,
                counterChain: current.counterChain,
              );
            }
            return remaining;
          }
          return current.copyWith(subMoves: newList);
        }
        newList[index] = result;
        return current.copyWith(subMoves: newList);
      }
      return current;
    }

    final topIndex = path[0];
    final remaining = path.sublist(1);

    if (remaining.isEmpty) {
      final result = updater(workspaceCards[topIndex]);
      if (result == null) {
        workspaceCards.removeAt(topIndex);
      } else {
        workspaceCards[topIndex] = result;
      }
    } else {
      final result = updateRecursive(workspaceCards[topIndex], remaining);
      if (result == null) {
        workspaceCards.removeAt(topIndex);
      } else {
        workspaceCards[topIndex] = result;
      }
    }
  }

  BuilderCardData updateNestedData(
    BuilderCardData root,
    List<int> counterPath,
    String? side,
    String? level,
    bool toggleFeint,
    int? kaliAngle,
    String? strikeType, {
    bool inCounterStructure = true,
  }) {
    if (counterPath.isEmpty) {
      // BASE CASE: We reached the target sub-item. Toggle its properties.
      String finalSide = root.side;
      if (side != null) {
        finalSide = (root.side == side) ? '' : side;
      }
      String finalLevel = root.level;
      if (level != null) {
        finalLevel = (root.level == level) ? '' : level;
      }
      return root.copyWith(
        side: finalSide,
        level: finalLevel,
        isFeint: toggleFeint ? !root.isFeint : root.isFeint,
        kaliAngle: kaliAngle ?? root.kaliAngle,
        strikeType: strikeType ?? root.strikeType,
      );
    }

    // RECURSIVE CASE: Navigate deeper
    final idx = counterPath[0];
    final remainingPath = counterPath.sublist(1);

    if (inCounterStructure) {
      // First step: enter root's counter structure, even when root is
      // itself a chain or combo.
      if (root.hasCounterCombo && idx < root.counterSubMoves.length) {
        final newList = List<BuilderCardData>.from(root.counterSubMoves);
        newList[idx] = updateNestedData(
          newList[idx],
          remainingPath,
          side,
          level,
          toggleFeint,
          kaliAngle,
          strikeType,
          inCounterStructure: false,
        );
        return root.copyWith(counterSubMoves: newList);
      } else if (root.hasCounterChain && idx < root.counterChain.length) {
        final newList = List<BuilderCardData>.from(root.counterChain);
        newList[idx] = updateNestedData(
          newList[idx],
          remainingPath,
          side,
          level,
          toggleFeint,
          kaliAngle,
          strikeType,
          inCounterStructure: false,
        );
        return root.copyWith(counterChain: newList);
      }
      return root;
    }

    if (root.isChain && idx < root.chain.length) {
      final newList = List<BuilderCardData>.from(root.chain);
      newList[idx] = updateNestedData(
        newList[idx],
        remainingPath,
        side,
        level,
        toggleFeint,
        kaliAngle,
        strikeType,
        inCounterStructure: false,
      );
      return root.copyWith(chain: newList);
    } else if (root.isCombo && idx < root.subMoves.length) {
      final newList = List<BuilderCardData>.from(root.subMoves);
      newList[idx] = updateNestedData(
        newList[idx],
        remainingPath,
        side,
        level,
        toggleFeint,
        kaliAngle,
        strikeType,
        inCounterStructure: false,
      );
      return root.copyWith(subMoves: newList);
    }

    return root;
  }

  void updateSelectedCard({
    String? side,
    String? level,
    bool toggleFeint = false,
    String? specialAction,
    int? kaliAngle,
    String? strikeType,
  }) {
    if (selectedPath == null) return;
    saveHistory();

    updateDataAtPath(selectedPath!, (item) {
      if (isCounterSelected && selectedCounterPath != null) {
        // Deep-nested update for structured counters
        return updateNestedData(
          item,
          selectedCounterPath!,
          side,
          level,
          toggleFeint,
          kaliAngle,
          strikeType,
        );
      } else if (isCounterSelected) {
        // Simple single counter toggle logic
        String finalSide = item.counterSide;
        if (side != null) {
          finalSide = (item.counterSide == side) ? '' : side;
        }
        String finalLevel = item.counterLevel;
        if (level != null) {
          finalLevel = (item.counterLevel == level) ? '' : level;
        }
        return item.copyWith(
          counterSide: finalSide,
          counterLevel: finalLevel,
          counterIsFeint: toggleFeint
              ? !item.counterIsFeint
              : item.counterIsFeint,
        );
      } else {
        // Top-level attacker toggle logic
        String finalSide = item.side;
        if (side != null) {
          finalSide = (item.side == side) ? '' : side;
        }
        String finalLevel = item.level;
        if (level != null) {
          finalLevel = (item.level == level) ? '' : level;
        }
        return item.copyWith(
          side: finalSide,
          level: finalLevel,
          isFeint: toggleFeint ? !item.isFeint : item.isFeint,
          specialAction: specialAction ?? item.specialAction,
          kaliAngle: kaliAngle ?? item.kaliAngle,
          strikeType: strikeType ?? item.strikeType,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Add
  // ---------------------------------------------------------------------------

  // Improvement #5: addItem split into focused sub-methods per mode.
  void addItem(BuilderCardData newItem) {
    HapticFeedback.lightImpact();
    saveHistory();
    switch (mode) {
      case BuilderMode.counterSimultaneous:
        if (selectedPath != null) addItemCounterSimultaneous(newItem);
      case BuilderMode.counterChain:
        if (selectedPath != null) addItemCounterChain(newItem);
      case BuilderMode.defense:
        if (selectedPath != null) addItemDefense(newItem);
      case BuilderMode.chain:
        if (selectedPath != null) addItemToChain(newItem);
      case BuilderMode.simultaneous:
        if (selectedPath != null) addItemSimultaneous(newItem);
      case BuilderMode.none:
        addItemDefault(newItem);
    }
  }

  void addItemCounterSimultaneous(BuilderCardData newItem) {
    updateDataAtPath(selectedPath!, (target) {
      if (selectedCounterPath != null) {
        final idx = selectedCounterPath![0];
        if (target.hasCounterCombo && idx < target.counterSubMoves.length) {
          final newList = List<BuilderCardData>.from(target.counterSubMoves);
          newList.insert(idx + 1, newItem);
          return target.copyWith(
            counterSubMoves: newList,
            counterName: newList.map((m) => m.name).join(' + '),
          );
        } else if (target.hasCounterChain && idx < target.counterChain.length) {
          final subItem = target.counterChain[idx];
          final simultaneous = BuilderCardData(
            name: '${subItem.name} + ${newItem.name}',
            category: 'simultaneous',
            subMoves: [subItem, newItem],
          );
          final newList = List<BuilderCardData>.from(target.counterChain);
          newList[idx] = simultaneous;
          return target.copyWith(counterChain: newList);
        }
        return target;
      }
      if (target.hasCounterCombo) {
        return target.copyWith(
          counterSubMoves: [...target.counterSubMoves, newItem],
          counterName:
              '${target.counterSubMoves.map((m) => m.name).join(' + ')} + ${newItem.name}',
        );
      }
      if (target.hasCounterChain) {
        final chainGroup = BuilderCardData(
          name: target.counterChain.map((m) => m.name).join(' -> '),
          category: 'chain',
          chain: List.from(target.counterChain),
        );
        return target.copyWith(
          counterSubMoves: [chainGroup, newItem],
          counterChain: const [],
          counterName: '(${chainGroup.name}) + ${newItem.name}',
        );
      }
      if (target.counterName == null || target.counterName!.isEmpty) {
        // No existing simple answer: start the structured answer with the
        // new item (no empty placeholder).
        return target.copyWith(
          counterSubMoves: [newItem],
          counterName: newItem.name,
        );
      }
      final existingCounter = BuilderCardData(
        name: target.counterName ?? '',
        category: target.counterCategory ?? '',
        glossaryId: target.counterGlossaryId,
        side: target.counterSide,
        level: target.counterLevel,
      );
      return target.copyWith(
        counterSubMoves: [existingCounter, newItem],
        counterName: '${target.counterName} + ${newItem.name}',
      );
    });
    mode = BuilderMode.none;
    selectedCounterPath = null;
  }

  void addItemCounterChain(BuilderCardData newItem) {
    updateDataAtPath(selectedPath!, (target) {
      if (selectedCounterPath != null) {
        final idx = selectedCounterPath![0];
        if (target.hasCounterChain && idx < target.counterChain.length) {
          final newList = List<BuilderCardData>.from(target.counterChain);
          newList.insert(idx + 1, newItem);
          return target.copyWith(
            counterChain: newList,
            counterName: newList.map((m) => m.name).join(' -> '),
          );
        } else if (target.hasCounterCombo &&
            idx < target.counterSubMoves.length) {
          final subItem = target.counterSubMoves[idx];
          final chainItem = BuilderCardData(
            name: '${subItem.name} -> ${newItem.name}',
            category: 'chain',
            chain: [subItem, newItem],
          );
          final newList = List<BuilderCardData>.from(target.counterSubMoves);
          newList[idx] = chainItem;
          return target.copyWith(counterSubMoves: newList);
        }
        return target;
      }
      if (target.hasCounterChain) {
        return target.copyWith(
          counterChain: [...target.counterChain, newItem],
          counterName:
              '${target.counterChain.map((m) => m.name).join(' -> ')} -> ${newItem.name}',
        );
      }
      if (target.hasCounterCombo) {
        final simultaneousGroup = BuilderCardData(
          name: target.counterSubMoves.map((m) => m.name).join(' + '),
          category: 'simultaneous',
          subMoves: List.from(target.counterSubMoves),
        );
        return target.copyWith(
          counterChain: [simultaneousGroup, newItem],
          counterSubMoves: const [],
          counterName: '(${simultaneousGroup.name}) -> ${newItem.name}',
        );
      }
      if (target.counterName == null || target.counterName!.isEmpty) {
        // No existing simple answer: start the structured answer with the
        // new item (no empty placeholder).
        return target.copyWith(
          counterChain: [newItem],
          counterName: newItem.name,
        );
      }
      final existingCounter = BuilderCardData(
        name: target.counterName ?? '',
        category: target.counterCategory ?? '',
        glossaryId: target.counterGlossaryId,
        side: target.counterSide,
        level: target.counterLevel,
      );
      return target.copyWith(
        counterChain: [existingCounter, newItem],
        counterName: '${target.counterName} -> ${newItem.name}',
      );
    });
    mode = BuilderMode.none;
    selectedCounterPath = null;
  }

  void addItemDefense(BuilderCardData newItem) {
    updateDataAtPath(
      selectedPath!,
      (target) => target.copyWith(
        counterName: newItem.name,
        counterCategory: newItem.category,
        counterGlossaryId: newItem.glossaryId,
        counterSubMoves: const [],
        counterChain: const [],
      ),
    );
    mode = BuilderMode.none;
  }

  void addItemToChain(BuilderCardData newItem) {
    if (selectedPath!.length > 1) {
      bool inserted = false;
      for (
        int depth = selectedPath!.length - 1;
        depth >= 1 && !inserted;
        depth--
      ) {
        final parentPath = selectedPath!.sublist(0, depth);
        final childIndex = selectedPath![depth];
        updateDataAtPath(parentPath, (parent) {
          if (parent.isChain) {
            final newChain = List<BuilderCardData>.from(parent.chain);
            newChain.insert(childIndex + 1, newItem);
            inserted = true;
            return parent.copyWith(chain: newChain);
          }
          return parent;
        });
        if (inserted) {
          selectedPath = [...parentPath, childIndex + 1];
        }
      }
      if (!inserted) {
        // No chain ancestor (e.g. leaf inside a simultaneous group):
        // wrap the selected item in a new chain instead of dropping it.
        updateDataAtPath(selectedPath!, (target) {
          return BuilderCardData(
            name: 'Chain',
            category: 'chain',
            chain: [target, newItem],
          );
        });
        selectedPath = [...selectedPath!, 1];
      }
    } else {
      final topIndex = selectedPath![0];
      final selected = getDataAtPath(selectedPath!);
      if (selected != null && selected.isChain) {
        updateDataAtPath(selectedPath!, (target) {
          return target.copyWith(chain: [...target.chain, newItem]);
        });
        selectedPath = [topIndex, selected.chain.length];
      } else {
        workspaceCards[topIndex] = BuilderCardData(
          name: 'Chain',
          category: 'chain',
          chain: [workspaceCards[topIndex], newItem],
        );
        selectedPath = [topIndex, 1];
      }
    }
    mode = BuilderMode.none;
  }

  void addItemSimultaneous(BuilderCardData newItem) {
    bool appended = false;
    List<int>? parentPath;
    if (selectedPath!.length > 1) {
      parentPath = selectedPath!.sublist(0, selectedPath!.length - 1);
      updateDataAtPath(parentPath, (parent) {
        if (parent.isCombo) {
          appended = true;
          return parent.copyWith(subMoves: [...parent.subMoves, newItem]);
        }
        return parent;
      });
    }
    if (appended && parentPath != null) {
      final parent = getDataAtPath(parentPath);
      if (parent != null && parent.isCombo) {
        selectedPath = [...parentPath, parent.subMoves.length - 1];
      }
    }
    if (!appended) {
      updateDataAtPath(selectedPath!, (target) {
        if (target.isCombo) {
          return target.copyWith(subMoves: [...target.subMoves, newItem]);
        }
        return BuilderCardData(
          name: 'Combo',
          category: 'simultaneous',
          subMoves: [target, newItem],
        );
      });
      final target = getDataAtPath(selectedPath!);
      if (target != null && target.isCombo) {
        selectedPath = [...selectedPath!, target.subMoves.length - 1];
      }
    }
    mode = BuilderMode.none;
  }

  void addItemDefault(BuilderCardData newItem) {
    if (selectedPath != null && selectedPath![0] < workspaceCards.length) {
      // Insert right after the selected card's top-level card (also works
      // for nested selections, not only top-level ones).
      final insertIndex = selectedPath![0] + 1;
      workspaceCards.insert(insertIndex, newItem);
      selectedPath = [insertIndex];
    } else {
      workspaceCards.add(newItem);
      selectedPath = [workspaceCards.length - 1];
    }
    mode = BuilderMode.none;
  }

  // ---------------------------------------------------------------------------
  // Finish
  // ---------------------------------------------------------------------------

  /// Builds the final [Move] from the workspace, or null if it is empty.
  Move? buildFinalMove() {
    if (workspaceCards.isEmpty) return null;
    if (workspaceCards.length == 1) {
      return moveFromBuilderCardData(workspaceCards.first);
    }
    final subMoves = workspaceCards.map(moveFromBuilderCardData).toList();
    return Move(
      name: 'Combo: ${subMoves.first.name} + ...',
      category: 'combo',
      subMoves: subMoves,
    );
  }
}
