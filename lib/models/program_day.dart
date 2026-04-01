import 'dart:convert';
import 'package:flutter/foundation.dart';

class SeriesAssignment {
  final int seriesId;
  final String? itemRange; // e.g., "1-4" or null for all items

  SeriesAssignment({
    required this.seriesId,
    this.itemRange,
  });

  Map<String, dynamic> toMap() {
    return {
      'series_id': seriesId,
      'item_range': itemRange,
    };
  }

  factory SeriesAssignment.fromMap(Map<String, dynamic> map) {
    return SeriesAssignment(
      seriesId: map['series_id'] as int,
      itemRange: map['item_range'] as String?,
    );
  }
}

class ProgramDay {
  final int? id;
  final int programId;
  final int dayNumber;
  final List<int> seriesIds; // Deprecated: kept for backward compatibility
  final List<SeriesAssignment>? seriesAssignments; // New: detailed assignments with ranges
  final String? notes; // Optional guidance for the day
  final bool isRestDay;

  ProgramDay({
    this.id,
    required this.programId,
    required this.dayNumber,
    List<int>? seriesIds,
    this.seriesAssignments,
    this.notes,
    this.isRestDay = false,
  }) : seriesIds = seriesIds ?? (seriesAssignments?.map((a) => a.seriesId).toList() ?? []);

  Map<String, dynamic> toMap() {
    final assignmentsJson = seriesAssignments != null
        ? json.encode(seriesAssignments!.map((a) => a.toMap()).toList())
        : null;

    // Debug: Log what we're saving
    if (seriesAssignments != null) {
      debugPrint('DEBUG ProgramDay.toMap: Day $dayNumber has ${seriesAssignments!.length} assignments');
      for (var a in seriesAssignments!) {
        print('  - seriesId: ${a.seriesId}, itemRange: ${a.itemRange}');
      }
      print('  - JSON: $assignmentsJson');
    }

    return {
      'id': id,
      'program_id': programId,
      'day_number': dayNumber,
      'series_ids': json.encode(seriesIds),
      'series_assignments': assignmentsJson,
      'notes': notes,
      'is_rest_day': isRestDay ? 1 : 0,
    };
  }

  factory ProgramDay.fromMap(Map<String, dynamic> map) {
    debugPrint('DEBUG ProgramDay.fromMap: Loading day ${map['day_number']}');
    print('  - Raw series_assignments: ${map['series_assignments']}');

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

    List<SeriesAssignment>? parsedAssignments;
    if (map['series_assignments'] != null) {
      try {
        final decoded = json.decode(map['series_assignments'] as String);
        print('  - Decoded series_assignments: $decoded');
        if (decoded is List) {
          parsedAssignments = decoded
              .map((e) => SeriesAssignment.fromMap(e as Map<String, dynamic>))
              .toList();
          print('  - Parsed ${parsedAssignments.length} assignments');
          for (var a in parsedAssignments) {
            print('    * seriesId: ${a.seriesId}, itemRange: ${a.itemRange}');
          }
        }
      } catch (e) {
        print('  - Error parsing series_assignments: $e');
        // If parsing fails, fall back to creating assignments from seriesIds
        parsedAssignments = null;
      }
    } else {
      print('  - series_assignments is null, creating from seriesIds');
    }

    // If no assignments but we have seriesIds, create basic assignments
    if (parsedAssignments == null && parsedSeriesIds.isNotEmpty) {
      parsedAssignments = parsedSeriesIds
          .map((id) => SeriesAssignment(seriesId: id))
          .toList();
      print('  - Created ${parsedAssignments.length} basic assignments from seriesIds');
    }

    return ProgramDay(
      id: map['id'] as int?,
      programId: map['program_id'] as int? ?? 0,
      dayNumber: map['day_number'] as int? ?? 1,
      seriesIds: parsedSeriesIds,
      seriesAssignments: parsedAssignments,
      notes: map['notes'] as String?,
      isRestDay: (map['is_rest_day'] as int? ?? 0) == 1,
    );
  }

  ProgramDay copyWith({
    int? id,
    int? programId,
    int? dayNumber,
    List<int>? seriesIds,
    List<SeriesAssignment>? seriesAssignments,
    String? notes,
    bool? isRestDay,
  }) {
    return ProgramDay(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      dayNumber: dayNumber ?? this.dayNumber,
      seriesIds: seriesIds,
      seriesAssignments: seriesAssignments ?? this.seriesAssignments,
      notes: notes ?? this.notes,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }
}
