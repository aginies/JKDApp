import 'dart:convert';
import '../utils/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../utils/app_dirs.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class BackupService {
  static const String _backupVersion = '1.0';

  static Future<String?> createGlobalBackup(String? galleryPath) async {
    try {
      // Full backup zips the filesystem: not available on web.
      if (kIsWeb) {
        throw UnsupportedError('Backup is not available on web');
      }
      final db = await DatabaseService().database;
      final tempDir = await getTemporaryDirectory();

      // 1. Create a workspace directory for gathering all files
      final String timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final workspaceDir = Directory(
        p.join(tempDir.path, 'jkd_backup_$timestamp'),
      );
      await workspaceDir.create(recursive: true);

      // 2. Export Database Tables to JSON
      final tables = [
        'glossary',
        'series',
        'series_moves',
        'settings',
        'voice_records',
        'training_programs',
        'program_days',
        'user_program_progress',
        'day_completions',
      ];

      final Map<String, dynamic> metadata = {
        'version': _backupVersion,
        'date': DateTime.now().toIso8601String(),
        'tables': tables,
      };

      await File(
        p.join(workspaceDir.path, 'metadata.json'),
      ).writeAsString(json.encode(metadata));

      for (var table in tables) {
        try {
          final List<Map<String, dynamic>> data = await db.query(table);
          await File(
            p.join(workspaceDir.path, '$table.json'),
          ).writeAsString(json.encode(data));
        } catch (e) {
          debugPrint('Skipping table $table: $e');
        }
      }

      // 2.1 Include Custom Kali Angles if exist
      final docsDir = await getApplicationDocumentsDirectory();
      final customAnglesFile = File(
        p.join(docsDir.path, 'custom_kali_angles.json'),
      );
      if (await customAnglesFile.exists()) {
        await customAnglesFile.copy(
          p.join(workspaceDir.path, 'custom_kali_angles.json'),
        );
      }

      // 3. Include Media if path provided
      if (galleryPath != null) {
        final mediaSourceDir = Directory(galleryPath);
        if (await mediaSourceDir.exists()) {
          final targetMediaDir = Directory(p.join(workspaceDir.path, 'media'));
          await targetMediaDir.create(recursive: true);
          await _copyDirectory(mediaSourceDir, targetMediaDir);
        }
      }

      // 4. Zip the entire workspace
      final String zipFileName =
          'jkd_full_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.zip';
      final String zipPath = p.join(tempDir.path, zipFileName);

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      // addDirectory is reliable when called on a completed directory
      // structure. dynamic: archive expects dart:io Directory; on web this
      // path is unreachable (backup is disabled and throws above).
      encoder.addDirectory(workspaceDir as dynamic, includeDirName: false);
      encoder.close();

      // 5. Clean up workspace
      await workspaceDir.delete(recursive: true);

      return zipPath;
    } catch (e) {
      debugPrint('Global backup error: $e');
      return null;
    }
  }

  static Future<bool> restoreGlobalBackup(
    String zipPath,
    String? galleryPath,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final restoreDir = Directory(
        p.join(
          tempDir.path,
          'jkd_restore_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await restoreDir.create(recursive: true);

      // 1. Unzip
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final safeName = _safeZipEntryPath(file.name);
        if (safeName == null) {
          debugPrint('Restore: skipping unsafe zip entry: ${file.name}');
          continue;
        }
        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File(p.join(restoreDir.path, safeName));
          await f.create(recursive: true);
          await f.writeAsBytes(data);
        } else {
          await Directory(
            p.join(restoreDir.path, safeName),
          ).create(recursive: true);
        }
      }

      // Find the base path (where metadata.json is)
      String basePath = restoreDir.path;
      if (!await File(p.join(basePath, 'metadata.json')).exists()) {
        // Check if it's wrapped in a single folder
        final entities = restoreDir.listSync();
        if (entities.length == 1 && entities.first is Directory) {
          basePath = entities.first.path;
        }
      }

      // 2. Validate metadata
      final metadataFile = File(p.join(basePath, 'metadata.json'));
      if (!await metadataFile.exists()) {
        debugPrint('Restore error: metadata.json not found at $basePath');
        return false;
      }

      // 3. Restore Database
      final db = await DatabaseService().database;
      await db.transaction((txn) async {
        final tables = [
          'day_completions',
          'user_program_progress',
          'program_days',
          'training_programs',
          'voice_records',
          'settings',
          'series_moves',
          'series',
          'glossary',
        ];

        for (var table in tables) {
          final file = File(p.join(basePath, '$table.json'));
          if (await file.exists()) {
            await txn.delete(table);
            final List<dynamic> data = json.decode(await file.readAsString());
            for (var row in data) {
              await txn.insert(table, Map<String, dynamic>.from(row));
            }
          }
        }
      });

      // 3.1 Restore Custom Kali Angles
      final customAnglesFile = File(
        p.join(basePath, 'custom_kali_angles.json'),
      );
      if (await customAnglesFile.exists()) {
        final docsDir = await getApplicationDocumentsDirectory();
        await customAnglesFile.copy(
          p.join(docsDir.path, 'custom_kali_angles.json'),
        );
      }

      // 4. Restore Media
      if (galleryPath != null) {
        final mediaSourceDir = Directory(p.join(basePath, 'media'));
        if (await mediaSourceDir.exists()) {
          final mediaTargetDir = Directory(galleryPath);
          await _copyDirectory(mediaSourceDir, mediaTargetDir);
        }
      }

      // Clean up
      await restoreDir.delete(recursive: true);
      return true;
    } catch (e) {
      debugPrint('Global restore error: $e');
      return false;
    }
  }

  /// Returns a safe, relative path for a zip entry, or `null` if the entry
  /// would escape the restore directory (absolute path or `..` traversal).
  static String? _safeZipEntryPath(String entryPath) {
    final normalized = entryPath.replaceAll('\\', '/');
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
      return null;
    }
    final parts = normalized
        .split('/')
        .where((s) => s.isNotEmpty && s != '.')
        .toList();
    if (parts.isEmpty || parts.any((s) => s == '..')) {
      return null;
    }
    return parts.join(p.separator);
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(
          p.join(destination.path, p.basename(entity.path)),
        );
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }
}
