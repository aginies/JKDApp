import 'dart:convert';
import '../utils/platform_io.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/series.dart';
import '../models/move.dart';
import 'database_service.dart';

import 'series_provider.dart';

class ImportService {
  static Future<bool> importSeries(SeriesProvider provider) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        File file = File(files.first.path!);
        String content = await file.readAsString();
        List<dynamic> jsonData = json.decode(content);

        final dbService = DatabaseService();
        final existingSeries = await dbService.getAllSeries();
        final existingTitles = existingSeries.map((s) => s.title).toList();

        final String importDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());

        for (var data in jsonData) {
          final series = JkdSeries.fromMap(Map<String, dynamic>.from(data), []);
          List<dynamic>? movesData = data['moves'];

          String finalTitle = series.title;
          if (existingTitles.contains(finalTitle)) {
            int count = 1;
            String newTitle;
            do {
              newTitle = "${series.title} (Imported $importDate #$count)";
              count++;
            } while (existingTitles.contains(newTitle));
            finalTitle = newTitle;
          }

          final newSeries = JkdSeries(
            title: finalTitle,
            category: series.category,
            type: series.type,
            attackMethod: series.attackMethod,
            notes: series.notes,
            isFromCloud: series.isFromCloud,
            moves: movesData != null
                ? movesData
                      .map((m) => Move.fromMap(Map<String, dynamic>.from(m)))
                      .toList()
                : [],
          );

          await dbService.insertSeries(newSeries);
          existingTitles.add(finalTitle);
        }

        // RELOAD DATA to refresh UI
        await provider.loadSeries();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }

  static Future<bool> importGlossary(SeriesProvider provider) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        File file = File(files.first.path!);
        String content = await file.readAsString();
        List<dynamic> jsonData = json.decode(content);

        final dbService = DatabaseService();
        await dbService.clearGlossary();

        for (var item in jsonData) {
          final Map<String, dynamic> cleanItem = Map<String, dynamic>.from(
            item,
          );
          cleanItem.remove('id'); // Fresh IDs
          await dbService.insertGlossaryItem(cleanItem);
        }

        // RELOAD GLOSSARY to refresh UI
        await provider.loadGlossary();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Glossary import error: $e');
      return false;
    }
  }
}
