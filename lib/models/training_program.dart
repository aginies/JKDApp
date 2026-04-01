import 'program_day.dart';

class TrainingProgram {
  final int? id;
  final String title;
  final String description;
  final String difficultyLevel; // 'beginner', 'intermediate', 'advanced'
  final int durationDays;
  final bool isSystem;
  final DateTime createdAt;
  final List<ProgramDay> days;

  TrainingProgram({
    this.id,
    required this.title,
    this.description = '',
    this.difficultyLevel = 'beginner',
    required this.durationDays,
    this.isSystem = true,
    DateTime? createdAt,
    this.days = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty_level': difficultyLevel,
      'duration_days': durationDays,
      'is_system': isSystem ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TrainingProgram.fromMap(
    Map<String, dynamic> map, {
    List<ProgramDay>? days,
  }) {
    return TrainingProgram(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled Program',
      description: map['description'] as String? ?? '',
      difficultyLevel: map['difficulty_level'] as String? ?? 'beginner',
      durationDays: map['duration_days'] as int? ?? 1,
      isSystem: (map['is_system'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      days: days ?? [],
    );
  }

  TrainingProgram copyWith({
    int? id,
    String? title,
    String? description,
    String? difficultyLevel,
    int? durationDays,
    bool? isSystem,
    DateTime? createdAt,
    List<ProgramDay>? days,
  }) {
    return TrainingProgram(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      durationDays: durationDays ?? this.durationDays,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      days: days ?? this.days,
    );
  }
}
