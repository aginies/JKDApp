import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import 'package:provider/provider.dart';
import '../../../services/localization_service.dart';
import '../controllers/training_controller.dart';
import 'move_display_widgets.dart';
import 'diagonal_cross.dart';
import 'kali_angle_icon.dart';

/// Displays the list of moves in a series with edit controls
class MoveListDisplayWidget {
  /// Helper to find translation in glossary if move translations are empty
  static String _getEffectiveTranslation(
    Move move,
    String language,
    List<Map<String, dynamic>> glossary,
  ) {
    final t = move.getTranslation(language);
    if (t.isNotEmpty) {
      // If it's a join of sub-translations (combo/chain), return it
      if (move.isCombo || move.isChain) return t;
      // If it's a leaf item and translation != name, return it
      if (t.toLowerCase() != move.name.toLowerCase()) return t;
    }

    // Fallback to glossary search by name
    final entry = glossary.firstWhere(
      (e) =>
          e['name'].toString().trim().toLowerCase() ==
          move.name.trim().toLowerCase(),
      orElse: () => {},
    );

    if (entry.isNotEmpty && entry['translations'] != null) {
      try {
        final dynamic tData = entry['translations'];
        final Map<String, dynamic> trans = (tData is String)
            ? json.decode(tData)
            : tData;
        final res = trans[language] ?? trans['en'] ?? trans['fr'] ?? '';
        if (res.toLowerCase() != move.name.toLowerCase()) return res;
      } catch (_) {}
    }
    return '';
  }

  /// Helper to find counter translation in glossary
  static String _getEffectiveCounterTranslation(
    Move move,
    String language,
    List<Map<String, dynamic>> glossary,
  ) {
    if (move.counterName == null || move.counterName!.isEmpty) return '';

    // First try to find by counterGlossaryId
    if (move.counterGlossaryId != null) {
      final entry = glossary.firstWhere(
        (e) => e['id'] == move.counterGlossaryId,
        orElse: () => {},
      );
      if (entry.isNotEmpty && entry['translations'] != null) {
        try {
          final dynamic tData = entry['translations'];
          final Map<String, dynamic> trans = (tData is String)
              ? json.decode(tData)
              : tData;
          return trans[language] ?? trans['en'] ?? trans['fr'] ?? '';
        } catch (_) {}
      }
    }

    // Fallback to glossary search by counterName
    final entry = glossary.firstWhere(
      (e) =>
          e['name'].toString().trim().toLowerCase() ==
          move.counterName!.trim().toLowerCase(),
      orElse: () => {},
    );

    if (entry.isNotEmpty && entry['translations'] != null) {
      try {
        final dynamic tData = entry['translations'];
        final Map<String, dynamic> trans = (tData is String)
            ? json.decode(tData)
            : tData;
        return trans[language] ?? trans['en'] ?? trans['fr'] ?? '';
      } catch (_) {}
    }
    return '';
  }

  /// Wraps an attacker move in a green box
  static Widget _attackerBox(Widget child, {bool mini = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mini ? 4 : 6,
        vertical: mini ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  /// Wraps a counter response in a red box
  static Widget _counterBox(Widget child, {bool mini = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mini ? 4 : 6,
        vertical: mini ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1),
      ),
      child: child,
    );
  }

  /// Builds content for structured counters (simultaneous or chain answers).
  static Widget _buildStructuredCounterContent(
    Move move,
    String language,
    List<Map<String, dynamic>> glossary,
    Function(String category, String moveName) onShowMediaGallery,
    VoidCallback? onEdit, {
    bool showTranslation = false,
  }) {
    if (move.hasCounterCombo) {
      // SIMULTANEOUS counter
      return Wrap(
        spacing: 6,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(
            Icons.subdirectory_arrow_right,
            size: 28,
            color: Colors.orange,
          ),
          ...move.counterSubMoves.asMap().entries.expand((e) {
            final idx = e.key;
            final cm = e.value;
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
              _buildMoveContent(
                cm,
                language,
                glossary,
                onShowMediaGallery,
                iconSize: 18,
                fontSize: 13,
                onEdit: onEdit,
                showTranslation: showTranslation,
              ),
            ];
          }),
        ],
      );
    } else if (move.hasCounterChain) {
      // CHAIN counter
      return Wrap(
        spacing: 6,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(
            Icons.subdirectory_arrow_right,
            size: 28,
            color: Colors.orange,
          ),
          ...move.counterChain.asMap().entries.expand((e) {
            final idx = e.key;
            final cm = e.value;
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
              _buildMoveContent(
                cm,
                language,
                glossary,
                onShowMediaGallery,
                iconSize: 18,
                fontSize: 13,
                onEdit: onEdit,
                showTranslation: showTranslation,
              ),
            ];
          }),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// Builds the content row for a move (icon, name, side, level, etc.)
  static Widget _buildMoveContent(
    Move sub,
    String language,
    List<Map<String, dynamic>> glossary,
    Function(String category, String moveName) onShowMediaGallery, {
    double iconSize = 24,
    double fontSize = 14,
    VoidCallback? onEdit,
    bool showTranslation = false,
  }) {
    if (sub.isChain || sub.isCombo) {
      // RECURSIVE rendering for nested groups
      return Wrap(
        spacing: 4,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...(sub.isChain ? sub.chain : sub.subMoves).asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMoveContent(
                  item,
                  language,
                  glossary,
                  onShowMediaGallery,
                  iconSize: iconSize * 0.85,
                  fontSize: fontSize * 0.95,
                  onEdit: onEdit,
                  showTranslation: showTranslation,
                ),
                if (sub.isChain && idx < sub.chain.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 24,
                      color: Colors.grey,
                    ),
                  ),
                if (sub.isCombo && idx < sub.subMoves.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      );
    }

    // LEAF ITEM rendering
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onDoubleTap:
              onEdit ?? () => onShowMediaGallery(sub.category, sub.name),
          child: _attackerBox(
            DiagonalCross(
              show: sub.isFeint,
              color: Colors.purple,
              child: Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if ((sub.category == 'kali' || sub.category == 'angles') && sub.kaliAngle != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: KaliAngleIcon(
                        angle: sub.kaliAngle!,
                        size: iconSize * 1.8, // Increased from 1.5
                        color: MoveDisplayWidgets.getCategoryColor('kali'),
                      ),
                    )
                  else
                    Icon(
                      MoveDisplayWidgets.getCategoryIcon(sub.displayCategory),
                      size: iconSize,
                      color: MoveDisplayWidgets.getCategoryColor(
                        sub.displayCategory,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    sub.name,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (sub.side.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: MoveDisplayWidgets.sideCircle(
                        LocalizationService.translate(
                          sub.side == 'L'
                              ? 'left'
                              : (sub.side == 'R'
                                    ? 'right'
                                    : (sub.side == 'F'
                                          ? 'front'
                                          : (sub.side == 'B'
                                                ? 'back'
                                                : 'mid'))),
                          language,
                        ).substring(0, 1),
                        sub.side,
                        mini: true,
                      ),
                    ),
                  if (sub.level.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: MoveDisplayWidgets.levelIcon(
                        sub.level,
                        mini: true,
                      ),
                    ),
                ],
              ),
            ),
            mini: iconSize < 28,
          ),
        ),
        if (showTranslation)
          Builder(
            builder: (context) {
              final String effectiveName = _getEffectiveTranslation(
                sub,
                language,
                glossary,
              );
              if (effectiveName.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2.0, left: 4.0),
                child: Text(
                  effectiveName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// Builds the move list tiles
  static List<Widget> buildTiles({
    required List<Move> moves,
    required String language,
    required bool isEditing,
    required TrainingController trainingController,
    required BuildContext context,
    required String category,
    required VoidCallback Function(int index) onEdit,
    required VoidCallback Function(int index) onClone,
    required VoidCallback Function(int index) onDelete,
    required Function(String category, String moveName) onShowMediaGallery,
    required Function(List<Move> movesToInsert, int atIndex) onSetState,
    bool showTranslation = false,
    int? singleItemIndex,
  }) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final glossary = provider.glossary;

    // Calculate display numbers excluding 'move' category items
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
        displayNumbers.add(0); // 0 means no number for move items
      }
    }

    final bool hideNumbers = category == 'Moves';

    return [
      for (int i = 0; i < moves.length; i++)
        Padding(
          key: ValueKey(moves[i].uKey),
          padding: EdgeInsets.only(
            left: (moves[i].category == 'move' || hideNumbers)
                ? 0.0
                : (moves[i].subLetter != null ? 45.0 : 15.0),
            bottom: 8.0,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  final t = _getEffectiveTranslation(
                    moves[i],
                    language,
                    glossary,
                  );
                  if (t.isNotEmpty) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${moves[i].name}: $t'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                onDoubleTap: isEditing
                    ? onEdit(i)
                    : () =>
                          onShowMediaGallery(moves[i].category, moves[i].name),
                child: Card(
                  margin: EdgeInsets.zero,
                  color:
                      trainingController.isTraining &&
                          trainingController.currentIndex ==
                              (singleItemIndex ?? i)
                      ? Colors.grey.withValues(alpha: 0.2)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      minLeadingWidth: 0,
                      horizontalTitleGap: 12,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 4,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (moves[i].repetitions > 1)
                                Chip(
                                  label: Text(
                                    'x${moves[i].repetitions}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors.blueGrey,
                                ),
                              if (moves[i].category == 'simultaneous')
                                _buildMoveContent(
                                  moves[i],
                                  language,
                                  glossary,
                                  onShowMediaGallery,
                                  iconSize: 28,
                                  fontSize: 14,
                                  onEdit: isEditing ? onEdit(i) : null,
                                  showTranslation: showTranslation,
                                )
                              else if (moves[i].category == 'chain' ||
                                  moves[i].isChain)
                                _buildMoveContent(
                                  moves[i],
                                  language,
                                  glossary,
                                  onShowMediaGallery,
                                  iconSize: 28,
                                  fontSize: 14,
                                  onEdit: isEditing ? onEdit(i) : null,
                                  showTranslation: showTranslation,
                                )
                              else if (moves[i].category == 'combo')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: moves[i].subMoves.asMap().entries.map((
                                    entry,
                                  ) {
                                    final subIdx = entry.key;
                                    final sub = entry.value;
                                    final bool isSingle =
                                        moves[i].subMoves.length == 1;

                                    // Calculate display number for submoves (skip 'move' category)
                                    int subDisplayNumber = 0;
                                    for (int j = 0; j <= subIdx; j++) {
                                      if (moves[i].subMoves[j].category !=
                                          'move') {
                                        subDisplayNumber++;
                                      }
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (isSingle)
                                                const Icon(
                                                  Icons.keyboard_arrow_right,
                                                  size: 18,
                                                  color: Colors.grey,
                                                )
                                              else if (sub.category != 'move')
                                                Text(
                                                  '$subDisplayNumber.',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Flexible(
                                                child: _buildMoveContent(
                                                  sub,
                                                  language,
                                                  glossary,
                                                  onShowMediaGallery,
                                                  onEdit: isEditing
                                                      ? onEdit(i)
                                                      : null,
                                                  showTranslation:
                                                      showTranslation,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (sub.counterName != null ||
                                              sub.hasStructuredCounter)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                                left: 12.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  InkWell(
                                                    onDoubleTap: () {
                                                      if (sub.counterName !=
                                                          null) {
                                                        onShowMediaGallery(
                                                          sub.counterCategory ??
                                                              '',
                                                          sub.counterName!,
                                                        );
                                                      }
                                                    },
                                                    child: _counterBox(
                                                      sub.hasStructuredCounter
                                                          ? _buildStructuredCounterContent(
                                                              sub,
                                                              language,
                                                              glossary,
                                                              onShowMediaGallery,
                                                              isEditing
                                                                  ? onEdit(i)
                                                                  : null,
                                                              showTranslation:
                                                                  showTranslation,
                                                            )
                                                          : DiagonalCross(
                                                              show: sub
                                                                  .counterIsFeint,
                                                              color:
                                                                  Colors.purple,
                                                              child: Wrap(
                                                                spacing: 6,
                                                                crossAxisAlignment:
                                                                    WrapCrossAlignment
                                                                        .center,
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .subdirectory_arrow_right,
                                                                    size: 28,
                                                                    color: Colors
                                                                        .orange,
                                                                  ),
                                                                  if ((sub.counterCategory == 'kali' || sub.counterCategory == 'angles') && sub.kaliAngle != null)
                                                                    KaliAngleIcon(
                                                                      angle: sub.kaliAngle!,
                                                                      size: 44, // Increased from 36
                                                                      color: MoveDisplayWidgets.getCategoryColor('kali'),
                                                                    )
                                                                  else
                                                                    Icon(
                                                                      MoveDisplayWidgets.getCategoryIcon(
                                                                        sub.counterCategory ??
                                                                            '',
                                                                      ),
                                                                      size: 22,
                                                                      color: MoveDisplayWidgets.getCategoryColor(
                                                                        sub.counterCategory ??
                                                                            '',
                                                                      ),
                                                                    ),
                                                                  Text(
                                                                    sub.counterName!,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Theme.of(
                                                                        context,
                                                                      ).colorScheme.secondary,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  if (sub
                                                                          .counterSide
                                                                          ?.isNotEmpty ??
                                                                      false)
                                                                    MoveDisplayWidgets.sideCircle(
                                                                      LocalizationService.translate(
                                                                        sub.counterSide ==
                                                                                'L'
                                                                            ? 'left'
                                                                            : (sub.counterSide ==
                                                                                      'R'
                                                                                  ? 'right'
                                                                                  : (sub.counterSide ==
                                                                                            'F'
                                                                                        ? 'front'
                                                                                        : (sub.counterSide ==
                                                                                                  'B'
                                                                                              ? 'back'
                                                                                              : 'mid'))),
                                                                        language,
                                                                      ).substring(
                                                                        0,
                                                                        1,
                                                                      ),
                                                                      sub.counterSide ??
                                                                          '',
                                                                      mini:
                                                                          true,
                                                                    ),
                                                                  if (sub
                                                                          .counterLevel
                                                                          ?.isNotEmpty ??
                                                                      false)
                                                                    MoveDisplayWidgets.levelIcon(
                                                                      sub.counterLevel ??
                                                                          '',
                                                                      mini:
                                                                          true,
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                      mini: true,
                                                    ),
                                                  ),
                                                  if (showTranslation &&
                                                      !sub.hasStructuredCounter)
                                                    Builder(
                                                      builder: (context) {
                                                        final ct =
                                                            _getEffectiveCounterTranslation(
                                                              sub,
                                                              language,
                                                              glossary,
                                                            );
                                                        if (ct.isEmpty) {
                                                          return const SizedBox.shrink();
                                                        }
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 2.0,
                                                                left: 28.0,
                                                              ),
                                                          child: Text(
                                                            ct,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .grey,
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                )
                              else ...[
                                _buildMoveContent(
                                  moves[i],
                                  language,
                                  glossary,
                                  onShowMediaGallery,
                                  iconSize: 28,
                                  fontSize: 14,
                                  onEdit: isEditing ? onEdit(i) : null,
                                  showTranslation: showTranslation,
                                ),
                              ],
                            ],
                          ),
                          if (moves[i].category != 'combo' &&
                              (moves[i].counterName != null ||
                                  moves[i].hasStructuredCounter))
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                left: 0.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onDoubleTap: () {
                                      if (moves[i].counterName != null) {
                                        onShowMediaGallery(
                                          moves[i].counterCategory ?? '',
                                          moves[i].counterName!,
                                        );
                                      }
                                    },
                                    child: _counterBox(
                                      moves[i].hasStructuredCounter
                                          ? _buildStructuredCounterContent(
                                              moves[i],
                                              language,
                                              glossary,
                                              onShowMediaGallery,
                                              isEditing ? onEdit(i) : null,
                                              showTranslation: showTranslation,
                                            )
                                          : Wrap(
                                              spacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .subdirectory_arrow_right,
                                                  size: 28,
                                                  color: Colors.orange,
                                                ),
                                                if ((moves[i].counterCategory == 'kali' || moves[i].counterCategory == 'angles') && moves[i].kaliAngle != null)
                                                  KaliAngleIcon(
                                                    angle: moves[i].kaliAngle!,
                                                    size: 52, // Increased from 44
                                                    color: MoveDisplayWidgets.getCategoryColor('kali'),
                                                  )
                                                else
                                                  Icon(
                                                    MoveDisplayWidgets.getCategoryIcon(
                                                      moves[i].counterCategory ??
                                                          '',
                                                    ),
                                                    size: 28,
                                                    color: MoveDisplayWidgets.getCategoryColor(
                                                      moves[i].counterCategory ??
                                                          '',
                                                    ),
                                                  ),
                                                const SizedBox(width: 4),
                                                DiagonalCross(
                                                  show: moves[i].counterIsFeint,
                                                  color: Colors.purple,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        moves[i].counterName!,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),

                                                      if (moves[i]
                                                              .counterSide
                                                              ?.isNotEmpty ??
                                                          false)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 4.0,
                                                              ),
                                                          child: MoveDisplayWidgets.sideCircle(
                                                            LocalizationService.translate(
                                                              moves[i].counterSide ==
                                                                      'L'
                                                                  ? 'left'
                                                                  : (moves[i].counterSide ==
                                                                            'R'
                                                                        ? 'right'
                                                                        : (moves[i].counterSide ==
                                                                                  'F'
                                                                              ? 'front'
                                                                              : (moves[i].counterSide ==
                                                                                        'B'
                                                                                    ? 'back'
                                                                                    : 'mid'))),
                                                              language,
                                                            ).substring(0, 1),
                                                            moves[i].counterSide ??
                                                                '',
                                                            mini: true,
                                                          ),
                                                        ),
                                                      if (moves[i]
                                                              .counterLevel
                                                              ?.isNotEmpty ??
                                                          false)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 4.0,
                                                              ),
                                                          child: MoveDisplayWidgets.levelIcon(
                                                            moves[i].counterLevel ??
                                                                '',
                                                            mini: true,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (moves[i]
                                                        .counterSpecialAction !=
                                                    null)
                                                  Chip(
                                                    label: Text(
                                                      moves[i]
                                                          .counterSpecialAction!,
                                                      style: const TextStyle(
                                                        fontSize: 8,
                                                      ),
                                                    ),
                                                    backgroundColor: Colors
                                                        .purple
                                                        .withValues(alpha: 0.2),
                                                    padding: EdgeInsets.zero,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  if (showTranslation &&
                                      !moves[i].hasStructuredCounter)
                                    Builder(
                                      builder: (context) {
                                        final ct =
                                            _getEffectiveCounterTranslation(
                                              moves[i],
                                              language,
                                              glossary,
                                            );
                                        if (ct.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2.0,
                                            left: 32.0,
                                          ),
                                          child: Text(
                                            ct,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: isEditing
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.blueGrey,
                                    size: 28,
                                  ),
                                  onPressed: onClone(i),
                                  tooltip: LocalizationService.translate(
                                    'clone',
                                    language,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  onPressed: onDelete(i),
                                ),
                                const SizedBox(width: 16),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(
                                    Icons.drag_handle,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (displayNumbers[i] > 0 && !hideNumbers)
                Positioned(
                  left: -15,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: provider.themeColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (moves[i].subLetter == null)
                            Text(
                              '${displayNumbers[i]}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    ThemeData.estimateBrightnessForColor(
                                          provider.themeColor,
                                        ) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                height: 1.0,
                              ),
                            )
                          else
                            Text(
                              '${displayNumbers[i]}${moves[i].subLetter}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color:
                                    ThemeData.estimateBrightnessForColor(
                                          provider.themeColor,
                                        ) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                height: 1.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ];
  }
}
