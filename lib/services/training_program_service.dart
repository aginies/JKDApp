import '../models/training_program.dart';
import '../models/program_day.dart';
import '../models/user_program_progress.dart';
import '../models/series.dart';
import 'database_service.dart';
import 'logging_service.dart';

/// Service layer for training program operations
/// Provides business logic on top of database operations
class TrainingProgramService {
  final DatabaseService _db = DatabaseService();

  /// Get all available training programs
  Future<List<TrainingProgram>> getAllPrograms() async {
    LoggingService.log('TrainingProgramService: Getting all programs');
    return await _db.getAllPrograms();
  }

  /// Get a specific program by ID
  Future<TrainingProgram?> getProgramById(int id) async {
    return await _db.getProgramById(id);
  }

  /// Get program with enriched series information for a specific day
  Future<Map<String, dynamic>?> getProgramDayDetails(
    int programId,
    int dayNumber,
  ) async {
    final program = await _db.getProgramById(programId);
    if (program == null) return null;

    final day = program.days.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () =>
          ProgramDay(programId: programId, dayNumber: dayNumber, seriesIds: []),
    );

    // Get full series objects
    final List<JkdSeries> series = [];
    for (final seriesId in day.seriesIds) {
      final allSeries = await _db.getAllSeries();
      final matchingSeries = allSeries.firstWhere(
        (s) => s.id == seriesId,
        orElse: () => JkdSeries(
          id: seriesId,
          title: 'Unknown Series',
          category: 'Other',
          moves: [],
        ),
      );
      series.add(matchingSeries);
    }

    return {'program': program, 'day': day, 'series': series};
  }

  /// Start a new program
  /// Returns the progress ID
  /// Throws if user already has an active program
  Future<int> startProgram(int programId) async {
    // Check if user already has an active program
    final activeProgress = await _db.getActiveProgress();
    if (activeProgress != null) {
      throw Exception(
        'You already have an active program. Please abandon it before starting a new one.',
      );
    }

    LoggingService.log('TrainingProgramService: Starting program $programId');
    return await _db.startProgram(programId);
  }

  /// Get currently active program progress (if any)
  Future<UserProgramProgress?> getActiveProgress() async {
    return await _db.getActiveProgress();
  }

  /// Get user's progress for a specific program
  Future<UserProgramProgress?> getUserProgress(int programId) async {
    return await _db.getUserProgress(programId);
  }

  /// Get all user progress records (for history view)
  Future<List<UserProgramProgress>> getAllUserProgress() async {
    return await _db.getAllUserProgress();
  }

  /// Mark a day as complete
  /// Automatically advances to next day and handles program completion
  Future<void> markDayComplete(
    int progressId,
    int dayNumber, {
    int? durationSeconds,
    String? notes,
  }) async {
    LoggingService.log(
      'TrainingProgramService: Marking day $dayNumber complete for progress $progressId',
    );
    await _db.markDayComplete(
      progressId,
      dayNumber,
      durationSeconds: durationSeconds,
      notes: notes,
    );
  }

  /// Skip a day without marking it complete
  /// Just advances the current day pointer
  Future<void> skipDay(int progressId, int dayNumber) async {
    LoggingService.log(
      'TrainingProgramService: Skipping day $dayNumber for progress $progressId',
    );
    await _db.skipDay(progressId, dayNumber);
  }

  /// Pause a program
  Future<void> pauseProgram(int progressId) async {
    LoggingService.log('TrainingProgramService: Pausing progress $progressId');
    await _db.pauseProgram(progressId);
  }

  /// Resume a paused program
  Future<void> resumeProgram(int progressId) async {
    LoggingService.log('TrainingProgramService: Resuming progress $progressId');
    await _db.resumeProgram(progressId);
  }

  /// Abandon a program
  Future<void> abandonProgram(int progressId) async {
    LoggingService.log(
      'TrainingProgramService: Abandoning progress $progressId',
    );
    await _db.abandonProgram(progressId);
  }

  /// Get completion statistics for a progress
  Future<Map<String, dynamic>> getProgressStats(int progressId) async {
    final progress = await _db.getAllUserProgress();
    final matchingProgress = progress.firstWhere(
      (p) => p.id == progressId,
      orElse: () => throw Exception('Progress not found'),
    );

    final program = await _db.getProgramById(matchingProgress.programId);
    if (program == null) {
      throw Exception('Program not found');
    }

    final completionPercentage = matchingProgress.getGlobalPercentage(program);
    final currentStreak = matchingProgress.getCurrentStreak();
    final completedCount = matchingProgress.completedDays.length;
    final remainingDays = program.durationDays - completedCount;

    return {
      'completion_percentage': completionPercentage,
      'current_streak': currentStreak,
      'completed_count': completedCount,
      'total_days': program.durationDays,
      'remaining_days': remainingDays,
      'is_completed': matchingProgress.isCompleted,
    };
  }

  /// Check if a specific day is completed
  Future<bool> isDayCompleted(int progressId, int dayNumber) async {
    final progress = await _db.getAllUserProgress();
    final matchingProgress = progress.firstWhere(
      (p) => p.id == progressId,
      orElse: () => throw Exception('Progress not found'),
    );

    return matchingProgress.completedDays.contains(dayNumber);
  }

  /// Get today's assignment for active program
  /// Returns null if no active program
  Future<Map<String, dynamic>?> getTodaysAssignment() async {
    final activeProgress = await _db.getActiveProgress();
    if (activeProgress == null) return null;

    final program = await _db.getProgramById(activeProgress.programId);
    if (program == null) return null;

    final currentDay = program.days.firstWhere(
      (d) => d.dayNumber == activeProgress.currentDay,
      orElse: () => ProgramDay(
        programId: program.id!,
        dayNumber: activeProgress.currentDay,
        seriesIds: [],
      ),
    );

    // Get series objects
    final List<JkdSeries> series = [];
    final allSeries = await _db.getAllSeries();

    // Use seriesAssignments as the primary source if available
    final idsToLoad =
        currentDay.seriesAssignments != null &&
            currentDay.seriesAssignments!.isNotEmpty
        ? currentDay.seriesAssignments!.map((a) => a.seriesId).toList()
        : currentDay.seriesIds;

    for (final seriesId in idsToLoad) {
      final matchingSeries = allSeries.firstWhere(
        (s) => s.id == seriesId,
        orElse: () => JkdSeries(
          id: seriesId,
          title: 'Unknown Series',
          category: 'Other',
          moves: [],
        ),
      );
      series.add(matchingSeries);
    }

    return {
      'progress': activeProgress,
      'program': program,
      'current_day': currentDay,
      'series': series,
    };
  }

  /// Record series completion and auto-mark day complete if all series done
  /// Returns completion info or null if not part of active program
  Future<Map<String, dynamic>?> recordSeriesCompletion(int seriesId) async {
    LoggingService.log(
      'TrainingProgramService: Recording completion of series $seriesId',
    );
    return await _db.recordSeriesCompletion(seriesId);
  }
}
