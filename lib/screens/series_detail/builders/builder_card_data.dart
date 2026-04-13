/// Data model for the AdvancedComboBuilder workspace.
class BuilderCardData {
  final String name;
  final String category;
  final int? glossaryId;
  final String side;
  final String level;
  final bool isFeint;
  final String? specialAction;
  final int? kaliAngle;
  final String? strikeType;
  final List<BuilderCardData> subMoves; // For simultaneous moves (+)
  final List<BuilderCardData> chain; // For sequential moves (->)

  // Counter (Answer) fields
  final String? counterName;
  final String? counterCategory;
  final int? counterGlossaryId;
  final String counterSide;
  final String counterLevel;
  final bool counterIsFeint;

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
    this.kaliAngle,
    this.strikeType,
    this.subMoves = const [],
    this.chain = const [],
    this.counterName,
    this.counterCategory,
    this.counterGlossaryId,
    this.counterSide = '',
    this.counterLevel = '',
    this.counterIsFeint = false,
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
    int? kaliAngle,
    String? strikeType,
    List<BuilderCardData>? subMoves,
    List<BuilderCardData>? chain,
    Object? counterName = _sentinel,
    Object? counterCategory = _sentinel,
    Object? counterGlossaryId = _sentinel,
    String? counterSide,
    String? counterLevel,
    bool? counterIsFeint,
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
      kaliAngle: kaliAngle ?? this.kaliAngle,
      strikeType: strikeType ?? this.strikeType,
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
      counterIsFeint: counterIsFeint ?? this.counterIsFeint,
      counterSubMoves: counterSubMoves ?? this.counterSubMoves,
      counterChain: counterChain ?? this.counterChain,
    );
  }

  static const _sentinel = Object();
}

/// Snapshot of workspace state for undo/redo history.
class BuilderHistoryEntry {
  final List<BuilderCardData> cards;
  final List<int>? selectedPath;
  final bool isCounterSelected;
  final List<int>? selectedCounterPath;

  BuilderHistoryEntry({
    required this.cards,
    this.selectedPath,
    this.isCounterSelected = false,
    this.selectedCounterPath,
  });
}
