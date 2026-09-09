import '../../../models/move.dart';
import 'builder_card_data.dart';

/// Fully recursive conversion from [Move] to [BuilderCardData], preserving
/// nested structures (Simultaneous, nested Chains, Answers).
BuilderCardData builderCardDataFromMove(Move m) {
  return BuilderCardData(
    name: m.name,
    category: m.category,
    side: m.side,
    level: m.level,
    isFeint: m.isFeint,
    specialAction: m.specialAction,
    kaliAngle: m.kaliAngle,
    strikeType: m.strikeType,
    glossaryId: m.glossaryId,
    counterName: m.counterName,
    counterCategory: m.counterCategory,
    counterSide: m.counterSide ?? '',
    counterLevel: m.counterLevel ?? '',
    counterIsFeint: m.counterIsFeint,
    subMoves: m.subMoves.map((sm) => builderCardDataFromMove(sm)).toList(),
    chain: m.chain.map((cm) => builderCardDataFromMove(cm)).toList(),
    counterSubMoves: m.counterSubMoves
        .map((cm) => builderCardDataFromMove(cm))
        .toList(),
    counterChain: m.counterChain
        .map((cm) => builderCardDataFromMove(cm))
        .toList(),
  );
}

/// Fully recursive conversion from [BuilderCardData] to [Move], preserving
/// nested structures (Simultaneous, nested Chains, Answers).
Move moveFromBuilderCardData(BuilderCardData data) {
  // 1. Recursive handling for CHAIN (Inner contents must be leaf or combos, NEVER nested chains)
  if (data.isChain) {
    return Move(
      name: data.chain.map((m) => m.name).join(' -> '),
      category: 'chain',
      chain: data.chain.map((m) => moveFromBuilderCardData(m)).toList(),
      counterName: data.counterName,
      counterCategory: data.counterCategory,
      counterGlossaryId: data.counterGlossaryId,
      counterSide: data.counterSide,
      counterLevel: data.counterLevel,
      counterIsFeint: data.counterIsFeint,
      counterSubMoves: data.counterSubMoves
          .map((cm) => moveFromBuilderCardData(cm))
          .toList(),
      counterChain: data.counterChain
          .map((m) => moveFromBuilderCardData(m))
          .toList(),
    );
  }

  // 2. Recursive handling for SIMULTANEOUS (Combo)
  if (data.isCombo) {
    return Move(
      name: data.subMoves.map((m) => m.name).join(' + '),
      category: 'simultaneous',
      subMoves: data.subMoves.map((m) => moveFromBuilderCardData(m)).toList(),
      counterName: data.counterName,
      counterCategory: data.counterCategory,
      counterGlossaryId: data.counterGlossaryId,
      counterSide: data.counterSide,
      counterLevel: data.counterLevel,
      counterIsFeint: data.counterIsFeint,
      counterSubMoves: data.counterSubMoves
          .map((cm) => moveFromBuilderCardData(cm))
          .toList(),
      counterChain: data.counterChain
          .map((m) => moveFromBuilderCardData(m))
          .toList(),
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
    kaliAngle: data.kaliAngle,
    strikeType: data.strikeType,
    glossaryId: data.glossaryId,
    counterName: data.counterName,
    counterCategory: data.counterCategory,
    counterGlossaryId: data.counterGlossaryId,
    counterSide: data.counterSide,
    counterLevel: data.counterLevel,
    counterIsFeint: data.counterIsFeint,
    counterSubMoves: data.counterSubMoves
        .map((cm) => moveFromBuilderCardData(cm))
        .toList(),
    counterChain: data.counterChain
        .map((m) => moveFromBuilderCardData(m))
        .toList(),
  );
}
