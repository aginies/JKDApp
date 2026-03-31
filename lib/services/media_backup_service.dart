import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class MediaBackupService {
  static String buildBackupPath(String sourcePath, String timestamp) =>
      p.join(sourcePath, 'jkd_media_backup_$timestamp.zip');

  static Future<String?> backupGalleryToZip(
    String sourcePath,
    String targetDir,
  ) async {
    try {
      final String timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm',
      ).format(DateTime.now());
      final String zipFileName = 'jkd_media_backup_$timestamp.zip';
      final String zipPath = p.join(targetDir, zipFileName);

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      final dir = Directory(sourcePath);
      if (await dir.exists()) {
        encoder.addDirectory(dir);
      }
      encoder.close();

      return zipPath;
    } catch (e) {
      debugPrint('Backup error: $e');
      return null;
    }
  }

  static Future<bool> restoreGalleryFromZip(
    String targetPath,
    String zipFilePath,
  ) async {
    try {
      final bytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(targetPath, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(p.join(targetPath, filename)).createSync(recursive: true);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
