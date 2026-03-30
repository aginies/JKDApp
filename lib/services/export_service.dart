import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/series.dart';
import 'database_service.dart';

class ExportService {
  static Future<String?> exportToJson(
    List<JkdSeries> seriesList, {
    String fileName = 'jkd_series_export.json',
    String? customDirectory,
  }) async {
    try {
      final List<Map<String, dynamic>> jsonData = seriesList.map((s) {
        final map = s.toMap();
        map['moves'] = s.moves.map((m) => m.toMap()).toList();
        return map;
      }).toList();

      final String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonData);

      String? targetPath;
      if (customDirectory != null) {
        targetPath = customDirectory;
      } else {
        targetPath = await FilePicker.platform.getDirectoryPath();
      }

      if (targetPath == null) return null;

      final File file = File('$targetPath/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  static Future<String?> exportGlossaryToJson({String? customDirectory}) async {
    try {
      final items = await DatabaseService().getGlossary();
      final String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(items);

      final String? targetDir =
          customDirectory ?? await FilePicker.platform.getDirectoryPath();
      if (targetDir == null) return null;

      final String fileName =
          'jkd_glossary_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final File file = File('$targetDir/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('Glossary export error: $e');
      return null;
    }
  }
}
