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
    'assets/jkd-series-abc.json',
    'assets/jkd-series-ping-chui-lop-sao-gwa-chui.json',
    'assets/jkd-series-sinawali-series.json',
    'assets/jkd-series-hou-ou-tek.json',
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
      version: 4, // Increment version for granular progress
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// In development, we simply reset the database on schema changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    LoggingService.log(
      'Development Mode: Resetting database for schema change ($oldVersion -> $newVersion)',
    );

    // Drop all tables
    await db.execute('DROP TABLE IF EXISTS day_completions');
    await db.execute('DROP TABLE IF EXISTS user_program_progress');
    await db.execute('DROP TABLE IF EXISTS program_days');
    await db.execute('DROP TABLE IF EXISTS training_programs');
    await db.execute('DROP TABLE IF EXISTS voice_records');
    await db.execute('DROP TABLE IF EXISTS settings');
    await db.execute('DROP TABLE IF EXISTS series_moves');
    await db.execute('DROP TABLE IF EXISTS series');
    await db.execute('DROP TABLE IF EXISTS glossary');

    // Recreate everything
    await _onCreate(db, newVersion);
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
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        title TEXT, 
        category TEXT, 
        type TEXT, 
        attack_method TEXT, 
        notes TEXT, 
        is_system INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE series_moves (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        series_id INTEGER, 
        glossary_id INTEGER, 
        counter_glossary_id INTEGER, 
        name TEXT, 
        category TEXT, 
        side TEXT, 
        level TEXT, 
        sub_letter TEXT, 
        is_feint INTEGER, 
        special_action TEXT, 
        translations TEXT, 
        repetitions INTEGER, 
        counter_name TEXT, 
        counter_category TEXT, 
        counter_side TEXT, 
        counter_level TEXT, 
        counter_special_action TEXT, 
        counter_is_feint INTEGER DEFAULT 0,
        counter_translations TEXT, 
        counter_sub_moves_json TEXT, 
        counter_chain_json TEXT, 
        sub_moves_json TEXT, 
        chain_json TEXT, 
        position INTEGER, 
        FOREIGN KEY (series_id) REFERENCES series (id) ON DELETE CASCADE
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
        completed_series_json TEXT DEFAULT '{}',
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

  Future<void> _seedGlossary(DatabaseExecutor db) async {
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

  Future<void> _seedSeries(DatabaseExecutor db) async {
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
              'counter_is_feint': move['counter_is_feint'] ?? 0,
              'counter_translations': move['counter_translations'],
              'counter_sub_moves_json': move['counter_sub_moves_json'],
              'counter_chain_json': move['counter_chain_json'],
              'sub_moves_json': move['sub_moves_json'],
              'chain_json': move['chain_json'],
              'position': i,
            });
          }
        }
      } catch (e) {
        debugPrint('Error seeding series from $seriesFile: $e');
      }
    }
  }

  Future<void> _seedTrainingPrograms(dynamic db) async {
    LoggingService.log('Seeding training programs from assets...');

    final List<String> programFiles = [
      'assets/training_programs/30-day-jkd-fundamentals.json',
      'assets/training_programs/2-week-trapping-intensive.json',
      'assets/training_programs/footwork-beginner-2-weeks.json',
      'assets/training_programs/footwork-advanced-2-weeks.json',
      'assets/training_programs/footwork-expert-2-weeks.json',
      'assets/training_programs/basic-hits-2-weeks.json',
      'assets/training_programs/counters-beginner-2-weeks.json',
      'assets/training_programs/counters-advanced-2-weeks.json',
      'assets/training_programs/counters-expert-2-weeks.json',
      'assets/training_programs/3-4-counts-beginner-2-weeks.json',
      'assets/training_programs/3-4-counts-advanced-2-weeks.json',
      'assets/training_programs/3-4-counts-expert-2-weeks.json',
      'assets/training_programs/advanced-combos-45-days.json',
    ];

    // Build a map of series titles to IDs for resolving references
    final seriesTitleMap = await _buildSeriesTitleMap(db);

    for (final programFile in programFiles) {
      try {
        final String programResponse = await rootBundle.loadString(programFile);
        final List<dynamic> programsData = json.decode(programResponse);

        for (var programJson in programsData) {
          final String title = programJson['title'];

          // Check if system program already exists
          final existing = await db.query(
            'training_programs',
            where: 'title = ? AND is_system = 1',
            whereArgs: [title],
          );

          int programId;
          if (existing.isNotEmpty) {
            programId = existing.first['id'] as int;
            await db.update(
              'training_programs',
              {
                'description': programJson['description'] ?? '',
                'difficulty_level':
                    programJson['difficulty_level'] ?? 'beginner',
                'duration_days': programJson['duration_days'] ?? 1,
              },
              where: 'id = ?',
              whereArgs: [programId],
            );
            // Clear existing days to re-populate them correctly
            await db.delete(
              'program_days',
              where: 'program_id = ?',
              whereArgs: [programId],
            );
          } else {
            // Insert new program
            programId = await db.insert('training_programs', {
              'title': title,
              'description': programJson['description'] ?? '',
              'difficulty_level': programJson['difficulty_level'] ?? 'beginner',
              'duration_days': programJson['duration_days'] ?? 1,
              'is_system': 1,
              'created_at': DateTime.now().toIso8601String(),
            });
          }

          // Insert program days
          final days = programJson['days'] as List<dynamic>? ?? [];
          for (var day in days) {
            // Resolve series titles to IDs
            final seriesTitles = day['series_ids'] as List<dynamic>? ?? [];
            final List<int> resolvedIds = [];

            for (var stitle in seriesTitles) {
              if (stitle is String) {
                final normalizedTitle = stitle.trim().toLowerCase();
                if (seriesTitleMap.containsKey(stitle)) {
                  resolvedIds.add(seriesTitleMap[stitle]!);
                } else if (seriesTitleMap.containsKey(normalizedTitle)) {
                  resolvedIds.add(seriesTitleMap[normalizedTitle]!);
                }
              }
            }

            // Handle detailed assignments if present
            final List<Map<String, dynamic>> assignments = [];
            if (day['assignments'] != null) {
              for (var assign in day['assignments']) {
                final atitle = assign['title'];
                if (atitle is String) {
                  final normalizedTitle = atitle.trim().toLowerCase();
                  if (seriesTitleMap.containsKey(atitle)) {
                    assignments.add({
                      'series_id': seriesTitleMap[atitle],
                      'item_range': assign['range'],
                    });
                  } else if (seriesTitleMap.containsKey(normalizedTitle)) {
                    assignments.add({
                      'series_id': seriesTitleMap[normalizedTitle],
                      'item_range': assign['range'],
                    });
                  }
                }
              }
            }

            // If no assignments specified but series_ids are, create default assignments
            if (assignments.isEmpty && resolvedIds.isNotEmpty) {
              for (var id in resolvedIds) {
                assignments.add({'series_id': id, 'item_range': null});
              }
            }

            await db.insert('program_days', {
              'program_id': programId,
              'day_number': day['day_number'] ?? 1,
              'series_ids': json.encode(resolvedIds),
              'series_assignments': assignments.isNotEmpty
                  ? json.encode(assignments)
                  : null,
              'notes': day['notes'],
              'is_rest_day': day['is_rest_day'] ?? 0,
            });
          }
        }
      } catch (e) {
        debugPrint('Error seeding training programs from $programFile: $e');
      }
    }

    LoggingService.log('Training programs seeding complete');
  }

  Future<Map<String, int>> _buildSeriesTitleMap(DatabaseExecutor db) async {
    final List<Map<String, dynamic>> series = await db.query('series');
    final Map<String, int> titleMap = {};
    for (var entry in series) {
      if (entry['title'] != null && entry['id'] != null) {
        // Store both exact title and normalized version
        final title = entry['title'] as String;
        titleMap[title] = entry['id'] as int;
        titleMap[title.trim().toLowerCase()] = entry['id'] as int;
      }
    }
    return titleMap;
  }

  Future<Map<String, Map<String, dynamic>>> _buildGlossaryNameMap(
    DatabaseExecutor db,
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
        m.counter_translations, m.counter_sub_moves_json, m.counter_chain_json,
        m.sub_moves_json, m.chain_json, m.position
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
            counterTranslations: TranslationUtils.parseTranslations(
              row['counter_translations'],
            ),
            counterSubMoves: _parseSubMoves(row['counter_sub_moves_json']),
            counterChain: _parseChain(row['counter_chain_json']),
            subMoves: _parseSubMoves(row['sub_moves_json']),
            chain: _parseChain(row['chain_json']),
          ),
        );
      }
    }
    return seriesMap.values.toList();
  }

  List<Move> _parseSubMoves(dynamic jsonStr) {
    if (jsonStr == null || jsonStr.toString().isEmpty || jsonStr == '[]') {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(jsonStr.toString());
      return decoded.map((m) => Move.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error parsing sub_moves_json: $e');
      return [];
    }
  }

  List<Move> _parseChain(dynamic jsonStr) {
    if (jsonStr == null || jsonStr.toString().isEmpty || jsonStr == '[]') {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(jsonStr.toString());
      return decoded.map((m) => Move.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error parsing chain_json: $e');
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

    return UserProgramProgress.fromMap(results.first);
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

    return UserProgramProgress.fromMap(results.first);
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
      progressList.add(UserProgramProgress.fromMap(map));
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
    final activeProgress = await getActiveProgress();
    if (activeProgress == null) return null;

    final program = await getProgramById(activeProgress.programId);
    if (program == null) return null;

    // Find WHICH DAY this series belongs to.
    // We prioritize the currentDay, but look through all days to be safe.
    int targetDayNum = activeProgress.currentDay;
    ProgramDay? targetDay;

    // Helper to check if a day contains the series
    bool dayContainsSeries(ProgramDay day) {
      final assignedSeriesIds =
          (day.seriesAssignments != null && day.seriesAssignments!.isNotEmpty)
          ? day.seriesAssignments!.map((a) => a.seriesId).toSet()
          : day.seriesIds.toSet();
      return assignedSeriesIds.contains(seriesId);
    }

    // Check current day first
    final currentDay = program.days.firstWhere(
      (d) => d.dayNumber == activeProgress.currentDay,
      orElse: () => program.days.first,
    );

    if (dayContainsSeries(currentDay)) {
      targetDay = currentDay;
    } else {
      // Look through all other days
      for (var day in program.days) {
        if (dayContainsSeries(day)) {
          targetDay = day;
          targetDayNum = day.dayNumber;
          break;
        }
      }
    }

    if (targetDay == null) {
      LoggingService.log(
        'Series $seriesId is not part of the active program "${program.title}". Progress not recorded.',
      );
      return null;
    }

    // Update completed series for the target day
    final Map<String, List<int>> completedMap = Map.from(
      activeProgress.completedSeriesPerDay,
    );
    final String dayKey = targetDayNum.toString();
    final List<int> dayCompleted = List.from(completedMap[dayKey] ?? []);

    if (!dayCompleted.contains(seriesId)) {
      dayCompleted.add(seriesId);
      completedMap[dayKey] = dayCompleted;
    }

    // Check if the target day is now fully complete
    final assignedSeriesIds =
        (targetDay.seriesAssignments != null &&
            targetDay.seriesAssignments!.isNotEmpty)
        ? targetDay.seriesAssignments!.map((a) => a.seriesId).toSet()
        : targetDay.seriesIds.toSet();

    bool isTargetDayNowComplete = true;
    for (final sid in assignedSeriesIds) {
      if (!dayCompleted.contains(sid)) {
        isTargetDayNowComplete = false;
        break;
      }
    }

    final db = await database;
    final List<int> completedDays = List.from(activeProgress.completedDays);

    if (isTargetDayNowComplete) {
      if (!completedDays.contains(targetDayNum)) {
        completedDays.add(targetDayNum);
      }
    }

    // Determine if we should advance the 'current_day' pointer.
    // We only advance if the current day was just completed.
    int nextCurrentDay = activeProgress.currentDay;
    if (targetDayNum == activeProgress.currentDay && isTargetDayNowComplete) {
      if (nextCurrentDay < program.durationDays) {
        nextCurrentDay++;
      }
    }

    final isProgramComplete = completedDays.length >= program.durationDays;
    final status = isProgramComplete ? 'completed' : 'active';
    final completedAt = isProgramComplete
        ? DateTime.now().toIso8601String()
        : null;

    await db.update(
      'user_program_progress',
      {
        'current_day': nextCurrentDay,
        'completed_days': json.encode(completedDays),
        'completed_series_json': json.encode(completedMap),
        'status': status,
        'completed_at': completedAt,
      },
      where: 'id = ?',
      whereArgs: [activeProgress.id],
    );

    final updatedProgress = activeProgress.copyWith(
      completedDays: completedDays,
      completedSeriesPerDay: completedMap,
      currentDay: nextCurrentDay,
      status: status,
    );

    return {
      'day_complete': isTargetDayNowComplete,
      'program_complete': isProgramComplete,
      'next_day': nextCurrentDay,
      'day_percentage': updatedProgress.getDayPercentage(program, targetDayNum),
      'global_percentage': updatedProgress.getGlobalPercentage(program),
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

  Future<Map<String, dynamic>?> getGlossaryItem(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'glossary',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> resetTechnicalLibrary() async {
    final db = await database;

    await db.transaction((txn) async {
      LoggingService.log('Resetting technical library (Glossary & Series)...');

      // 1. Clear glossary
      await txn.delete('glossary');

      // 2. Identify and delete system series
      final systemSeries = await txn.query(
        'series',
        columns: ['id'],
        where: 'is_system = 1',
      );
      final List<int> systemIds = systemSeries
          .map((s) => s['id'] as int)
          .toList();

      if (systemIds.isNotEmpty) {
        final idList = systemIds.join(',');
        await txn.delete('series_moves', where: 'series_id IN ($idList)');
        await txn.delete('series', where: 'id IN ($idList)');
      }

      // 3. Re-seed Glossary
      await _seedGlossary(txn);

      // 4. Re-seed Series
      await _seedSeries(txn);

      // 5. Re-map Training Programs
      await _remapProgramReferences(txn);
    });

    LoggingService.log('Technical library reset complete.');
  }

  Future<void> resetTrainingProgress() async {
    final db = await database;
    await db.transaction((txn) async {
      LoggingService.log('Resetting ALL training progress...');
      await txn.delete('day_completions');
      await txn.delete('user_program_progress');
    });
  }

  Future<void> resetActiveProgram() async {
    final db = await database;
    LoggingService.log('Resetting currently active program...');
    await db.delete(
      'user_program_progress',
      where: 'status = ?',
      whereArgs: ['active'],
    );
  }

  Future<void> resetTrainingPrograms() async {
    final db = await database;
    await db.transaction((txn) async {
      LoggingService.log('Resetting all training programs...');
      // 1. Delete all custom programs (is_system = 0)
      // program_days and progress will be deleted via CASCADE or manually
      await txn.delete('training_programs', where: 'is_system = 0');

      // 2. Re-seed system programs from assets
      await _seedTrainingPrograms(txn);
    });
  }

  Future<void> _remapProgramReferences(dynamic txn) async {
    // Build a fresh title map
    final List<Map<String, dynamic>> allSeries = await txn.query('series');
    final Map<String, int> titleToId = {};
    for (var s in allSeries) {
      if (s['title'] != null) {
        titleToId[s['title'].toString().toLowerCase().trim()] = s['id'] as int;
      }
    }

    // Update program_days
    final List<Map<String, dynamic>> days = await txn.query('program_days');
    for (var day in days) {
      // Handle series_assignments (new format)
      if (day['series_assignments'] != null) {
        try {
          final List<dynamic> assignments = json.decode(
            day['series_assignments'],
          );

          for (var i = 0; i < assignments.length; i++) {
            // We need the title to find the new ID.
            // Since we don't store the title in assignments, we have a problem.
            // However, most assignments are created from system programs using titles.
          }
          // Note: Full re-mapping of custom programs is difficult without title storage.
          // For now, we rely on _seedTrainingPrograms to handle system programs.
        } catch (_) {}
      }
    }

    // Re-run the system program seeding logic to ensure they are correct
    await _seedTrainingPrograms(txn);
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
