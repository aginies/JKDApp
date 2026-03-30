import 'dart:convert';
import 'package:uuid/uuid.dart';

class Move {
  final int? id;
  final int? glossaryId; // NEW: Track the source glossary item
  final String uKey;
  final String name;
  final String category; // 'punch', 'kick', 'packs', 'trapping', 'special'
  final String side;
  final String level;
  final bool isFeint;
  final String? specialAction;
  final Map<String, String> translations;
  final int repetitions;

  final String? counterName;
  final String? counterSide;
  final String? counterLevel;
  final String? counterSpecialAction;
  final String? counterCategory;

  final List<Move> subMoves;

  Move({
    this.id,
    this.glossaryId,
    String? uKey,
    required this.name,
    this.category = '',
    this.side = '',
    this.level = '',
    this.isFeint = false,
    this.specialAction,
    this.translations = const {},
    this.repetitions = 1,
    this.counterName,
    this.counterSide,
    this.counterLevel,
    this.counterSpecialAction,
    this.counterCategory,
    this.subMoves = const [],
  }) : uKey = uKey ?? const Uuid().v4();

  bool get isCombo => subMoves.isNotEmpty;

  String getTranslation(String lang) {
    if (isCombo) {
      return subMoves.map((m) => m.getTranslation(lang)).join(' + ');
    }
    return translations[lang] ?? translations['en'] ?? translations['fr'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'glossary_id': glossaryId,
      'name': name,
      'category': category,
      'side': side,
      'level': level,
      'is_feint': isFeint ? 1 : 0,
      'special_action': specialAction,
      'translations': json.encode(translations),
      'repetitions': repetitions,
      'counter_name': counterName,
      'counter_side': counterSide,
      'counter_level': counterLevel,
      'counter_special_action': counterSpecialAction,
      'counter_category': counterCategory,
      'sub_moves_json': subMoves.isNotEmpty ? json.encode(subMoves.map((m) => m.toMap()).toList()) : null,
    };
  }

  factory Move.fromMap(Map<String, dynamic> map) {
    Map<String, String> trans = {};
    if (map['translations'] != null) {
      try {
        final decoded = json.decode(map['translations']);
        if (decoded is Map) {
          trans = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    List<Move> subs = [];
    if (map['sub_moves_json'] != null) {
      try {
        final decoded = json.decode(map['sub_moves_json']);
        if (decoded is List) {
          subs = decoded.map((m) => Move.fromMap(Map<String, dynamic>.from(m))).toList();
        }
      } catch (_) {}
    }

    return Move(
      id: map['id'],
      glossaryId: map['glossary_id'],
      uKey: map['uKey'] ?? (map['id']?.toString() ?? const Uuid().v4()),
      name: map['name'] ?? (subs.isNotEmpty ? 'Combo' : ''),
      category: map['category'] ?? '',
      side: map['side'] ?? '',
      level: map['level'] ?? '',
      isFeint: (map['is_feint'] ?? 0) == 1,
      specialAction: map['special_action'],
      translations: trans,
      repetitions: map['repetitions'] ?? 1,
      counterName: map['counter_name'],
      counterSide: map['counter_side'],
      counterLevel: map['counter_level'],
      counterSpecialAction: map['counter_special_action'],
      counterCategory: map['counter_category'],
      subMoves: subs,
    );
  }

  Move copyWith({
    int? id,
    int? glossaryId,
    String? uKey,
    String? name,
    String? category,
    String? side,
    String? level,
    bool? isFeint,
    String? specialAction,
    Map<String, String>? translations,
    int? repetitions,
    String? counterName,
    String? counterSide,
    String? counterLevel,
    String? counterSpecialAction,
    String? counterCategory,
    List<Move>? subMoves,
  }) {
    return Move(
      id: id ?? this.id,
      glossaryId: glossaryId ?? this.glossaryId,
      uKey: uKey ?? this.uKey,
      name: name ?? this.name,
      category: category ?? this.category,
      side: side ?? this.side,
      level: level ?? this.level,
      isFeint: isFeint ?? this.isFeint,
      specialAction: specialAction ?? this.specialAction,
      translations: translations ?? this.translations,
      repetitions: repetitions ?? this.repetitions,
      counterName: counterName ?? this.counterName,
      counterSide: counterSide ?? this.counterSide,
      counterLevel: counterLevel ?? this.counterLevel,
      counterSpecialAction: counterSpecialAction ?? this.counterSpecialAction,
      counterCategory: counterCategory ?? this.counterCategory,
      subMoves: subMoves ?? this.subMoves,
    );
  }
}
