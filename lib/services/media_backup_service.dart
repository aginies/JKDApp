import 'dart:io';
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
        encoder.addFile(entity, entryPath);
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
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File(p.join(targetPath, filename));
          await f.create(recursive: true);
          await f.writeAsBytes(data);
        } else {
          await Directory(p.join(targetPath, filename)).create(recursive: true);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
