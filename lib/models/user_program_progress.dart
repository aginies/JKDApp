import 'dart:convert';

class UserProgramProgress {
  final int? id;
  final int programId;
  final DateTime startedAt;
  final int currentDay;
  final List<int> completedDays; // Array of day numbers that have been completed
  final String status; // 'active', 'paused', 'completed', 'abandoned'
  final DateTime? completedAt;

  // Cached values for performance
  final int? _totalDays;

  UserProgramProgress({
    this.id,
    required this.programId,
    DateTime? startedAt,
    this.currentDay = 1,
    this.completedDays = const [],
    this.status = 'active',
    this.completedAt,
    int? totalDays,
  })  : startedAt = startedAt ?? DateTime.now(),
        _totalDays = totalDays;

  /// Calculate completion percentage (0.0 to 1.0)
  double getCompletionPercentage(int totalDays) {
    if (totalDays == 0) return 0.0;
    return completedDays.length / totalDays;
  }

  /// Calculate current streak of consecutive completed days
  int getStreakDays() {
    if (completedDays.isEmpty) return 0;

    final sortedDays = List<int>.from(completedDays)..sort();
    int streak = 1;
    int maxStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      if (sortedDays[i] == sortedDays[i - 1] + 1) {
        streak++;
        if (streak > maxStreak) {
          maxStreak = streak;
        }
      } else {
        streak = 1;
      }
    }

    // Check if the streak continues to the current day
    if (sortedDays.last == currentDay - 1) {
      return maxStreak;
    }

    return 0; // Streak broken if latest completion is not adjacent to current day
  }

  /// Get current streak counting backwards from most recent completion
  int getCurrentStreak() {
    if (completedDays.isEmpty) return 0;

    final sortedDays = List<int>.from(completedDays)..sort();
    int streak = 1;

    for (int i = sortedDays.length - 2; i >= 0; i--) {
      if (sortedDays[i] == sortedDays[i + 1] - 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPaused => status == 'paused';
  bool get isAbandoned => status == 'abandoned';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'program_id': programId,
      'started_at': startedAt.toIso8601String(),
      'current_day': currentDay,
      'completed_days': json.encode(completedDays),
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory UserProgramProgress.fromMap(Map<String, dynamic> map, {int? totalDays}) {
    List<int> parsedCompletedDays = [];
    if (map['completed_days'] != null) {
      try {
        final decoded = json.decode(map['completed_days'] as String);
        if (decoded is List) {
          parsedCompletedDays = decoded.map((e) => e as int).toList();
        }
      } catch (e) {
        parsedCompletedDays = [];
      }
    }

    return UserProgramProgress(
      id: map['id'] as int?,
      programId: map['program_id'] as int? ?? 0,
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : DateTime.now(),
      currentDay: map['current_day'] as int? ?? 1,
      completedDays: parsedCompletedDays,
      status: map['status'] as String? ?? 'active',
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      totalDays: totalDays,
    );
  }

  UserProgramProgress copyWith({
    int? id,
    int? programId,
    DateTime? startedAt,
    int? currentDay,
    List<int>? completedDays,
    String? status,
    DateTime? completedAt,
    int? totalDays,
  }) {
    return UserProgramProgress(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      startedAt: startedAt ?? this.startedAt,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays ?? this.completedDays,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      totalDays: totalDays ?? _totalDays,
    );
  }
}
