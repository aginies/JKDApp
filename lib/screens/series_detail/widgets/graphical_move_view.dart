import 'package:flutter/material.dart';
import '../../../models/move.dart';
import '../../../services/localization_service.dart';
import '../controllers/training_controller.dart';
import 'move_display_widgets.dart';

/// Read-only graphical card view for moves — mirrors the visual style
/// of the AdvancedComboBuilder cards but without any editing capabilities.
class GraphicalMoveView {
  /// Builds a list of graphical card widgets from moves.
  /// Each top-level move is wrapped in a numbered card.
  /// When [trainingController] is provided, the currently-spoken move
  /// (and sub-move) is highlighted.
  static List<Widget> buildCards({
    required List<Move> moves,
    required String language,
    required BuildContext context,
    required Function(String category, String moveName) onShowMediaGallery,
    TrainingController? trainingController,
    int? singleItemIndex,
  }) {
    // Compute display numbers (skip 'move' category items)
    int displayNumber = 0;
    return [
      for (int i = 0; i < moves.length; i++)
        Builder(
          builder: (context) {
            if (moves[i].category != 'move') displayNumber++;
            final num = moves[i].category != 'move' ? displayNumber : 0;
            final effectiveIndex = singleItemIndex ?? i;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: _buildMoveCard(
                moves[i],
                language,
                context,
                onShowMediaGallery,
                cardNumber: num > 0 ? num : null,
                trainingController: trainingController,
                moveIndex: effectiveIndex,
              ),
            );
          },
        ),
    ];
  }

  /// Given a top-level move and the current [subIndex] from TTS,
  /// compute which sub-move (by index into subMoves/chain) is active.
  ///
  /// Each sub-move without a counter produces 1 TtsLine.
  /// Each sub-move with a counter produces 2 TtsLines (attack + answer).
  /// Returns -1 if no sub-move is active.
  static int _activeSubMoveIndex(Move move, int subIndex) {
    final List<Move> subs;
    if (move.isChain) {
      subs = move.chain;
    } else if (move.isCombo) {
      subs = move.subMoves;
    } else {
      return -1; // leaf / simultaneous — no sub-indexing
    }

    int lineCount = 0;
    for (int j = 0; j < subs.length; j++) {
      final linesForThis = subs[j].counterName != null ? 2 : 1;
      if (subIndex >= lineCount && subIndex < lineCount + linesForThis) {
        return j;
      }
      lineCount += linesForThis;
    }
    return -1;
  }

  /// Whether the answer part of a sub-move is currently being spoken.
  /// True when subIndex points to the second TtsLine of a sub-move with counter.
  static bool _isAnswerActive(Move subMove, int subIndex, int linesBefore) {
    if (subMove.counterName == null) return false;
    // attack line is at linesBefore, answer line is at linesBefore + 1
    return subIndex == linesBefore + 1;
  }

  /// Count TTS lines before sub-move at [targetIndex].
  static int _linesBeforeSubMove(List<Move> subs, int targetIndex) {
    int count = 0;
    for (int j = 0; j < targetIndex; j++) {
      count += subs[j].counterName != null ? 2 : 1;
    }
    return count;
  }

  /// Recursive card builder for a single Move.
  static Widget _buildMoveCard(
    Move move,
    String lang,
    BuildContext context,
    Function(String, String) onShowMediaGallery, {
    int? cardNumber,
    TrainingController? trainingController,
    int? moveIndex,
    bool isActiveSubItem = false,
    bool isActiveAnswer = false,
  }) {
    final theme = Theme.of(context);
    final color = MoveDisplayWidgets.getCategoryColor(move.category);

    // Determine if this top-level card is the one currently being spoken
    final bool isTopLevel = cardNumber != null;
    final bool isCurrentMove =
        isTopLevel &&
        trainingController != null &&
        trainingController.isTraining &&
        moveIndex != null &&
        trainingController.currentIndex == moveIndex;

    // For combo/chain: compute which sub-move index is active
    final int activeSubIdx = isCurrentMove
        ? _activeSubMoveIndex(move, trainingController.subIndex)
        : -1;

    Widget card;

    if (move.isChain) {
      // CHAIN card
      card = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CHAIN',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            _buildSubItemsWrap(
              children: move.chain.asMap().entries.map((e) {
                final subActive = isCurrentMove && activeSubIdx == e.key;
                final linesBefore = _linesBeforeSubMove(move.chain, e.key);
                final answerActive =
                    subActive &&
                    _isAnswerActive(
                      e.value,
                      trainingController.subIndex,
                      linesBefore,
                    );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMoveCard(
                      e.value,
                      lang,
                      context,
                      onShowMediaGallery,
                      isActiveSubItem: subActive,
                      isActiveAnswer: answerActive,
                    ),
                    if (e.key < move.chain.length - 1)
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
            if (move.counterName != null) ...[
              const SizedBox(height: 4),
              _buildCounterBox(move, lang),
            ],
          ],
        ),
      );
    } else if (move.category == 'simultaneous') {
      // SIMULTANEOUS card
      card = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SIMULTANEOUS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: move.subMoves.map((sm) {
                  return _buildMoveCard(sm, lang, context, onShowMediaGallery);
                }).toList(),
              ),
            ),
            if (move.counterName != null) ...[
              const SizedBox(height: 4),
              _buildCounterBox(move, lang),
            ],
          ],
        ),
      );
    } else if (move.category == 'combo') {
      // COMBO card — sub-items displayed left to right with row separators
      card = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubItemsWrap(
              children: move.subMoves.asMap().entries.map((e) {
                final subActive = isCurrentMove && activeSubIdx == e.key;
                final linesBefore = _linesBeforeSubMove(move.subMoves, e.key);
                final answerActive =
                    subActive &&
                    _isAnswerActive(
                      e.value,
                      trainingController.subIndex,
                      linesBefore,
                    );
                return _buildMoveCard(
                  e.value,
                  lang,
                  context,
                  onShowMediaGallery,
                  isActiveSubItem: subActive,
                  isActiveAnswer: answerActive,
                );
              }).toList(),
            ),
            if (move.counterName != null) ...[
              const SizedBox(height: 4),
              _buildCounterBox(move, lang),
            ],
          ],
        ),
      );
    } else {
      // LEAF ITEM — single move card
      card = GestureDetector(
        onDoubleTap: () => onShowMediaGallery(move.category, move.name),
        child: Container(
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 75),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: isActiveSubItem
                ? Border.all(
                    color: Colors.amber.withValues(alpha: 0.8),
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Attacker box
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActiveSubItem && !isActiveAnswer
                      ? Colors.amber.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      MoveDisplayWidgets.getCategoryIcon(move.category),
                      size: 20,
                      color: color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      move.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (move.specialAction != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Chip(
                          label: Text(
                            move.specialAction!,
                            style: const TextStyle(fontSize: 8),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (move.side.isNotEmpty ||
                        move.level.isNotEmpty ||
                        move.isFeint) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (move.side.isNotEmpty)
                            MoveDisplayWidgets.sideCircle(
                              LocalizationService.translate(
                                move.side == 'L' ? 'left' : 'right',
                                lang,
                              ).substring(0, 1),
                              move.side,
                              mini: true,
                            ),
                          if (move.level.isNotEmpty)
                            MoveDisplayWidgets.levelIcon(
                              move.level,
                              size: 12,
                              mini: true,
                            ),
                          if (move.isFeint)
                            MoveDisplayWidgets.drawBox(mini: true),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (move.counterName != null) ...[
                const SizedBox(height: 4),
                _buildCounterBox(move, lang, isActive: isActiveAnswer),
              ],
            ],
          ),
        ),
      );
    }

    // Wrap with highlight + number badge for top-level cards
    if (cardNumber != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Highlight border for currently-spoken top-level card
          if (isCurrentMove)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.7),
                    width: 2.5,
                  ),
                ),
              ),
            ),
          card,
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCurrentMove ? Colors.amber[700] : Colors.grey[700],
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

  /// A Wrap-like layout that inserts subtle divider lines between visual rows.
  /// Uses [LayoutBuilder] to measure available width and partition [children]
  /// into rows, inserting a thin [Divider] between them.
  static Widget _buildSubItemsWrap({required List<Widget> children}) {
    if (children.isEmpty) return const SizedBox.shrink();

    return _SeparatedWrap(spacing: 4, children: children);
  }

  /// Read-only counter (answer) box.
  static Widget _buildCounterBox(
    Move move,
    String lang, {
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.amber.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? Colors.amber.withValues(alpha: 0.8)
              : Colors.red.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            LocalizationService.translate('answer', lang).toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.amber[800] : Colors.red,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            move.counterName!,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if ((move.counterSide ?? '').isNotEmpty ||
              (move.counterLevel ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 2,
              children: [
                if ((move.counterSide ?? '').isNotEmpty)
                  MoveDisplayWidgets.sideCircle(
                    LocalizationService.translate(
                      move.counterSide == 'L' ? 'left' : 'right',
                      lang,
                    ).substring(0, 1),
                    move.counterSide!,
                    mini: true,
                  ),
                if ((move.counterLevel ?? '').isNotEmpty)
                  MoveDisplayWidgets.levelIcon(
                    move.counterLevel!,
                    size: 10,
                    mini: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A widget that lays out children in a Wrap and draws subtle horizontal
/// separator lines between visual rows when children overflow to a new line.
class _SeparatedWrap extends StatelessWidget {
  final double spacing;
  final List<Widget> children;

  const _SeparatedWrap({required this.spacing, required this.children});

  @override
  Widget build(BuildContext context) {
    // Wrap with a custom paint layer that draws row separators.
    // We use a Wrap inside a _SeparatedWrapRenderWrapper that inspects
    // child positions after layout.
    return _SeparatedWrapLayout(spacing: spacing, children: children);
  }
}

/// Uses a Wrap and post-layout inspection to draw divider lines between rows.
class _SeparatedWrapLayout extends StatefulWidget {
  final double spacing;
  final List<Widget> children;

  const _SeparatedWrapLayout({required this.spacing, required this.children});

  @override
  State<_SeparatedWrapLayout> createState() => _SeparatedWrapLayoutState();
}

class _SeparatedWrapLayoutState extends State<_SeparatedWrapLayout> {
  final GlobalKey _wrapKey = GlobalKey();
  List<double> _rowBottoms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeRows());
  }

  @override
  void didUpdateWidget(covariant _SeparatedWrapLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _computeRows());
  }

  void _computeRows() {
    final renderBox = _wrapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    // Walk through Wrap's children via their parent data to find row breaks.
    // We inspect each child's offset.dy to detect row boundaries.
    final wrapRender = renderBox;
    final List<double> bottoms = [];
    double currentRowTop = -1;
    double currentRowBottom = 0;

    void visitChild(RenderObject child) {
      if (child is RenderBox && child.hasSize) {
        final offset = child.localToGlobal(Offset.zero, ancestor: wrapRender);
        final top = offset.dy;
        final bottom = top + child.size.height;

        if (currentRowTop < 0) {
          // First child
          currentRowTop = top;
          currentRowBottom = bottom;
        } else if (top > currentRowBottom - 1) {
          // New row detected — save the midpoint between rows as divider pos
          bottoms.add((currentRowBottom + top) / 2);
          currentRowTop = top;
          currentRowBottom = bottom;
        } else {
          // Same row
          if (bottom > currentRowBottom) currentRowBottom = bottom;
        }
      }
    }

    wrapRender.visitChildren(visitChild);

    if (!mounted) return;
    if (_rowBottoms.length != bottoms.length ||
        !_listEquals(_rowBottoms, bottoms)) {
      setState(() {
        _rowBottoms = bottoms;
      });
    }
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.5) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _RowSeparatorPainter(
        rowBottoms: _rowBottoms,
        color: Colors.grey.withValues(alpha: 0.25),
      ),
      child: Wrap(
        key: _wrapKey,
        spacing: widget.spacing,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: widget.children,
      ),
    );
  }
}

/// Draws thin horizontal lines at the given Y positions (midpoints between rows).
class _RowSeparatorPainter extends CustomPainter {
  final List<double> rowBottoms;
  final Color color;

  _RowSeparatorPainter({required this.rowBottoms, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (rowBottoms.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (final y in rowBottoms) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RowSeparatorPainter oldDelegate) {
    return oldDelegate.rowBottoms != rowBottoms || oldDelegate.color != color;
  }
}
