import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/move.dart';
import '../../../services/localization_service.dart';
import '../../../services/series_provider.dart';
import '../widgets/move_display_widgets.dart';
import '../glossary/glossary_data_service.dart';

class AdvancedComboBuilder extends StatefulWidget {
  final Function(Move) onFinish;
  final VoidCallback onCancel;
  final Move? initialMove;

  const AdvancedComboBuilder({
    super.key,
    required this.onFinish,
    required this.onCancel,
    this.initialMove,
  });

  @override
  State<AdvancedComboBuilder> createState() => _AdvancedComboBuilderState();
}

class _AdvancedComboBuilderState extends State<AdvancedComboBuilder> {
  // Current state of the workspace
  final List<BuilderCardData> _workspaceCards = [];
  final _customTextController = TextEditingController();

  // Path-based selection for recursive structures
  List<int>? _selectedPath;
  bool _isCounterSelected = false;
  int?
  _selectedCounterIndex; // Which sub-item inside a structured counter is selected (null = whole counter)

  // Modes
  bool _isDefenseMode = false;
  bool _isSimultaneousMode = false;
  bool _isChainMode = false;
  bool _isCounterSimultaneousMode = false;
  bool _isCounterChainMode = false;

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
      glossaryId: m.glossaryId,
      counterName: m.counterName,
      counterCategory: m.counterCategory,
      counterSide: m.counterSide ?? '',
      counterLevel: m.counterLevel ?? '',
      subMoves: m.subMoves.map((sm) => _convertFromMove(sm)).toList(),
      chain: m.chain.map((cm) => _convertFromMove(cm)).toList(),
      counterSubMoves: m.counterSubMoves
          .map((cm) => _convertFromMove(cm))
          .toList(),
      counterChain: m.counterChain.map((cm) => _convertFromMove(cm)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SeriesProvider>(context).language;
    final theme = Theme.of(context);

    return Container(
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
                        children: _workspaceCards.asMap().entries.map((entry) {
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

          const SizedBox(height: 8),

          // BOTTOM TOOLBAR: Property buttons (stuck to bottom)
          _buildBottomToolbar(lang),
        ],
      ),
    );
  }

  void _clearAllModes() {
    _isSimultaneousMode = false;
    _isChainMode = false;
    _isDefenseMode = false;
    _isCounterSimultaneousMode = false;
    _isCounterChainMode = false;
  }

  Widget _buildTopToolbar(String lang) {
    return Row(
      children: [
        // LEFT group: action buttons
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                _toolbarButton('', Icons.add, Colors.blue, _onAddClick),
                _toolbarButton('', Icons.remove, Colors.red, _onRemoveClick),
                const SizedBox(width: 8, child: VerticalDivider()),
                _toolbarButton(
                  '',
                  null,
                  (_isSimultaneousMode || _isCounterSimultaneousMode)
                      ? Colors.green
                      : Colors.blueAccent,
                  () {
                    if (_selectedPath != null) {
                      setState(() {
                        _clearAllModes();
                        if (_isCounterSelected) {
                          _isCounterSimultaneousMode = true;
                        } else {
                          _isSimultaneousMode = true;
                        }
                      });
                      _showGlossaryPicker();
                    }
                  },
                  isActive: _isSimultaneousMode || _isCounterSimultaneousMode,
                  customChild: Builder(
                    builder: (context) {
                      final active =
                          _isSimultaneousMode || _isCounterSimultaneousMode;
                      final fg = active ? Colors.white : Colors.blueAccent;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: fg,
                            ),
                          ),
                          Text(
                            'B',
                            style: TextStyle(
                              fontSize: 13,
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
                  (_isChainMode || _isCounterChainMode)
                      ? Colors.green
                      : Colors.teal,
                  () {
                    if (_selectedPath != null) {
                      setState(() {
                        _clearAllModes();
                        if (_isCounterSelected) {
                          _isCounterChainMode = true;
                        } else {
                          _isChainMode = true;
                        }
                      });
                      _showGlossaryPicker();
                    }
                  },
                  isActive: _isChainMode || _isCounterChainMode,
                  customChild: Builder(
                    builder: (context) {
                      final active = _isChainMode || _isCounterChainMode;
                      final fg = active ? Colors.white : Colors.teal;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'A',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: fg,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: fg,
                            ),
                          ),
                          Icon(Icons.add, size: 14, color: fg),
                        ],
                      );
                    },
                  ),
                ),
                _toolbarButton(
                  '',
                  Icons.subdirectory_arrow_right,
                  _isDefenseMode ? Colors.green : Colors.orange,
                  () {
                    if (_selectedPath != null) {
                      setState(() {
                        _clearAllModes();
                        _isDefenseMode = true;
                      });
                      _showGlossaryPicker();
                    }
                  },
                  isActive: _isDefenseMode,
                ),
              ],
            ),
          ),
        ),
        // RIGHT group: Finish & Cancel
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolbarButton('', Icons.check, Colors.green, _onFinishClick),
            _toolbarButton(
              '',
              Icons.close,
              Colors.red,
              widget.onCancel,
              isActive: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(String lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          minimumSize: const Size(0, 36),
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
                if (icon != null) Icon(icon, size: 20, color: fgColor),
                if (icon != null && label.isNotEmpty) const SizedBox(width: 4),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
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
      card = GestureDetector(
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
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                            size: 16,
                            color: Colors.teal,
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
              if (data.hasCounter) ...[
                const SizedBox(height: 4),
                _buildCounterBox(path, data, lang, isSelected),
              ],
            ],
          ),
        ),
      );
    } else if (data.isCombo) {
      card = GestureDetector(
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
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: data.subMoves.asMap().entries.map((e) {
                    final itemPath = [...path, e.key];
                    return _buildCard(itemPath, e.value, lang);
                  }).toList(),
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
                      if (data.side.isNotEmpty ||
                          data.level.isNotEmpty ||
                          data.isFeint) ...[
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
                            if (data.isFeint)
                              MoveDisplayWidgets.drawBox(mini: true),
                          ],
                        ),
                      ],
                    ],
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
    int index,
    String lang,
    bool isTopSelected,
  ) {
    final theme = Theme.of(context);
    final color = MoveDisplayWidgets.getCategoryColor(sm.category);
    final bool isSubSelected =
        isTopSelected && _isCounterSelected && _selectedCounterIndex == index;

    return GestureDetector(
      onTap: () => _selectPath(path, isCounter: true, counterIndex: index),
      child: Container(
        padding: const EdgeInsets.all(4),
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
            if (sm.side.isNotEmpty || sm.level.isNotEmpty || sm.isFeint)
              Wrap(
                spacing: 2,
                children: [
                  if (sm.side.isNotEmpty)
                    MoveDisplayWidgets.sideCircle(
                      LocalizationService.translate(
                        sm.side == 'L' ? 'left' : 'right',
                        lang,
                      ).substring(0, 1),
                      sm.side,
                      mini: true,
                    ),
                  if (sm.level.isNotEmpty)
                    MoveDisplayWidgets.levelIcon(sm.level, mini: true),
                  if (sm.isFeint) MoveDisplayWidgets.drawBox(mini: true),
                ],
              ),
          ],
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
    // Whole-counter selected (no specific sub-item)
    final bool isWholeCounterSelected =
        isThisCounterSelected && _selectedCounterIndex == null;

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
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: data.counterSubMoves.asMap().entries.map((e) {
                return _buildCounterSubCard(
                  path,
                  e.value,
                  e.key,
                  lang,
                  isTopSelected,
                );
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
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: data.counterChain.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCounterSubCard(
                    path,
                    e.value,
                    e.key,
                    lang,
                    isTopSelected,
                  ),
                  if (e.key < data.counterChain.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.0),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 12,
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

  void _selectPath(
    List<int> path, {
    bool isCounter = false,
    int? counterIndex,
  }) {
    setState(() {
      _selectedPath = List<int>.from(path);
      _isCounterSelected = isCounter;
      _selectedCounterIndex = isCounter ? counterIndex : null;
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
      _clearAllModes();
    });
    _showGlossaryPicker();
  }

  void _onRemoveClick() {
    if (_selectedPath == null) return;

    setState(() {
      if (_isCounterSelected && _selectedCounterIndex != null) {
        // DELETE A SPECIFIC SUB-ITEM inside a structured counter
        final idx = _selectedCounterIndex!;
        _updateDataAtPath(_selectedPath!, (item) {
          if (item.hasCounterCombo) {
            final newList = List<BuilderCardData>.from(item.counterSubMoves);
            if (idx >= newList.length) return item;
            newList.removeAt(idx);
            if (newList.isEmpty) {
              // No items left — clear counter entirely
              return item.copyWith(
                counterName: null,
                counterCategory: null,
                counterGlossaryId: null,
                counterSide: '',
                counterLevel: '',
                counterSubMoves: const [],
              );
            }
            if (newList.length == 1) {
              // Unwrap: single item becomes a simple counter
              final remaining = newList.first;
              return item.copyWith(
                counterName: remaining.name,
                counterCategory: remaining.category,
                counterGlossaryId: remaining.glossaryId,
                counterSide: remaining.side,
                counterLevel: remaining.level,
                counterSubMoves: const [],
              );
            }
            return item.copyWith(
              counterSubMoves: newList,
              counterName: newList.map((m) => m.name).join(' + '),
            );
          } else if (item.hasCounterChain) {
            final newList = List<BuilderCardData>.from(item.counterChain);
            if (idx >= newList.length) return item;
            newList.removeAt(idx);
            if (newList.isEmpty) {
              // No items left — clear counter entirely
              return item.copyWith(
                counterName: null,
                counterCategory: null,
                counterGlossaryId: null,
                counterSide: '',
                counterLevel: '',
                counterChain: const [],
              );
            }
            if (newList.length == 1) {
              // Unwrap: single item becomes a simple counter
              final remaining = newList.first;
              return item.copyWith(
                counterName: remaining.name,
                counterCategory: remaining.category,
                counterGlossaryId: remaining.glossaryId,
                counterSide: remaining.side,
                counterLevel: remaining.level,
                counterChain: const [],
              );
            }
            return item.copyWith(
              counterChain: newList,
              counterName: newList.map((m) => m.name).join(' -> '),
            );
          }
          return item;
        });
        _selectedCounterIndex = null;
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
        _selectedCounterIndex = null;
      } else if (_selectedPath!.length > 1) {
        // DELETE ONLY THE TARGETED SUB-ITEM
        final parentPath = _selectedPath!.sublist(0, _selectedPath!.length - 1);
        final indexToRemove = _selectedPath!.last;

        _updateDataAtPath(parentPath, (parent) {
          final isChain = parent.isChain;
          final List<BuilderCardData> subList = List.from(
            isChain ? parent.chain : parent.subMoves,
          );
          subList.removeAt(indexToRemove);

          // Remove parent if it's completely empty
          if (subList.isEmpty) return null;

          // Unwrap if only 1 item remains (no longer a group)
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

          return isChain
              ? parent.copyWith(chain: subList)
              : parent.copyWith(subMoves: subList);
        });

        _selectedPath = null;
        _selectedCounterIndex = null;
      } else {
        // DELETE ENTIRE TOP-LEVEL CARD
        _workspaceCards.removeAt(_selectedPath![0]);
        _selectedPath = null;
        _selectedCounterIndex = null;
      }
    });
  }

  void _onFinishClick() {
    if (_workspaceCards.isEmpty) return;

    Move finalMove;
    if (_workspaceCards.length == 1) {
      // Single card: return it directly as the series item
      finalMove = _convertToMove(_workspaceCards.first);
    } else {
      // Multiple cards: bundle into ONE series item with category 'combo'.
      // Each workspace card becomes a numbered sub-item (1. Jab  2. Cross  3. Jik Tek)
      // displayed one per line in the series view.
      final subMoves = _workspaceCards.map((c) => _convertToMove(c)).toList();
      finalMove = Move(
        name: 'Combo: ${subMoves.first.name} + ...',
        category: 'combo',
        subMoves: subMoves,
      );
    }

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
        counterSubMoves: data.counterSubMoves
            .map((m) => _convertToMove(m))
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
        counterSubMoves: data.counterSubMoves
            .map((m) => _convertToMove(m))
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
      glossaryId: data.glossaryId,
      counterName: data.counterName,
      counterCategory: data.counterCategory,
      counterSide: data.counterSide,
      counterLevel: data.counterLevel,
      counterSubMoves: data.counterSubMoves
          .map((m) => _convertToMove(m))
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

  void _updateSelectedCard({
    String? side,
    String? level,
    bool toggleFeint = false,
    String? specialAction,
  }) {
    if (_selectedPath == null) return;

    setState(() {
      _updateDataAtPath(_selectedPath!, (item) {
        if (_isCounterSelected && _selectedCounterIndex != null) {
          // Update a specific sub-item inside a structured counter
          final idx = _selectedCounterIndex!;
          if (item.hasCounterCombo && idx < item.counterSubMoves.length) {
            final subItem = item.counterSubMoves[idx];
            String finalSide = subItem.side;
            if (side != null) {
              finalSide = (subItem.side == side) ? '' : side;
            }
            String finalLevel = subItem.level;
            if (level != null) {
              finalLevel = (subItem.level == level) ? '' : level;
            }
            final newList = List<BuilderCardData>.from(item.counterSubMoves);
            newList[idx] = subItem.copyWith(
              side: finalSide,
              level: finalLevel,
              isFeint: toggleFeint ? !subItem.isFeint : subItem.isFeint,
            );
            return item.copyWith(counterSubMoves: newList);
          } else if (item.hasCounterChain && idx < item.counterChain.length) {
            final subItem = item.counterChain[idx];
            String finalSide = subItem.side;
            if (side != null) {
              finalSide = (subItem.side == side) ? '' : side;
            }
            String finalLevel = subItem.level;
            if (level != null) {
              finalLevel = (subItem.level == level) ? '' : level;
            }
            final newList = List<BuilderCardData>.from(item.counterChain);
            newList[idx] = subItem.copyWith(
              side: finalSide,
              level: finalLevel,
              isFeint: toggleFeint ? !subItem.isFeint : subItem.isFeint,
            );
            return item.copyWith(counterChain: newList);
          }
          return item;
        } else if (_isCounterSelected) {
          // Toggle logic for counterSide
          String finalSide = item.counterSide;
          if (side != null) {
            finalSide = (item.counterSide == side) ? '' : side;
          }

          // Toggle logic for counterLevel
          String finalLevel = item.counterLevel;
          if (level != null) {
            finalLevel = (item.counterLevel == level) ? '' : level;
          }

          return item.copyWith(
            counterSide: finalSide,
            counterLevel: finalLevel,
          );
        } else {
          // Toggle logic for side
          String finalSide = item.side;
          if (side != null) {
            finalSide = (item.side == side) ? '' : side;
          }

          // Toggle logic for level
          String finalLevel = item.level;
          if (level != null) {
            finalLevel = (item.level == level) ? '' : level;
          }

          return item.copyWith(
            side: finalSide,
            level: finalLevel,
            isFeint: toggleFeint ? !item.isFeint : item.isFeint,
            specialAction: specialAction ?? item.specialAction,
          );
        }
      });
    });
  }

  void _showGlossaryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _isDefenseMode ? 'Select Answer' : 'Select Item to Add',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 7,
                initialIndex: _isDefenseMode ? 2 : 0,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: [
                        const Tab(text: 'Punches'),
                        const Tab(text: 'Kicks'),
                        const Tab(text: 'Packs'),
                        const Tab(text: 'Trapping'),
                        const Tab(text: 'JKD Moves'),
                        const Tab(text: 'Move'),
                        Tab(
                          icon: Icon(
                            MoveDisplayWidgets.getCategoryIcon('text'),
                            size: 16,
                          ),
                          text: 'Text',
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildGlossaryTab('punch', scrollController),
                          _buildGlossaryTab('kick', scrollController),
                          _buildGlossaryTab('packs', scrollController),
                          _buildGlossaryTab('trapping', scrollController),
                          _buildGlossaryTab('jkd_moves', scrollController),
                          _buildGlossaryTab('move', scrollController),
                          _buildTextTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddItem(BuilderCardData newItem) {
    setState(() {
      if (_isCounterSimultaneousMode && _selectedPath != null) {
        // A+B for ANSWER
        _updateDataAtPath(_selectedPath!, (target) {
          if (_selectedCounterIndex != null) {
            // A+B on a specific counter sub-item
            final idx = _selectedCounterIndex!;
            if (target.hasCounterCombo && idx < target.counterSubMoves.length) {
              // Append new item to the simultaneous group
              final newList = List<BuilderCardData>.from(
                target.counterSubMoves,
              );
              newList.insert(idx + 1, newItem);
              return target.copyWith(
                counterSubMoves: newList,
                counterName: newList.map((m) => m.name).join(' + '),
              );
            } else if (target.hasCounterChain &&
                idx < target.counterChain.length) {
              // Replace the selected chain item with a simultaneous group
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
            // Already a simultaneous counter — append
            return target.copyWith(
              counterSubMoves: [...target.counterSubMoves, newItem],
              counterName:
                  '${target.counterSubMoves.map((m) => m.name).join(' + ')} + ${newItem.name}',
            );
          }
          if (target.hasCounterChain) {
            // Has a chain — wrap it as the first simultaneous item,
            // then add the new item as second simultaneous item.
            // (A -> B) + C
            final chainGroup = BuilderCardData(
              name: target.counterChain.map((m) => m.name).join(' -> '),
              category: 'chain',
              chain: List.from(target.counterChain),
            );
            return target.copyWith(
              counterSubMoves: [chainGroup, newItem],
              counterChain: const [], // clear — now inside simultaneous
              counterName: '(${chainGroup.name}) + ${newItem.name}',
            );
          }
          // Create simultaneous group from existing single counter + new item
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
        _isCounterSimultaneousMode = false;
        _selectedCounterIndex = null;
      } else if (_isCounterChainMode && _selectedPath != null) {
        // A->+ for ANSWER
        _updateDataAtPath(_selectedPath!, (target) {
          if (_selectedCounterIndex != null) {
            // A->+ on a specific counter sub-item
            final idx = _selectedCounterIndex!;
            if (target.hasCounterChain && idx < target.counterChain.length) {
              // Insert after the selected chain item
              final newList = List<BuilderCardData>.from(target.counterChain);
              newList.insert(idx + 1, newItem);
              return target.copyWith(
                counterChain: newList,
                counterName: newList.map((m) => m.name).join(' -> '),
              );
            } else if (target.hasCounterCombo &&
                idx < target.counterSubMoves.length) {
              // Replace the selected simultaneous item with a chain
              final subItem = target.counterSubMoves[idx];
              final chainItem = BuilderCardData(
                name: '${subItem.name} -> ${newItem.name}',
                category: 'chain',
                chain: [subItem, newItem],
              );
              final newList = List<BuilderCardData>.from(
                target.counterSubMoves,
              );
              newList[idx] = chainItem;
              return target.copyWith(counterSubMoves: newList);
            }
            return target;
          }
          if (target.hasCounterChain) {
            // Already a counter chain — append
            return target.copyWith(
              counterChain: [...target.counterChain, newItem],
              counterName:
                  '${target.counterChain.map((m) => m.name).join(' -> ')} -> ${newItem.name}',
            );
          }
          if (target.hasCounterCombo) {
            // Has a simultaneous group — wrap it as the first chain item,
            // then append the new item as second chain step.
            // (Insinda + Jab) -> Hook
            final simultaneousGroup = BuilderCardData(
              name: target.counterSubMoves.map((m) => m.name).join(' + '),
              category: 'simultaneous',
              subMoves: List.from(target.counterSubMoves),
            );
            return target.copyWith(
              counterChain: [simultaneousGroup, newItem],
              counterSubMoves: const [], // clear — now inside chain
              counterName: '(${simultaneousGroup.name}) -> ${newItem.name}',
            );
          }
          // Create chain from existing single counter + new item
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
        _isCounterChainMode = false;
        _selectedCounterIndex = null;
      } else if (_isDefenseMode && _selectedPath != null) {
        // Nested Answer (inside chain or combo)
        _updateDataAtPath(
          _selectedPath!,
          (target) => target.copyWith(
            counterName: newItem.name,
            counterCategory: newItem.category,
            counterGlossaryId: newItem.glossaryId,
            // Clear any structured counter when setting a simple one
            counterSubMoves: const [],
            counterChain: const [],
          ),
        );
        _isDefenseMode = false;
      } else if (_isChainMode && _selectedPath != null) {
        // CHAIN / INSERT AFTER — context-aware:
        if (_selectedPath!.length > 1) {
          // Nested item — find the nearest chain ancestor and
          // insert after the child index within that chain.
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
              // Select the newly inserted item
              _selectedPath = [...parentPath, childIndex + 1];
              break;
            }
          }
        } else {
          // Top-level card
          final topIndex = _selectedPath![0];
          final selected = _getDataAtPath(_selectedPath!);

          if (selected != null && selected.isChain) {
            // Already a chain — append new item at end
            _updateDataAtPath(_selectedPath!, (target) {
              return target.copyWith(chain: [...target.chain, newItem]);
            });
            // Select the newly appended item
            _selectedPath = [topIndex, selected.chain.length];
          } else {
            // Standalone card — wrap selected + new into a chain
            _workspaceCards[topIndex] = BuilderCardData(
              name: 'Chain',
              category: 'chain',
              chain: [_workspaceCards[topIndex], newItem],
            );
            // Select the new item inside the chain
            _selectedPath = [topIndex, 1];
          }
        }
        _isChainMode = false;
      } else if (_isSimultaneousMode && _selectedPath != null) {
        // SMART APPEND into existing combo or create new one
        bool appended = false;
        if (_selectedPath!.length > 1) {
          final parentPath = _selectedPath!.sublist(
            0,
            _selectedPath!.length - 1,
          );
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
        }
        _isSimultaneousMode = false;
      } else {
        // Insert after selected top-level card, or append at end
        if (_selectedPath != null && _selectedPath!.length == 1) {
          final insertIndex = _selectedPath![0] + 1;
          _workspaceCards.insert(insertIndex, newItem);
        } else {
          _workspaceCards.add(newItem);
        }
      }
    });
  }

  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _customTextController,
            decoration: const InputDecoration(
              labelText: 'Custom Text',
              border: OutlineInputBorder(),
              hintText: 'Enter custom instruction or move name',
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
            label: const Text('Add Custom Text'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryTab(String category, ScrollController scrollController) {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: GlossaryDataService.fetchGlossaryByCategory(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        return ListView.builder(
          controller: scrollController,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final translations = GlossaryDataService.parseTranslations(
              item['translations'],
            );
            final translation = GlossaryDataService.getTranslation(
              translations,
              lang,
            );

            return ListTile(
              leading: Icon(
                MoveDisplayWidgets.getCategoryIcon(category),
                color: MoveDisplayWidgets.getCategoryColor(category),
              ),
              title: Text(
                item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: translation.isNotEmpty
                  ? Text(
                      translation,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    )
                  : null,
              onTap: () {
                final newItem = BuilderCardData(
                  name: item['name'],
                  category: category,
                  glossaryId: item['id'],
                );
                _onAddItem(newItem);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}

class BuilderCardData {
  final String name;
  final String category;
  final int? glossaryId;
  final String side;
  final String level;
  final bool isFeint;
  final String? specialAction;
  final List<BuilderCardData> subMoves; // For simultaneous moves (+)
  final List<BuilderCardData> chain; // For sequential moves (->)

  // Counter (Answer) fields
  final String? counterName;
  final String? counterCategory;
  final int? counterGlossaryId;
  final String counterSide;
  final String counterLevel;

  // Structured counter: simultaneous answer moves (A+B for answer)
  final List<BuilderCardData> counterSubMoves;
  // Structured counter: sequential answer chain (A->+ for answer)
  final List<BuilderCardData> counterChain;

  BuilderCardData({
    required this.name,
    required this.category,
    this.glossaryId,
    this.side = '',
    this.level = '',
    this.isFeint = false,
    this.specialAction,
    this.subMoves = const [],
    this.chain = const [],
    this.counterName,
    this.counterCategory,
    this.counterGlossaryId,
    this.counterSide = '',
    this.counterLevel = '',
    this.counterSubMoves = const [],
    this.counterChain = const [],
  });

  bool get isCombo => subMoves.isNotEmpty;
  bool get isChain => chain.isNotEmpty;
  bool get hasCounter =>
      counterName != null ||
      counterSubMoves.isNotEmpty ||
      counterChain.isNotEmpty;
  bool get hasCounterCombo => counterSubMoves.isNotEmpty;
  bool get hasCounterChain => counterChain.isNotEmpty;
  bool get hasStructuredCounter => hasCounterCombo || hasCounterChain;

  BuilderCardData copyWith({
    String? name,
    String? category,
    int? glossaryId,
    String? side,
    String? level,
    bool? isFeint,
    String? specialAction,
    List<BuilderCardData>? subMoves,
    List<BuilderCardData>? chain,
    Object? counterName = _sentinel,
    Object? counterCategory = _sentinel,
    Object? counterGlossaryId = _sentinel,
    String? counterSide,
    String? counterLevel,
    List<BuilderCardData>? counterSubMoves,
    List<BuilderCardData>? counterChain,
  }) {
    return BuilderCardData(
      name: name ?? this.name,
      category: category ?? this.category,
      glossaryId: glossaryId ?? this.glossaryId,
      side: side ?? this.side,
      level: level ?? this.level,
      isFeint: isFeint ?? this.isFeint,
      specialAction: specialAction ?? this.specialAction,
      subMoves: subMoves ?? this.subMoves,
      chain: chain ?? this.chain,
      counterName: counterName == _sentinel
          ? this.counterName
          : (counterName as String?),
      counterCategory: counterCategory == _sentinel
          ? this.counterCategory
          : (counterCategory as String?),
      counterGlossaryId: counterGlossaryId == _sentinel
          ? this.counterGlossaryId
          : (counterGlossaryId as int?),
      counterSide: counterSide ?? this.counterSide,
      counterLevel: counterLevel ?? this.counterLevel,
      counterSubMoves: counterSubMoves ?? this.counterSubMoves,
      counterChain: counterChain ?? this.counterChain,
    );
  }

  static const _sentinel = Object();
}
