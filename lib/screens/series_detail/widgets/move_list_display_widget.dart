import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import 'package:provider/provider.dart';
import '../../../services/localization_service.dart';
import '../controllers/training_controller.dart';
import 'move_display_widgets.dart';

/// Displays the list of moves in a series with edit controls
class MoveListDisplayWidget {
  /// Helper to find translation in glossary if move translations are empty
  static String _getEffectiveTranslation(
    Move move,
    String language,
    List<Map<String, dynamic>> glossary,
  ) {
    final t = move.getTranslation(language);
    if (t.isNotEmpty) return t;

    // Fallback to glossary search if move translations are empty
    if (move.isCombo) {
      return move.subMoves
          .map((m) => _getEffectiveTranslation(m, language, glossary))
          .where((s) => s.isNotEmpty)
          .join(' + ');
    }

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
        } else if (currentMainNumber == 0) {
          // If the very first item has a sub-letter, we start at 1
          currentMainNumber = 1;
        }
        displayNumbers.add(currentMainNumber);
      } else {
        displayNumbers.add(0); // 0 means no number for move items
      }
    }

    final bool hideNumbers = category == 'JKD Moves';

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
                  color: trainingController.currentIndex == i
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
                              if (!moves[i].isCombo) ...[
                                Icon(
                                  MoveDisplayWidgets.getCategoryIcon(
                                    moves[i].category,
                                  ),
                                  size: 32,
                                  color: MoveDisplayWidgets.getCategoryColor(
                                    moves[i].category,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: _getEffectiveTranslation(
                                    moves[i],
                                    language,
                                    glossary,
                                  ),
                                  child: Text(
                                    moves[i].name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                MoveDisplayWidgets.sideCircle(
                                  LocalizationService.translate(
                                    moves[i].side == 'L' ? 'left' : 'right',
                                    language,
                                  ).substring(0, 1),
                                  moves[i].side,
                                ),
                                MoveDisplayWidgets.levelIcon(
                                  moves[i].level,
                                  size: 14,
                                ),
                                if (moves[i].isFeint)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: MoveDisplayWidgets.drawBox(),
                                  ),
                                if (moves[i].specialAction != null)
                                  Chip(
                                    label: Text(
                                      moves[i].specialAction!,
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                    backgroundColor: Colors.purple.withValues(
                                      alpha: 0.3,
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ],
                          ),
                          if (showTranslation && !moves[i].isCombo)
                            Builder(
                              builder: (context) {
                                final t = _getEffectiveTranslation(
                                  moves[i],
                                  language,
                                  glossary,
                                );
                                if (t.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    top: 2.0,
                                    left: 36.0,
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (moves[i].isCombo)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 0.0,
                                top: 4.0,
                              ),
                              child: Column(
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
                                  final bool isMove = sub.category == 'move';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onDoubleTap: () => onShowMediaGallery(
                                            sub.category,
                                            sub.name,
                                          ),
                                          child: Wrap(
                                            spacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              if (isSingle)
                                                const Icon(
                                                  Icons.keyboard_arrow_right,
                                                  size: 18,
                                                  color: Colors.grey,
                                                )
                                              else if (!isMove)
                                                Text(
                                                  '$subDisplayNumber.',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Icon(
                                                MoveDisplayWidgets.getCategoryIcon(
                                                  sub.category,
                                                ),
                                                size: 24,
                                                color:
                                                    MoveDisplayWidgets.getCategoryColor(
                                                      sub.category,
                                                    ),
                                              ),
                                              Text(
                                                sub.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              MoveDisplayWidgets.sideCircle(
                                                LocalizationService.translate(
                                                  sub.side == 'L'
                                                      ? 'left'
                                                      : 'right',
                                                  language,
                                                ).substring(0, 1),
                                                sub.side,
                                                mini: false,
                                              ),
                                              MoveDisplayWidgets.levelIcon(
                                                sub.level,
                                                size: 12,
                                              ),
                                              if (sub.isFeint)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 4.0,
                                                      ),
                                                  child:
                                                      MoveDisplayWidgets.drawBox(
                                                        mini: true,
                                                      ),
                                                ),
                                              if (sub.specialAction != null)
                                                Chip(
                                                  label: Text(
                                                    sub.specialAction!,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.purple
                                                      .withValues(alpha: 0.2),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (showTranslation)
                                          Builder(
                                            builder: (context) {
                                              final t =
                                                  _getEffectiveTranslation(
                                                    sub,
                                                    language,
                                                    glossary,
                                                  );
                                              if (t.isEmpty) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                  left: 24.0,
                                                ),
                                                child: Text(
                                                  t,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        if (sub.counterName != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                              left: 0.0,
                                            ),
                                            child: InkWell(
                                              onDoubleTap: () =>
                                                  onShowMediaGallery(
                                                    sub.counterCategory ?? '',
                                                    sub.counterName!,
                                                  ),
                                              child: Wrap(
                                                spacing: 6,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .subdirectory_arrow_right,
                                                    size: 22,
                                                    color: Colors.orange,
                                                  ),
                                                  Icon(
                                                    MoveDisplayWidgets.getCategoryIcon(
                                                      sub.counterCategory ?? '',
                                                    ),
                                                    size: 22,
                                                    color:
                                                        MoveDisplayWidgets.getCategoryColor(
                                                          sub.counterCategory ??
                                                              '',
                                                        ),
                                                  ),
                                                  Text(
                                                    sub.counterName!,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.orangeAccent,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  MoveDisplayWidgets.sideCircle(
                                                    LocalizationService.translate(
                                                      sub.counterSide == 'L'
                                                          ? 'left'
                                                          : 'right',
                                                      language,
                                                    ).substring(0, 1),
                                                    sub.counterSide ?? '',
                                                    mini: true,
                                                  ),
                                                  MoveDisplayWidgets.levelIcon(
                                                    sub.counterLevel ?? '',
                                                    size: 10,
                                                    mini: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (!moves[i].isCombo && moves[i].counterName != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                left: 0.0,
                              ),
                              child: InkWell(
                                onDoubleTap: () => onShowMediaGallery(
                                  moves[i].counterCategory ?? '',
                                  moves[i].counterName!,
                                ),
                                child: Wrap(
                                  spacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.subdirectory_arrow_right,
                                      size: 28,
                                      color: Colors.orange,
                                    ),
                                    Icon(
                                      MoveDisplayWidgets.getCategoryIcon(
                                        moves[i].counterCategory ?? '',
                                      ),
                                      size: 28,
                                      color:
                                          MoveDisplayWidgets.getCategoryColor(
                                            moves[i].counterCategory ?? '',
                                          ),
                                    ),
                                    Text(
                                      moves[i].counterName!,
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    MoveDisplayWidgets.sideCircle(
                                      LocalizationService.translate(
                                        moves[i].counterSide == 'L'
                                            ? 'left'
                                            : 'right',
                                        language,
                                      ).substring(0, 1),
                                      moves[i].counterSide ?? '',
                                      mini: true,
                                    ),
                                    MoveDisplayWidgets.levelIcon(
                                      moves[i].counterLevel ?? '',
                                      size: 10,
                                      mini: true,
                                    ),
                                    if (moves[i].counterSpecialAction != null)
                                      Chip(
                                        label: Text(
                                          moves[i].counterSpecialAction!,
                                          style: const TextStyle(fontSize: 8),
                                        ),
                                        backgroundColor: Colors.purple
                                            .withValues(alpha: 0.2),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
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
                      backgroundColor: Colors.redAccent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (moves[i].subLetter == null)
                            Text(
                              '${displayNumbers[i]}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            )
                          else
                            Text(
                              moves[i].subLetter!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.yellowAccent,
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
