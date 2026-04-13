import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/series.dart';
import '../models/move.dart';
import '../models/search_result.dart';
import '../models/user_program_progress.dart';
import '../models/training_program.dart';
import '../models/custom_kali_angle.dart';
import '../models/kali_angle_elements.dart';
import '../services/database_service.dart';
import '../services/garmin_service.dart';
import '../services/localization_service.dart';
import '../services/logging_service.dart';
import '../services/training_program_service.dart';
import '../services/usage_statistics_service.dart';
import '../services/custom_angles_service.dart';
import '../utils/translation_utils.dart';

enum JkdThemeMode { system, light, dark, amoled }

class SeriesProvider with ChangeNotifier {
  static const List<String> _seriesFiles = [
    'assets/jkd-series-punches.json',
    'assets/jkd-series-3-counts.json',
    'assets/jkd-series-4-counts.json',
    'assets/jkd-series-5-counts.json',
    'assets/jkd-series-6-counts.json',
    'assets/jkd-series-contre-jab-cross.json',
    'assets/jkd-series-contre-jab-hook.json',
    'assets/jkd-series-kicks.json',
    'assets/jkd-series-loyda-jfk.json',
    'assets/jkd-series-trapping-base.json',
    'assets/jkd-series-footwork.json',
    'assets/jkd-series-abc.json',
    'assets/jkd-series-ping-chui-lop-sao-gwa-chui.json',
    'assets/jkd-series-sinawali-series.json',
    'assets/jkd-series-hou-ou-tek.json',
    'assets/jkd-series-7-d-placements-kali.json',
  ];

  List<JkdSeries> _series = [];
  List<TrainingProgram> _allPrograms = [];
  final Map<String, List<JkdSeries>> _filteredCache = {};
  List<Map<String, dynamic>> _glossary = [];
  String _language = 'en';
  JkdThemeMode _themeMode = JkdThemeMode.system;
  Color _themeColor = Colors.blue;
  bool _voiceEnabled = false;
  bool _garminCoachingTtsEnabled = false;
  bool _garminConnected = false;
  bool _garminCoachingVoiceActive = false;
  final GarminService _garminService = GarminService();
  bool _developerMode = false;
  bool _manageSeriesMode = false;
  bool _showTranslation = true;
  String? _projectPath;
  double _speechRate = 0.50;
  double _fontSizeScale = 1.0;
  String _searchQuery = '';
  String? _galleryPath;
  bool _isLoading = false;
  int _autoAdvanceSec = 0; // 0 = manual, >0 = seconds
  String _contributorName = '';
  UserProgramProgress? _activeProgram;
  TrainingProgram? _activeProgramDetails;
  List<CustomKaliAngle> _customAngles = [];

  final DatabaseService _dbService = DatabaseService();
  final TrainingProgramService _programService = TrainingProgramService();
  final UsageStatisticsService _usageService = UsageStatisticsService();
  final CustomAnglesService _customAnglesService = CustomAnglesService();

  List<JkdSeries> get series => _series;
  List<TrainingProgram> get allPrograms => _allPrograms;
  UserProgramProgress? get activeProgram => _activeProgram;
  TrainingProgram? get activeProgramDetails => _activeProgramDetails;
  List<Map<String, dynamic>> get glossary => _glossary;
  List<CustomKaliAngle> get customAngles => _customAngles;
  String get language => _language;
  JkdThemeMode get themeMode => _themeMode;
  Color get themeColor => _themeColor;
  bool get voiceEnabled => _voiceEnabled;
  bool get garminCoachingTtsEnabled => _garminCoachingTtsEnabled;
  bool get garminConnected => _garminConnected;
  bool get garminCoachingVoiceActive => _garminCoachingVoiceActive;
  bool get developerMode => _developerMode;
  bool get manageSeriesMode => _manageSeriesMode;
  bool get showTranslation => _showTranslation;
  String? get projectPath => _projectPath;
  double get speechRate => _speechRate;
  double get fontSizeScale => _fontSizeScale;
  String get searchQuery => _searchQuery;
  String? get galleryPath => _galleryPath;
  bool get isLoading => _isLoading;
  int get autoAdvanceSec => _autoAdvanceSec;
  String get contributorName => _contributorName;

  SeriesProvider() {
    // Run initialization in a microtask to allow the constructor to return immediately
    // and not block the main thread during app startup.
    scheduleMicrotask(() => _init());
  }

  @visibleForTesting
  SeriesProvider.empty();

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    LoggingService.info('Initializing SeriesProvider...');
    final prefs = await _dbService.getSettings();
    await _loadSettings(prefs);

    _garminService.initialize(
      ttsEnabled: _garminCoachingTtsEnabled,
      speechRate: _speechRate,
      language: _language,
    );
    _garminService.onConnectionChanged.listen((v) {
      _garminConnected = v;
      notifyListeners();
    });
    _garminService.onCoachingVoiceChanged.listen((v) {
      _garminCoachingVoiceActive = v;
      notifyListeners();
    });

    await _initGalleryDirectories();
    await loadGlossary();
    await loadSeries();
    await loadAllPrograms();
    await loadActiveProgram();
    await loadCustomAngles();
  }

  Future<void> loadCustomAngles() async {
    _customAngles = await _customAnglesService.loadCustomAngles(
      projectPath: _projectPath,
    );
    notifyListeners();
  }

  Future<void> addCustomAngle(
    String name,
    List<DrawingElement> elements,
  ) async {
    int nextId = 100;
    if (_customAngles.isNotEmpty) {
      nextId = _customAngles.map((a) => a.id).reduce(math.max) + 1;
    }

    final newAngle = CustomKaliAngle(
      id: nextId,
      name: name,
      elements: elements,
    );

    _customAngles.add(newAngle);
    await _customAnglesService.saveCustomAngles(
      _customAngles,
      projectPath: _projectPath,
    );
    notifyListeners();
  }

  Future<void> deleteCustomAngle(int id) async {
    _customAngles.removeWhere((a) => a.id == id);
    await _customAnglesService.saveCustomAngles(
      _customAngles,
      projectPath: _projectPath,
    );
    notifyListeners();
  }

  Future<void> updateCustomAngle(CustomKaliAngle angle) async {
    final index = _customAngles.indexWhere((a) => a.id == angle.id);
    if (index != -1) {
      _customAngles[index] = angle;
      await _customAnglesService.saveCustomAngles(
        _customAngles,
        projectPath: _projectPath,
      );
      notifyListeners();
    }
  }

  Future<void> importCustomAngles(List<CustomKaliAngle> importedAngles) async {
    int maxId = 99;
    if (_customAngles.isNotEmpty) {
      maxId = _customAngles.map((a) => a.id).reduce(math.max);
    }

    for (final imported in importedAngles) {
      // Ensure no ID conflicts by assigning new IDs
      maxId++;
      final newAngle = CustomKaliAngle(
        id: maxId,
        name: imported.name,
        elements: imported.elements,
      );
      _customAngles.add(newAngle);
    }

    await _customAnglesService.saveCustomAngles(
      _customAngles,
      projectPath: _projectPath,
    );
    notifyListeners();
  }

  Future<void> _loadSettings(Map<String, String> prefs) async {
    // Language
    if (prefs.containsKey('language')) {
      _language = prefs['language']!;
    } else {
      try {
        final String systemLocale = Platform.localeName.toLowerCase();
        _language = systemLocale.startsWith('fr') ? 'fr' : 'en';
      } catch (_) {
        _language = 'en';
      }
    }

    // Voice
    _voiceEnabled = !Platform.isLinux && (prefs['voice_enabled'] ?? '0') == '1';

    // Garmin coaching TTS
    _garminCoachingTtsEnabled =
        (Platform.isAndroid || Platform.isIOS) &&
        (prefs['garmin_coaching_tts_enabled'] ?? '0') == '1';

    // Developer Mode
    _developerMode = (prefs['developer_mode'] ?? '0') == '1';
    _manageSeriesMode = (prefs['manage_series_mode'] ?? '0') == '1';
    _projectPath = prefs['project_path'];

    // Translation (Enabled by default)
    _showTranslation = (prefs['show_translation'] ?? '1') == '1';

    // Speech Rate
    if (prefs.containsKey('speech_rate')) {
      _speechRate = double.tryParse(prefs['speech_rate']!) ?? 0.25;
    }

    // Font Size Scale
    if (prefs.containsKey('font_size_scale')) {
      _fontSizeScale = double.tryParse(prefs['font_size_scale']!) ?? 1.0;
    }

    // Theme
    final themeStr = prefs['theme'] ?? 'system';
    _themeMode = JkdThemeMode.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => JkdThemeMode.system,
    );

    // Theme Color
    if (prefs.containsKey('theme_color')) {
      try {
        _themeColor = Color(int.parse(prefs['theme_color']!));
      } catch (_) {
        _themeColor = Colors.blue;
      }
    }

    // Auto Advance
    if (prefs.containsKey('auto_advance_sec')) {
      _autoAdvanceSec = int.tryParse(prefs['auto_advance_sec']!) ?? 0;
    }

    // Contributor Name
    _contributorName = prefs['contributor_name'] ?? '';

    // Gallery
    _galleryPath = prefs['gallery_path'];
    if (_galleryPath == null) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      _galleryPath = '${appDocDir.path}/jkd_gallery';
    }
  }

  /// Reloads all user settings from the database into memory.
  /// Call this after a full restore to keep in-memory state consistent.
  Future<void> reloadSettings() async {
    final prefs = await _dbService.getSettings();
    await _loadSettings(prefs);
    notifyListeners();
  }

  Future<void> _initGalleryDirectories() async {
    if (_galleryPath == null) return;
    final List<String> categories = [
      'Punches',
      'Kicks',
      'Packs',
      'Trapping',
      'Special',
      'General',
      'Other',
    ];
    try {
      for (var cat in categories) {
        final dir = Directory('$_galleryPath/$cat');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
    } catch (e) {
      LoggingService.error('Error creating gallery directories', e);
    }
  }

  void setContributorName(String name) async {
    _contributorName = name;
    await _dbService.saveSetting('contributor_name', name);
    notifyListeners();
  }

  void setLanguage(String lang) async {
    _language = lang;
    _garminService.setLanguage(lang);
    await _dbService.saveSetting('language', lang);
    notifyListeners();
  }

  void setThemeMode(JkdThemeMode mode) async {
    _themeMode = mode;
    await _dbService.saveSetting('theme', mode.name);
    notifyListeners();
  }

  void setThemeColor(Color color) async {
    _themeColor = color;
    await _dbService.saveSetting('theme_color', color.toARGB32().toString());
    notifyListeners();
  }

  void setVoiceEnabled(bool enabled) async {
    if (Platform.isLinux && enabled) return;
    _voiceEnabled = enabled;
    await _dbService.saveSetting('voice_enabled', enabled ? '1' : '0');
    notifyListeners();
  }

  void setAutoAdvanceSec(int sec) async {
    _autoAdvanceSec = sec;
    await _dbService.saveSetting('auto_advance_sec', sec.toString());
    notifyListeners();
  }

  void setDeveloperMode(bool enabled) async {
    _developerMode = enabled;
    await _dbService.saveSetting('developer_mode', enabled ? '1' : '0');
    notifyListeners();
  }

  void setManageSeriesMode(bool enabled) async {
    _manageSeriesMode = enabled;
    await _dbService.saveSetting('manage_series_mode', enabled ? '1' : '0');
    notifyListeners();
  }

  void setShowTranslation(bool enabled) async {
    _showTranslation = enabled;
    await _dbService.saveSetting('show_translation', enabled ? '1' : '0');
    notifyListeners();
  }

  void setProjectPath(String path) async {
    _projectPath = path;
    await _dbService.saveSetting('project_path', path);
    await loadSeries();
    notifyListeners();
  }

  void setSpeechRate(double rate) async {
    _speechRate = rate;
    _garminService.setSpeechRate(rate);
    await _dbService.saveSetting('speech_rate', rate.toString());
    notifyListeners();
  }

  void setGarminCoachingTtsEnabled(bool enabled) async {
    if (!(Platform.isAndroid || Platform.isIOS) && enabled) return;
    _garminCoachingTtsEnabled = enabled;
    _garminService.setTtsEnabled(enabled);
    await _dbService.saveSetting(
      'garmin_coaching_tts_enabled',
      enabled ? '1' : '0',
    );
    notifyListeners();
  }

  void setFontSizeScale(double scale) async {
    _fontSizeScale = double.parse(scale.toStringAsFixed(2));
    await _dbService.saveSetting('font_size_scale', _fontSizeScale.toString());
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filteredCache.clear();
    notifyListeners();
  }

  void setGalleryPath(String path) async {
    _galleryPath = path;
    await _dbService.saveSetting('gallery_path', path);
    await _initGalleryDirectories();
    _filteredCache.clear();
    notifyListeners();
  }

  Future<void> loadGlossary() async {
    _glossary = await _dbService.getGlossary();
  }

  Future<void> loadSeries() async {
    _isLoading = true;
    notifyListeners();
    LoggingService.info('Loading series from database...');
    _series = await _dbService.getAllSeries();
    _filteredCache.clear(); // Clear cache AFTER updating _series
    await _usageService.refresh(_series);
    _isLoading = false;
    notifyListeners();
    LoggingService.info('Loaded ${_series.length} series.');
  }

  Future<void> loadAllPrograms() async {
    _allPrograms = await _programService.getAllPrograms();
    notifyListeners();
  }

  /// Get global search results across series, glossary, and programs
  List<SearchResult> getGlobalSearchResults(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final results = <SearchResult>[];

    // 1. Search Series
    for (final s in _series) {
      bool match =
          s.title.toLowerCase().contains(q) ||
          s.category.toLowerCase().contains(q) ||
          s.notes.toLowerCase().contains(q);

      if (match) {
        results.add(
          SearchResult(
            type: SearchResultType.series,
            title: s.title,
            subtitle: s.category,
            data: s,
          ),
        );
      } else {
        // Search moves within series
        for (final m in s.moves) {
          if (m.name.toLowerCase().contains(q)) {
            results.add(
              SearchResult(
                type: SearchResultType.move,
                title: m.name,
                subtitle: 'From Series: ${s.title}',
                data: s, // Clicking a move result takes you to its series
              ),
            );
            break; // Only one result per series if multiple moves match
          }
        }
      }
    }

    // 2. Search Glossary
    for (final item in _glossary) {
      final name = item['name'].toString().toLowerCase();
      final trans = TranslationUtils.parseTranslations(item['translations']);
      final t = (trans[_language] ?? trans['en'] ?? '').toLowerCase();

      if (name.contains(q) || t.contains(q)) {
        results.add(
          SearchResult(
            type: SearchResultType.glossary,
            title: item['name'].toString(),
            subtitle: 'Glossary - ${item['category']}',
            data: item,
          ),
        );
      }
    }

    // 3. Search Programs
    for (final p in _allPrograms) {
      if (p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            type: SearchResultType.program,
            title: p.title,
            subtitle: 'Training Program',
            data: p,
          ),
        );
      }
    }

    return results;
  }

  /// Get glossary items by category from the pre-loaded cache
  /// This eliminates N+1 queries by using in-memory filtering
  List<Map<String, dynamic>> getGlossaryByCategory(String category) {
    return _glossary.where((item) => item['category'] == category).toList();
  }

  Future<void> addSeries(JkdSeries series) async {
    await _dbService.insertSeries(series);
    if (_developerMode && _projectPath != null) {
      await _exportToProjectJson(series);
    }
    await loadSeries();
  }

  Future<void> updateSeries(JkdSeries series) async {
    await _dbService.updateSeries(series);
    if (_developerMode && _projectPath != null) {
      await _exportToProjectJson(series);
    }
    await loadSeries();
  }

  Future<void> _exportToProjectJson(JkdSeries series) async {
    if (_projectPath == null) {
      LoggingService.warn('Sync aborted: Project path not set.');
      return;
    }

    LoggingService.info('Starting project sync for series: "${series.title}"');

    for (final relPath in _seriesFiles) {
      final fullPath = _getProjectFilePath(relPath);
      final file = File(fullPath);
      if (await file.exists()) {
        try {
          final String content = await file.readAsString();
          final List<dynamic> data = json.decode(content);
          bool found = false;
          for (int i = 0; i < data.length; i++) {
            final String jsonTitle = data[i]['title']
                .toString()
                .toLowerCase()
                .trim();
            final String appTitle = series.title.toLowerCase().trim();

            LoggingService.debug(
              '  - Comparing "[$jsonTitle]" with "[$appTitle]" in $relPath',
            );

            if (jsonTitle == appTitle) {
              LoggingService.info(
                '    MATCH FOUND! Updating series in $relPath',
              );

              // Use EXACT SAME logic as ExportService.exportToJson
              final Map<String, dynamic> seriesMap = series.toMap();
              seriesMap['moves'] = series.moves.map((m) => m.toMap()).toList();
              // Always set is_system to 1 when saving in dev mode
              seriesMap['is_system'] = 1;

              data[i] = seriesMap;
              found = true;
              break;
            }
          }

          if (found) {
            final encoder = JsonEncoder.withIndent('  ');
            final jsonString = encoder.convert(data);

            if (_isValidJson(jsonString)) {
              await file.writeAsString(jsonString);
              LoggingService.info('SUCCESS: Project file $fullPath updated.');
              return; // Exit after first match
            }
          }
        } catch (e) {
          LoggingService.error('ERROR processing $fullPath', e);
        }
      }
    }
    LoggingService.warn(
      'FAILURE: Series "${series.title}" not found in any project JSON file.',
    );
  }

  bool _isValidJson(String source) {
    try {
      json.decode(source);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getProjectFilePath(String relPath) {
    if (_projectPath == null) return relPath;

    // If user selected the 'assets' folder instead of project root,
    // and relPath starts with 'assets/', strip the redundant part.
    String cleanRelPath = relPath;
    if ((_projectPath!.endsWith('assets') ||
            _projectPath!.endsWith('assets/')) &&
        relPath.startsWith('assets/')) {
      cleanRelPath = relPath.substring(7); // Remove 'assets/'
    }

    return p.join(_projectPath!, cleanRelPath);
  }

  Future<void> deleteSeries(int id) async {
    await _dbService.deleteSeries(id);
    await loadSeries();
  }

  Future<void> cloneSeries(JkdSeries original) async {
    final newSeries = JkdSeries(
      title:
          "${original.title} (${LocalizationService.translate('cloned', _language)})",
      category: original.category,
      type: original.type,
      attackMethod: original.attackMethod,
      notes: original.notes,
      moves: original.moves.map((m) => Move.fromMap(m.toMap())).toList(),
    );
    await addSeries(newSeries);
  }

  /// Get filtered series list for a specific category
  List<JkdSeries> getFilteredSeries(String category) {
    if (_filteredCache.containsKey(category) && _searchQuery.isEmpty) {
      return _filteredCache[category]!;
    }

    List<JkdSeries> filtered = _series
        .where((s) => s.category == category)
        .toList();
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.title.toLowerCase().contains(query) ||
            s.notes.toLowerCase().contains(query) ||
            s.moves.any((m) => m.name.toLowerCase().contains(query));
      }).toList();
    }

    // Only cache if not searching to prevent cache explosion or stale results
    if (_searchQuery.isEmpty) {
      _filteredCache[category] = filtered;
    }

    return filtered;
  }

  // ============================================================
  // Training Program Methods
  // ============================================================

  /// Load the currently active training program (if any)
  Future<void> loadActiveProgram() async {
    LoggingService.info('Loading active training program...');
    try {
      _activeProgram = await _programService.getActiveProgress();
      if (_activeProgram != null) {
        _activeProgramDetails = await _programService.getProgramById(
          _activeProgram!.programId,
        );
        LoggingService.info(
          'Active program loaded: ${_activeProgramDetails?.title ?? "Unknown"}',
        );
      } else {
        _activeProgramDetails = null;
        LoggingService.info('No active program found');
      }
      notifyListeners();
    } catch (e) {
      LoggingService.error('Error loading active program', e);
      _activeProgram = null;
      _activeProgramDetails = null;
    }
  }

  /// Start a new training program
  Future<void> startProgram(int programId) async {
    await _programService.startProgram(programId);
    await loadActiveProgram();
  }

  Future<void> createProgram(TrainingProgram program) async {
    await _dbService.createProgram(program);
    await loadAllPrograms();
  }

  Future<void> updateProgram(TrainingProgram program) async {
    await _dbService.updateProgram(program);
    await loadAllPrograms();
  }

  Future<void> deleteProgram(int programId) async {
    await _dbService.deleteProgram(programId);
    await loadAllPrograms();
  }

  Future<void> resetTrainingProgress() async {
    await _dbService.resetTrainingProgress();
    await loadActiveProgram();
    await loadAllPrograms();
  }

  Future<void> resetActiveProgram() async {
    await _dbService.resetActiveProgram();
    await loadActiveProgram();
  }

  Future<void> resetTrainingPrograms() async {
    await _dbService.resetTrainingPrograms();
    await loadActiveProgram();
    await loadAllPrograms();
  }

  /// Mark a day as complete in the active program
  Future<void> markDayComplete(
    int dayNumber, {
    int? durationSeconds,
    String? notes,
  }) async {
    if (_activeProgram == null) {
      throw Exception('No active program to mark complete');
    }
    await _programService.markDayComplete(
      _activeProgram!.id!,
      dayNumber,
      durationSeconds: durationSeconds,
      notes: notes,
    );
    await loadActiveProgram();
  }

  /// Record a series completion and auto-mark day complete if all series done
  /// Returns completion info: {dayCompleted: bool, streak: int, progress: double}
  Future<Map<String, dynamic>?> recordSeriesCompletion(int seriesId) async {
    final result = await _programService.recordSeriesCompletion(seriesId);
    if (result != null) {
      // Reload active program to get updated state
      await loadActiveProgram();
    }
    return result;
  }

  /// Pause the active program
  Future<void> pauseActiveProgram() async {
    if (_activeProgram == null) return;
    await _programService.pauseProgram(_activeProgram!.id!);
    await loadActiveProgram();
  }

  /// Resume the active program
  Future<void> resumeActiveProgram() async {
    if (_activeProgram == null) return;
    await _programService.resumeProgram(_activeProgram!.id!);
    await loadActiveProgram();
  }

  /// Abandon the active program
  Future<void> abandonActiveProgram() async {
    if (_activeProgram == null) return;
    await _programService.abandonProgram(_activeProgram!.id!);
    await loadActiveProgram();
  }

  /// Skip a day in the active program
  Future<void> skipDay(int dayNumber) async {
    if (_activeProgram == null) return;
    await _programService.skipDay(_activeProgram!.id!, dayNumber);
    await loadActiveProgram();
  }

  /// Check if there's an active program
  bool get hasActiveProgram => _activeProgram != null;

  /// Get today's assignment details (program, day, series)
  Future<Map<String, dynamic>?> getTodaysAssignment() async {
    return await _programService.getTodaysAssignment();
  }

  /// Check if a specific series has been completed today
  bool isSeriesCompletedToday(int seriesId) {
    if (_activeProgram == null) return false;
    return _activeProgram!.isSeriesCompleted(
      _activeProgram!.currentDay,
      seriesId,
    );
  }
}
