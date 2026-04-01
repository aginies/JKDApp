class DayCompletion {
  final int? id;
  final int progressId;
  final int dayNumber;
  final DateTime completedAt;
  final int? durationSeconds;
  final String? notes;

  DayCompletion({
    this.id,
    required this.progressId,
    required this.dayNumber,
    DateTime? completedAt,
    this.durationSeconds,
    this.notes,
  }) : completedAt = completedAt ?? DateTime.now();

  /// Get duration as formatted string (e.g., "15m 30s")
  String get formattedDuration {
    if (durationSeconds == null) return '--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'progress_id': progressId,
      'day_number': dayNumber,
      'completed_at': completedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'notes': notes,
    };
  }

  factory DayCompletion.fromMap(Map<String, dynamic> map) {
    return DayCompletion(
      id: map['id'] as int?,
      progressId: map['progress_id'] as int? ?? 0,
      dayNumber: map['day_number'] as int? ?? 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : DateTime.now(),
      durationSeconds: map['duration_seconds'] as int?,
      notes: map['notes'] as String?,
    );
  }

  DayCompletion copyWith({
    int? id,
    int? progressId,
    int? dayNumber,
    DateTime? completedAt,
    int? durationSeconds,
    String? notes,
  }) {
    return DayCompletion(
      id: id ?? this.id,
      progressId: progressId ?? this.progressId,
      dayNumber: dayNumber ?? this.dayNumber,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
    );
  }
}
