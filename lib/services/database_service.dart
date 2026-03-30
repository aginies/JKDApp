import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/move.dart';
import '../models/series.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'jkd_notes.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS voice_records (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, file_path TEXT, created_at TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)');
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE series_moves ADD COLUMN glossary_id INTEGER'); } catch (_) {}
    }
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE glossary ADD COLUMN hit_type TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE glossary ADD COLUMN possible_type_attack TEXT'); } catch (_) {}
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE glossary ADD COLUMN possible_level TEXT'); } catch (_) {}
    }
    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE series ADD COLUMN is_system INTEGER DEFAULT 0'); } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE glossary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        translations TEXT,
        category TEXT,
        position INTEGER,
        removal TEXT,
        hit_type TEXT,
        possible_type_attack TEXT,
        possible_level TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE series (
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, category TEXT, type TEXT, attack_method TEXT, notes TEXT, is_system INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE series_moves (
        id INTEGER PRIMARY KEY AUTOINCREMENT, series_id INTEGER, glossary_id INTEGER, name TEXT, category TEXT, side TEXT, level TEXT, is_feint INTEGER, special_action TEXT, translations TEXT, repetitions INTEGER, counter_name TEXT, counter_category TEXT, counter_side TEXT, counter_level TEXT, counter_special_action TEXT, sub_moves_json TEXT, position INTEGER, FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
    await db.execute('CREATE TABLE voice_records (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, file_path TEXT, created_at TEXT)');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final String glossaryResponse = await rootBundle.loadString('assets/glossary.json');
    final Map<String, dynamic> glossaryData = json.decode(glossaryResponse);
    
    int globalPosition = 0;
    glossaryData.forEach((category, items) {
      if (items is List) {
        for (var item in items) {
          db.insert('glossary', {
            'name': item['name'],
            'category': category,
            'translations': json.encode(item['translations']),
            'position': globalPosition++,
            'removal': json.encode(item['removal'] ?? {}),
            'hit_type': item['hit_type'],
            'possible_type_attack': item['possible_type_attack'],
            'possible_level': item['possible_level'] ?? 'H,M,L',
          });
        }
      }
    });

    final String seriesResponse = await rootBundle.loadString('assets/series.json');
    final List<dynamic> seriesData = json.decode(seriesResponse);
    for (var s in seriesData) {
      int seriesId = await db.insert('series', {
        'title': s['title'], 'category': 'Jun Fan Gung Fu', 'type': 'Attack', 'attack_method': null, 'notes': 'Initial seed data', 'is_system': 1,
      });

      for (int i = 0; i < s['moves'].length; i++) {
        var move = s['moves'][i];
        await db.insert('series_moves', {
          'series_id': seriesId, 'name': move['name'], 'category': 'punch', 'side': move['side'] ?? '', 'level': '', 'is_feint': 0, 'special_action': null, 'translations': json.encode({}), 'repetitions': 1, 'counter_name': null, 'counter_category': null, 'counter_side': null, 'counter_level': null, 'counter_special_action': null, 'sub_moves_json': null, 'position': i,
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getGlossary() async {
    final db = await database; return await db.query('glossary', orderBy: 'position');
  }

  Future<void> clearGlossary() async {
    final db = await database; await db.delete('glossary');
  }

  Future<void> insertGlossaryItem(Map<String, dynamic> item) async {
    final db = await database; await db.insert('glossary', item);
  }

  Future<List<Map<String, dynamic>>> getGlossaryByCategory(String category) async {
    final db = await database;
    return await db.query('glossary', where: 'category = ?', whereArgs: [category], orderBy: 'position');
  }

  Future<List<JkdSeries>> getAllSeries() async {
    final db = await database; final List<Map<String, dynamic>> maps = await db.query('series');
    List<JkdSeries> result = [];
    for (var map in maps) {
      final List<Map<String, dynamic>> moveMaps = await db.query('series_moves', where: 'series_id = ?', whereArgs: [map['id']], orderBy: 'position');
      List<Move> moves = moveMaps.map((m) => Move.fromMap(m)).toList();
      result.add(JkdSeries.fromMap(map, moves));
    }
    return result;
  }

  Future<int> insertSeries(JkdSeries series) async {
    final db = await database; final seriesMap = series.toMap(); seriesMap.remove('id');
    int id = await db.insert('series', seriesMap);
    for (int i = 0; i < series.moves.length; i++) {
      var moveMap = series.moves[i].toMap(); moveMap.remove('id'); moveMap['series_id'] = id; moveMap['position'] = i; await db.insert('series_moves', moveMap);
    }
    return id;
  }

  Future<void> updateSeries(JkdSeries series) async {
    final db = await database; final seriesMap = series.toMap();
    await db.update('series', seriesMap, where: 'id = ?', whereArgs: [series.id]);
    await db.delete('series_moves', where: 'series_id = ?', whereArgs: [series.id]);
    for (int i = 0; i < series.moves.length; i++) {
      var moveMap = series.moves[i].toMap(); moveMap.remove('id'); moveMap['series_id'] = series.id; moveMap['position'] = i; await db.insert('series_moves', moveMap);
    }
  }

  Future<void> deleteSeries(int id) async {
    final db = await database; await db.delete('series', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, String>> getSettings() async {
    final db = await database; final List<Map<String, dynamic>> maps = await db.query('settings');
    return {for (var m in maps) m['key'] as String: m['value'] as String};
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getVoiceRecords() async {
    final db = await database; return await db.query('voice_records', orderBy: 'created_at DESC');
  }

  Future<int> insertVoiceRecord(String name, String filePath) async {
    final db = await database;
    return await db.insert('voice_records', {'name': name, 'file_path': filePath, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<void> updateVoiceRecordName(int id, String newName) async {
    final db = await database; await db.update('voice_records', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVoiceRecord(int id) async {
    final db = await database; await db.delete('voice_records', where: 'id = ?', whereArgs: [id]);
  }
}
