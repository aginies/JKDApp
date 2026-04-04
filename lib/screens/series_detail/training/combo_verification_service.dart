import '../../../models/move.dart';

enum TrainingLevel {
  beginner, // Ignore Side (L/R) and Level (H/M/L)
  advanced, // Ignore Level (H/M/L), check Side (L/R)
  expert,   // Check everything
}

class VerificationResult {
  final bool isCorrect;
  final List<String> differences;
  final Move original;
  final Move attempt;
  final TrainingLevel level;

  VerificationResult({
    required this.isCorrect,
    required this.differences,
    required this.original,
    required this.attempt,
    required this.level,
  });
}

class ComboVerificationService {
  static VerificationResult verifyMove(Move original, Move attempt, TrainingLevel level) {
    List<String> differences = [];
    _compareMoves(original, attempt, differences, "Move", level);

    return VerificationResult(
      isCorrect: differences.isEmpty,
      differences: differences,
      original: original,
      attempt: attempt,
      level: level,
    );
  }

  static void _compareMoves(Move orig, Move att, List<String> diffs, String context, TrainingLevel level) {
    // 1. Basic property comparison
    if (orig.name.toLowerCase().trim() != att.name.toLowerCase().trim()) {
      diffs.add('$context: Name expected "${orig.name}" but got "${att.name}"');
    }
    
    // Check Side based on level
    if (level != TrainingLevel.beginner) {
      if (orig.side != att.side) {
        diffs.add('$context (${orig.name}): Side expected "${orig.side}" but got "${att.side}"');
      }
    }
    
    // Check Height/Level based on level
    if (level == TrainingLevel.expert) {
      if (orig.level != att.level) {
        diffs.add('$context (${orig.name}): Height expected "${orig.level}" but got "${att.level}"');
      }
    }

    if (orig.isFeint != att.isFeint) {
      diffs.add('$context (${orig.name}): Draw/Feint status mismatch');
    }

    // 2. Structural comparison: Chain
    if (orig.isChain != att.isChain) {
      diffs.add('$context: Structural mismatch. Expected a Chain but got something else');
    } else if (orig.isChain) {
      if (orig.chain.length != att.chain.length) {
        diffs.add('$context: Chain length mismatch. Expected ${orig.chain.length} items but got ${att.chain.length}');
      } else {
        for (int i = 0; i < orig.chain.length; i++) {
          _compareMoves(orig.chain[i], att.chain[i], diffs, 'Chain Item ${i + 1}', level);
        }
      }
    }

    // 3. Structural comparison: Simultaneous (Combo)
    if (orig.isCombo != att.isCombo) {
      diffs.add('$context: Structural mismatch. Expected Simultaneous group but got something else');
    } else if (orig.isCombo) {
      if (orig.subMoves.length != att.subMoves.length) {
        diffs.add('$context: Simultaneous group size mismatch');
      } else {
        for (int i = 0; i < orig.subMoves.length; i++) {
          _compareMoves(orig.subMoves[i], att.subMoves[i], diffs, 'Simultaneous Item ${i + 1}', level);
        }
      }
    }

    // 4. Counter (Answer) comparison
    if (orig.hasCounter != att.hasCounter) {
      if (orig.hasCounter) {
        diffs.add('$context: Missing Answer');
      } else {
        diffs.add('$context: Unexpected Answer added');
      }
    } else if (orig.hasCounter) {
      // Compare counters
      if (orig.hasStructuredCounter != att.hasStructuredCounter) {
         diffs.add('$context Answer: Structural mismatch');
      } else if (orig.hasCounterCombo) {
         if (orig.counterSubMoves.length != att.counterSubMoves.length) {
           diffs.add('$context Answer: Simultaneous size mismatch');
         } else {
           for (int i = 0; i < orig.counterSubMoves.length; i++) {
             _compareMoves(orig.counterSubMoves[i], att.counterSubMoves[i], diffs, 'Answer Item ${i + 1}', level);
           }
         }
      } else if (orig.hasCounterChain) {
         if (orig.counterChain.length != att.counterChain.length) {
           diffs.add('$context Answer: Chain size mismatch');
         } else {
           for (int i = 0; i < orig.counterChain.length; i++) {
             _compareMoves(orig.counterChain[i], att.counterChain[i], diffs, 'Answer Chain Item ${i + 1}', level);
           }
         }
      } else {
        // Simple counter
        if (orig.counterName?.toLowerCase().trim() != att.counterName?.toLowerCase().trim()) {
          diffs.add('$context Answer: Name expected "${orig.counterName}" but got "${att.counterName}"');
        }
        
        // Counter Side
        if (level != TrainingLevel.beginner) {
          if (orig.counterSide != att.counterSide) {
            diffs.add('$context Answer: Side expected "${orig.counterSide}" but got "${att.counterSide}"');
          }
        }
        
        // Counter Level
        if (level == TrainingLevel.expert) {
          if (orig.counterLevel != att.counterLevel) {
            diffs.add('$context Answer: Level expected "${orig.counterLevel}" but got "${att.counterLevel}"');
          }
        }

        if (orig.counterIsFeint != att.counterIsFeint) {
          diffs.add('$context Answer: Draw status mismatch');
        }
      }
    }
  }
}
