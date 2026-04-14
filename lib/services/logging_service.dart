import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum LogLevel { info, warn, error, debug }

class LoggingService {
  static final List<String> _logs = [];
  static const String appVersion = "2.6.0+1";

  /// Standard log (defaults to INFO)
  static void log(String message) {
    info(message);
  }

  static void info(String message) {
    _addLog(message, LogLevel.info);
  }

  static void warn(String message) {
    _addLog(message, LogLevel.warn);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    String fullMessage = message;
    if (error != null) fullMessage += ' | Error: $error';
    _addLog(fullMessage, LogLevel.error);
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      _addLog(message, LogLevel.debug);
    }
  }

  static void _addLog(String message, LogLevel level) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final levelStr = level.toString().split('.').last.toUpperCase().padRight(5);
    final logEntry = '[$timestamp] [$levelStr] $message';

    _logs.add(logEntry);
    debugPrint(logEntry);

    // Keep only last 2000 logs to avoid memory issues (increased from 1000)
    if (_logs.length > 2000) {
      _logs.removeAt(0);
    }
  }

  static List<String> get logs => _logs;
  static String get allLogs => _logs.join('\n');

  /// Shares the log file using the system share sheet
  static Future<void> shareLogs() async {
    try {
      final directory = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final fileName = 'jkd_app_logs_$dateStr.txt';
      final file = File('${directory.path}/$fileName');

      String content = "JKD App Logs - v$appVersion\n";
      content += "Exported: ${DateTime.now()}\n";
      content += "----------------------------------------\n\n";
      content += allLogs;

      await file.writeAsString(content);

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'JKD App Logs - $dateStr');
    } catch (e) {
      error('Error sharing logs', e);
    }
  }
}
