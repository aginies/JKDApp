import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';

class VoiceNoteService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final DatabaseService _db = DatabaseService();

  VoiceNoteService() {
    _initAudioContext();
  }

  Future<void> _initAudioContext() async {
    await _player.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.duckOthers,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
  }

  Future<String?> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String voiceDir = p.join(appDocDir.path, 'voice_notes');
        final Directory dir = Directory(voiceDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final String fileName =
            'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final String filePath = p.join(voiceDir, fileName);

        const config = RecordConfig();
        await _recorder.start(config, path: filePath);
        return filePath;
      }
    } catch (e) {
      debugPrint('Recording error: $e');
    }
    return null;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> play(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<List<Map<String, dynamic>>> getRecords() async {
    return await _db.getVoiceRecords();
  }

  Future<void> saveRecord(String name, String path) async {
    await _db.insertVoiceRecord(name, path);
  }

  Future<void> renameRecord(int id, String newName) async {
    await _db.updateVoiceRecordName(id, newName);
  }

  Future<void> deleteRecord(int id, String path) async {
    await _db.deleteVoiceRecord(id);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
