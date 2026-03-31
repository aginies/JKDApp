import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/series.dart';
import '../models/move.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';

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
  ];

  List<JkdSeries> _series = [];
  final Map<String, List<JkdSeries>> _filteredCache = {};
  String _language = 'en';
  JkdThemeMode _themeMode = JkdThemeMode.system;
  bool _voiceEnabled = false;
  bool _developerMode = false;
  String? _projectPath;
  double _speechRate = 0.25;
  String _searchQuery = '';
  String? _galleryPath;

  final DatabaseService _dbService = DatabaseService();

  List<JkdSeries> get series => _series;
  String get language => _language;
  JkdThemeMode get themeMode => _themeMode;
  bool get voiceEnabled => _voiceEnabled;
  bool get developerMode => _developerMode;
  String? get projectPath => _projectPath;
  double get speechRate => _speechRate;
  String get searchQuery => _searchQuery;
  String? get galleryPath => _galleryPath;

  SeriesProvider() {
    _init();
  }

  @visibleForTesting
  SeriesProvider.empty();

  Future<void> _init() async {
    final prefs = await _dbService.getSettings();

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

    // Developer Mode
    _developerMode = (prefs['developer_mode'] ?? '0') == '1';
    _projectPath = prefs['project_path'];

    // Speech Rate
    if (prefs.containsKey('speech_rate')) {
      _speechRate = double.tryParse(prefs['speech_rate']!) ?? 0.25;
    }

    // Theme
    final themeStr = prefs['theme'] ?? 'system';
    _themeMode = JkdThemeMode.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => JkdThemeMode.system,
    );

    // Gallery
    _galleryPath = prefs['gallery_path'];
    if (_galleryPath == null) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      _galleryPath = '${appDocDir.path}/jkd_gallery';
    }

    await _initGalleryDirectories();
    await loadSeries();
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
      debugPrint('Error creating gallery directories: $e');
    }
  }

  void setLanguage(String lang) async {
    _language = lang;
    await _dbService.saveSetting('language', lang);
    notifyListeners();
  }

  void setThemeMode(JkdThemeMode mode) async {
    _themeMode = mode;
    await _dbService.saveSetting('theme', mode.name);
    notifyListeners();
  }

  void setVoiceEnabled(bool enabled) async {
    if (Platform.isLinux && enabled) return;
    _voiceEnabled = enabled;
    await _dbService.saveSetting('voice_enabled', enabled ? '1' : '0');
    notifyListeners();
  }

  void setDeveloperMode(bool enabled) async {
    _developerMode = enabled;
    await _dbService.saveSetting('developer_mode', enabled ? '1' : '0');
    await loadSeries();
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
    await _dbService.saveSetting('speech_rate', rate.toString());
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setGalleryPath(String path) async {
    _galleryPath = path;
    await _dbService.saveSetting('gallery_path', path);
    await _initGalleryDirectories();
    notifyListeners();
  }

  Future<void> loadSeries() async {
    _filteredCache.clear();
    _series = await _dbService.getAllSeries();
    notifyListeners();
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
      debugPrint('Sync aborted: Project path not set.');
      return;
    }

    debugPrint('Starting project sync for series: "${series.title}"');

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

            debugPrint(
              '  - Comparing "[$jsonTitle]" with "[$appTitle]" in $relPath',
            );

            if (jsonTitle == appTitle) {
              debugPrint('    MATCH FOUND! Updating series in $relPath');

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
              debugPrint('SUCCESS: Project file $fullPath updated.');
              return; // Exit after first match
            }
          }
        } catch (e) {
          debugPrint('ERROR processing $fullPath: $e');
        }
      }
    }
    debugPrint(
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

  List<JkdSeries> getFilteredSeries(String category) {
    if (_filteredCache.containsKey(category)) {
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
    _filteredCache[category] = filtered;
    return filtered;
  }
}
