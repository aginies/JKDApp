import 'dart:convert';
import 'training_program.dart';

class UserProgramProgress {
  final int? id;
  final int programId;
  final DateTime startedAt;
  final int currentDay;
  
  /// Array of day numbers that have been fully completed
  final List<int> completedDays; 
  
  /// Map of Day Number -> List of completed series IDs for that day
  /// Key is String because JSON only supports string keys for Maps
  final Map<String, List<int>> completedSeriesPerDay;
  
  final String status; // 'active', 'paused', 'completed', 'abandoned'
  final DateTime? completedAt;

  UserProgramProgress({
    this.id,
    required this.programId,
    DateTime? startedAt,
    this.currentDay = 1,
    this.completedDays = const [],
    this.completedSeriesPerDay = const {},
    this.status = 'active',
    this.completedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  /// Calculate global completion percentage (0.0 to 1.0)
  /// Based on TOTAL series across ALL days.
  double getGlobalPercentage(TrainingProgram program) {
    int totalSeries = 0;
    for (var day in program.days) {
      totalSeries += (day.seriesAssignments?.length ?? day.seriesIds.length);
    }
    if (totalSeries == 0) return 0.0;

    int completedCount = 0;
    completedSeriesPerDay.forEach((dayKey, seriesList) {
      completedCount += seriesList.length;
    });

    return (completedCount / totalSeries).clamp(0.0, 1.0);
  }

  /// Calculate completion percentage for a SPECIFIC day (0.0 to 1.0)
  double getDayPercentage(TrainingProgram program, int dayNumber) {
    final day = program.days.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () => throw Exception('Day $dayNumber not found in program'),
    );
    
    int totalInDay = (day.seriesAssignments?.length ?? day.seriesIds.length);
    if (totalInDay == 0) return 1.0; // Rest day or empty day is 100%

    final completedInDay = completedSeriesPerDay[dayNumber.toString()]?.length ?? 0;
    return (completedInDay / totalInDay).clamp(0.0, 1.0);
  }

  bool isSeriesCompleted(int dayNumber, int seriesId) {
    final list = completedSeriesPerDay[dayNumber.toString()];
    return list != null && list.contains(seriesId);
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
        if (streak > maxStreak) maxStreak = streak;
      } else {
        streak = 1;
      }
    }
    if (sortedDays.last == currentDay - 1) return maxStreak;
    return 0;
  }

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
      'completed_series_json': json.encode(completedSeriesPerDay),
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory UserProgramProgress.fromMap(Map<String, dynamic> map) {
    List<int> parsedCompletedDays = [];
    if (map['completed_days'] != null) {
      try {
        final decoded = json.decode(map['completed_days'] as String);
        if (decoded is List) {
          parsedCompletedDays = decoded.map((e) => e as int).toList();
        }
      } catch (_) {}
    }

    Map<String, List<int>> parsedCompletedSeries = {};
    // Try new column name first, fallback to old one for migration safety
    final seriesJson = map['completed_series_json'] ?? map['todays_completed_series_ids'];
    if (seriesJson != null) {
      try {
        final decoded = json.decode(seriesJson as String);
        if (decoded is Map) {
          parsedCompletedSeries = decoded.map((key, value) {
            if (value is List) {
              return MapEntry(key.toString(), value.map((e) => e as int).toList());
            } else if (value is int) {
              // Handle migration from old 'todays_completed_series_ids' which was Map<int, int>
              // We'll put it in the 'currentDay' slot
              return MapEntry(map['current_day'].toString(), [key as int]);
            }
            return MapEntry(key.toString(), <int>[]);
          });
        }
      } catch (_) {}
    }

    return UserProgramProgress(
      id: map['id'] as int?,
      programId: map['program_id'] as int? ?? 0,
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : DateTime.now(),
      currentDay: map['current_day'] as int? ?? 1,
      completedDays: parsedCompletedDays,
      completedSeriesPerDay: parsedCompletedSeries,
      status: map['status'] as String? ?? 'active',
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  UserProgramProgress copyWith({
    int? id,
    int? programId,
    DateTime? startedAt,
    int? currentDay,
    List<int>? completedDays,
    Map<String, List<int>>? completedSeriesPerDay,
    String? status,
    DateTime? completedAt,
  }) {
    return UserProgramProgress(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      startedAt: startedAt ?? this.startedAt,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays ?? this.completedDays,
      completedSeriesPerDay:
          completedSeriesPerDay ?? this.completedSeriesPerDay,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
