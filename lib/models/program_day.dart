import 'dart:convert';

class ProgramDay {
  final int? id;
  final int programId;
  final int dayNumber;
  final List<int> seriesIds; // IDs of series to practice on this day
  final String? notes; // Optional guidance for the day
  final bool isRestDay;

  ProgramDay({
    this.id,
    required this.programId,
    required this.dayNumber,
    required this.seriesIds,
    this.notes,
    this.isRestDay = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'program_id': programId,
      'day_number': dayNumber,
      'series_ids': json.encode(seriesIds),
      'notes': notes,
      'is_rest_day': isRestDay ? 1 : 0,
    };
  }

  factory ProgramDay.fromMap(Map<String, dynamic> map) {
    List<int> parsedSeriesIds = [];
    if (map['series_ids'] != null) {
      try {
        final decoded = json.decode(map['series_ids'] as String);
        if (decoded is List) {
          parsedSeriesIds = decoded.map((e) => e as int).toList();
        }
      } catch (e) {
        // If parsing fails, return empty list
        parsedSeriesIds = [];
      }
    }

    return ProgramDay(
      id: map['id'] as int?,
      programId: map['program_id'] as int? ?? 0,
      dayNumber: map['day_number'] as int? ?? 1,
      seriesIds: parsedSeriesIds,
      notes: map['notes'] as String?,
      isRestDay: (map['is_rest_day'] as int? ?? 0) == 1,
    );
  }

  ProgramDay copyWith({
    int? id,
    int? programId,
    int? dayNumber,
    List<int>? seriesIds,
    String? notes,
    bool? isRestDay,
  }) {
    return ProgramDay(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      dayNumber: dayNumber ?? this.dayNumber,
      seriesIds: seriesIds ?? this.seriesIds,
      notes: notes ?? this.notes,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }
}
