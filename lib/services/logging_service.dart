import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class LoggingService {
  static final List<String> _logs = [];
  static const String appVersion = "1.5.0+2";

  static void log(String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final logEntry = '[$timestamp] $message';
    _logs.add(logEntry);
    debugPrint(logEntry);
    // Keep only last 1000 logs to avoid memory issues
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }

  static List<String> get logs => _logs;
  static String get allLogs => _logs.join('\n');

  static Future<String?> saveLogsToDevice() async {
    try {
      String? targetPath = await FilePicker.platform.getDirectoryPath();
      if (targetPath == null) return null;

      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final hourStr = DateFormat('HHmm').format(DateTime.now());
      final fileName = 'jkd_app-$appVersion-$dateStr-$hourStr.log';

      final File file = File('$targetPath/$fileName');
      await file.writeAsString(allLogs);
      return file.path;
    } catch (e) {
      log('Error saving logs: $e');
      return null;
    }
  }
}
