import '../utils/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class MediaBackupService {
  static String _getTimestamp() =>
      DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());

  static Future<String?> backupGalleryToZip(
    String sourcePath,
    String targetDir, {
    String? zipFileName,
  }) async {
    try {
      final String finalFileName =
          zipFileName ?? 'jkd-media-backup-${_getTimestamp()}.zip';
      final String zipPath = p.join(targetDir, finalFileName);

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      final dir = Directory(sourcePath);
      if (await dir.exists()) {
        await _addDirectoryToZip(encoder, dir, '');
      }
      encoder.close();

      return zipPath;
    } catch (e) {
      debugPrint('Backup error: $e');
      return null;
    }
  }

  static Future<void> _addDirectoryToZip(
    ZipFileEncoder encoder,
    Directory dir,
    String zipPath,
  ) async {
    final List<FileSystemEntity> entities = await dir
        .list(recursive: false)
        .toList();
    for (final entity in entities) {
      final String name = p.basename(entity.path);
      final String entryPath = zipPath.isEmpty ? name : '$zipPath/$name';

      if (entity is Directory) {
        await _addDirectoryToZip(encoder, entity, entryPath);
      } else if (entity is File) {
        // dynamic: archive expects dart:io File; on web this path is
        // unreachable (media backup is disabled).
        encoder.addFile(entity as dynamic, entryPath);
      }
    }
  }

  static Future<bool> restoreGalleryFromZip(
    String targetPath,
    String zipFilePath,
  ) async {
    try {
      final bytes = await File(zipFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final safeName = _safeZipEntryPath(file.name);
        if (safeName == null) {
          debugPrint('Restore: skipping unsafe zip entry: ${file.name}');
          continue;
        }
        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File(p.join(targetPath, safeName));
          await f.create(recursive: true);
          await f.writeAsBytes(data);
        } else {
          await Directory(p.join(targetPath, safeName)).create(recursive: true);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
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
}
