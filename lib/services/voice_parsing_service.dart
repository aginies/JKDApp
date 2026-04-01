import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';
import '../models/move.dart';
import 'database_service.dart';
import '../utils/translation_utils.dart';

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

class MoveOption {
  final Move move;
  final double score;

  MoveOption({required this.move, required this.score});
}

class VoiceParsingService {
  final SpeechToText _speechToText = SpeechToText();
  final List<GlossaryEntry> _glossary = [];
  bool _isInitialized = false;
  Function(String)? _onStatusCallback;

  // Keywords
  final List<String> _leftKeywords = ['left', 'gauche'];
  final List<String> _rightKeywords = ['right', 'droite', 'droit'];
  final List<String> _highKeywords = ['high', 'haut'];
  final List<String> _midKeywords = ['mid', 'middle', 'centre', 'milieu'];
  final List<String> _lowKeywords = ['low', 'bas'];
  final List<String> _nextKeywords = [
    'next',
    'then',
    'and',
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
  final List<String> _comboKeywords = ['plus', '+'];

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) {
          debugPrint('STT Status: $status');
          _onStatusCallback?.call(status);
        },
      );
      await _loadGlossary();
    }
    return _isInitialized;
  }

  Future<void> _loadGlossary() async {
    _glossary.clear();
    final categories = {
      'punch',
      'kick',
      'packs',
      'trapping',
      'special',
      'general',
      'other',
      'kali',
    };

    // Load all glossary items in one query instead of 7 sequential queries
    final allItems = await DatabaseService().getGlossary();

    for (var item in allItems) {
      final cat = item['category'] as String?;
      if (cat == null || !categories.contains(cat)) continue;

      final trans = TranslationUtils.parseTranslations(item['translations']);

      Map<String, dynamic> removal = {};
      try {
        removal = json.decode(item['removal'] ?? '{}');
      } catch (e) {
        debugPrint('Error parsing removal data: $e');
      }

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

  void startListening(
    Function(String) onResult, {
    String? localeId,
    Function(String)? onStatus,
  }) {
    _onStatusCallback = onStatus;
    _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
    );
  }

  void stopListening() {
    _speechToText.stop();
    _onStatusCallback = null;
  }

  bool get isListening => _speechToText.isListening;

  /// Parses a spoken sentence into a list of Move objects.
  List<Move> parseSentenceToCombo(String sentence, String language) {
    if (sentence.trim().isEmpty) return [];

    // Normalize string: lowercase, remove punctuation but keep +
    String normalized = sentence.toLowerCase().replaceAll(
      RegExp(r'[^\w\sàâäéèêëîïôöùûüç+]'),
      '',
    );

    // Split into segments based on "next" keywords
    List<String> moveSegments = _splitByKeywords(normalized, _nextKeywords);

    List<Move> combo = [];

    for (String segment in moveSegments) {
      if (segment.trim().isEmpty) continue;

      // Handle combination (simultaneous) within segment
      List<String> comboParts = _splitByKeywords(segment, _comboKeywords);
      if (comboParts.length > 1) {
        List<Move> subMoves = [];
        for (String part in comboParts) {
          Move? m = _parseSingleMove(part, language);
          if (m != null) subMoves.add(m);
        }

        if (subMoves.isNotEmpty) {
          if (subMoves.length == 1) {
            combo.add(subMoves.first);
          } else {
            combo.add(
              Move(
                name: subMoves.map((m) => m.name).join(' + '),
                category: 'simultaneous',
                subMoves: subMoves,
                translations: {
                  'en': subMoves.map((m) => m.name).join(' + '),
                  'fr': subMoves.map((m) => m.getTranslation('fr')).join(' + '),
                },
              ),
            );
          }
        }
        continue;
      }

      Move? move = _parseSingleMove(segment, language);
      if (move != null) {
        combo.add(move);
      }
    }

    return combo;
  }

  Move? _parseSingleMove(String phrase, String language) {
    // Split segment into attack and optional counter
    List<String> attackAndCounter = _splitByKeywords(
      phrase,
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
      language,
    );

    if (matchedAttack != null) {
      String? cName;
      String? cCategory;
      String? cSide;
      String? cLevel;

      // Parse Counter if it exists
      if (counterPhrase.trim().isNotEmpty) {
        ParsedAttributes counterAttrs = _extractAttributes(counterPhrase);
        var matchedCounter = _findBestMatch(
          counterAttrs.remainingText,
          language,
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

      return Move(
        name: matchedAttack.name,
        category: matchedAttack.category,
        translations: matchedAttack.translations,
        side: attackAttrs.side,
        level: _resolveLevel(attackAttrs.level, matchedAttack.restrictedLevel),
        repetitions: 1,
        counterName: cName,
        counterCategory: cCategory,
        counterSide: cSide,
        counterLevel: cLevel,
      );
    }
    return null;
  }

  String _resolveLevel(String requestedLevel, String? restrictedLevel) {
    if (requestedLevel.isEmpty) return '';
    if (requestedLevel == restrictedLevel) {
      return ''; // If they asked for a restricted level, ignore it
    }
    return requestedLevel;
  }

  List<List<MoveOption>> parseSentenceToOptions(
    String sentence,
    String language,
  ) {
    if (sentence.trim().isEmpty) return [];

    String normalized = sentence.toLowerCase().replaceAll(
      RegExp(r'[^\w\sàâäéèêëîïôöùûüç+]'),
      '',
    );

    List<String> moveSegments = _splitByKeywords(normalized, _nextKeywords);
    List<List<MoveOption>> results = [];

    for (String segment in moveSegments) {
      if (segment.trim().isEmpty) continue;

      // For options, we don't automatically create simultaneous moves
      // but we split by combo keywords to give options for each part
      List<String> comboParts = _splitByKeywords(segment, _comboKeywords);

      for (String part in comboParts) {
        List<String> attackAndCounter = _splitByKeywords(
          part,
          _answerKeywords,
          limit: 2,
        );

        String attackPhrase = attackAndCounter[0];
        String counterPhrase = attackAndCounter.length > 1
            ? attackAndCounter[1]
            : '';

        ParsedAttributes attackAttrs = _extractAttributes(attackPhrase);
        var topAttacks = findTopMatches(attackAttrs.remainingText, language);

        if (topAttacks.isEmpty) continue;

        List<MoveOption> segmentOptions = [];

        for (var attackEntry in topAttacks) {
          String? cName;
          String? cCategory;
          String? cSide;
          String? cLevel;

          if (counterPhrase.trim().isNotEmpty) {
            ParsedAttributes counterAttrs = _extractAttributes(counterPhrase);
            var topCounters = findTopMatches(
              counterAttrs.remainingText,
              language,
            );

            if (topCounters.isNotEmpty) {
              var matchedCounter = topCounters.first.entry;
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
                  attackEntry.entry.restrictedLevel,
                );
              }
            }
          }

          segmentOptions.add(
            MoveOption(
              move: Move(
                name: attackEntry.entry.name,
                category: attackEntry.entry.category,
                translations: attackEntry.entry.translations,
                side: attackAttrs.side,
                level: _resolveLevel(
                  attackAttrs.level,
                  attackEntry.entry.restrictedLevel,
                ),
                repetitions: 1,
                counterName: cName,
                counterCategory: cCategory,
                counterSide: cSide,
                counterLevel: cLevel,
              ),
              score: attackEntry.score,
            ),
          );
        }
        results.add(segmentOptions);
      }
    }
    return results;
  }

  List<({GlossaryEntry entry, double score})> findTopMatches(
    String text,
    String language,
  ) {
    if (text.trim().isEmpty) return [];

    List<({GlossaryEntry entry, double score})> scores = [];

    for (var entry in _glossary) {
      List<double> matchScores = [];

      // 1. Check Technical Name (always allowed, e.g. "Jab" even in French mode)
      matchScores.add(
        StringSimilarity.compareTwoStrings(text, entry.name.toLowerCase()),
      );

      // 2. Check Translation for the CURRENT language only
      // This allows saying "Direct du bras avant" if in French mode.
      if (entry.translations[language] != null) {
        matchScores.add(
          StringSimilarity.compareTwoStrings(
            text,
            entry.translations[language]!.toLowerCase(),
          ),
        );
      }

      double maxScore = matchScores.reduce((a, b) => a > b ? a : b);

      if (maxScore > 0.3) {
        scores.add((entry: entry, score: maxScore));
      }
    }

    scores.sort((a, b) => b.score.compareTo(a.score));

    // If best score is very high (> 0.8), return only it
    if (scores.isNotEmpty && scores.first.score > 0.8) {
      return [scores.first];
    }

    // Otherwise return top 3
    return scores.take(3).toList();
  }

  GlossaryEntry? _findBestMatch(String text, String language) {
    final top = findTopMatches(text, language);
    if (top.isNotEmpty) {
      return top.first.entry;
    }
    return null;
  }

  List<String> _splitByKeywords(
    String input,
    List<String> keywords, {
    int? limit,
  }) {
    // Build pattern: use word boundaries for word-only keywords,
    // and just escape for others (like '+')
    String pattern = keywords
        .map((k) {
          final escaped = RegExp.escape(k);
          if (RegExp(r'^\w+$').hasMatch(k)) {
            return r'\b' + escaped + r'\b';
          }
          return escaped;
        })
        .join('|');

    final regExp = RegExp(pattern);

    if (limit == 2) {
      final match = regExp.firstMatch(input);
      if (match != null) {
        return [
          input.substring(0, match.start).trim(),
          input.substring(match.end).trim(),
        ];
      }
      return [input];
    }

    List<String> parts = input.split(regExp);
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
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
