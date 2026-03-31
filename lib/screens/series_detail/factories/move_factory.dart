import '../../models/move.dart';

class MoveFactory {
  /// Creates a standard move from glossary item
  static Move createMove({
    required Map<String, dynamic> item,
    required String category,
    required String side,
    required String level,
    required bool isFeint,
    String? specialAction,
    Map<String, String>? translations,
    int repetitions = 1,
    bool isCustom = false,
  }) {
    return Move(
      glossaryId: isCustom ? null : item['id'],
      name: isCustom && item['name'] is String ? item['name'] : item['name'],
      category: category,
      translations: translations ?? {},
      side: side,
      level: level,
      isFeint: isFeint,
      specialAction: specialAction,
      repetitions: repetitions,
    );
  }

  /// Creates a move with counter information
  static Move createMoveWithCounter({
    required Map<String, dynamic> attackItem,
    required String attackCategory,
    required String attackSide,
    required String attackLevel,
    required bool attackIsFeint,
    String? attackSpecialAction,
    Map<String, String>? attackTranslations,
    required Map<String, dynamic> counterItem,
    required String counterCategory,
    required String counterSide,
    String? counterLevel,
    String? counterSpecialAction,
    int repetitions = 1,
    bool isCustomAttack = false,
    bool isCustomCounter = false,
  }) {
    return Move(
      glossaryId: isCustomAttack ? null : attackItem['id'],
      counterGlossaryId: isCustomCounter ? null : counterItem['id'],
      name: isCustomAttack && attackItem['name'] is String
          ? attackItem['name']
          : attackItem['name'],
      category: attackCategory,
      translations: attackTranslations ?? {},
      side: attackSide,
      level: attackLevel,
      isFeint: attackIsFeint,
      specialAction: attackSpecialAction,
      repetitions: repetitions,
      counterName: isCustomCounter && counterItem['name'] is String
          ? counterItem['name']
          : counterItem['name'],
      counterCategory: counterCategory,
      counterSide: counterSide,
      counterLevel: counterLevel ?? attackLevel,
      counterSpecialAction: counterSpecialAction,
    );
  }

  /// Updates existing move with new attack data
  static Move updateMoveAttack({
    required Move existingMove,
    required Map<String, dynamic> item,
    required String category,
    required String side,
    required String level,
    required bool isFeint,
    String? specialAction,
    Map<String, String>? translations,
    bool isCustom = false,
  }) {
    return Move(
      glossaryId: isCustom ? null : item['id'],
      counterGlossaryId: existingMove.counterGlossaryId,
      name: isCustom && item['name'] is String ? item['name'] : item['name'],
      category: category,
      translations: translations ?? {},
      side: side,
      level: level,
      isFeint: isFeint,
      specialAction: specialAction,
      repetitions: existingMove.repetitions,
      counterName: existingMove.counterName,
      counterCategory: existingMove.counterCategory,
      counterSide: existingMove.counterSide,
      counterLevel: existingMove.counterLevel,
      counterSpecialAction: existingMove.counterSpecialAction,
    );
  }

  /// Updates existing move with new counter data
  static Move updateMoveCounter({
    required Move existingMove,
    required Map<String, dynamic> counterItem,
    required String counterCategory,
    required String counterSide,
    String? counterLevel,
    String? counterSpecialAction,
    bool isCustom = false,
  }) {
    return existingMove.copyWith(
      counterName: isCustom && counterItem['name'] is String
          ? counterItem['name']
          : counterItem['name'],
      counterGlossaryId: isCustom ? null : counterItem['id'],
      counterCategory: counterCategory,
      counterSide: counterSide,
      counterLevel: counterLevel ?? existingMove.level,
      counterSpecialAction: counterSpecialAction,
    );
  }

  /// Creates a combo move from multiple sub-moves
  static Move createCombo(List<Move> subMoves) {
    if (subMoves.isEmpty) {
      throw ArgumentError('Cannot create combo with no moves');
    }

    if (subMoves.length == 1) {
      return subMoves.first;
    }

    return Move(
      name: 'Combo: ${subMoves.first.name} + ...',
      category: 'combo',
      subMoves: List.from(subMoves),
    );
  }
}
