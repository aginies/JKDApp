import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/series.dart';
import '../models/move.dart';
import 'database_service.dart';

class ImportService {
  static Future<bool> importSeries() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonData = json.decode(content);

        final dbService = DatabaseService();
        final existingSeries = await dbService.getAllSeries();
        final existingTitles = existingSeries.map((s) => s.title).toList();
        
        final String importDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
            moves: movesData != null 
              ? movesData.map((m) => Move.fromMap(Map<String, dynamic>.from(m))).toList()
              : [],
          );
          
          await dbService.insertSeries(newSeries);
          existingTitles.add(finalTitle);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }

  static Future<bool> importGlossary() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonData = json.decode(content);

        final dbService = DatabaseService();
        await dbService.clearGlossary();

        for (var item in jsonData) {
          final Map<String, dynamic> cleanItem = Map<String, dynamic>.from(item);
          cleanItem.remove('id'); // Fresh IDs
          await dbService.insertGlossaryItem(cleanItem);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Glossary import error: $e');
      return false;
    }
  }
}
