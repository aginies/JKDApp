import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/series.dart';
import 'database_service.dart';

class ExportService {
  static String _getTimestamp() =>
      DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());

  static Future<void> shareSeriesJson(
    List<JkdSeries> seriesList, {
    String? fileName,
  }) async {
    try {
      final String finalFileName =
          fileName ?? 'jkd_series_export_${_getTimestamp()}.json';
      final List<Map<String, dynamic>> jsonData = seriesList.map((s) {
        final map = s.toMap();
        map['moves'] = s.moves.map((m) => m.toMap()).toList();
        return map;
      }).toList();

      final String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonData);

      final directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/$finalFileName');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'JKD Series Backup'),
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  static Future<void> shareGlossaryJson() async {
    try {
      final items = await DatabaseService().getGlossary();
      final String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(items);

      final directory = await getTemporaryDirectory();
      final String fileName = 'jkd_glossary_backup_${_getTimestamp()}.json';
      final File file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'JKD Glossary Backup'),
      );
    } catch (e) {
      debugPrint('Glossary share error: $e');
    }
  }

  static Future<String?> exportToJson(
    List<JkdSeries> seriesList, {
    String? fileName,
    String? customDirectory,
  }) async {
    try {
      final String finalFileName =
          fileName ?? 'jkd_series_export_${_getTimestamp()}.json';
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

      final File file = File('$targetPath/$finalFileName');
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

      final String fileName = 'jkd_glossary_backup_${_getTimestamp()}.json';
      final File file = File('$targetDir/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('Glossary export error: $e');
      return null;
    }
  }
}
