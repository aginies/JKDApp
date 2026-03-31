import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/move.dart';
import '../models/series.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // List of series JSON files to load from assets (all are trusted system series)
  // To add a new series file:
  // 1. Place the jkd-series-*.json file in the assets/ directory
  // 2. Add the filename to this list
  // The file will be automatically loaded and seeded into the database
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
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS voice_records (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, file_path TEXT, created_at TEXT)',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)',
      );
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE series_moves ADD COLUMN glossary_id INTEGER',
        );
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE glossary ADD COLUMN hit_type TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE glossary ADD COLUMN possible_type_attack TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE glossary ADD COLUMN possible_level TEXT');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE series ADD COLUMN is_system INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 7) {
      await db.delete('glossary');
      await _seedGlossary(db);
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
          'ALTER TABLE series_moves ADD COLUMN counter_glossary_id INTEGER',
        );
      } catch (_) {}
    }
    if (oldVersion < 9) {
      // Populate missing glossary_ids and counter_glossary_ids for existing moves
      final allMoves = await db.query('series_moves');
      for (var move in allMoves) {
        Map<String, dynamic> updates = {};

        if (move['glossary_id'] == null && move['name'] != null) {
          final results = await db.query(
            'glossary',
            where: 'name = ?',
            whereArgs: [move['name']],
            limit: 1,
          );
          if (results.isNotEmpty) {
            updates['glossary_id'] = results.first['id'];
          }
        }

        if (move['counter_glossary_id'] == null &&
            move['counter_name'] != null) {
          final results = await db.query(
            'glossary',
            where: 'name = ?',
            whereArgs: [move['counter_name']],
            limit: 1,
          );
          if (results.isNotEmpty) {
            updates['counter_glossary_id'] = results.first['id'];
          }
        }

        if (updates.isNotEmpty) {
          await db.update(
            'series_moves',
            updates,
            where: 'id = ?',
            whereArgs: [move['id']],
          );
        }
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE glossary ADD COLUMN possible_direction TEXT',
        );
      } catch (_) {}
      // Re-seed glossary to include possible_direction data
      await db.delete('glossary');
      await _seedGlossary(db);
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
        possible_level TEXT,
        possible_direction TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE series (
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, category TEXT, type TEXT, attack_method TEXT, notes TEXT, is_system INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE series_moves (
        id INTEGER PRIMARY KEY AUTOINCREMENT, series_id INTEGER, glossary_id INTEGER, counter_glossary_id INTEGER, name TEXT, category TEXT, side TEXT, level TEXT, is_feint INTEGER, special_action TEXT, translations TEXT, repetitions INTEGER, counter_name TEXT, counter_category TEXT, counter_side TEXT, counter_level TEXT, counter_special_action TEXT, sub_moves_json TEXT, position INTEGER, FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)',
    );
    await db.execute(
      'CREATE TABLE voice_records (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, file_path TEXT, created_at TEXT)',
    );

    await _seedGlossary(db);
    await _seedSeries(db);
  }

  Future<void> _seedGlossary(Database db) async {
    final String glossaryResponse = await rootBundle.loadString(
      'assets/jkd-glossary.json',
    );
    final Map<String, dynamic> glossaryData = json.decode(glossaryResponse);

    int globalPosition = 0;
    for (var category in glossaryData.keys) {
      final items = glossaryData[category];
      if (items is List) {
        for (var item in items) {
          await db.insert('glossary', {
            'name': item['name'],
            'category': category,
            'translations': json.encode(item['translations']),
            'position': globalPosition++,
            'removal': json.encode(item['removal'] ?? {}),
            'hit_type': item['hit_type'],
            'possible_type_attack': item['possible_type_attack'],
            'possible_level': item['possible_level'] ?? 'H,M,L',
            'possible_direction': item['possible_direction'],
          });
        }
      }
    }
  }

  Future<void> _seedSeries(Database db) async {
    // Load all series files from the list (all are trusted system series)
    final List<dynamic> allSeriesData = [];

    for (final seriesFile in _seriesFiles) {
      try {
        final String response = await rootBundle.loadString(seriesFile);
        final List<dynamic> fileData = json.decode(response);
        allSeriesData.addAll(fileData);
      } catch (e) {
        debugPrint('Error loading series file $seriesFile: $e');
      }
    }

    for (var s in allSeriesData) {
      int seriesId = await db.insert('series', {
        'title': s['title'],
        'category': s['category'] ?? 'Jun Fan Gung Fu',
        'type': s['type'] ?? 'Attack',
        'attack_method': s['attack_method'],
        'notes': s['notes'] ?? 'Initial seed data',
        'is_system': s['is_system'] ?? 1,
      });

      final moves = s['moves'] as List<dynamic>;
      for (int i = 0; i < moves.length; i++) {
        var move = moves[i];

        // Try to find glossary ID by name matching (for simple moves)
        int? gid;
        if (move['glossary_id'] != null) {
          gid = move['glossary_id'];
        } else if (move['name'] != null &&
            !move['name'].toString().startsWith('Combo:')) {
          final glossaryResults = await db.query(
            'glossary',
            where: 'name = ?',
            whereArgs: [move['name']],
            limit: 1,
          );
          if (glossaryResults.isNotEmpty) {
            gid = glossaryResults.first['id'] as int?;
          }
        }

        await db.insert('series_moves', {
          'series_id': seriesId,
          'glossary_id': gid,
          'name': move['name'],
          'category': move['category'] ?? 'punch',
          'side': move['side'] ?? '',
          'level': move['level'] ?? '',
          'is_feint': move['is_feint'] ?? 0,
          'special_action': move['special_action'],
          'translations': move['translations'] ?? json.encode({}),
          'repetitions': move['repetitions'] ?? 1,
          'counter_name': move['counter_name'],
          'counter_category': move['counter_category'],
          'counter_side': move['counter_side'],
          'counter_level': move['counter_level'],
          'counter_special_action': move['counter_special_action'],
          'sub_moves_json': move['sub_moves_json'],
          'position': i,
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getGlossary() async {
    final db = await database;
    return await db.query('glossary', orderBy: 'position');
  }

  Future<void> clearGlossary() async {
    final db = await database;
    await db.delete('glossary');
  }

  Future<void> insertGlossaryItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('glossary', item);
  }

  Future<List<Map<String, dynamic>>> getGlossaryByCategory(
    String category,
  ) async {
    final db = await database;
    return await db.query(
      'glossary',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'position',
    );
  }

  Future<List<JkdSeries>> getAllSeries() async {
    final db = await database;

    // Join series and moves to get everything in one go
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        s.id as s_id, s.title, s.category as s_category, s.type, s.attack_method, s.notes, s.is_system,
        m.id as m_id, m.series_id, m.glossary_id, m.counter_glossary_id, m.name, m.category as m_category, 
        m.side, m.level, m.is_feint, m.special_action, m.translations, m.repetitions, 
        m.counter_name, m.counter_category, m.counter_side, m.counter_level, m.counter_special_action, 
        m.sub_moves_json, m.position
      FROM series s
      LEFT JOIN series_moves m ON s.id = m.series_id
      ORDER BY s.id, m.position
    ''');

    Map<int, JkdSeries> seriesMap = {};

    for (var row in results) {
      int sId = row['s_id'] as int;

      if (!seriesMap.containsKey(sId)) {
        seriesMap[sId] = JkdSeries(
          id: sId,
          title: row['title'] as String,
          category: row['s_category'] as String,
          type: row['type'] as String,
          attackMethod: row['attack_method'] as String?,
          notes: row['notes'] as String,
          isSystem: (row['is_system'] as int) == 1,
          moves: [],
        );
      }

      if (row['m_id'] != null) {
        seriesMap[sId]!.moves.add(
          Move(
            id: row['m_id'] as int,
            glossaryId: row['glossary_id'] as int?,
            counterGlossaryId: row['counter_glossary_id'] as int?,
            name: row['name'] as String,
            category: row['m_category'] as String,
            side: row['side'] as String,
            level: row['level'] as String,
            isFeint: (row['is_feint'] as int) == 1,
            specialAction: row['special_action'] as String?,
            translations: _parseTranslations(row['translations']),
            repetitions: row['repetitions'] as int,
            counterName: row['counter_name'] as String?,
            counterCategory: row['counter_category'] as String?,
            counterSide: row['counter_side'] as String?,
            counterLevel: row['counter_level'] as String?,
            counterSpecialAction: row['counter_special_action'] as String?,
            subMoves: _parseSubMoves(row['sub_moves_json']),
          ),
        );
      }
    }

    return seriesMap.values.toList();
  }

  Map<String, String> _parseTranslations(dynamic jsonStr) {
    if (jsonStr == null || jsonStr.toString().isEmpty) return {};
    try {
      return Map<String, String>.from(json.decode(jsonStr.toString()));
    } catch (_) {
      return {};
    }
  }

  List<Move> _parseSubMoves(dynamic jsonStr) {
    if (jsonStr == null || jsonStr.toString().isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr.toString());
      return decoded.map((m) => Move.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> insertSeries(JkdSeries series) async {
    final db = await database;
    final seriesMap = series.toMap();
    seriesMap.remove('id');
    int id = await db.insert('series', seriesMap);
    for (int i = 0; i < series.moves.length; i++) {
      var moveMap = series.moves[i].toMap();
      moveMap.remove('id');
      moveMap['series_id'] = id;
      moveMap['position'] = i;
      await db.insert('series_moves', moveMap);
    }
    return id;
  }

  Future<void> updateSeries(JkdSeries series) async {
    final db = await database;
    final seriesMap = series.toMap();
    await db.update(
      'series',
      seriesMap,
      where: 'id = ?',
      whereArgs: [series.id],
    );
    await db.delete(
      'series_moves',
      where: 'series_id = ?',
      whereArgs: [series.id],
    );
    for (int i = 0; i < series.moves.length; i++) {
      var moveMap = series.moves[i].toMap();
      moveMap.remove('id');
      moveMap['series_id'] = series.id;
      moveMap['position'] = i;
      await db.insert('series_moves', moveMap);
    }
  }

  Future<void> deleteSeries(int id) async {
    final db = await database;
    await db.delete('series', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, String>> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    return {for (var m in maps) m['key'] as String: m['value'] as String};
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getVoiceRecords() async {
    final db = await database;
    return await db.query('voice_records', orderBy: 'created_at DESC');
  }

  Future<int> insertVoiceRecord(String name, String filePath) async {
    final db = await database;
    return await db.insert('voice_records', {
      'name': name,
      'file_path': filePath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateVoiceRecordName(int id, String newName) async {
    final db = await database;
    await db.update(
      'voice_records',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteVoiceRecord(int id) async {
    final db = await database;
    await db.delete('voice_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetDatabase() async {
    // Close existing database connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the database file
    final String path = join(await getDatabasesPath(), 'jkd_notes.db');
    await deleteDatabase(path);

    // Re-initialize the database (will trigger onCreate)
    _database = await _initDatabase();
  }
}
