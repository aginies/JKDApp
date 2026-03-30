import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';
import '../models/move.dart';
import 'database_service.dart';

class GlossaryEntry {
  final String name;
  final String category;
  final Map<String, String> translations;
  final String? restrictedLevel;

  GlossaryEntry({
    required this.name,
    required this.category,
    required this.translations,
    this.restrictedLevel,
  });
}

class VoiceParsingService {
  final SpeechToText _speechToText = SpeechToText();
  final List<GlossaryEntry> _glossary = [];
  bool _isInitialized = false;

  // Keywords
  final List<String> _leftKeywords = ['left', 'gauche'];
  final List<String> _rightKeywords = ['right', 'droite', 'droit'];
  final List<String> _highKeywords = ['high', 'haut'];
  final List<String> _midKeywords = ['mid', 'middle', 'centre', 'milieu'];
  final List<String> _lowKeywords = ['low', 'bas'];
  final List<String> _nextKeywords = [
    'next',
    'then',
    'suivant',
    'ensuite',
    'puis',
    'et',
  ];
  final List<String> _answerKeywords = [
    'answer',
    'counter',
    'réponse',
    'reponse',
    'contre',
  ];

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
      await _loadGlossary();
    }
    return _isInitialized;
  }

  Future<void> _loadGlossary() async {
    _glossary.clear();
    final categories = [
      'punch',
      'kick',
      'packs',
      'trapping',
      'special',
      'general',
      'other',
    ];
    for (String cat in categories) {
      final items = await DatabaseService().getGlossaryByCategory(cat);
      for (var item in items) {
        Map<String, String> trans = {};
        try {
          trans = Map<String, String>.from(
            json.decode(item['translations'] ?? '{}'),
          );
        } catch (_) {}

        Map<String, dynamic> removal = {};
        try {
          removal = json.decode(item['removal'] ?? '{}');
        } catch (_) {}

        _glossary.add(
          GlossaryEntry(
            name: item['name'],
            category: cat,
            translations: trans,
            restrictedLevel: removal['level'],
          ),
        );
      }
    }
  }

  void startListening(Function(String) onResult, {String? localeId}) {
    _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
    );
  }

  void stopListening() {
    _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;

  /// Parses a spoken sentence into a list of Move objects.
  List<Move> parseSentenceToCombo(String sentence) {
    if (sentence.trim().isEmpty) return [];

    // Normalize string: lowercase, remove punctuation
    String normalized = sentence.toLowerCase().replaceAll(
      RegExp(r'[^\w\sàâäéèêëîïôöùûüç]'),
      '',
    );

    // Split into segments based on "next" keywords
    List<String> moveSegments = _splitByKeywords(normalized, _nextKeywords);

    List<Move> combo = [];

    for (String segment in moveSegments) {
      if (segment.trim().isEmpty) continue;

      // Split segment into attack and optional counter
      List<String> attackAndCounter = _splitByKeywords(
        segment,
        _answerKeywords,
        limit: 2,
      );

      String attackPhrase = attackAndCounter[0];
      String counterPhrase = attackAndCounter.length > 1
          ? attackAndCounter[1]
          : '';

      // Parse Attack
      ParsedAttributes attackAttrs = _extractAttributes(attackPhrase);
      GlossaryEntry? matchedAttack = _findBestMatch(
        attackAttrs.remainingText,
        allowAll: true,
      );

      if (matchedAttack != null) {
        String? cName;
        String? cCategory;
        String? cSide;
        String? cLevel;

        // Parse Counter if it exists
        if (counterPhrase.trim().isNotEmpty) {
          ParsedAttributes counterAttrs = _extractAttributes(counterPhrase);
          GlossaryEntry? matchedCounter = _findBestMatch(
            counterAttrs.remainingText,
            allowAll: true,
          );

          if (matchedCounter != null) {
            cName = matchedCounter.name;
            cCategory = matchedCounter.category;
            cSide = counterAttrs.side.isNotEmpty ? counterAttrs.side : null;
            cLevel = _resolveLevel(
              counterAttrs.level,
              matchedCounter.restrictedLevel,
            );
            if (cLevel.isEmpty) {
              cLevel = _resolveLevel(
                attackAttrs.level,
                matchedAttack.restrictedLevel,
              );
            }
          }
        }

        combo.add(
          Move(
            name: matchedAttack.name,
            category: matchedAttack.category,
            translations: matchedAttack.translations,
            side: attackAttrs.side,
            level: _resolveLevel(
              attackAttrs.level,
              matchedAttack.restrictedLevel,
            ),
            repetitions: 1,
            counterName: cName,
            counterCategory: cCategory,
            counterSide: cSide,
            counterLevel: cLevel,
          ),
        );
      }
    }

    return combo;
  }

  String _resolveLevel(String requestedLevel, String? restrictedLevel) {
    if (requestedLevel.isEmpty) return '';
    if (requestedLevel == restrictedLevel) {
      return ''; // If they asked for a restricted level, ignore it
    }
    return requestedLevel;
  }

  List<String> _splitByKeywords(
    String input,
    List<String> keywords, {
    int? limit,
  }) {
    // Build a regex to match any of the keywords as isolated words
    String pattern = r'\b(' + keywords.join('|') + r')\b';
    List<String> parts = input.split(RegExp(pattern));

    if (limit != null && parts.length > limit) {
      // Re-join the rest if we have a limit (e.g. only split on first "answer")
      String first = parts[0];
      String rest = parts
          .sublist(1)
          .join(
            ' ',
          ); // We lose the exact keyword, which is fine, it was just a separator
      return [first, rest];
    }
    return parts;
  }

  ParsedAttributes _extractAttributes(String phrase) {
    List<String> words = phrase.split(' ');
    String side = '';
    String level = '';
    List<String> remainingWords = [];

    for (String word in words) {
      if (word.isEmpty) continue;
      if (_leftKeywords.contains(word)) {
        side = 'L';
      } else if (_rightKeywords.contains(word)) {
        side = 'R';
      } else if (_highKeywords.contains(word)) {
        level = 'High';
      } else if (_midKeywords.contains(word)) {
        level = 'Mid';
      } else if (_lowKeywords.contains(word)) {
        level = 'Low';
      } else {
        remainingWords.add(word);
      }
    }

    return ParsedAttributes(
      side: side,
      level: level,
      remainingText: remainingWords.join(' '),
    );
  }

  GlossaryEntry? _findBestMatch(String text, {bool allowAll = false}) {
    if (text.trim().isEmpty) return null;

    double bestScore = 0.0;
    GlossaryEntry? bestMatch;

    for (var entry in _glossary) {
      // Check English name
      double scoreEn = StringSimilarity.compareTwoStrings(
        text,
        entry.name.toLowerCase(),
      );

      // Check French translation if available
      double scoreFr = 0.0;
      if (entry.translations['fr'] != null) {
        scoreFr = StringSimilarity.compareTwoStrings(
          text,
          entry.translations['fr']!.toLowerCase(),
        );
      }

      // Check other translations just in case
      double scoreOther = 0.0;
      if (entry.translations['en'] != null) {
        scoreOther = StringSimilarity.compareTwoStrings(
          text,
          entry.translations['en']!.toLowerCase(),
        );
      }

      double maxScore = [
        scoreEn,
        scoreFr,
        scoreOther,
      ].reduce((a, b) => a > b ? a : b);

      if (maxScore > bestScore) {
        bestScore = maxScore;
        bestMatch = entry;
      }
    }

    // A threshold to avoid matching garbage noise. Lowered to 0.3 for better STT recognition
    if (bestScore > 0.3) {
      return bestMatch;
    }
    return null;
  }
}

class ParsedAttributes {
  final String side;
  final String level;
  final String remainingText;

  ParsedAttributes({
    required this.side,
    required this.level,
    required this.remainingText,
  });
}
