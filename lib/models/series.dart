import 'move.dart';

class JkdSeries {
  final int? id;
  final String title;
  final String category; // 'JKD' or 'Jun Fan Kungh Fu'
  final String type; // 'Attack' or 'Defense'
  final String? attackMethod; // 'PIA', 'SDA', 'SIA', 'BTAA', 'ABD', 'ABC'
  final List<Move> moves;
  final String notes;
  final bool isSystem;
  final bool isFromCloud;

  JkdSeries({
    this.id,
    required this.title,
    this.category = 'JKD',
    this.type = 'Attack',
    this.attackMethod,
    this.moves = const [],
    this.notes = '',
    this.isSystem = false,
    this.isFromCloud = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'type': type,
      'attack_method': attackMethod,
      'notes': notes,
      'is_system': isSystem ? 1 : 0,
      'is_from_cloud': isFromCloud ? 1 : 0,
    };
  }

  factory JkdSeries.fromMap(Map<String, dynamic> map, List<Move> moves) {
    return JkdSeries(
      id: map['id'],
      title: map['title'],
      category: map['category'] ?? 'JKD',
      type: map['type'] ?? 'Attack',
      attackMethod: map['attack_method'],
      notes: map['notes'] ?? '',
      isSystem: (map['is_system'] ?? 0) == 1,
      isFromCloud: (map['is_from_cloud'] ?? 0) == 1,
      moves: moves,
    );
  }

  JkdSeries copyWith({
    int? id,
    String? title,
    String? category,
    String? type,
    String? attackMethod,
    List<Move>? moves,
    String? notes,
    bool? isSystem,
    bool? isFromCloud,
  }) {
    return JkdSeries(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      attackMethod: attackMethod ?? this.attackMethod,
      moves: moves ?? this.moves,
      notes: notes ?? this.notes,
      isSystem: isSystem ?? this.isSystem,
      isFromCloud: isFromCloud ?? this.isFromCloud,
    );
  }
}
