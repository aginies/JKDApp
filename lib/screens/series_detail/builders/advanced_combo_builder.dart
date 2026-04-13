import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../models/move.dart';
import '../../../services/localization_service.dart';
import '../../../services/series_provider.dart';
import '../widgets/move_display_widgets.dart';
import '../widgets/separated_wrap.dart';
import '../widgets/diagonal_cross.dart';
import '../glossary/glossary_data_service.dart';
import '../training/combo_verification_service.dart';
import '../../../services/usage_statistics_service.dart';
import '../../../services/logging_service.dart';
import '../../../widgets/empty_state_illustration.dart';
import 'builder_card_data.dart';
import 'kali_hit_selector.dart';
import '../widgets/kali_angle_icon.dart';
import '../widgets/kali_angle_designer.dart';

// Improvement #1: single enum replaces 5 booleans — enforces mutual exclusivity.
enum _BuilderMode {
  none,
  defense,
  simultaneous,
  chain,
  counterSimultaneous,
  counterChain,
}

class AdvancedComboBuilder extends StatefulWidget {
  final Function(Move) onFinish;
  final VoidCallback onCancel;
  final Move? initialMove;
  final String? finishButtonLabel;
  final Move? trainingOriginalMove;
  final TrainingLevel? trainingLevel;

  const AdvancedComboBuilder({
    super.key,
    required this.onFinish,
    required this.onCancel,
    this.initialMove,
    this.finishButtonLabel,
    this.trainingOriginalMove,
    this.trainingLevel,
  });

  @override
  State<AdvancedComboBuilder> createState() => _AdvancedComboBuilderState();
}

class _AdvancedComboBuilderState extends State<AdvancedComboBuilder> {
  // Current state of the workspace
  final List<BuilderCardData> _workspaceCards = [];
  final _customTextController = TextEditingController();
  // Improvement #2: persistent controller — disposed in dispose(), not recreated per-frame.
  final _searchController = TextEditingController();
  String _glossarySearchQuery = '';

  // Performance: glossary futures cached so tab switches don't re-fetch.
  final Map<String, Future<List<Map<String, dynamic>>>> _glossaryCache = {};
  // Performance: single UsageStatisticsService instance reused across filter calls.
  final _usageService = UsageStatisticsService();

  // Path-based selection for recursive structures
  List<int>? _selectedPath;
  bool _isCounterSelected = false;
  bool _showAngleSelector = false;
  // Improvement #3: _selectedCounterIndex removed — was always _selectedCounterPath?.first.
  List<int>? _selectedCounterPath;

  // Improvement #1: mode enum
  _BuilderMode _mode = _BuilderMode.none;

  // History for undo/redo
  final List<BuilderHistoryEntry> _undoStack = [];
  final List<BuilderHistoryEntry> _redoStack = [];

  void _saveHistory() {
    _undoStack.add(
      BuilderHistoryEntry(
        cards: List.from(_workspaceCards),
        selectedPath: _selectedPath != null ? List.from(_selectedPath!) : null,
        isCounterSelected: _isCounterSelected,
        selectedCounterPath: _selectedCounterPath != null
            ? List.from(_selectedCounterPath!)
            : null,
      ),
    );
    _redoStack.clear();
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _redoStack.add(
        BuilderHistoryEntry(
          cards: List.from(_workspaceCards),
          selectedPath: _selectedPath != null
              ? List.from(_selectedPath!)
              : null,
          isCounterSelected: _isCounterSelected,
          selectedCounterPath: _selectedCounterPath != null
              ? List.from(_selectedCounterPath!)
              : null,
        ),
      );
      final entry = _undoStack.removeLast();
      _workspaceCards.clear();
      _workspaceCards.addAll(entry.cards);
      _selectedPath = entry.selectedPath;
      _isCounterSelected = entry.isCounterSelected;
      _selectedCounterPath = entry.selectedCounterPath;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _undoStack.add(
        BuilderHistoryEntry(
          cards: List.from(_workspaceCards),
          selectedPath: _selectedPath != null
              ? List.from(_selectedPath!)
              : null,
          isCounterSelected: _isCounterSelected,
          selectedCounterPath: _selectedCounterPath != null
              ? List.from(_selectedCounterPath!)
              : null,
        ),
      );
      final entry = _redoStack.removeLast();
      _workspaceCards.clear();
      _workspaceCards.addAll(entry.cards);
      _selectedPath = entry.selectedPath;
      _isCounterSelected = entry.isCounterSelected;
      _selectedCounterPath = entry.selectedCounterPath;
    });
  }

  Set<String> _getRelevantCategories(Move move) {
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
      cats.addAll(_getRelevantCategories(m));
    }
    for (var m in move.chain) {
      cats.addAll(_getRelevantCategories(m));
    }
    for (var m in move.counterSubMoves) {
      cats.addAll(_getRelevantCategories(m));
    }
    for (var m in move.counterChain) {
      cats.addAll(_getRelevantCategories(m));
    }
    return cats;
  }

  Set<String> _getTrainingMoves(Move move) {
    Set<String> names = {move.name.toLowerCase().trim()};
    if (move.counterName != null && move.counterName!.isNotEmpty) {
      names.add(move.counterName!.toLowerCase().trim());
    }
    for (var m in move.subMoves) {
      names.addAll(_getTrainingMoves(m));
    }
    for (var m in move.chain) {
      names.addAll(_getTrainingMoves(m));
    }
    for (var m in move.counterSubMoves) {
      names.addAll(_getTrainingMoves(m));
    }
    for (var m in move.counterChain) {
      names.addAll(_getTrainingMoves(m));
    }
    return names;
  }

  List<Map<String, dynamic>> _filterGlossaryForTraining(
    List<Map<String, dynamic>> items,
  ) {
    if (widget.trainingOriginalMove == null) return items;

    final allowedNames = _getTrainingMoves(widget.trainingOriginalMove!);
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
      return 0;
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialMove != null) {
      final m = widget.initialMove!;

      // Unpack ONE level so each sub-item becomes a separate workspace card.
      //
      // 'combo' items store numbered sub-items in subMoves.  When editing,
      // each sub-item becomes its own card (1. Jab  2. Cross  3. Jik Tek).
      //
      // Everything else (chains, simultaneous, standalone) is kept as a
      // single workspace card so the structure is preserved on round-trip.
      final bool isComboWrapper =
          m.category == 'combo' &&
          m.subMoves.isNotEmpty &&
          (m.counterName == null || m.counterName!.isEmpty);

      if (isComboWrapper) {
        _workspaceCards.addAll(m.subMoves.map((sm) => _convertFromMove(sm)));
      } else {
        _workspaceCards.add(_convertFromMove(m));
      }
    }
  }

  @override
  void dispose() {
    _customTextController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getSurfaceColor(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      // On AMOLED (black), cardColor is 0xFF121212.
      // Reduced contrast from 0.12 to 0.07
      return Color.alphaBlend(
        Colors.white.withValues(alpha: 0.07),
        theme.cardColor,
      );
    }
    return theme.cardColor;
  }

  Color _getAlphaColor(Color color, ThemeData theme) {
    // Significantly increase opacity in dark mode for better visibility
    return color.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.4 : 0.1,
    );
  }

  Color _getBorderColor(
    Color color,
    ThemeData theme, {
    bool isSelected = false,
  }) {
    if (theme.brightness == Brightness.dark) {
      return isSelected ? color : color.withValues(alpha: 0.5);
    }
    return isSelected ? color : color.withValues(alpha: 0.2);
  }

  // Fully recursive conversion to preserve nested structures (Simultaneous, nested Chains, Answers)
  BuilderCardData _convertFromMove(Move m) {
    return BuilderCardData(
      name: m.name,
      category: m.category,
      side: m.side,
      level: m.level,
      isFeint: m.isFeint,
      specialAction: m.specialAction,
      kaliAngle: m.kaliAngle,
      strikeType: m.strikeType,
      glossaryId: m.glossaryId,
      counterName: m.counterName,
      counterCategory: m.counterCategory,
      counterSide: m.counterSide ?? '',
      counterLevel: m.counterLevel ?? '',
      counterIsFeint: m.counterIsFeint,
      subMoves: m.subMoves.map((sm) => _convertFromMove(sm)).toList(),
      chain: m.chain.map((cm) => _convertFromMove(cm)).toList(),
      counterSubMoves: m.counterSubMoves
          .map((cm) => _convertFromMove(cm))
          .toList(),
      counterChain: m.counterChain.map((cm) => _convertFromMove(cm)).toList(),
    );
  }

  bool _shouldShowBottomToolbar() {
    if (_selectedPath == null) return false;

    final data = _getDataAtPath(_selectedPath!);
    if (data == null) return false;

    if (_isCounterSelected) {
      if (_selectedCounterPath != null) {
        // Selecting a sub-item in a structured answer
        // Check if the SUB-ITEM is an action card (not a group)
        BuilderCardData? sub = data;
        // Navigate down to the sub-item
        for (int idx in _selectedCounterPath!) {
          if (sub!.isChain && idx < sub.chain.length) {
            sub = sub.chain[idx];
          } else if (sub.isCombo && idx < sub.subMoves.length) {
            sub = sub.subMoves[idx];
          } else if (sub.hasCounterCombo && idx < sub.counterSubMoves.length) {
            sub = sub.counterSubMoves[idx];
          } else if (sub.hasCounterChain && idx < sub.counterChain.length) {
            sub = sub.counterChain[idx];
          } else {
            return false;
          }
        }
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SeriesProvider>(context).language;
    final theme = Theme.of(context);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _redo,
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _getSurfaceColor(theme),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            // TOP TOOLBAR: Structural buttons (stuck to top)
            _buildTopToolbar(lang),

            const SizedBox(height: 8),

            // MAIN WORKSPACE (scrollable, takes all available space)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: _workspaceCards.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            LocalizationService.translate(
                              'add_items_to_start',
                              lang,
                            ),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _workspaceCards.asMap().entries.map((
                            entry,
                          ) {
                            return _buildCard(
                              [entry.key],
                              entry.value,
                              lang,
                              cardNumber: entry.key + 1,
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),

            if (_shouldShowBottomToolbar()) ...[
              const SizedBox(height: 8),
              // BOTTOM TOOLBAR: Property buttons (stuck to bottom)
              _buildBottomToolbar(lang),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolbar(String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSimulActive =
        _mode == _BuilderMode.simultaneous ||
        _mode == _BuilderMode.counterSimultaneous;
    final isChainActive =
        _mode == _BuilderMode.chain || _mode == _BuilderMode.counterChain;
    final isDefenseActive = _mode == _BuilderMode.defense;

    return Row(
      children: [
        // LEFT group: action buttons
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _toolbarButton('', Icons.add, Colors.blue, _onAddClick),
                _toolbarButton('', Icons.remove, Colors.red, _onDeleteSelected),

                // History Box (Undo/Redo)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toolbarButton(
                        '',
                        Icons.undo,
                        Colors.grey,
                        _undo,
                        isActive: _undoStack.isNotEmpty,
                      ),
                      _toolbarButton(
                        '',
                        Icons.redo,
                        Colors.grey,
                        _redo,
                        isActive: _redoStack.isNotEmpty,
                      ),
                    ],
                  ),
                ),

                _toolbarButton(
                  '',
                  null,
                  isSimulActive ? Colors.green : Colors.blueAccent,
                  () {
                    if (_selectedPath != null) {
                      setState(() {
                        _mode = _isCounterSelected
                            ? _BuilderMode.counterSimultaneous
                            : _BuilderMode.simultaneous;
                      });
                      _showGlossaryPicker();
                    }
                  },
                  isActive: isSimulActive,
                  customChild: Builder(
                    builder: (context) {
                      final fg = isSimulActive
                          ? Colors.white
                          : Colors.blueAccent;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 14,
                              color: fg,
                            ),
                          ),
                          Text(
                            'B',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                _toolbarButton(
                  '',
                  null,
                  isChainActive ? Colors.green : Colors.teal,
                  () {
                    if (_selectedPath != null) {
                      setState(() {
                        _mode = _isCounterSelected
                            ? _BuilderMode.counterChain
                            : _BuilderMode.chain;
                      });
                      _showGlossaryPicker();
                    }
                  },
                  isActive: isChainActive,
                  customChild: Builder(
                    builder: (context) {
                      final fg = isChainActive ? Colors.white : Colors.teal;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: fg,
                            ),
                          ),
                          Icon(Icons.add, size: 12, color: fg),
                        ],
                      );
                    },
                  ),
                ),
                _toolbarButton(
                  '',
                  Icons.subdirectory_arrow_right,
                  isDefenseActive
                      ? Colors.green
                      : ((_selectedPath != null && _isCounterSelected)
                            ? Colors.grey
                            : Colors.orange),
                  () {
                    // Prevent nested answers: disable if an answer is already selected
                    if (_selectedPath != null && !_isCounterSelected) {
                      setState(() {
                        _mode = _BuilderMode.defense;
                      });
                      _showGlossaryPicker();
                    }
                  },
                  isActive: isDefenseActive,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        // RIGHT group: Finish & Cancel
        _toolbarButton(
          (widget.finishButtonLabel == null ||
                  widget.finishButtonLabel!.isEmpty)
              ? ''
              : widget.finishButtonLabel!,
          Icons.check,
          Colors.green,
          _onFinishClick,
          isActive: true,
        ),
        _toolbarButton(
          '',
          Icons.close,
          Colors.red,
          widget.onCancel,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(String lang) {
    final data = _getDataAtPath(_selectedPath!);
    final isKali =
        data != null && (data.category == 'kali' || data.category == 'angles');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isKali && _showAngleSelector) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: KaliHitSelector(
              selectedAngle: data.kaliAngle,
              selectedStrikeType: data.strikeType,
              onAngleSelected: (angle) => _updateSelectedCard(kaliAngle: angle),
              onStrikeTypeSelected: (type) =>
                  _updateSelectedCard(strikeType: type),
            ),
          ),
          const Divider(),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (isKali) ...[
                _toolbarButton(
                  'Angle',
                  Icons.architecture,
                  _showAngleSelector ? Colors.brown : Colors.grey,
                  () =>
                      setState(() => _showAngleSelector = !_showAngleSelector),
                  isActive: _showAngleSelector,
                ),
                const SizedBox(width: 8, child: VerticalDivider()),
              ],
              _toolbarButton(
                LocalizationService.translate('left', lang),
                Icons.arrow_back,
                Colors.blue,
                () => _updateSelectedCard(side: 'L'),
              ),
              _toolbarButton(
                LocalizationService.translate('right', lang),
                Icons.arrow_forward,
                Colors.red,
                () => _updateSelectedCard(side: 'R'),
              ),
              const SizedBox(width: 8, child: VerticalDivider()),
              _toolbarButton(
                LocalizationService.translate('draw', lang),
                Icons.gesture,
                Colors.purple,
                () => _updateSelectedCard(toggleFeint: true),
              ),
              const SizedBox(width: 8, child: VerticalDivider()),
              _toolbarButton(
                'H',
                Icons.north_east,
                Colors.grey[700]!,
                () => _updateSelectedCard(level: 'High'),
                customText: Colors.white,
              ),
              _toolbarButton(
                'M',
                Icons.arrow_forward,
                Colors.grey[700]!,
                () => _updateSelectedCard(level: 'Mid'),
                customText: Colors.white,
              ),
              _toolbarButton(
                'L',
                Icons.south_east,
                Colors.grey[700]!,
                () => _updateSelectedCard(level: 'Low'),
                customText: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolbarButton(
    String label,
    IconData? icon,
    Color color,
    VoidCallback onPressed, {
    bool isActive = false,
    Color? customText,
    Widget? customChild,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 95% opacity for active buttons in dark mode
    final double bgAlpha = isDark
        ? (isActive ? 0.95 : 0.3)
        : (isActive ? 1.0 : 0.1);

    final Color bgColor = color.withValues(alpha: bgAlpha);

    // In dark mode, non-active buttons should use a brighter version of the color or white
    final Color fgColor =
        customText ??
        (isActive
            ? Colors.white
            : (isDark
                  ? Color.alphaBlend(color.withValues(alpha: 0.7), Colors.white)
                  : color));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          minimumSize: const Size(0, 32),
          backgroundColor: bgColor,
          side: isDark
              ? BorderSide(color: color.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child:
            customChild ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 16, color: fgColor),
                if (icon != null && label.isNotEmpty) const SizedBox(width: 2),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  // Recursive Card builder
  Widget _buildCard(
    List<int> path,
    BuilderCardData data,
    String lang, {
    int? cardNumber,
  }) {
    final theme = Theme.of(context);
    final isSelected = _isPathSelected(path);
    final color = MoveDisplayWidgets.getCategoryColor(data.category);

    Widget card;

    // BOX: CHAIN
    if (data.isChain) {
      card = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _selectPath(path),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSurfaceColor(theme),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isSelected && !_isCounterSelected)
                      ? Colors.green
                      : _getBorderColor(Colors.grey, theme),
                  width: (isSelected && !_isCounterSelected) ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CHAIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SeparatedWrap(
                    spacing: 4,
                    runSpacing: 10,
                    children: data.chain.asMap().entries.map((e) {
                      final itemPath = [...path, e.key];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCard(itemPath, e.value, lang),
                          if (e.key < data.chain.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 28, // Standardized large size
                                color: Colors.teal,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          if (data.hasCounter) ...[
            const SizedBox(height: 4),
            _buildCounterBox(path, data, lang, isSelected),
          ],
        ],
      );
    } else if (data.isCombo) {
      card = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _selectPath(path),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSurfaceColor(theme),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isSelected && !_isCounterSelected)
                      ? Colors.green
                      : _getBorderColor(Colors.grey, theme),
                  width: (isSelected && !_isCounterSelected) ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SIMULTANEOUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getAlphaColor(Colors.grey, theme),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SeparatedWrap(
                      spacing: 4,
                      runSpacing: 10,
                      children: data.subMoves.asMap().entries.expand((e) {
                        final itemPath = [...path, e.key];
                        return [
                          if (e.key > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.0),
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          _buildCard(itemPath, e.value, lang),
                        ];
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (data.hasCounter) ...[
            const SizedBox(height: 4),
            _buildCounterBox(path, data, lang, isSelected),
          ],
        ],
      );
    } else {
      // RENDER LEAF ITEM
      card = GestureDetector(
        onTap: () => _selectPath(path),
        child: Container(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 75),
          decoration: BoxDecoration(
            color: _getSurfaceColor(theme),
            borderRadius: BorderRadius.circular(8),
            // Removed outer border to fix double border issue
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ATTACKER BOX
              GestureDetector(
                onTap: () => _selectPath(path, isCounter: false),
                child: DiagonalCross(
                  show: data.isFeint,
                  color: Colors.purple,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getAlphaColor(color, theme),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getBorderColor(
                          color,
                          theme,
                          isSelected: isSelected && !_isCounterSelected,
                        ),
                        width: (isSelected && !_isCounterSelected) ? 2.0 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((data.category == 'kali' ||
                                data.category == 'angles') &&
                            data.kaliAngle != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: KaliAngleIcon(
                              angle: data.kaliAngle!,
                              size: 24,
                              color: MoveDisplayWidgets.getCategoryColor(
                                'kali',
                              ),
                            ),
                          )
                        else
                          Icon(
                            MoveDisplayWidgets.getCategoryIcon(data.category),
                            size: 20,
                            color: color,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          data.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: theme.brightness == Brightness.dark
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (data.specialAction != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Chip(
                              label: Text(
                                data.specialAction!,
                                style: const TextStyle(fontSize: 8),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        if (data.side.isNotEmpty || data.level.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: [
                              if (data.side.isNotEmpty)
                                MoveDisplayWidgets.sideCircle(
                                  LocalizationService.translate(
                                    data.side == 'L'
                                        ? 'left'
                                        : (data.side == 'R' ? 'right' : 'mid'),
                                    lang,
                                  ).substring(0, 1),
                                  data.side,
                                  mini: true,
                                ),
                              if (data.level.isNotEmpty)
                                MoveDisplayWidgets.levelIcon(
                                  data.level,
                                  mini: true,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              if (data.hasCounter) ...[
                const SizedBox(height: 4),
                _buildCounterBox(path, data, lang, isSelected),
              ],
            ],
          ),
        ),
      );
    }

    // Wrap with number badge for top-level cards
    if (cardNumber != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$cardNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }

  /// Builds a single counter sub-item card (used inside simultaneous/chain counter boxes).
  Widget _buildCounterSubCard(
    List<int> path,
    BuilderCardData sm,
    List<int> counterPath,
    String lang,
    bool isTopSelected,
  ) {
    final theme = Theme.of(context);
    final bool isSubSelected = _isCounterPathSelected(path, counterPath);

    if (sm.isChain || sm.isCombo) {
      // RECURSIVE rendering for nested groups inside an answer
      final color = MoveDisplayWidgets.getCategoryColor(sm.category);
      return GestureDetector(
        onTap: () =>
            _selectPath(path, isCounter: true, counterPath: counterPath),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getAlphaColor(color, theme),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBorderColor(color, theme, isSelected: isSubSelected),
              width: isSubSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sm.isChain ? 'CHAIN' : 'SIMUL.',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: (sm.isChain ? sm.chain : sm.subMoves)
                    .asMap()
                    .entries
                    .map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final itemPath = [...counterPath, idx];

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCounterSubCard(
                            path,
                            item,
                            itemPath,
                            lang,
                            isTopSelected,
                          ),
                          if (sm.isChain && idx < sm.chain.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 28,
                                color: Colors.grey,
                              ),
                            ),
                          if (sm.isCombo && idx < sm.subMoves.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.0),
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }

    // Leaf item rendering (standard)
    final color = MoveDisplayWidgets.getCategoryColor(sm.category);
    return GestureDetector(
      onTap: () => _selectPath(path, isCounter: true, counterPath: counterPath),
      child: DiagonalCross(
        show: sm.isFeint,
        color: Colors.purple,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getAlphaColor(color, theme),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getBorderColor(color, theme, isSelected: isSubSelected),
              width: isSubSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((sm.category == 'kali' || sm.category == 'angles') &&
                  sm.kaliAngle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: KaliAngleIcon(
                    angle: sm.kaliAngle!,
                    size: 20,
                    color: MoveDisplayWidgets.getCategoryColor('kali'),
                  ),
                )
              else
                Icon(
                  MoveDisplayWidgets.getCategoryIcon(sm.category),
                  size: 18,
                  color: color,
                ),
              Text(
                sm.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: theme.brightness == Brightness.dark
                      ? FontWeight.w600
                      : FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (sm.side.isNotEmpty || sm.level.isNotEmpty)
                Wrap(
                  spacing: 2,
                  children: [
                    if (sm.side.isNotEmpty)
                      MoveDisplayWidgets.sideCircle(
                        LocalizationService.translate(
                          sm.side == 'L'
                              ? 'left'
                              : (sm.side == 'R' ? 'right' : 'mid'),
                          lang,
                        ).substring(0, 1),
                        sm.side,
                        mini: true,
                      ),
                    if (sm.level.isNotEmpty)
                      MoveDisplayWidgets.levelIcon(sm.level, mini: true),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterBox(
    List<int> path,
    BuilderCardData data,
    String lang,
    bool isTopSelected,
  ) {
    final theme = Theme.of(context);
    final bool isThisCounterSelected = isTopSelected && _isCounterSelected;
    // Improvement #3: derive from _selectedCounterPath instead of removed _selectedCounterIndex.
    final bool isWholeCounterSelected =
        isThisCounterSelected && _selectedCounterPath == null;

    // Build inner content based on counter structure
    Widget counterContent;

    if (data.hasCounterCombo) {
      // SIMULTANEOUS counter (A+B answer)
      counterContent = Column(
        children: [
          const Text(
            'ANSWER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'SIMULTANEOUS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getAlphaColor(Colors.grey, theme),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SeparatedWrap(
              spacing: 4,
              runSpacing: 10,
              children: data.counterSubMoves.asMap().entries.expand((e) {
                return [
                  if (e.key > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  _buildCounterSubCard(
                    path,
                    e.value,
                    [e.key],
                    lang,
                    isTopSelected,
                  ),
                ];
              }).toList(),
            ),
          ),
        ],
      );
    } else if (data.hasCounterChain) {
      // CHAIN counter (A->+ answer)
      counterContent = Column(
        children: [
          const Text(
            'ANSWER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'CHAIN',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          SeparatedWrap(
            spacing: 4,
            runSpacing: 10,
            children: data.counterChain.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCounterSubCard(
                    path,
                    e.value,
                    [e.key],
                    lang,
                    isTopSelected,
                  ),
                  if (e.key < data.counterChain.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 28,
                        color: Colors.teal,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      );
    } else {
      // Simple single counter (existing behavior)
      counterContent = Column(
        children: [
          const Text(
            'ANSWER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 2),
          if ((data.counterCategory == 'kali' ||
                  data.counterCategory == 'angles') &&
              data.kaliAngle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: KaliAngleIcon(
                angle: data.kaliAngle!,
                size: 20,
                color: MoveDisplayWidgets.getCategoryColor('kali'),
              ),
            ),
          Text(
            data.counterName!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: theme.brightness == Brightness.dark
                  ? FontWeight.w600
                  : FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (data.counterSide.isNotEmpty || data.counterLevel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 2,
              children: [
                if (data.counterSide.isNotEmpty)
                  MoveDisplayWidgets.sideCircle(
                    LocalizationService.translate(
                      data.counterSide == 'L' ? 'left' : 'right',
                      lang,
                    ).substring(0, 1),
                    data.counterSide,
                    mini: true,
                  ),
                if (data.counterLevel.isNotEmpty)
                  MoveDisplayWidgets.levelIcon(data.counterLevel, mini: true),
              ],
            ),
          ],
        ],
      );
    }

    return GestureDetector(
      onTap: () => _selectPath(path, isCounter: true),
      child: DiagonalCross(
        show: data.counterIsFeint,
        color: Colors.purple,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getAlphaColor(Colors.red, theme),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getBorderColor(
                Colors.red,
                theme,
                isSelected:
                    isWholeCounterSelected ||
                    (isThisCounterSelected && !data.hasStructuredCounter),
              ),
              width:
                  isWholeCounterSelected ||
                      (isThisCounterSelected && !data.hasStructuredCounter)
                  ? 2
                  : 1,
            ),
          ),
          child: counterContent,
        ),
      ),
    );
  }

  bool _isPathSelected(List<int> path) {
    if (_selectedPath == null || _selectedPath!.length != path.length) {
      return false;
    }
    for (int i = 0; i < path.length; i++) {
      if (_selectedPath![i] != path[i]) return false;
    }
    return true;
  }

  bool _isCounterPathSelected(List<int> path, List<int> counterPath) {
    if (!_isPathSelected(path)) return false;
    if (_selectedCounterPath == null ||
        _selectedCounterPath!.length != counterPath.length) {
      return false;
    }
    for (int i = 0; i < counterPath.length; i++) {
      if (_selectedCounterPath![i] != counterPath[i]) return false;
    }
    return true;
  }

  void _selectPath(
    List<int> path, {
    bool isCounter = false,
    List<int>? counterPath,
  }) {
    setState(() {
      _selectedPath = List<int>.from(path);
      _isCounterSelected = isCounter;
      _showAngleSelector = false;
      _selectedCounterPath = counterPath != null
          ? List<int>.from(counterPath)
          : null;
    });
  }

  /// Read-only helper: returns the BuilderCardData at the given path, or null.
  BuilderCardData? _getDataAtPath(List<int> path) {
    if (path.isEmpty || path[0] >= _workspaceCards.length) return null;
    BuilderCardData current = _workspaceCards[path[0]];
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

  void _onAddClick() {
    setState(() {
      _mode = _BuilderMode.none;
    });
    _showGlossaryPicker();
  }

  BuilderCardData? _deleteNestedData(
    BuilderCardData root,
    List<int> counterPath,
  ) {
    if (counterPath.length == 1) {
      // BASE CASE: We are at the parent of the item to remove
      final idx = counterPath[0];

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
      } else if (root.hasCounterCombo && idx < root.counterSubMoves.length) {
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

    // RECURSIVE CASE: Navigate deeper
    final idx = counterPath[0];
    final remainingPath = counterPath.sublist(1);

    if (root.isChain && idx < root.chain.length) {
      final newList = List<BuilderCardData>.from(root.chain);
      final updated = _deleteNestedData(newList[idx], remainingPath);
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
      final updated = _deleteNestedData(newList[idx], remainingPath);
      if (updated == null) {
        newList.removeAt(idx);
      } else {
        newList[idx] = updated;
      }
      if (newList.isEmpty) return null;
      if (newList.length == 1) return newList.first;
      return root.copyWith(subMoves: newList);
    } else if (root.hasCounterCombo && idx < root.counterSubMoves.length) {
      final newList = List<BuilderCardData>.from(root.counterSubMoves);
      final updated = _deleteNestedData(newList[idx], remainingPath);
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
      final updated = _deleteNestedData(newList[idx], remainingPath);
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

  void _onDeleteSelected() {
    if (_selectedPath == null) return;
    HapticFeedback.lightImpact();
    _saveHistory();

    setState(() {
      if (_isCounterSelected && _selectedCounterPath != null) {
        // Nested deletion within structured counters
        _updateDataAtPath(_selectedPath!, (item) {
          return _deleteNestedData(item, _selectedCounterPath!) ?? item;
        });
        _selectedCounterPath = null;
      } else if (_isCounterSelected) {
        // DELETE ONLY THE ANSWER of the item at the selected path
        _updateDataAtPath(_selectedPath!, (item) {
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
        _isCounterSelected = false;
        _selectedCounterPath = null;
      } else if (_selectedPath!.length > 1) {
        // DELETE ONLY THE TARGETED SUB-ITEM
        final parentPath = _selectedPath!.sublist(0, _selectedPath!.length - 1);
        final indexToRemove = _selectedPath!.last;

        _updateDataAtPath(parentPath, (parent) {
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

        _selectedPath = null;
        _selectedCounterPath = null;
      } else {
        // DELETE ENTIRE TOP-LEVEL CARD
        _workspaceCards.removeAt(_selectedPath![0]);
        _selectedPath = null;
        _selectedCounterPath = null;
      }
    });
  }

  void _onFinishClick() {
    LoggingService.log('AdvancedComboBuilder: Finish/Verify clicked');
    if (_workspaceCards.isEmpty) {
      LoggingService.log(
        'AdvancedComboBuilder: Workspace is empty, ignoring click',
      );
      return;
    }

    Move finalMove;
    if (_workspaceCards.length == 1) {
      finalMove = _convertToMove(_workspaceCards.first);
    } else {
      final subMoves = _workspaceCards.map((c) => _convertToMove(c)).toList();
      finalMove = Move(
        name: 'Combo: ${subMoves.first.name} + ...',
        category: 'combo',
        subMoves: subMoves,
      );
    }

    LoggingService.log('AdvancedComboBuilder: Calling onFinish callback');
    widget.onFinish(finalMove);
  }

  Move _convertToMove(BuilderCardData data) {
    // 1. Recursive handling for CHAIN (Inner contents must be leaf or combos, NEVER nested chains)
    if (data.isChain) {
      return Move(
        name: data.chain.map((m) => m.name).join(' -> '),
        category: 'chain',
        chain: data.chain.map((m) => _convertToMove(m)).toList(),
        counterName: data.counterName,
        counterCategory: data.counterCategory,
        counterSide: data.counterSide,
        counterLevel: data.counterLevel,
        counterIsFeint: data.counterIsFeint,
        counterSubMoves: data.counterSubMoves
            .map((cm) => _convertToMove(cm))
            .toList(),
        counterChain: data.counterChain.map((m) => _convertToMove(m)).toList(),
      );
    }

    // 2. Recursive handling for SIMULTANEOUS (Combo)
    if (data.isCombo) {
      return Move(
        name: data.subMoves.map((m) => m.name).join(' + '),
        category: 'simultaneous',
        subMoves: data.subMoves.map((m) => _convertToMove(m)).toList(),
        counterName: data.counterName,
        counterCategory: data.counterCategory,
        counterSide: data.counterSide,
        counterLevel: data.counterLevel,
        counterIsFeint: data.counterIsFeint,
        counterSubMoves: data.counterSubMoves
            .map((cm) => _convertToMove(cm))
            .toList(),
        counterChain: data.counterChain.map((m) => _convertToMove(m)).toList(),
      );
    }

    // 3. BASE ITEM (Leaf)
    return Move(
      name: data.name,
      category: data.category,
      side: data.side,
      level: data.level,
      isFeint: data.isFeint,
      specialAction: data.specialAction,
      kaliAngle: data.kaliAngle,
      strikeType: data.strikeType,
      glossaryId: data.glossaryId,
      counterName: data.counterName,
      counterCategory: data.counterCategory,
      counterSide: data.counterSide,
      counterLevel: data.counterLevel,
      counterIsFeint: data.counterIsFeint,
      counterSubMoves: data.counterSubMoves
          .map((cm) => _convertToMove(cm))
          .toList(),
      counterChain: data.counterChain.map((m) => _convertToMove(m)).toList(),
    );
  }

  // Deep update helper
  void _updateDataAtPath(
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
      final result = updater(_workspaceCards[topIndex]);
      if (result == null) {
        _workspaceCards.removeAt(topIndex);
      } else {
        _workspaceCards[topIndex] = result;
      }
    } else {
      final result = updateRecursive(_workspaceCards[topIndex], remaining);
      if (result == null) {
        _workspaceCards.removeAt(topIndex);
      } else {
        _workspaceCards[topIndex] = result;
      }
    }
  }

  BuilderCardData _updateNestedData(
    BuilderCardData root,
    List<int> counterPath,
    String? side,
    String? level,
    bool toggleFeint,
    int? kaliAngle,
    String? strikeType,
  ) {
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

    if (root.isChain && idx < root.chain.length) {
      final newList = List<BuilderCardData>.from(root.chain);
      newList[idx] = _updateNestedData(
        newList[idx],
        remainingPath,
        side,
        level,
        toggleFeint,
        kaliAngle,
        strikeType,
      );
      return root.copyWith(chain: newList);
    } else if (root.isCombo && idx < root.subMoves.length) {
      final newList = List<BuilderCardData>.from(root.subMoves);
      newList[idx] = _updateNestedData(
        newList[idx],
        remainingPath,
        side,
        level,
        toggleFeint,
        kaliAngle,
        strikeType,
      );
      return root.copyWith(subMoves: newList);
    } else if (root.hasCounterCombo && idx < root.counterSubMoves.length) {
      final newList = List<BuilderCardData>.from(root.counterSubMoves);
      newList[idx] = _updateNestedData(
        newList[idx],
        remainingPath,
        side,
        level,
        toggleFeint,
        kaliAngle,
        strikeType,
      );
      return root.copyWith(counterSubMoves: newList);
    } else if (root.hasCounterChain && idx < root.counterChain.length) {
      final newList = List<BuilderCardData>.from(root.counterChain);
      newList[idx] = _updateNestedData(
        newList[idx],
        remainingPath,
        side,
        level,
        toggleFeint,
        kaliAngle,
        strikeType,
      );
      return root.copyWith(counterChain: newList);
    }

    return root;
  }

  void _updateSelectedCard({
    String? side,
    String? level,
    bool toggleFeint = false,
    String? specialAction,
    int? kaliAngle,
    String? strikeType,
  }) {
    if (_selectedPath == null) return;
    _saveHistory();

    setState(() {
      _updateDataAtPath(_selectedPath!, (item) {
        if (_isCounterSelected && _selectedCounterPath != null) {
          // Deep-nested update for structured counters
          return _updateNestedData(
            item,
            _selectedCounterPath!,
            side,
            level,
            toggleFeint,
            kaliAngle,
            strikeType,
          );
        } else if (_isCounterSelected) {
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
            kaliAngle: kaliAngle ?? item.kaliAngle,
            strikeType: strikeType ?? item.strikeType,
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
    });
  }

  void _showGlossaryPicker() {
    // Improvement #2: reset the persistent controller instead of recreating it.
    _glossarySearchQuery = '';
    _searchController.clear();

    // Performance (#9): build the tab definitions once per modal open rather
    // than rebuilding them on every setModalState call.
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    final allTabs = _buildAllTabDefs(lang);

    // Compute enabled tabs once — trainingLevel and trainingOriginalMove are
    // stable for the lifetime of this widget.
    List<Map<String, dynamic>> enabledTabs;
    if (widget.trainingLevel == TrainingLevel.beginner &&
        widget.trainingOriginalMove != null) {
      final relevantCats = _getRelevantCategories(widget.trainingOriginalMove!);
      enabledTabs = allTabs.where((tab) {
        final cats = tab['cats'] as List<String>;
        if (tab['id'] == 'text') return true; // always show text tab
        return cats.any((c) => relevantCats.contains(c));
      }).toList();
      if (enabledTabs.isEmpty) enabledTabs = [allTabs.last];
    } else {
      enabledTabs = allTabs;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 8.0,
                      top: 12.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              autofocus: false,
                              decoration: InputDecoration(
                                hintText: LocalizationService.translate(
                                  'search_hint',
                                  lang,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                suffixIcon: _glossarySearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          _searchController.clear();
                                          setModalState(() {
                                            _glossarySearchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              controller: _searchController,
                              onChanged: (val) {
                                setModalState(() => _glossarySearchQuery = val);
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _glossarySearchQuery.isEmpty
                        ? DefaultTabController(
                            length: enabledTabs.length,
                            child: Column(
                              children: [
                                TabBar(
                                  isScrollable: true,
                                  tabs: enabledTabs
                                      .map(
                                        (t) => Tab(text: t['label'] as String),
                                      )
                                      .toList(),
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: enabledTabs.map((tab) {
                                      final builder =
                                          tab['view']
                                              as Widget Function(
                                                ScrollController,
                                              );
                                      return builder(scrollController);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildGlobalGlossarySearchResults(scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Defines the fixed set of glossary tabs. Called once per modal open.
  List<Map<String, dynamic>> _buildAllTabDefs(String lang) {
    return [
      {
        'id': 'punch_kick',
        'label':
            '${LocalizationService.translate('punches', lang)} / ${LocalizationService.translate('kicks', lang)}',
        'cats': ['punch', 'kick'],
        'view': (ScrollController sc) =>
            _buildDualGlossaryTab('punch', 'kick', sc),
      },
      {
        'id': 'packs_trapping',
        'label':
            '${LocalizationService.translate('packs', lang)} / ${LocalizationService.translate('trapping', lang)}',
        'cats': ['packs', 'trapping'],
        'view': (ScrollController sc) =>
            _buildDualGlossaryTab('packs', 'trapping', sc),
      },
      {
        'id': 'move',
        'label': LocalizationService.translate('move', lang),
        'cats': ['move'],
        'view': (ScrollController sc) =>
            _buildDualGlossaryTab('move', null, sc),
      },
      {
        'id': 'kali',
        'label': LocalizationService.translate('kali', lang),
        'cats': ['kali'],
        'view': (ScrollController sc) =>
            _buildDualGlossaryTab('kali', null, sc),
      },
      {
        'id': 'angles',
        'label': LocalizationService.translate('angles', lang),
        'cats': ['angles'],
        'view': (ScrollController sc) =>
            _buildDualGlossaryTab('angles', null, sc),
      },
      {
        'id': 'custom_angles',
        'label': lang == 'fr' ? 'Angles Persos' : 'Custom Angles',
        'cats': ['custom_angles'],
        'view': (ScrollController sc) => _buildCustomAnglesTab(sc),
      },
      {
        'id': 'text',
        'label': LocalizationService.translate('text', lang),
        'cats': ['text'],
        'view': (ScrollController sc) =>
            _buildDualGlossaryTab('text', null, sc),
      },
    ];
  }

  Widget _buildDualGlossaryTab(
    String cat1,
    String? cat2,
    ScrollController scrollController,
  ) {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;

    // Special case for Text alone
    if (cat1 == 'text') {
      return SingleChildScrollView(
        controller: scrollController,
        child: _buildTextTab(),
      );
    }

    // Performance: cache futures so switching tabs does not re-fetch.
    _glossaryCache[cat1] ??= GlossaryDataService.fetchGlossaryByCategory(cat1);
    if (cat2 != null) {
      _glossaryCache[cat2] ??= GlossaryDataService.fetchGlossaryByCategory(
        cat2,
      );
    }

    return FutureBuilder<List<List<Map<String, dynamic>>>>(
      future: Future.wait([
        _glossaryCache[cat1]!,
        cat2 != null
            ? _glossaryCache[cat2]!
            : Future.value(<Map<String, dynamic>>[]),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items1 = _filterGlossaryForTraining(snapshot.data![0]);
        final items2 = _filterGlossaryForTraining(snapshot.data![1]);

        // If cat2 is null, split cat1 into two columns
        if (cat2 == null) {
          final half = (items1.length / 2).ceil();
          return ListView.builder(
            controller: scrollController,
            itemCount: half,
            itemBuilder: (context, index) {
              final idx1 = index;
              final idx2 = index + half;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCompactGlossaryTile(items1[idx1], cat1, lang),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: idx2 < items1.length
                        ? _buildCompactGlossaryTile(items1[idx2], cat1, lang)
                        : const SizedBox(),
                  ),
                ],
              );
            },
          );
        }

        // Standard dual category mode
        final maxLen = items1.length > items2.length
            ? items1.length
            : items2.length;

        return ListView.builder(
          controller: scrollController,
          itemCount: maxLen,
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: index < items1.length
                      ? _buildCompactGlossaryTile(items1[index], cat1, lang)
                      : const SizedBox(),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: index < items2.length
                      ? _buildCompactGlossaryTile(items2[index], cat2, lang)
                      : const SizedBox(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompactGlossaryTile(
    Map<String, dynamic> item,
    String category,
    String lang,
  ) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final themeColor = provider.themeColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final translations = GlossaryDataService.parseTranslations(
      item['translations'],
    );
    final translation = GlossaryDataService.getTranslation(translations, lang);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                themeColor.withValues(alpha: isDark ? 0.1 : 0.05),
              ],
            ),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: (category == 'angles')
              ? Builder(
                  builder: (context) {
                    final name = item['name'].toString();
                    final match = RegExp(r'Angle\s+(\d+)').firstMatch(name);
                    final angle = match != null
                        ? int.tryParse(match.group(1) ?? '')
                        : null;
                    if (angle != null) {
                      return KaliAngleIcon(
                        angle: angle,
                        size: 28, // Increased from 22
                        color: MoveDisplayWidgets.getCategoryColor(category),
                        showCircle: false,
                      );
                    }
                    return Icon(
                      MoveDisplayWidgets.getCategoryIcon(category),
                      color: MoveDisplayWidgets.getCategoryColor(category),
                      size: 28, // Increased from 22
                    );
                  },
                )
              : Icon(
                  MoveDisplayWidgets.getCategoryIcon(category),
                  color: MoveDisplayWidgets.getCategoryColor(category),
                  size: 28, // Increased from 22
                ),
        ),
        title: Text(
          item['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: translation.isNotEmpty
            ? Text(
                translation,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        onTap: () {
          int? angle;
          if (category == 'kali' || category == 'angles') {
            final name = item['name'].toString();
            final match = RegExp(r'Angle\s+(\d+)').firstMatch(name);
            if (match != null) {
              angle = int.tryParse(match.group(1) ?? '');
            }
          }

          final newItem = BuilderCardData(
            name: item['name'],
            category: category,
            glossaryId: item['id'],
            kaliAngle: angle,
          );
          _onAddItem(newItem);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Improvement #5: _onAddItem split into focused sub-methods per mode.
  // ---------------------------------------------------------------------------

  void _onAddItem(BuilderCardData newItem) {
    HapticFeedback.lightImpact();
    _saveHistory();
    setState(() {
      switch (_mode) {
        case _BuilderMode.counterSimultaneous:
          if (_selectedPath != null) _addItemCounterSimultaneous(newItem);
        case _BuilderMode.counterChain:
          if (_selectedPath != null) _addItemCounterChain(newItem);
        case _BuilderMode.defense:
          if (_selectedPath != null) _addItemDefense(newItem);
        case _BuilderMode.chain:
          if (_selectedPath != null) _addItemToChain(newItem);
        case _BuilderMode.simultaneous:
          if (_selectedPath != null) _addItemSimultaneous(newItem);
        case _BuilderMode.none:
          _addItemDefault(newItem);
      }
    });
  }

  void _addItemCounterSimultaneous(BuilderCardData newItem) {
    _updateDataAtPath(_selectedPath!, (target) {
      if (_selectedCounterPath != null) {
        final idx = _selectedCounterPath![0];
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
    _mode = _BuilderMode.none;
    _selectedCounterPath = null;
  }

  void _addItemCounterChain(BuilderCardData newItem) {
    _updateDataAtPath(_selectedPath!, (target) {
      if (_selectedCounterPath != null) {
        final idx = _selectedCounterPath![0];
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
    _mode = _BuilderMode.none;
    _selectedCounterPath = null;
  }

  void _addItemDefense(BuilderCardData newItem) {
    _updateDataAtPath(
      _selectedPath!,
      (target) => target.copyWith(
        counterName: newItem.name,
        counterCategory: newItem.category,
        counterGlossaryId: newItem.glossaryId,
        counterSubMoves: const [],
        counterChain: const [],
      ),
    );
    _mode = _BuilderMode.none;
  }

  void _addItemToChain(BuilderCardData newItem) {
    if (_selectedPath!.length > 1) {
      for (int depth = _selectedPath!.length - 1; depth >= 1; depth--) {
        final parentPath = _selectedPath!.sublist(0, depth);
        final childIndex = _selectedPath![depth];
        bool inserted = false;
        _updateDataAtPath(parentPath, (parent) {
          if (parent.isChain) {
            final newChain = List<BuilderCardData>.from(parent.chain);
            newChain.insert(childIndex + 1, newItem);
            inserted = true;
            return parent.copyWith(chain: newChain);
          }
          return parent;
        });
        if (inserted) {
          _selectedPath = [...parentPath, childIndex + 1];
          break;
        }
      }
    } else {
      final topIndex = _selectedPath![0];
      final selected = _getDataAtPath(_selectedPath!);
      if (selected != null && selected.isChain) {
        _updateDataAtPath(_selectedPath!, (target) {
          return target.copyWith(chain: [...target.chain, newItem]);
        });
        _selectedPath = [topIndex, selected.chain.length];
      } else {
        _workspaceCards[topIndex] = BuilderCardData(
          name: 'Chain',
          category: 'chain',
          chain: [_workspaceCards[topIndex], newItem],
        );
        _selectedPath = [topIndex, 1];
      }
    }
    _mode = _BuilderMode.none;
  }

  void _addItemSimultaneous(BuilderCardData newItem) {
    bool appended = false;
    if (_selectedPath!.length > 1) {
      final parentPath = _selectedPath!.sublist(0, _selectedPath!.length - 1);
      _updateDataAtPath(parentPath, (parent) {
        if (parent.isCombo) {
          appended = true;
          return parent.copyWith(subMoves: [...parent.subMoves, newItem]);
        }
        return parent;
      });
    }
    if (!appended) {
      _updateDataAtPath(_selectedPath!, (target) {
        if (target.isCombo) {
          return target.copyWith(subMoves: [...target.subMoves, newItem]);
        }
        return BuilderCardData(
          name: 'Combo',
          category: 'simultaneous',
          subMoves: [target, newItem],
        );
      });
      final target = _getDataAtPath(_selectedPath!);
      if (target != null && target.isCombo) {
        _selectedPath = [..._selectedPath!, target.subMoves.length - 1];
      }
    }
    _mode = _BuilderMode.none;
  }

  void _addItemDefault(BuilderCardData newItem) {
    if (_selectedPath != null && _selectedPath!.length == 1) {
      final insertIndex = _selectedPath![0] + 1;
      _workspaceCards.insert(insertIndex, newItem);
      _selectedPath = [insertIndex];
    } else {
      _workspaceCards.add(newItem);
      if (_workspaceCards.length == 1) {
        _selectedPath = [0];
      } else {
        _selectedPath = [_workspaceCards.length - 1];
      }
    }
    _mode = _BuilderMode.none;
  }

  Widget _buildCustomAnglesTab(ScrollController scrollController) {
    return Consumer<SeriesProvider>(
      builder: (context, provider, child) {
        final customAngles = provider.customAngles;
        final lang = provider.language;

        if (customAngles.isEmpty) {
          return Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    lang == 'fr'
                        ? 'Aucun angle personnalisé créé.\nTapez sur + pour en créer un.'
                        : 'No custom angles created.\nTap + to design one.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'add_custom_angle_empty_fab',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => KaliAngleDesigner(),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: customAngles.length,
              itemBuilder: (context, index) {
                final custom = customAngles[index];
                return InkWell(
                  onTap: () {
                    final newItem = BuilderCardData(
                      name: custom.name,
                      category: 'kali',
                      kaliAngle: custom.id,
                    );
                    _onAddItem(newItem);
                    Navigator.pop(context);
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Custom Angle?'),
                        content: Text('Delete "${custom.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              provider.deleteCustomAngle(custom.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: double.infinity),
                            KaliAngleIcon(
                              angle: custom.id,
                              size: 60,
                              showCircle: true,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Text(
                                custom.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (context) =>
                                    KaliAngleDesigner(existingAngle: custom),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'add_custom_angle_fab',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => KaliAngleDesigner(),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextTab() {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _customTextController,
            decoration: InputDecoration(
              labelText: LocalizationService.translate('custom_text', lang),
              border: const OutlineInputBorder(),
              hintText: LocalizationService.translate('custom_text_hint', lang),
            ),
            autofocus: true,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                final newItem = BuilderCardData(
                  name: val.trim(),
                  category: 'text',
                );
                _onAddItem(newItem);
                _customTextController.clear();
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              final val = _customTextController.text.trim();
              if (val.isNotEmpty) {
                final newItem = BuilderCardData(name: val, category: 'text');
                _onAddItem(newItem);
                _customTextController.clear();
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(LocalizationService.translate('add_custom_text', lang)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalGlossarySearchResults(ScrollController scrollController) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final query = _glossarySearchQuery.toLowerCase();
    final lang = provider.language;

    final baseResults = provider.glossary.where((item) {
      final name = item['name'].toString().toLowerCase();
      final trans = GlossaryDataService.parseTranslations(item['translations']);
      final t = (trans[lang] ?? trans['en'] ?? '').toLowerCase();
      return name.contains(query) || t.contains(query);
    }).toList();

    final results = _filterGlossaryForTraining(baseResults);

    if (results.isEmpty) {
      return const EmptyStateIllustration(titleKey: 'nothing');
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final category = item['category'] ?? 'other';
        return _buildCompactGlossaryTile(item, category, lang);
      },
    );
  }
}
