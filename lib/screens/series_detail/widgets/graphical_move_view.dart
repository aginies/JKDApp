import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import '../../../services/localization_service.dart';
import '../controllers/training_controller.dart';
import 'move_display_widgets.dart';
import 'separated_wrap.dart';

/// Read-only graphical card view for moves — mirrors the visual style
/// of the AdvancedComboBuilder cards but without any editing capabilities.
class GraphicalMoveView {
  /// Helper to find translation in glossary if move translations are empty
  static String _getEffectiveTranslation(
    Move move,
    String language,
    List<Map<String, dynamic>> glossary,
  ) {
    final t = move.getTranslation(language);
    if (t.isNotEmpty) return t;

    final entry = glossary.firstWhere(
      (e) => e['name'].toString().toLowerCase() == move.name.toLowerCase(),
      orElse: () => {},
    );

    if (entry.isNotEmpty && entry['translations'] != null) {
      try {
        final Map<String, dynamic> trans = json.decode(entry['translations']);
        return trans[language] ?? trans['en'] ?? trans['fr'] ?? '';
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  /// Helper to find counter translation in glossary
  static String _getEffectiveCounterTranslation(
    Move move,
    String language,
    List<Map<String, dynamic>> glossary,
  ) {
    if (move.counterName == null) return '';

    // First try by counterGlossaryId
    if (move.counterGlossaryId != null) {
      final entry = glossary.firstWhere(
        (e) => e['id'] == move.counterGlossaryId,
        orElse: () => {},
      );
      if (entry.isNotEmpty && entry['translations'] != null) {
        try {
          final Map<String, dynamic> trans = json.decode(entry['translations']);
          return trans[language] ?? trans['en'] ?? trans['fr'] ?? '';
        } catch (_) {}
      }
    }

    // Fallback to glossary search by counterName
    final entry = glossary.firstWhere(
      (e) =>
          e['name'].toString().toLowerCase() == move.counterName!.toLowerCase(),
      orElse: () => {},
    );

    if (entry.isNotEmpty && entry['translations'] != null) {
      try {
        final Map<String, dynamic> trans = json.decode(entry['translations']);
        return trans[language] ?? trans['en'] ?? trans['fr'] ?? '';
      } catch (_) {}
    }
    return '';
  }

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
    bool showTranslation = true,
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
                showTranslation: showTranslation,
              ),
            );
          },
        ),
    ];
  }

  /// Given a top-level move and the current [subIndex] from TTS,
  /// compute which sub-move (by index into subMoves/chain) is active.
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
      final hasCounter =
          subs[j].counterName != null || subs[j].hasStructuredCounter;
      final linesForThis = hasCounter ? 2 : 1;
      if (subIndex >= lineCount && subIndex < lineCount + linesForThis) {
        return j;
      }
      lineCount += linesForThis;
    }
    return -1;
  }

  /// Whether the answer part of a sub-move is currently being spoken.
  static bool _isAnswerActive(Move subMove, int subIndex, int linesBefore) {
    if (subMove.counterName == null && !subMove.hasStructuredCounter) {
      return false;
    }
    // attack line is at linesBefore, answer line is at linesBefore + 1
    return subIndex == linesBefore + 1;
  }

  /// Count TTS lines before sub-move at [targetIndex].
  static int _linesBeforeSubMove(List<Move> subs, int targetIndex) {
    int count = 0;
    for (int j = 0; j < targetIndex; j++) {
      final hasCounter =
          subs[j].counterName != null || subs[j].hasStructuredCounter;
      count += hasCounter ? 2 : 1;
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
    bool showTranslation = true,
  }) {
    final theme = Theme.of(context);
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final themeColor = provider.themeColor;
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
                      showTranslation: showTranslation,
                    ),
                    if (e.key < move.chain.length - 1)
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
            if (move.counterName != null || move.hasStructuredCounter) ...[
              const SizedBox(height: 4),
              _buildCounterBox(move, lang, showTranslation: showTranslation),
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
                  return _buildMoveCard(
                    sm,
                    lang,
                    context,
                    onShowMediaGallery,
                    showTranslation: showTranslation,
                  );
                }).toList(),
              ),
            ),
            if (move.counterName != null || move.hasStructuredCounter) ...[
              const SizedBox(height: 4),
              _buildCounterBox(move, lang, showTranslation: showTranslation),
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
              children: move.subMoves.asMap().entries.expand((e) {
                final subActive = isCurrentMove && activeSubIdx == e.key;
                final linesBefore = _linesBeforeSubMove(move.subMoves, e.key);
                final answerActive =
                    subActive &&
                    _isAnswerActive(
                      e.value,
                      trainingController.subIndex,
                      linesBefore,
                    );
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
                  _buildMoveCard(
                    e.value,
                    lang,
                    context,
                    onShowMediaGallery,
                    isActiveSubItem: subActive,
                    isActiveAnswer: answerActive,
                    showTranslation: showTranslation,
                  ),
                ];
              }).toList(),
            ),
            if (move.counterName != null || move.hasStructuredCounter) ...[
              const SizedBox(height: 4),
              _buildCounterBox(move, lang, showTranslation: showTranslation),
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
              DiagonalCross(
                show: move.isFeint,
                color: Colors.purple,
                child: Container(
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
                      Builder(
                        builder: (context) {
                          if (!showTranslation) return const SizedBox.shrink();
                          final provider = context.read<SeriesProvider>();
                          final trans = _getEffectiveTranslation(
                            move,
                            lang,
                            provider.glossary,
                          );
                          if (trans.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              trans,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
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
                      if (move.side.isNotEmpty || move.level.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: [
                            if (move.side.isNotEmpty)
                              MoveDisplayWidgets.sideCircle(
                                LocalizationService.translate(
                                  move.side == 'L'
                                      ? 'left'
                                      : (move.side == 'R' ? 'right' : 'mid'),
                                  lang,
                                ).substring(0, 1),
                                move.side,
                                mini: true,
                              ),
                            if (move.level.isNotEmpty)
                              MoveDisplayWidgets.levelIcon(
                                move.level,
                                mini: true,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (move.counterName != null || move.hasStructuredCounter) ...[
                const SizedBox(height: 4),
                _buildCounterBox(
                  move,
                  lang,
                  isActive: isActiveAnswer,
                  showTranslation: showTranslation,
                ),
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
            top: -10,
            left: -10,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCurrentMove ? Colors.amber[700] : themeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$cardNumber',
                style: TextStyle(
                  color: isCurrentMove
                      ? Colors.white
                      : (ThemeData.estimateBrightnessForColor(themeColor) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black),
                  fontSize: 13,
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
  static Widget _buildSubItemsWrap({required List<Widget> children}) {
    if (children.isEmpty) return const SizedBox.shrink();

    return SeparatedWrap(spacing: 4, children: children);
  }

  /// Read-only counter (answer) box — supports simple, simultaneous, and chain counters.
  static Widget _buildCounterBox(
    Move move,
    String lang, {
    bool isActive = false,
    bool showTranslation = true,
  }) {
    final borderColor = isActive
        ? Colors.amber.withValues(alpha: 0.8)
        : Colors.red.withValues(alpha: 0.3);
    final bgColor = isActive
        ? Colors.amber.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.1);
    final labelColor = isActive ? Colors.amber[800]! : Colors.red;

    // Build inner content based on counter structure
    Widget counterContent;

    if (move.hasCounterCombo) {
      // SIMULTANEOUS counter (A+B answer)
      counterContent = Column(
        children: [
          Text(
            LocalizationService.translate('answer', lang).toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'SIMULTANEOUS',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: move.counterSubMoves.asMap().entries.expand((e) {
                final idx = e.key;
                final sm = e.value;
                return [
                  if (idx > 0)
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
                  _buildMiniMoveCard(
                    sm,
                    lang,
                    showTranslation: showTranslation,
                  ),
                ];
              }).toList(),
            ),
          ),
        ],
      );
    } else if (move.hasCounterChain) {
      // CHAIN counter (A->+ answer)
      counterContent = Column(
        children: [
          Text(
            LocalizationService.translate('answer', lang).toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: move.counterChain.asMap().entries.expand((e) {
              final idx = e.key;
              final sm = e.value;
              return [
                if (idx > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 28,
                      color: Colors.teal,
                    ),
                  ),
                _buildMiniMoveCard(sm, lang, showTranslation: showTranslation),
              ];
            }).toList(),
          ),
        ],
      );
    } else {
      // Simple single counter (existing behavior)
      counterContent = Column(
        children: [
          Text(
            LocalizationService.translate('answer', lang).toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            move.counterName!,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Builder(
            builder: (context) {
              if (!showTranslation) return const SizedBox.shrink();
              final provider = context.read<SeriesProvider>();
              final ct = _getEffectiveCounterTranslation(
                move,
                lang,
                provider.glossary,
              );
              if (ct.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  ct,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
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
                  MoveDisplayWidgets.levelIcon(move.counterLevel!, mini: true),
              ],
            ),
          ],
        ],
      );
    }

    return DiagonalCross(
      show: move.counterIsFeint,
      color: Colors.purple,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        ),
        child: counterContent,
      ),
    );
  }

  /// Small card for rendering a single move (or nested group) inside a structured counter box.
  static Widget _buildMiniMoveCard(
    Move move,
    String lang, {
    bool showTranslation = true,
  }) {
    if (move.isChain || move.isCombo) {
      // RECURSIVE rendering for nested groups inside an answer
      final color = MoveDisplayWidgets.getCategoryColor(move.category);
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              move.isChain ? 'CHAIN' : 'SIMUL.',
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
              children: (move.isChain ? move.chain : move.subMoves)
                  .asMap()
                  .entries
                  .map((e) {
                    final idx = e.key;
                    final item = e.value;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniMoveCard(
                          item,
                          lang,
                          showTranslation: showTranslation,
                        ),
                        if (move.isChain && idx < move.chain.length - 1)
                          const Icon(
                            Icons.arrow_forward,
                            size: 10,
                            color: Colors.grey,
                          ),
                        if (move.isCombo && idx < move.subMoves.length - 1)
                          const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      );
    }

    final color = MoveDisplayWidgets.getCategoryColor(move.category);
    return DiagonalCross(
      show: move.isFeint,
      color: Colors.purple,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              MoveDisplayWidgets.getCategoryIcon(move.category),
              size: 14,
              color: color,
            ),
            Text(
              move.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Builder(
              builder: (context) {
                if (!showTranslation) return const SizedBox.shrink();
                final provider = context.read<SeriesProvider>();
                final trans = _getEffectiveTranslation(
                  move,
                  lang,
                  provider.glossary,
                );
                if (trans.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Text(
                    trans,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            if (move.side.isNotEmpty || move.level.isNotEmpty)
              Wrap(
                spacing: 2,
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
                    MoveDisplayWidgets.levelIcon(move.level, mini: true),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DiagonalCross extends StatelessWidget {
  final Widget child;
  final bool show;
  final Color color;

  const DiagonalCross({
    super.key,
    required this.child,
    required this.show,
    this.color = Colors.purple,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: DiagonalCrossPainter(color: color)),
          ),
        ),
      ],
    );
  }
}

class DiagonalCrossPainter extends CustomPainter {
  final Color color;

  DiagonalCrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw X
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
