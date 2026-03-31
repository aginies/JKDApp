/// Represents parameters for creating or updating a move
class MoveParameters {
  final Map<String, dynamic> item;
  final String category;
  final String side;
  final String level;
  final bool isFeint;
  final String? specialAction;
  final Map<String, String> translations;
  final int repetitions;

  const MoveParameters({
    required this.item,
    required this.category,
    required this.side,
    required this.level,
    required this.isFeint,
    this.specialAction,
    this.translations = const {},
    this.repetitions = 1,
  });

  MoveParameters copyWith({
    Map<String, dynamic>? item,
    String? category,
    String? side,
    String? level,
    bool? isFeint,
    String? specialAction,
    Map<String, String>? translations,
    int? repetitions,
  }) {
    return MoveParameters(
      item: item ?? this.item,
      category: category ?? this.category,
      side: side ?? this.side,
      level: level ?? this.level,
      isFeint: isFeint ?? this.isFeint,
      specialAction: specialAction ?? this.specialAction,
      translations: translations ?? this.translations,
      repetitions: repetitions ?? this.repetitions,
    );
  }
}

/// Represents parameters for creating a counter move
class CounterMoveParameters {
  final MoveParameters attack;
  final Map<String, dynamic> counterItem;
  final String counterCategory;
  final String counterSide;
  final String? counterLevel;
  final String? counterSpecialAction;
  final Map<String, String> counterTranslations;

  const CounterMoveParameters({
    required this.attack,
    required this.counterItem,
    required this.counterCategory,
    required this.counterSide,
    this.counterLevel,
    this.counterSpecialAction,
    this.counterTranslations = const {},
  });
}
