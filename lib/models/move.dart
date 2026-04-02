import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../utils/translation_utils.dart';

class Move {
  final int? id;
  final int? glossaryId; // Track the source glossary item for hit
  final int? counterGlossaryId; // Track the source glossary item for counter
  final String uKey;
  final String name;
  final String category; // 'punch', 'kick', 'packs', 'trapping', 'move'
  final String side;
  final String level;
  final String? subLetter;
  final bool isFeint;
  final String? specialAction;
  final Map<String, String> translations;
  final int repetitions;

  final String? counterName;
  final String? counterSide;
  final String? counterLevel;
  final String? counterSpecialAction;
  final String? counterCategory;
  final Map<String, String> counterTranslations;

  final List<Move> subMoves;
  final List<Move> chain;

  Move({
    this.id,
    this.glossaryId,
    this.counterGlossaryId,
    String? uKey,
    required this.name,
    this.category = '',
    this.side = '',
    this.level = '',
    this.subLetter,
    this.isFeint = false,
    this.specialAction,
    this.translations = const {},
    this.repetitions = 1,
    this.counterName,
    this.counterSide,
    this.counterLevel,
    this.counterSpecialAction,
    this.counterCategory,
    this.counterTranslations = const {},
    this.subMoves = const [],
    this.chain = const [],
  }) : uKey = uKey ?? const Uuid().v4();

  bool get isCombo => subMoves.isNotEmpty;
  bool get isChain => chain.isNotEmpty;

  String getTranslation(String lang) {
    if (isChain) {
      return chain.map((m) => m.getTranslation(lang)).join(' -> ');
    }
    if (isCombo) {
      return subMoves.map((m) => m.getTranslation(lang)).join(' + ');
    }
    return translations[lang] ?? translations['en'] ?? translations['fr'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'glossary_id': glossaryId,
      'counter_glossary_id': counterGlossaryId,
      'name': name,
      'category': category,
      'side': side,
      'level': level,
      'sub_letter': subLetter,
      'is_feint': isFeint ? 1 : 0,
      'special_action': specialAction,
      'translations': json.encode(translations),
      'repetitions': repetitions,
      'counter_name': counterName,
      'counter_side': counterSide,
      'counter_level': counterLevel,
      'counter_special_action': counterSpecialAction,
      'counter_category': counterCategory,
      'counter_translations': json.encode(counterTranslations),
      'sub_moves_json': subMoves.isNotEmpty
          ? json.encode(subMoves.map((m) => m.toMap()).toList())
          : null,
      'chain_json': chain.isNotEmpty
          ? json.encode(chain.map((m) => m.toMap()).toList())
          : null,
    };
  }

  factory Move.fromMap(Map<String, dynamic> map) {
    final trans = TranslationUtils.parseTranslations(map['translations']);
    final counterTrans = TranslationUtils.parseTranslations(
      map['counter_translations'],
    );

    List<Move> subs = [];
    if (map['sub_moves_json'] != null) {
      try {
        final decoded = json.decode(map['sub_moves_json']);
        if (decoded is List) {
          subs = decoded
              .map((m) => Move.fromMap(Map<String, dynamic>.from(m)))
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing sub_moves_json: $e');
      }
    }

    List<Move> chainItems = [];
    if (map['chain_json'] != null) {
      try {
        final decoded = json.decode(map['chain_json']);
        if (decoded is List) {
          chainItems = decoded
              .map((m) => Move.fromMap(Map<String, dynamic>.from(m)))
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing chain_json: $e');
      }
    }

    return Move(
      id: map['id'],
      glossaryId: map['glossary_id'],
      counterGlossaryId: map['counter_glossary_id'],
      uKey: map['uKey'] ?? (map['id']?.toString() ?? const Uuid().v4()),
      name:
          map['name'] ??
          (subs.isNotEmpty ? 'Combo' : (chainItems.isNotEmpty ? 'Chain' : '')),
      category: map['category'] ?? (chainItems.isNotEmpty ? 'chain' : ''),
      side: map['side'] ?? '',
      level: map['level'] ?? '',
      subLetter: map['sub_letter'],
      isFeint: (map['is_feint'] ?? 0) == 1,
      specialAction: map['special_action'],
      translations: trans,
      repetitions: map['repetitions'] ?? 1,
      counterName: map['counter_name'],
      counterSide: map['counter_side'],
      counterLevel: map['counter_level'],
      counterSpecialAction: map['counter_special_action'],
      counterCategory: map['counter_category'],
      counterTranslations: counterTrans,
      subMoves: subs,
      chain: chainItems,
    );
  }

  Move copyWith({
    int? id,
    int? glossaryId,
    int? counterGlossaryId,
    String? uKey,
    String? name,
    String? category,
    String? side,
    String? level,
    Object? subLetter = _sentinel,
    bool? isFeint,
    String? specialAction,
    Map<String, String>? translations,
    int? repetitions,
    String? counterName,
    String? counterSide,
    String? counterLevel,
    String? counterSpecialAction,
    String? counterCategory,
    Map<String, String>? counterTranslations,
    List<Move>? subMoves,
    List<Move>? chain,
  }) {
    return Move(
      id: id ?? this.id,
      glossaryId: glossaryId ?? this.glossaryId,
      counterGlossaryId: counterGlossaryId ?? this.counterGlossaryId,
      uKey: uKey ?? this.uKey,
      name: name ?? this.name,
      category: category ?? this.category,
      side: side ?? this.side,
      level: level ?? this.level,
      subLetter: subLetter == _sentinel
          ? this.subLetter
          : (subLetter as String?),
      isFeint: isFeint ?? this.isFeint,
      specialAction: specialAction ?? this.specialAction,
      translations: translations ?? this.translations,
      repetitions: repetitions ?? this.repetitions,
      counterName: counterName ?? this.counterName,
      counterSide: counterSide ?? this.counterSide,
      counterLevel: counterLevel ?? this.counterLevel,
      counterSpecialAction: counterSpecialAction ?? this.counterSpecialAction,
      counterCategory: counterCategory ?? this.counterCategory,
      counterTranslations: counterTranslations ?? this.counterTranslations,
      subMoves: subMoves ?? this.subMoves,
      chain: chain ?? this.chain,
    );
  }

  static const _sentinel = Object();
}
