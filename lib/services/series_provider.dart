import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/series.dart';
import '../models/move.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';

enum JkdThemeMode { system, light, dark, amoled }

class SeriesProvider with ChangeNotifier {
  List<JkdSeries> _series = [];
  String _language = 'en';
  JkdThemeMode _themeMode = JkdThemeMode.system;
  bool _voiceEnabled = false;
  double _speechRate = 0.25;
  String _searchQuery = '';
  String? _galleryPath;

  final DatabaseService _dbService = DatabaseService();

  List<JkdSeries> get series => _series;
  String get language => _language;
  JkdThemeMode get themeMode => _themeMode;
  bool get voiceEnabled => _voiceEnabled;
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
    _series = await _dbService.getAllSeries();
    notifyListeners();
  }

  Future<void> addSeries(JkdSeries series) async {
    await _dbService.insertSeries(series);
    await loadSeries();
  }

  Future<void> updateSeries(JkdSeries series) async {
    await _dbService.updateSeries(series);
    await loadSeries();
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
    List<JkdSeries> filtered = _series
        .where((s) => s.category == category)
        .toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        final query = _searchQuery.toLowerCase();
        return s.title.toLowerCase().contains(query) ||
            s.notes.toLowerCase().contains(query) ||
            s.moves.any((m) => m.name.toLowerCase().contains(query));
      }).toList();
    }
    return filtered;
  }
}
