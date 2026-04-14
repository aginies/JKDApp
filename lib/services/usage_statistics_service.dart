import 'package:flutter/foundation.dart';
import '../models/move.dart';
import '../models/series.dart';

class UsageStatisticsService {
  static final UsageStatisticsService _instance =
      UsageStatisticsService._internal();
  factory UsageStatisticsService() => _instance;
  UsageStatisticsService._internal();

  Map<String, int> _usageCounts = {};
  bool _isInitialized = false;

  Map<String, int> get usageCounts => _usageCounts;

  Future<void> init(List<JkdSeries> allSeries) async {
    _usageCounts = {};
    for (var series in allSeries) {
      for (var move in series.moves) {
        _countMove(move);
      }
    }
    _isInitialized = true;
    debugPrint(
      'UsageStatisticsService initialized with ${_usageCounts.length} unique moves',
    );
  }

  void _countMove(Move move) {
    // Count the main move
    if (move.name.isNotEmpty && !move.name.startsWith('Combo:')) {
      _incrementCount(move.name);
    }

    // Count the counter move if present
    if (move.counterName != null && move.counterName!.isNotEmpty) {
      _incrementCount(move.counterName!);
    }

    // Count sub-moves (combos)
    for (var subMove in move.subMoves) {
      _countMove(subMove);
    }

    // Count chain items
    for (var chainMove in move.chain) {
      _countMove(chainMove);
    }
  }

  void _incrementCount(String name) {
    _usageCounts[name] = (_usageCounts[name] ?? 0) + 1;
  }

  int getCount(String name) {
    return _usageCounts[name] ?? 0;
  }

  void updateWithNewSeries(JkdSeries series) {
    if (!_isInitialized) return;
    for (var move in series.moves) {
      _countMove(move);
    }
  }

  /// Recalculate everything (e.g. after a series is deleted or heavily modified)
  Future<void> refresh(List<JkdSeries> allSeries) async {
    await init(allSeries);
  }

  /// Record a generic training activity (e.g. Warmup)
  void recordActivity(String activityName) {
    _incrementCount(activityName);
  }
}
