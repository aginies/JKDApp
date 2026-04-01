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

    if (move.isChain) {
      return move.chain
          .map((m) => _getEffectiveTranslation(m, language, glossary))
          .where((s) => s.isNotEmpty)
          .join(' -> ');
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

  /// Helper to find counter translation in glossary
  /// First tries counterGlossaryId, then falls back to counterName lookup
  static String _getEffectiveCounterTranslation(
    Move move,
    String language,
    List<Map<String, dynamic>> glossary,
  ) {
    if (move.counterName == null) return '';

    // Handle simultaneous counters (separated by " + ")
    if (move.counterName!.contains(' + ')) {
      final counterNames = move.counterName!.split(' + ');
      return counterNames
          .map((name) {
            final entry = glossary.firstWhere(
              (e) =>
                  e['name'].toString().toLowerCase() ==
                  name.trim().toLowerCase(),
              orElse: () => {},
            );
            if (entry.isNotEmpty && entry['translations'] != null) {
              try {
                final Map<String, dynamic> trans = json.decode(
                  entry['translations'],
                );
                return trans[language] ??
                    trans['en'] ??
                    trans['fr'] ??
                    name.trim();
              } catch (_) {
                return name.trim();
              }
            }
            return name.trim();
          })
          .join(' + ');
    }

    // First try to find by counterGlossaryId
    if (move.counterGlossaryId != null) {
      final entry = glossary.firstWhere(
        (e) => e['id'] == move.counterGlossaryId,
        orElse: () => {},
      );
      if (entry.isNotEmpty && entry['translations'] != null) {
        try {
          final Map<String, dynamic> trans = json.decode(entry['translations']);
          return trans[language] ?? trans['en'] ?? trans['fr'] ?? '';
        } catch (_) {
          // Fall through to name-based lookup
        }
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
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  /// Builds the content row for a move (icon, name, side, level, etc.)
  static Widget _buildMoveContent(
    Move sub,
    String language,
    Function(String category, String moveName) onShowMediaGallery, {
    double iconSize = 24,
    double fontSize = 14,
    VoidCallback? onEdit,
  }) {
    return InkWell(
      onDoubleTap: onEdit ?? () => onShowMediaGallery(sub.category, sub.name),
      child: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            MoveDisplayWidgets.getCategoryIcon(sub.category),
            size: iconSize,
            color: MoveDisplayWidgets.getCategoryColor(sub.category),
          ),
          Text(
            sub.name,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
          MoveDisplayWidgets.sideCircle(
            LocalizationService.translate(
              sub.side == 'L' ? 'left' : 'right',
              language,
            ).substring(0, 1),
            sub.side,
            mini: iconSize < 28,
          ),
          MoveDisplayWidgets.levelIcon(sub.level, size: iconSize / 2),
          if (sub.isFeint)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: MoveDisplayWidgets.drawBox(mini: iconSize < 28),
            ),
          if (sub.specialAction != null)
            Chip(
              label: Text(
                sub.specialAction!,
                style: TextStyle(fontSize: fontSize - 4),
              ),
              backgroundColor: Colors.purple.withValues(alpha: 0.2),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }

  /// Builds the content for a simultaneous group of moves
  static Widget _buildSimultaneousContent(
    Move move,
    String language,
    Function(String category, String moveName) onShowMediaGallery, {
    double iconSize = 24,
    double fontSize = 14,
    int? subDisplayNumber,
    VoidCallback? onEdit,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (subDisplayNumber != null)
          Text(
            '$subDisplayNumber.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ...move.subMoves.asMap().entries.map((e) {
          final idx = e.key;
          final m = e.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMoveContent(
                m,
                language,
                onShowMediaGallery,
                iconSize: iconSize,
                fontSize: fontSize,
                onEdit: onEdit,
              ),
              if (idx < move.subMoves.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.add,
                    size: iconSize * 0.6,
                    color: Colors.grey,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  /// Builds the content for a sequential chain of moves
  static Widget _buildChainContent(
    BuildContext context,
    Move move,
    String language,
    Function(String category, String moveName) onShowMediaGallery, {
    double iconSize = 24,
    double fontSize = 14,
    int? subDisplayNumber,
    VoidCallback? onEdit,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        if (subDisplayNumber != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '$subDisplayNumber.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ...move.chain.asMap().entries.map((e) {
          final idx = e.key;
          final m = e.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMoveContent(
                    m,
                    language,
                    onShowMediaGallery,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    onEdit: onEdit,
                  ),
                  if (m.counterName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.subdirectory_arrow_right,
                            size: 18,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            m.counterName!,
                            style: TextStyle(
                              fontSize: fontSize - 1,
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (idx < move.chain.length - 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Icon(
                    Icons.arrow_forward,
                    size: iconSize * 0.7,
                    color: Colors.teal,
                  ),
                ),
            ],
          );
        }),
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
                              if (moves[i].category == 'simultaneous')
                                _buildSimultaneousContent(
                                  moves[i],
                                  language,
                                  onShowMediaGallery,
                                  iconSize: 32,
                                  fontSize: 16,
                                  onEdit: isEditing ? onEdit(i) : null,
                                )
                              else if (moves[i].category == 'chain' || moves[i].isChain)
                                _buildChainContent(
                                  context,
                                  moves[i],
                                  language,
                                  onShowMediaGallery,
                                  iconSize: 32,
                                  fontSize: 16,
                                  onEdit: isEditing ? onEdit(i) : null,
                                )
                              else if (!moves[i].isCombo) ...[
                                _buildMoveContent(
                                  moves[i],
                                  language,
                                  onShowMediaGallery,
                                  iconSize: 32,
                                  fontSize: 16,
                                  onEdit: isEditing ? onEdit(i) : null,
                                ),
                              ],
                            ],
                          ),
                          if (showTranslation &&
                              !moves[i].isCombo &&
                              moves[i].category != 'simultaneous' &&
                              moves[i].category != 'chain')
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
                          if (moves[i].category == 'combo')
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
                                  final bool isSimultaneous =
                                      sub.category == 'simultaneous';
                                  final bool isChain = sub.category == 'chain';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isSimultaneous)
                                          _buildSimultaneousContent(
                                            sub,
                                            language,
                                            onShowMediaGallery,
                                            subDisplayNumber: subDisplayNumber,
                                            onEdit: isEditing
                                                ? onEdit(i)
                                                : null,
                                          )
                                        else if (isChain)
                                          _buildChainContent(
                                            context,
                                            sub,
                                            language,
                                            onShowMediaGallery,
                                            subDisplayNumber: subDisplayNumber,
                                            onEdit: isEditing
                                                ? onEdit(i)
                                                : null,
                                          )
                                        else
                                          Row(
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
                                              _buildMoveContent(
                                                sub,
                                                language,
                                                onShowMediaGallery,
                                                onEdit: isEditing
                                                    ? onEdit(i)
                                                    : null,
                                              ),
                                            ],
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
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                InkWell(
                                                  onDoubleTap: () =>
                                                      onShowMediaGallery(
                                                        sub.counterCategory ??
                                                            '',
                                                        sub.counterName!,
                                                      ),
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
                                                        color: Colors.orange,
                                                      ),
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
                                                          fontSize: 13,
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                                if (showTranslation)
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
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
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
                              ),
                            ),
                          if (moves[i].category != 'combo' &&
                              moves[i].category != 'chain' &&
                              moves[i].counterName != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                left: 0.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onDoubleTap: () => onShowMediaGallery(
                                      moves[i].counterCategory ?? '',
                                      moves[i].counterName!,
                                    ),
                                    child: Wrap(
                                      spacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
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
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontWeight: FontWeight.bold,
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
                                        if (moves[i].counterSpecialAction !=
                                            null)
                                          Chip(
                                            label: Text(
                                              moves[i].counterSpecialAction!,
                                              style: const TextStyle(
                                                fontSize: 8,
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
                                              fontWeight: FontWeight.bold,
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
                              '${displayNumbers[i]}${moves[i].subLetter}',
                              style: const TextStyle(
                                fontSize: 13,
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
