import 'package:flutter/material.dart';
import '../../../models/move.dart';
import '../../../services/database_service.dart';
import '../../../services/localization_service.dart';
import '../constants/series_detail_constants.dart';
import 'move_display_widgets.dart';

class ComboCardWidget extends StatelessWidget {
  final Move move;
  final int index;
  final String language;
  final Animation<double> animation;
  final VoidCallback onRemove;
  final Function(int index, bool isCounter) onEdit;
  final Function(String category, String moveName) onShowMediaGallery;
  final bool isSelected;
  final bool isCounterSelected;
  final bool isRemoving;

  const ComboCardWidget({
    super.key,
    required this.move,
    required this.index,
    required this.language,
    required this.animation,
    required this.onRemove,
    required this.onEdit,
    required this.onShowMediaGallery,
    this.isSelected = false,
    this.isCounterSelected = false,
    this.isRemoving = false,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeIn,
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: Axis.horizontal,
          child: Card(
            key: isRemoving ? null : ValueKey(move.uKey),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            shape: (isSelected || isCounterSelected)
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? MoveDisplayWidgets.getCategoryColor(move.category)
                          : MoveDisplayWidgets.getCategoryColor(
                              move.counterCategory ?? '',
                            ),
                      width: 2,
                    ),
                  )
                : null,
            child: Container(
              width: SeriesDetailConstants.comboCardWidth,
              padding: const EdgeInsets.all(6),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAttackSection(),
                      if (move.counterName != null)
                        Expanded(child: _buildCounterSection()),
                    ],
                  ),
                  if (!isRemoving)
                    Positioned(
                      right: -10,
                      top: -10,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
                        ),
                        onPressed: onRemove,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttackSection() {
    final bool isSimultaneous = move.category == 'simultaneous';

    return GestureDetector(
      onTap: isRemoving
          ? null
          : () async {
              // If it's a simultaneous group, we "go to the first item" 
              // by editing the group but ideally we'd want to pick the component.
              // For now, it triggers the standard edit which will use the group's first hit
              // if we implement auto-selection logic in the parent.
              onEdit(index, false);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSimultaneous)
            Wrap(
              spacing: 4,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${index + 1}.',
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
                      _buildMoveThumbnail(m),
                      if (idx < move.subMoves.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.0),
                          child: Text(
                            '+',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  MoveDisplayWidgets.getCategoryIcon(move.category),
                  size: 22,
                  color: MoveDisplayWidgets.getCategoryColor(move.category),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${index + 1}. ${move.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (!isSimultaneous)
            Row(
              children: [
                if (move.side.isNotEmpty)
                  MoveDisplayWidgets.sideCircle(
                    LocalizationService.translate(
                      move.side == 'L' ? 'left' : 'right',
                      language,
                    ).substring(0, 1),
                    move.side,
                    mini: true,
                  ),
                MoveDisplayWidgets.levelIcon(move.level, size: 10, mini: true),
                if (move.isFeint)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: MoveDisplayWidgets.drawBox(mini: true),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMoveThumbnail(Move m) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          MoveDisplayWidgets.getCategoryIcon(m.category),
          size: 16,
          color: MoveDisplayWidgets.getCategoryColor(m.category),
        ),
        const SizedBox(width: 2),
        Text(
          m.name,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        if (m.side.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: MoveDisplayWidgets.sideCircle(
              LocalizationService.translate(
                m.side == 'L' ? 'left' : 'right',
                language,
              ).substring(0, 1),
              m.side,
              mini: true,
            ),
          ),
      ],
    );
  }

  Widget _buildCounterSection() {
    return GestureDetector(
      onTap: isRemoving
          ? null
          : () async {
              final cat = move.counterCategory ?? '';
              int? gid = move.counterGlossaryId;
              if (gid == null && move.counterName != null) {
                gid = await _findGlossaryId(cat, move.counterName!);
              }
              onEdit(index, true);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Divider(height: 8),
          Row(
            children: [
              Icon(
                MoveDisplayWidgets.getCategoryIcon(move.counterCategory ?? ''),
                size: 16,
                color: MoveDisplayWidgets.getCategoryColor(
                  move.counterCategory ?? '',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  move.counterName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if ((move.counterSide ?? '').isNotEmpty)
            Row(
              children: [
                MoveDisplayWidgets.sideCircle(
                  LocalizationService.translate(
                    move.counterSide == 'L' ? 'left' : 'right',
                    language,
                  ).substring(0, 1),
                  move.counterSide!,
                  mini: true,
                ),
                MoveDisplayWidgets.levelIcon(
                  move.counterLevel ?? '',
                  size: 10,
                  mini: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<int?> _findGlossaryId(String category, String name) async {
    final items = await DatabaseService().getGlossaryByCategory(category);
    final match = items.firstWhere(
      (i) => i['name'].toString().toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );
    if (match.isEmpty) {
      final all = await DatabaseService().getGlossary();
      final matchAll = all.firstWhere(
        (i) => i['name'].toString().toLowerCase() == name.toLowerCase(),
        orElse: () => {},
      );
      if (matchAll.isNotEmpty) return matchAll['id'];
    }
    return match.isNotEmpty ? match['id'] : null;
  }
}
