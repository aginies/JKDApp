import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/custom_kali_angle.dart';
import 'logging_service.dart';

class CustomAnglesService {
  static const String _fileName = 'custom_kali_angles.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<List<CustomKaliAngle>> loadCustomAngles({String? projectPath}) async {
    try {
      File file = await _localFile;

      // If in developer mode and file exists in project, use that
      if (projectPath != null && projectPath.isNotEmpty) {
        final projectFile = File('$projectPath/$_fileName');
        if (await projectFile.exists()) {
          file = projectFile;
          LoggingService.info('Loading custom angles from project path: ${projectFile.path}');
        }
      }

      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((json) => CustomKaliAngle.fromJson(json)).toList();
    } catch (e) {
      LoggingService.error('Error loading custom angles', e);
      return [];
    }
  }

  Future<void> saveCustomAngles(List<CustomKaliAngle> angles, {String? projectPath}) async {
    try {
      final jsonList = angles.map((a) => a.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // 1. Save to app documents (standard)
      final file = await _localFile;
      await file.writeAsString(jsonString);

      // 2. Save to project path if in developer mode
      if (projectPath != null && projectPath.isNotEmpty) {
        final projectFile = File('$projectPath/$_fileName');
        await projectFile.writeAsString(jsonString);
        LoggingService.info('Custom angles also saved to project path: ${projectFile.path}');
      }
    } catch (e) {
      LoggingService.error('Error saving custom angles', e);
    }
  }
}
