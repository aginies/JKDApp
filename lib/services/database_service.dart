import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/move.dart';
import '../models/series.dart';
import '../models/training_program.dart';
import '../models/program_day.dart';
import '../models/user_program_progress.dart';
import '../utils/translation_utils.dart';
import 'logging_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // List of series JSON files to load from assets (all are trusted system series)
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
  ];

  static Map<String, int?>? _glossaryNameMap;
  static Map<String, int?>? get glossaryNameMap => _glossaryNameMap;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'jkd_notes.db');
    LoggingService.log('Initializing database at $path');
    return await openDatabase(
      path,
      version: 16,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    LoggingService.log('Upgrading database from $oldVersion to $newVersion');
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
      } catch (e) {
        debugPrint(
          'Migration warning: glossary_id column may already exist - $e',
        );
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE glossary ADD COLUMN hit_type TEXT');
      } catch (e) {
        debugPrint('Migration warning: hit_type column may already exist - $e');
      }
      try {
        await db.execute(
          'ALTER TABLE glossary ADD COLUMN possible_type_attack TEXT',
        );
      } catch (e) {
        debugPrint(
          'Migration warning: possible_type_attack column may already exist - $e',
        );
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE glossary ADD COLUMN possible_level TEXT');
      } catch (e) {
        debugPrint(
          'Migration warning: possible_level column may already exist - $e',
        );
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE series ADD COLUMN is_system INTEGER DEFAULT 0',
        );
      } catch (e) {
        debugPrint(
          'Migration warning: is_system column may already exist - $e',
        );
      }
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
      } catch (e) {
        debugPrint(
          'Migration warning: counter_glossary_id column may already exist - $e',
        );
      }
    }
    if (oldVersion < 9) {
      await db.rawQuery('''
        UPDATE series_moves 
        SET glossary_id = (SELECT id FROM glossary WHERE name = series_moves.name LIMIT 1)
        WHERE glossary_id IS NULL AND name IS NOT NULL
      ''');
      await db.rawQuery('''
        UPDATE series_moves 
        SET counter_glossary_id = (SELECT id FROM glossary WHERE name = series_moves.counter_name LIMIT 1)
        WHERE counter_glossary_id IS NULL AND counter_name IS NOT NULL
      ''');
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE glossary ADD COLUMN possible_direction TEXT',
        );
      } catch (e) {
        debugPrint(
          'Migration warning: possible_direction column may already exist - $e',
        );
      }
      await db.delete('glossary');
      await _seedGlossary(db);
    }
    if (oldVersion < 11) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_series_moves_series_id ON series_moves(series_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_series_moves_glossary_id ON series_moves(glossary_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_series_moves_counter_glossary_id ON series_moves(counter_glossary_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_glossary_name ON glossary(name)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_series_moves_series_pos ON series_moves(series_id, position)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_glossary_cat_pos ON glossary(category, position)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_voice_records_created ON voice_records(created_at DESC)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_glossary_position ON glossary(position)',
      );
    }
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE series_moves ADD COLUMN sub_letter TEXT');
      } catch (e) {
        debugPrint(
          'Migration warning: sub_letter column may already exist - $e',
        );
      }
    }
    if (oldVersion < 13) {
      // Re-seed system series to ensure they have correct categories and data
      // Note: deleting from 'series' will cascade delete to 'series_moves' due to FK
      await db.delete('series', where: 'is_system = 1');
      await _seedSeries(db);
    }
    if (oldVersion < 14) {
      // Add training programs tables
      await db.execute('''
        CREATE TABLE training_programs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          difficulty_level TEXT,
          duration_days INTEGER NOT NULL,
          is_system INTEGER DEFAULT 1,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE program_days (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          program_id INTEGER NOT NULL,
          day_number INTEGER NOT NULL,
          series_ids TEXT NOT NULL,
          notes TEXT,
          is_rest_day INTEGER DEFAULT 0,
          FOREIGN KEY (program_id) REFERENCES training_programs(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE user_program_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          program_id INTEGER NOT NULL,
          started_at TEXT NOT NULL,
          current_day INTEGER DEFAULT 1,
          completed_days TEXT,
          status TEXT DEFAULT 'active',
          completed_at TEXT,
          FOREIGN KEY (program_id) REFERENCES training_programs(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE day_completions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          progress_id INTEGER NOT NULL,
          day_number INTEGER NOT NULL,
          completed_at TEXT NOT NULL,
          duration_seconds INTEGER,
          notes TEXT,
          FOREIGN KEY (progress_id) REFERENCES user_program_progress(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for performance
      await db.execute(
        'CREATE INDEX idx_program_days_program_id ON program_days(program_id)',
      );
      await db.execute(
        'CREATE INDEX idx_user_progress_status ON user_program_progress(status)',
      );
      await db.execute(
        'CREATE INDEX idx_day_completions_progress_id ON day_completions(progress_id)',
      );

      // Seed training programs from JSON assets
      await _seedTrainingPrograms(db);
    }

    if (oldVersion < 15) {
      // Add todays_completed_series_ids column to track series completion counts for today
      // Format: JSON map like {"1": 2, "3": 1} where key is series ID and value is completion count
      try {
        await db.execute(
          'ALTER TABLE user_program_progress ADD COLUMN todays_completed_series_ids TEXT DEFAULT "{}"',
        );
      } catch (e) {
        debugPrint(
          'Migration warning: todays_completed_series_ids column may already exist - $e',
        );
      }
    }

    if (oldVersion < 16) {
      // Add series_assignments column to store detailed series assignments with item ranges
      // Format: JSON array like [{"series_id": 1, "item_range": "1-4"}, {"series_id": 3, "item_range": null}]
      try {
        await db.execute(
          'ALTER TABLE program_days ADD COLUMN series_assignments TEXT',
        );
        debugPrint(
          'Migration v16: Added series_assignments column to program_days',
        );
      } catch (e) {
        debugPrint(
          'Migration warning: series_assignments column may already exist - $e',
        );
      }
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
        id INTEGER PRIMARY KEY AUTOINCREMENT, series_id INTEGER, glossary_id INTEGER, counter_glossary_id INTEGER, name TEXT, category TEXT, side TEXT, level TEXT, sub_letter TEXT, is_feint INTEGER, special_action TEXT, translations TEXT, repetitions INTEGER, counter_name TEXT, counter_category TEXT, counter_side TEXT, counter_level TEXT, counter_special_action TEXT, sub_moves_json TEXT, position INTEGER, FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)',
    );
    await db.execute(
      'CREATE TABLE voice_records (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, file_path TEXT, created_at TEXT)',
    );

    await db.execute(
      'CREATE INDEX idx_series_moves_series_id ON series_moves(series_id)',
    );
    await db.execute(
      'CREATE INDEX idx_series_moves_glossary_id ON series_moves(glossary_id)',
    );
    await db.execute(
      'CREATE INDEX idx_series_moves_counter_glossary_id ON series_moves(counter_glossary_id)',
    );
    await db.execute('CREATE INDEX idx_glossary_name ON glossary(name)');
    await db.execute(
      'CREATE INDEX idx_series_moves_series_pos ON series_moves(series_id, position)',
    );
    await db.execute(
      'CREATE INDEX idx_glossary_cat_pos ON glossary(category, position)',
    );
    await db.execute(
      'CREATE INDEX idx_voice_records_created ON voice_records(created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_glossary_position ON glossary(position)',
    );

    // Training programs tables
    await db.execute('''
      CREATE TABLE training_programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        difficulty_level TEXT,
        duration_days INTEGER NOT NULL,
        is_system INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE program_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        series_ids TEXT NOT NULL,
        series_assignments TEXT,
        notes TEXT,
        is_rest_day INTEGER DEFAULT 0,
        FOREIGN KEY (program_id) REFERENCES training_programs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_program_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        current_day INTEGER DEFAULT 1,
        completed_days TEXT,
        todays_completed_series_ids TEXT DEFAULT '{}',
        status TEXT DEFAULT 'active',
        completed_at TEXT,
        FOREIGN KEY (program_id) REFERENCES training_programs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE day_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        progress_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        duration_seconds INTEGER,
        notes TEXT,
        FOREIGN KEY (progress_id) REFERENCES user_program_progress(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_program_days_program_id ON program_days(program_id)',
    );
    await db.execute(
      'CREATE INDEX idx_user_progress_status ON user_program_progress(status)',
    );
    await db.execute(
      'CREATE INDEX idx_day_completions_progress_id ON day_completions(progress_id)',
    );

    await _seedGlossary(db);
    await _seedSeries(db);
    await _seedTrainingPrograms(db);
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
    final glossaryMap = await _buildGlossaryNameMap(db);

    for (final seriesFile in _seriesFiles) {
      try {
        final String seriesResponse = await rootBundle.loadString(seriesFile);
        final List<dynamic> seriesData = json.decode(seriesResponse);

        for (var s in seriesData) {
          int seriesId = await db.insert('series', {
            'title': s['title'],
            'category': s['category'],
            'type': s['type'] ?? 'Attack',
            'attack_method': s['attack_method'],
            'notes': s['notes'] ?? '',
            'is_system': 1,
          });

          final moves = s['moves'] as List<dynamic>;
          for (int i = 0; i < moves.length; i++) {
            var move = moves[i];
            int? gid;
            String? glossaryTranslations;

            if (move['glossary_id'] != null) {
              gid = (move['glossary_id'] as num).toInt();
            } else if (move['name'] != null &&
                !move['name'].toString().startsWith('Combo:')) {
              String name = move['name'] as String;
              if (name.contains(':')) name = name.split(':').last.trim();

              if (glossaryMap.containsKey(name)) {
                final entry = glossaryMap[name]!;
                gid = entry['id'] as int?;
                glossaryTranslations = entry['translations'] as String?;
              }
            }

            await db.insert('series_moves', {
              'series_id': seriesId,
              'glossary_id': gid,
              'name': move['name'],
              'category': move['category'] ?? 'punch',
              'side': move['side'] ?? '',
              'level': move['level'] ?? '',
              'sub_letter': move['sub_letter'],
              'is_feint': move['is_feint'] ?? 0,
              'special_action': move['special_action'],
              'translations':
                  move['translations'] ??
                  glossaryTranslations ??
                  json.encode({}),
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
      } catch (e) {
        debugPrint('Error seeding series from $seriesFile: $e');
      }
    }
  }

  Future<void> _seedTrainingPrograms(Database db) async {
    // Check if programs already exist
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM training_programs'),
    );
    if (count != null && count > 0) {
      LoggingService.log('Training programs already seeded, skipping');
      return;
    }

    LoggingService.log('Seeding training programs from assets...');

    final List<String> programFiles = [
      'assets/training_programs/30-day-jkd-fundamentals.json',
      'assets/training_programs/2-week-trapping-intensive.json',
      'assets/training_programs/footwork-fundamentals-2-weeks.json',
      'assets/training_programs/advanced-combos-45-days.json',
    ];

    // Build a map of series titles to IDs for resolving references
    final seriesTitleMap = await _buildSeriesTitleMap(db);

    for (final programFile in programFiles) {
      try {
        final String programResponse = await rootBundle.loadString(programFile);
        final List<dynamic> programsData = json.decode(programResponse);

        for (var programJson in programsData) {
          // Insert program
          final int programId = await db.insert('training_programs', {
            'title': programJson['title'],
            'description': programJson['description'] ?? '',
            'difficulty_level': programJson['difficulty_level'] ?? 'beginner',
            'duration_days': programJson['duration_days'] ?? 1,
            'is_system': programJson['is_system'] ?? 1,
            'created_at': DateTime.now().toIso8601String(),
          });

          // Insert program days
          final days = programJson['days'] as List<dynamic>? ?? [];
          for (var day in days) {
            // Resolve series titles to IDs
            final seriesTitles = day['series_ids'] as List<dynamic>? ?? [];
            final List<int> resolvedIds = [];

            for (var title in seriesTitles) {
              if (title is String && seriesTitleMap.containsKey(title)) {
                resolvedIds.add(seriesTitleMap[title]!);
              }
            }

            await db.insert('program_days', {
              'program_id': programId,
              'day_number': day['day_number'] ?? 1,
              'series_ids': json.encode(resolvedIds),
              'series_assignments':
                  null, // System programs don't have item ranges
              'notes': day['notes'],
              'is_rest_day': day['is_rest_day'] ?? 0,
            });
          }

          LoggingService.log(
            'Seeded program: ${programJson['title']} with ${days.length} days',
          );
        }
      } catch (e) {
        debugPrint('Error seeding training programs from $programFile: $e');
      }
    }

    LoggingService.log('Training programs seeding complete');
  }

  Future<Map<String, int>> _buildSeriesTitleMap(Database db) async {
    final List<Map<String, dynamic>> series = await db.query('series');
    final Map<String, int> titleMap = {};
    for (var entry in series) {
      if (entry['title'] != null && entry['id'] != null) {
        titleMap[entry['title'] as String] = entry['id'] as int;
      }
    }
    return titleMap;
  }

  Future<Map<String, Map<String, dynamic>>> _buildGlossaryNameMap(
    Database db,
  ) async {
    final List<Map<String, dynamic>> glossary = await db.query(
      'glossary',
      orderBy: 'position',
    );
    final Map<String, Map<String, dynamic>> nameMap = {};
    for (var entry in glossary) {
      if (entry['name'] != null) {
        nameMap[entry['name'] as String] = entry;
      }
    }
    return nameMap;
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
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        s.id as s_id, s.title, s.category as s_category, s.type, s.attack_method, s.notes, s.is_system,
        m.id as m_id, m.series_id, m.glossary_id, m.counter_glossary_id, m.name, m.category as m_category, 
        m.side, m.level, m.sub_letter, m.is_feint, m.special_action, m.translations, m.repetitions, 
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
          title: row['title'] as String? ?? 'Untitled',
          category: row['s_category'] as String? ?? 'Other',
          type: row['type'] as String? ?? 'Attack',
          attackMethod: row['attack_method'] as String?,
          notes: row['notes'] as String? ?? '',
          isSystem: (row['is_system'] as int? ?? 0) == 1,
          moves: [],
        );
      }
      if (row['m_id'] != null) {
        seriesMap[sId]!.moves.add(
          Move(
            id: row['m_id'] as int,
            glossaryId: row['glossary_id'] as int?,
            counterGlossaryId: row['counter_glossary_id'] as int?,
            name: row['name'] as String? ?? '',
            category: row['m_category'] as String? ?? '',
            side: row['side'] as String? ?? '',
            level: row['level'] as String? ?? '',
            subLetter: row['sub_letter'] as String?,
            isFeint: (row['is_feint'] as int? ?? 0) == 1,
            specialAction: row['special_action'] as String?,
            translations: TranslationUtils.parseTranslations(
              row['translations'],
            ),
            repetitions: row['repetitions'] as int? ?? 1,
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

  List<Move> _parseSubMoves(dynamic jsonStr) {
    if (jsonStr == null || jsonStr.toString().isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr.toString());
      return decoded.map((m) => Move.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error parsing sub_moves_json: $e');
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

  // ============================================================
  // Training Programs CRUD Methods
  // ============================================================

  /// Get all training programs with their days
  Future<List<TrainingProgram>> getAllPrograms() async {
    final db = await database;
    final List<Map<String, dynamic>> programMaps = await db.query(
      'training_programs',
      orderBy: 'difficulty_level, title',
    );

    List<TrainingProgram> programs = [];
    for (var programMap in programMaps) {
      final days = await getProgramDays(programMap['id'] as int);
      programs.add(TrainingProgram.fromMap(programMap, days: days));
    }

    return programs;
  }

  /// Get a specific training program by ID
  Future<TrainingProgram?> getProgramById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'training_programs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final days = await getProgramDays(id);
    return TrainingProgram.fromMap(results.first, days: days);
  }

  /// Get all days for a specific program
  Future<List<ProgramDay>> getProgramDays(int programId) async {
    final db = await database;
    final List<Map<String, dynamic>> dayMaps = await db.query(
      'program_days',
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'day_number',
    );

    return dayMaps.map((map) => ProgramDay.fromMap(map)).toList();
  }

  /// Insert a new training program with its days
  Future<int> insertProgram(TrainingProgram program) async {
    final db = await database;
    final programId = await db.insert('training_programs', program.toMap());

    for (var day in program.days) {
      await db.insert(
        'program_days',
        day.copyWith(programId: programId).toMap(),
      );
    }

    return programId;
  }

  /// Get user's progress for a specific program
  Future<UserProgramProgress?> getUserProgress(int programId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'user_program_progress',
      where: 'program_id = ? AND status = ?',
      whereArgs: [programId, 'active'],
    );

    if (results.isEmpty) return null;

    // Get total days for completion percentage calculation
    final program = await getProgramById(programId);
    return UserProgramProgress.fromMap(
      results.first,
      totalDays: program?.durationDays,
    );
  }

  /// Get the currently active program progress (if any)
  Future<UserProgramProgress?> getActiveProgress() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'user_program_progress',
      where: 'status = ?',
      whereArgs: ['active'],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final progress = results.first;
    final program = await getProgramById(progress['program_id'] as int);
    return UserProgramProgress.fromMap(
      progress,
      totalDays: program?.durationDays,
    );
  }

  /// Get all user progress records
  Future<List<UserProgramProgress>> getAllUserProgress() async {
    final db = await database;
    final List<Map<String, dynamic>> progressMaps = await db.query(
      'user_program_progress',
      orderBy: 'started_at DESC',
    );

    List<UserProgramProgress> progressList = [];
    for (var map in progressMaps) {
      final program = await getProgramById(map['program_id'] as int);
      progressList.add(
        UserProgramProgress.fromMap(map, totalDays: program?.durationDays),
      );
    }

    return progressList;
  }

  /// Create a new training program (user-created)
  Future<int> createProgram(TrainingProgram program) async {
    final db = await database;

    // Insert program
    final programId = await db.insert('training_programs', {
      'title': program.title,
      'description': program.description,
      'difficulty_level': program.difficultyLevel,
      'duration_days': program.durationDays,
      'is_system': program.isSystem ? 1 : 0,
      'created_at': program.createdAt.toIso8601String(),
    });

    // Insert program days
    for (final day in program.days) {
      await db.insert(
        'program_days',
        day.copyWith(programId: programId).toMap(),
      );
    }

    return programId;
  }

  /// Update an existing training program
  Future<void> updateProgram(TrainingProgram program) async {
    if (program.id == null) {
      throw Exception('Cannot update program without ID');
    }

    final db = await database;

    // Update program
    await db.update(
      'training_programs',
      {
        'title': program.title,
        'description': program.description,
        'difficulty_level': program.difficultyLevel,
        'duration_days': program.durationDays,
        'is_system': program.isSystem ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [program.id],
    );

    // Delete old program days
    await db.delete(
      'program_days',
      where: 'program_id = ?',
      whereArgs: [program.id],
    );

    // Insert new program days
    for (final day in program.days) {
      await db.insert(
        'program_days',
        day.copyWith(programId: program.id).toMap(),
      );
    }
  }

  /// Delete a training program
  Future<void> deleteProgram(int programId) async {
    final db = await database;
    // CASCADE delete will automatically remove program_days
    await db.delete(
      'training_programs',
      where: 'id = ?',
      whereArgs: [programId],
    );
  }

  /// Start a new program
  Future<int> startProgram(int programId) async {
    final db = await database;
    return await db.insert('user_program_progress', {
      'program_id': programId,
      'started_at': DateTime.now().toIso8601String(),
      'current_day': 1,
      'completed_days': json.encode([]),
      'status': 'active',
    });
  }

  /// Mark a day as complete
  Future<void> markDayComplete(
    int progressId,
    int dayNumber, {
    int? durationSeconds,
    String? notes,
  }) async {
    final db = await database;

    // Get current progress
    final List<Map<String, dynamic>> progressResults = await db.query(
      'user_program_progress',
      where: 'id = ?',
      whereArgs: [progressId],
    );

    if (progressResults.isEmpty) return;

    final progress = UserProgramProgress.fromMap(progressResults.first);

    // Add to completed days if not already there
    final updatedCompletedDays = List<int>.from(progress.completedDays);
    if (!updatedCompletedDays.contains(dayNumber)) {
      updatedCompletedDays.add(dayNumber);
    }

    // Update current day to next day
    final program = await getProgramById(progress.programId);
    final nextDay = dayNumber + 1;
    final isCompleted = program != null && nextDay > program.durationDays;

    // Update progress
    await db.update(
      'user_program_progress',
      {
        'completed_days': json.encode(updatedCompletedDays),
        'current_day': isCompleted ? dayNumber : nextDay,
        'status': isCompleted ? 'completed' : 'active',
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [progressId],
    );

    // Record day completion
    await db.insert('day_completions', {
      'progress_id': progressId,
      'day_number': dayNumber,
      'completed_at': DateTime.now().toIso8601String(),
      'duration_seconds': durationSeconds,
      'notes': notes,
    });

    // Reset today's series completion counts for the new day
    await db.update(
      'user_program_progress',
      {'todays_completed_series_ids': json.encode({})},
      where: 'id = ?',
      whereArgs: [progressId],
    );
  }

  /// Record a series completion and auto-mark day complete if all series done
  /// Requires 2 completions per series before counting as complete
  /// Returns a map with: {dayCompleted: bool, streak: int, progress: double}
  Future<Map<String, dynamic>?> recordSeriesCompletion(int seriesId) async {
    final db = await database;

    // Get active program
    final activeProgress = await getActiveProgress();
    if (activeProgress == null) return null; // No active program

    // Get today's assigned series
    final program = await getProgramById(activeProgress.programId);
    if (program == null) return null;

    final currentDayData = program.days.firstWhere(
      (day) => day.dayNumber == activeProgress.currentDay,
      orElse: () => ProgramDay(
        programId: activeProgress.programId,
        dayNumber: activeProgress.currentDay,
        seriesIds: [],
      ),
    );

    // Check if this series is in today's assignment
    if (!currentDayData.seriesIds.contains(seriesId)) {
      return null; // Not part of today's program
    }

    // Increment completion count for this series
    final updatedCounts = Map<int, int>.from(
      activeProgress.todaysSeriesCompletionCounts,
    );
    updatedCounts[seriesId] = (updatedCounts[seriesId] ?? 0) + 1;

    // Convert to string keys for JSON encoding
    final countsAsStrings = updatedCounts.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    // Update the progress record
    await db.update(
      'user_program_progress',
      {'todays_completed_series_ids': json.encode(countsAsStrings)},
      where: 'id = ?',
      whereArgs: [activeProgress.id],
    );

    // Check if all series for today have been completed at least 2 times
    final allSeriesComplete = currentDayData.seriesIds.every(
      (id) => (updatedCounts[id] ?? 0) >= 2,
    );

    // Count how many series are fully complete (2+ reps)
    final completedSeriesCount = currentDayData.seriesIds
        .where((id) => (updatedCounts[id] ?? 0) >= 2)
        .length;

    if (allSeriesComplete) {
      // Auto-mark day complete
      await markDayComplete(activeProgress.id!, activeProgress.currentDay);

      // Reload progress to get updated values
      final updatedProgress = await getActiveProgress();
      if (updatedProgress != null) {
        return {
          'dayCompleted': true,
          'dayNumber': activeProgress.currentDay,
          'streak': updatedProgress.getCurrentStreak(),
          'progress': updatedProgress.getCompletionPercentage(
            program.durationDays,
          ),
        };
      }
    }

    return {
      'dayCompleted': false,
      'completedSeries': completedSeriesCount,
      'totalSeries': currentDayData.seriesIds.length,
      'currentSeriesCount': updatedCounts[seriesId] ?? 0,
    };
  }

  /// Pause a program
  Future<void> pauseProgram(int progressId) async {
    final db = await database;
    await db.update(
      'user_program_progress',
      {'status': 'paused'},
      where: 'id = ?',
      whereArgs: [progressId],
    );
  }

  /// Resume a paused program
  Future<void> resumeProgram(int progressId) async {
    final db = await database;
    await db.update(
      'user_program_progress',
      {'status': 'active'},
      where: 'id = ?',
      whereArgs: [progressId],
    );
  }

  /// Abandon a program
  Future<void> abandonProgram(int progressId) async {
    final db = await database;
    await db.update(
      'user_program_progress',
      {'status': 'abandoned'},
      where: 'id = ?',
      whereArgs: [progressId],
    );
  }

  /// Skip a day (doesn't mark as complete, just advances current day)
  Future<void> skipDay(int progressId, int dayNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> progressResults = await db.query(
      'user_program_progress',
      where: 'id = ?',
      whereArgs: [progressId],
    );

    if (progressResults.isEmpty) return;

    await db.update(
      'user_program_progress',
      {'current_day': dayNumber + 1},
      where: 'id = ?',
      whereArgs: [progressId],
    );
  }

  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    final String path = join(await getDatabasesPath(), 'jkd_notes.db');
    await deleteDatabase(path);
    _database = await _initDatabase();
  }
}
