// Widget builder service for glossary-related UI components
// Handles glossary list rendering, buttons, and selection controls
//
// This service contains all the UI building methods for the glossary picker
// and can be called from the main screen by passing necessary dependencies.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/localization_service.dart';
import '../../../services/series_provider.dart';
import '../widgets/move_display_widgets.dart';
import '../state/picker_state.dart';
import 'glossary_data_service.dart';
import 'glossary_picker_widgets.dart';

// Service class for building glossary UI components
//
// All methods are static and receive their dependencies as parameters
// to maintain testability and avoid tight coupling.
class GlossaryUIBuilder {
  // Static storage for glossary scroll controllers
  static final Map<String, ScrollController> _scrollControllers = {};

  // Get or create scroll controller for a category
  static ScrollController getScrollController(String category) {
    return _scrollControllers.putIfAbsent(category, () => ScrollController());
  }

  // Dispose all glossary scroll controllers
  static void disposeAllControllers() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
  }

  // Build the main glossary list (moves tab)
  static Widget buildGlossaryList(
    BuildContext context,
    String category,
    StateSetter setState, {
    int? initialIndex,
    bool isCounterMode = false,
    Map<String, dynamic>? attackMove,
    bool isSimultaneous = false,
    ScrollController? scrollController,
    PickerState? pickerState,
    List<dynamic>? currentCombo,
    VoidCallback? onShowMediaGallery,
    VoidCallback? onActivateGlossaryItem,
    Function(int)? onPickSpecial,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onNext,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onSimultaneous,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onChain,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onAnswer,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onFinish,
    VoidCallback? onCancel,
  }) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    ScrollController controller =
        scrollController ?? getScrollController(category);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: GlossaryDataService.fetchGlossaryByCategory(
        category,
        hitTypeFilter: isCounterMode
            ? (attackMove?['hit_type'] ?? 'both')
            : null,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;

        // Handle initial scroll
        if (initialIndex != null &&
            initialIndex >= 0 &&
            initialIndex < items.length) {
          _handleInitialScroll(
            controller,
            initialIndex,
            items[initialIndex]['id'],
            pickerState,
          );
        }

        return ListView.builder(
          controller: controller,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            // Build glossary item card
            return _buildGlossaryItemCard(
              context: context,
              item: item,
              category: category,
              isCounterMode: isCounterMode,
              showTranslation: provider.showTranslation,
              setState: setState,
              lang: lang,
              pickerState: pickerState,
              currentCombo: currentCombo,
              attackMove: attackMove,
              onShowMediaGallery: onShowMediaGallery,
              onActivateGlossaryItem: onActivateGlossaryItem,
              onPickSpecial: onPickSpecial,
              onNext: onNext,
              onSimultaneous: onSimultaneous,
              onChain: onChain,
              onAnswer: onAnswer,
              onFinish: onFinish,
              onCancel: onCancel,
            );
          },
        );
      },
    );
  }

  // Handle scrolling to initial item
  static void _handleInitialScroll(
    ScrollController controller,
    int index,
    int itemId,
    PickerState? pickerState,
  ) {
    if (pickerState?.lastScrolledItemId != itemId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.hasClients ||
            !controller.position.hasContentDimensions) {
          return;
        }

        final viewportHeight = controller.position.viewportDimension;
        double offset =
            (index * GlossaryDataService.estimatedItemHeight) -
            (viewportHeight / 2) +
            (GlossaryDataService.estimatedItemHeight / 2);

        if (offset < 0) {
          offset = 0;
        } else if (offset > controller.position.maxScrollExtent) {
          offset = controller.position.maxScrollExtent;
        }

        controller.jumpTo(offset);

        // Update picker state
        pickerState?.setLastScrolledItemId(itemId);
      });
    }
  }

  // Build individual glossary item card
  static Widget _buildGlossaryItemCard({
    required BuildContext context,
    required Map<String, dynamic> item,
    required String category,
    required bool isCounterMode,
    required bool showTranslation,
    required StateSetter setState,
    required String lang,
    PickerState? pickerState,
    List<dynamic>? currentCombo,
    Map<String, dynamic>? attackMove,
    VoidCallback? onShowMediaGallery,
    VoidCallback? onActivateGlossaryItem,
    Function(int)? onPickSpecial,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onNext,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onSimultaneous,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onChain,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onAnswer,
    Function(
      Map<String, dynamic> item,
      String cat,
      String side,
      String level,
      bool isFeint,
      String? special,
      Map<String, String> translations,
    )?
    onFinish,
    VoidCallback? onCancel,
  }) {
    final id = item['id'];
    final side = pickerState?.selectedSides[id] ?? '';
    final isFeint = pickerState?.selectedFeints[id] ?? false;
    final specialAction = pickerState?.selectedSpecials[id];
    final isExpanded = pickerState?.pendingActionItemId == id;

    // Parse translations
    final translations = GlossaryDataService.parseTranslations(
      item['translations'],
    );
    final translation = GlossaryDataService.getTranslation(translations, lang);

    // Item name (use English name for moves)
    final itemName = category == 'move'
        ? translations['en'] ?? item['name']
        : item['name'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: isExpanded
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: MoveDisplayWidgets.getCategoryColor(category),
                width: 2,
              ),
            )
          : null,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (pickerState?.pendingActionItemId == id) {
                  pickerState?.setPendingActionItem(null);
                } else {
                  pickerState?.setPendingActionItem(id);
                  pickerState?.setPendingLevel('');
                }
                onActivateGlossaryItem?.call();
              });
            },
            onDoubleTap: onShowMediaGallery,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and name
                  Row(
                    children: [
                      Icon(
                        MoveDisplayWidgets.getCategoryIcon(category),
                        size: 32,
                        color: MoveDisplayWidgets.getCategoryColor(category),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Translation (if available and shown)
                  if (showTranslation &&
                      category != 'move' &&
                      translation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0),
                      child: Text(
                        translation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Selection controls
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ..._buildSelectionControls(
                        context: context,
                        item: item,
                        category: category,
                        id: id,
                        side: side,
                        isFeint: isFeint,
                        specialAction: specialAction,
                        isCounterMode: isCounterMode,
                        setState: setState,
                        lang: lang,
                        pickerState: pickerState,
                        onActivateGlossaryItem: onActivateGlossaryItem,
                        onPickSpecial: onPickSpecial,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Workflow buttons (when expanded) - OUTSIDE InkWell
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: GlossaryPickerWidgets.workflowButtons(
                context,
                (pickerState?.editingComboItemIndex != null &&
                        !(pickerState?.isEditingCounter ?? false))
                    ? LocalizationService.translate('update_item', lang)
                    : (isCounterMode
                          ? LocalizationService.translate('add', lang)
                          : LocalizationService.translate('next', lang)),
                isCounterMode,
                // isEditing: hide +/→ only when editing the attack side,
                // not when editing a counter (counter mode still needs +/→)
                pickerState?.editingComboItemIndex != null &&
                    !(pickerState?.isEditingCounter ?? false),
                lang: lang,
                onNext: () {
                  debugPrint('GlossaryUIBuilder: onNext clicked');
                  final currentLevel = pickerState?.pendingLevel ?? '';
                  final currentSide = pickerState?.selectedSides[id] ?? '';
                  final currentFeint = pickerState?.selectedFeints[id] ?? false;
                  final currentSpecial = pickerState?.selectedSpecials[id];
                  onNext?.call(
                    item,
                    category,
                    currentSide,
                    currentLevel,
                    currentFeint,
                    currentSpecial,
                    translations,
                  );
                },
                onSimultaneous: () {
                  debugPrint('GlossaryUIBuilder: onSimultaneous (+) clicked');
                  final currentLevel = pickerState?.pendingLevel ?? '';
                  final currentSide = pickerState?.selectedSides[id] ?? '';
                  final currentFeint = pickerState?.selectedFeints[id] ?? false;
                  final currentSpecial = pickerState?.selectedSpecials[id];
                  onSimultaneous?.call(
                    item,
                    category,
                    currentSide,
                    currentLevel,
                    currentFeint,
                    currentSpecial,
                    translations,
                  );
                },
                onChain: () {
                  debugPrint('GlossaryUIBuilder: onChain clicked');
                  final currentLevel = pickerState?.pendingLevel ?? '';
                  final currentSide = pickerState?.selectedSides[id] ?? '';
                  final currentFeint = pickerState?.selectedFeints[id] ?? false;
                  final currentSpecial = pickerState?.selectedSpecials[id];
                  onChain?.call(
                    item,
                    category,
                    currentSide,
                    currentLevel,
                    currentFeint,
                    currentSpecial,
                    translations,
                  );
                },
                onAnswer: () {
                  debugPrint('GlossaryUIBuilder: onAnswer clicked');
                  final currentLevel = pickerState?.pendingLevel ?? '';
                  final currentSide = pickerState?.selectedSides[id] ?? '';
                  final currentFeint = pickerState?.selectedFeints[id] ?? false;
                  final currentSpecial = pickerState?.selectedSpecials[id];
                  onAnswer?.call(
                    item,
                    category,
                    currentSide,
                    currentLevel,
                    currentFeint,
                    currentSpecial,
                    translations,
                  );
                },
                onFinish: () {
                  debugPrint('GlossaryUIBuilder: onFinish clicked');
                  final currentLevel = pickerState?.pendingLevel ?? '';
                  final currentSide = pickerState?.selectedSides[id] ?? '';
                  final currentFeint = pickerState?.selectedFeints[id] ?? false;
                  final currentSpecial = pickerState?.selectedSpecials[id];
                  onFinish?.call(
                    item,
                    category,
                    currentSide,
                    currentLevel,
                    currentFeint,
                    currentSpecial,
                    translations,
                  );
                },
                onCancel: () {
                  debugPrint('GlossaryUIBuilder: onCancel clicked');
                  onCancel?.call();
                },
              ),
            ),
        ],
      ),
    );
  }

  // Build selection controls (sides, levels, feints, special actions)
  static List<Widget> _buildSelectionControls({
    required BuildContext context,
    required Map<String, dynamic> item,
    required String category,
    required int id,
    required String side,
    required bool isFeint,
    String? specialAction,
    required bool isCounterMode,
    required StateSetter setState,
    required String lang,
    required PickerState? pickerState,
    required VoidCallback? onActivateGlossaryItem,
    Function(int)? onPickSpecial,
  }) {
    final String possibleLevel = item['possible_level'] ?? 'H,M,L';
    final bool hasHigh = possibleLevel.contains('H');
    final bool hasMid = possibleLevel.contains('M');
    final bool hasLow = possibleLevel.contains('L');
    final bool hasDirection =
        item['possible_direction'] != null &&
        (item['possible_direction'] ?? '').isNotEmpty;

    final List<Widget> controls = [];

    if (hasDirection) {
      // Directional controls with arrow
      controls.add(
        GlossaryPickerWidgets.pickerSideButton(
          LocalizationService.translate('left', lang),
          'L',
          side,
          Colors.blue,
          id,
          () {
            setState(() {
              pickerState?.setPendingActionItem(id);
              pickerState?.setSelectedSide(id, 'L');
              onActivateGlossaryItem?.call();
            });
          },
          lang,
          withArrow: true,
        ),
      );
      controls.add(
        GlossaryPickerWidgets.pickerSideButton(
          LocalizationService.translate('right', lang),
          'R',
          side,
          Colors.red,
          id,
          () {
            setState(() {
              pickerState?.setPendingActionItem(id);
              pickerState?.setSelectedSide(id, 'R');
              onActivateGlossaryItem?.call();
            });
          },
          lang,
          withArrow: true,
        ),
      );
    } else if (category == 'move') {
      // Simple ADD button for moves
      controls.add(
        ElevatedButton(
          onPressed: () {
            setState(() {
              pickerState?.setPendingActionItem(id);
              pickerState?.setPendingLevel('');
              onActivateGlossaryItem?.call();
            });
          },
          child: const Text('ADD'),
        ),
      );
    } else if (category == 'trapping' || category == 'packs') {
      // Side buttons with arrows for trapping/packs
      controls.add(
        GlossaryPickerWidgets.sideButtonWithArrow(
          LocalizationService.translate('left', lang),
          'L',
          Colors.blue,
          () {
            setState(() {
              pickerState?.setPendingActionItem(id);
              pickerState?.setPendingLevel('');
              pickerState?.setSelectedSide(id, 'L');
              onActivateGlossaryItem?.call();
            });
          },
          lang,
          id,
        ),
      );
      controls.add(
        GlossaryPickerWidgets.sideButtonWithArrow(
          LocalizationService.translate('right', lang),
          'R',
          Colors.red,
          () {
            setState(() {
              pickerState?.setPendingActionItem(id);
              pickerState?.setPendingLevel('');
              pickerState?.setSelectedSide(id, 'R');
              onActivateGlossaryItem?.call();
            });
          },
          lang,
          id,
        ),
      );
    } else {
      // Default side buttons
      controls.add(
        GlossaryPickerWidgets.pickerSideButton(
          LocalizationService.translate('left', lang),
          'L',
          side,
          Colors.blue,
          id,
          () {
            setState(() {
              pickerState?.setPendingActionItem(id);
              pickerState?.setSelectedSide(id, 'L');
              onActivateGlossaryItem?.call();
            });
          },
          lang,
          withArrow: true,
        ),
      );
      controls.add(
        GlossaryPickerWidgets.pickerSideButton(
          LocalizationService.translate('right', lang),
          'R',
          side,
          Colors.red,
          id,
          () {
            setState(() {
              pickerState?.setPendingActionItem(id);
              pickerState?.setSelectedSide(id, 'R');
              onActivateGlossaryItem?.call();
            });
          },
          lang,
          withArrow: true,
        ),
      );

      // Feint filter and special action for punches/kicks
      if (category == 'punch' || category == 'kick') {
        controls.add(
          FilterChip(
            label: Text(
              LocalizationService.translate('draw', lang),
              style: const TextStyle(fontSize: 10),
            ),
            selected: isFeint,
            onSelected: (selected) {
              setState(() {
                pickerState?.setPendingActionItem(id);
                pickerState?.setSelectedFeint(id, selected);
                onActivateGlossaryItem?.call();
              });
            },
          ),
        );
        controls.add(
          ActionChip(
            label: Text(
              specialAction ?? LocalizationService.translate('move', lang),
              style: const TextStyle(fontSize: 10),
            ),
            onPressed: () {
              setState(() {
                pickerState?.setPendingActionItem(id);
                if (onPickSpecial != null) {
                  onPickSpecial(id);
                }
                onActivateGlossaryItem?.call();
              });
            },
          ),
        );
      }
    }

    // Add spacing before level controls
    controls.add(const SizedBox(width: 8));

    // Level selection
    if (isCounterMode) {
      if (hasHigh) {
        controls.add(
          GlossaryPickerWidgets.counterLevelButton(
            context,
            'High',
            id,
            () {
              setState(() {
                pickerState?.setPendingActionItem(id);
                pickerState?.setPendingLevel('High');
                onActivateGlossaryItem?.call();
              });
            },
            lang,
            isSelected:
                pickerState?.pendingActionItemId == id &&
                pickerState?.pendingLevel == 'High',
            withArrow: true,
          ),
        );
      }
      if (hasMid) {
        controls.add(
          GlossaryPickerWidgets.counterLevelButton(
            context,
            'Mid',
            id,
            () {
              setState(() {
                pickerState?.setPendingActionItem(id);
                pickerState?.setPendingLevel('Mid');
                onActivateGlossaryItem?.call();
              });
            },
            lang,
            isSelected:
                pickerState?.pendingActionItemId == id &&
                pickerState?.pendingLevel == 'Mid',
            withArrow: true,
          ),
        );
      }
      if (hasLow) {
        controls.add(
          GlossaryPickerWidgets.counterLevelButton(
            context,
            'Low',
            id,
            () {
              setState(() {
                pickerState?.setPendingActionItem(id);
                pickerState?.setPendingLevel('Low');
                onActivateGlossaryItem?.call();
              });
            },
            lang,
            isSelected:
                pickerState?.pendingActionItemId == id &&
                pickerState?.pendingLevel == 'Low',
            withArrow: true,
          ),
        );
      }
    } else if (!hasDirection) {
      if (hasHigh) {
        controls.add(
          GlossaryPickerWidgets.levelSelectionButton(
            context,
            'High',
            id,
            () {
              setState(() {
                pickerState?.setPendingActionItem(id);
                pickerState?.setPendingLevel(
                  pickerState.pendingLevel == 'High' ? '' : 'High',
                );
                onActivateGlossaryItem?.call();
              });
            },
            lang,
            isSelected:
                pickerState?.pendingActionItemId == id &&
                pickerState?.pendingLevel == 'High',
          ),
        );
      }
      if (hasMid) {
        controls.add(
          GlossaryPickerWidgets.levelSelectionButton(
            context,
            'Mid',
            id,
            () {
              setState(() {
                pickerState?.setPendingActionItem(id);
                pickerState?.setPendingLevel(
                  pickerState.pendingLevel == 'Mid' ? '' : 'Mid',
                );
                onActivateGlossaryItem?.call();
              });
            },
            lang,
            isSelected:
                pickerState?.pendingActionItemId == id &&
                pickerState?.pendingLevel == 'Mid',
          ),
        );
      }
      if (hasLow) {
        controls.add(
          GlossaryPickerWidgets.levelSelectionButton(
            context,
            'Low',
            id,
            () {
              setState(() {
                pickerState?.setPendingActionItem(id);
                pickerState?.setPendingLevel(
                  pickerState.pendingLevel == 'Low' ? '' : 'Low',
                );
                onActivateGlossaryItem?.call();
              });
            },
            lang,
            isSelected:
                pickerState?.pendingActionItemId == id &&
                pickerState?.pendingLevel == 'Low',
          ),
        );
      }
    }

    return controls;
  }
}
