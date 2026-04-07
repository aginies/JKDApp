import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'logging_service.dart';

/// Bridges Garmin ConnectIQ watch messages to Flutter TTS.
///
/// Message types from the watch:
///   {"speak": "<combo text>"}      — speak the text via TTS
///   {"coachingVoice": true/false}  — coaching voice toggled on the watch
///
/// After TTS completes, sends {"ttsComplete": true} back to the watch so it
/// can advance to the next combo (when auto-advance + voice are both active),
/// keeping the watch display and phone speech in sync.
///
/// Text transformations applied before speaking:
///   - "counter with" → "Contre" (French)
///   - standalone "L" → "Left" / "Gauche"
///   - standalone "R" → "Right" / "Droite"
///   - ", " separators → short beep tone instead of being spoken
class GarminService {
  static const MethodChannel _methodChannel =
      MethodChannel('org.ginies.jkd/garmin');
  static const EventChannel _eventChannel =
      EventChannel('org.ginies.jkd/garmin_events');

  static final GarminService _instance = GarminService._internal();
  factory GarminService() => _instance;
  GarminService._internal();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _coachingVoiceController =
      StreamController<bool>.broadcast();

  Stream<bool> get onConnectionChanged => _connectionController.stream;
  Stream<bool> get onCoachingVoiceChanged => _coachingVoiceController.stream;

  bool _isConnected = false;
  bool _watchCoachingVoiceActive = false;
  bool _ttsEnabled = false;
  String _language = 'en';

  bool get isConnected => _isConnected;
  bool get watchCoachingVoiceActive => _watchCoachingVoiceActive;

  StreamSubscription? _eventSubscription;
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _beepPlayer = AudioPlayer();
  late final Uint8List _beepWav = _generateBeepWav();
  double _speechRate = 0.5;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  void initialize({
    required bool ttsEnabled,
    required double speechRate,
    String language = 'en',
  }) {
    if (!_isMobile) return;

    _ttsEnabled = ttsEnabled;
    _speechRate = speechRate;
    _language = language;
    _tts.setSpeechRate(_speechRate);

    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleEvent, onError: _handleError);

    _methodChannel.invokeMethod<void>('initialize').catchError((e) {
      LoggingService.log('Garmin initialize error: $e');
    });

    LoggingService.log(
        'GarminService initialized (ttsEnabled=$ttsEnabled, lang=$_language)');
  }

  void _handleEvent(dynamic rawEvent) {
    if (rawEvent is! Map) return;
    final event = Map<String, dynamic>.from(rawEvent as Map);
    final type = event['type'] as String?;

    switch (type) {
      case 'message':
        final rawData = event['data'];
        if (rawData is Map) {
          final data = Map<String, dynamic>.from(rawData);
          if (data.containsKey('speak')) {
            final text = data['speak'] as String?;
            if (text != null && _ttsEnabled) {
              _speakCombo(text);
            } else {
              // TTS disabled but watch may be waiting: ack immediately.
              _sendTtsComplete();
            }
          }
          if (data.containsKey('coachingVoice')) {
            final active = data['coachingVoice'] == true;
            if (active != _watchCoachingVoiceActive) {
              _watchCoachingVoiceActive = active;
              _coachingVoiceController.add(_watchCoachingVoiceActive);
              LoggingService.log('Watch coaching voice: $active');
            }
          }
        }
        break;

      case 'deviceStatus':
        final status = event['status'] as String?;
        final connected = status == 'CONNECTED';
        if (connected != _isConnected) {
          _isConnected = connected;
          _connectionController.add(_isConnected);
          LoggingService.log('Garmin device status: $status');
        }
        break;

      case 'sdkReady':
        LoggingService.log(
            'Garmin SDK ready (${event['deviceCount']} devices)');
        break;

      case 'error':
        LoggingService.log('Garmin SDK: ${event['message']}');
        break;
    }
  }

  void _handleError(dynamic error) {
    LoggingService.log('Garmin EventChannel error: $error');
  }

  /// Applies all text substitutions and splits on ", " into speakable fragments.
  List<String> _prepareFragments(String raw) {
    final bool fr = _language == 'fr';
    var text = raw;

    // "counter with" comes from the watch's " -> " conversion.
    if (fr) {
      text = text.replaceAll('counter with', 'Contre');
    }

    // Expand standalone L / R.
    text = text
        .replaceAllMapped(RegExp(r'\bL\b'), (_) => fr ? 'Gauche' : 'Left')
        .replaceAllMapped(RegExp(r'\bR\b'), (_) => fr ? 'Droite' : 'Right');

    // Split on the ", " separator the watch inserts between moves.
    return text.split(', ').where((s) => s.trim().isNotEmpty).toList();
  }

  /// Speaks each fragment with a short beep between them, then acks the watch.
  Future<void> _speakCombo(String raw) async {
    final fragments = _prepareFragments(raw);
    LoggingService.log('Garmin TTS fragments: $fragments');

    for (int i = 0; i < fragments.length; i++) {
      await _speakFragment(fragments[i]);
      if (i < fragments.length - 1) {
        await _playBeep();
      }
    }

    _sendTtsComplete();
  }

  Future<void> _speakFragment(String text) async {
    final completer = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setCancelHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(text);
    await completer.future;
  }

  Future<void> _playBeep() async {
    final completer = Completer<void>();
    _beepPlayer.onPlayerComplete.first.then((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await _beepPlayer.play(BytesSource(_beepWav));
    await completer.future;
  }

  void _sendTtsComplete() {
    _methodChannel.invokeMethod<void>('sendTtsComplete').catchError((e) {
      LoggingService.log('Garmin sendTtsComplete error: $e');
    });
  }

  /// Generates a minimal in-memory WAV: 880 Hz, 70 ms, 8-bit mono, 8000 Hz,
  /// with short fade-in/out to avoid clicks.
  static Uint8List _generateBeepWav() {
    const sampleRate = 8000;
    const durationMs = 70;
    const frequency = 880.0;
    const amplitude = 90; // 0–127 for unsigned 8-bit PCM

    final numSamples = sampleRate * durationMs ~/ 1000;
    final fadeLen = numSamples ~/ 8;

    final pcm = Uint8List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      double envelope = 1.0;
      if (i < fadeLen) envelope = i / fadeLen;
      if (i > numSamples - fadeLen) envelope = (numSamples - i) / fadeLen;
      final sample =
          amplitude * envelope * math.sin(2 * math.pi * frequency * i / sampleRate);
      pcm[i] = (127 + sample).round().clamp(0, 255);
    }

    // Build WAV file in memory.
    final wav = ByteData(44 + numSamples);
    void setStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        wav.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    setStr(0, 'RIFF');
    wav.setUint32(4, 36 + numSamples, Endian.little);
    setStr(8, 'WAVE');
    setStr(12, 'fmt ');
    wav.setUint32(16, 16, Endian.little); // fmt chunk size
    wav.setUint16(20, 1, Endian.little);  // PCM
    wav.setUint16(22, 1, Endian.little);  // mono
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate, Endian.little); // byte rate (8-bit mono)
    wav.setUint16(32, 1, Endian.little);  // block align
    wav.setUint16(34, 8, Endian.little);  // bits per sample
    setStr(36, 'data');
    wav.setUint32(40, numSamples, Endian.little);
    final result = wav.buffer.asUint8List();
    result.setRange(44, 44 + numSamples, pcm);
    return result;
  }

  void setTtsEnabled(bool enabled) {
    _ttsEnabled = enabled;
    if (!enabled) _tts.stop();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate;
    _tts.setSpeechRate(rate);
  }

  void setLanguage(String language) {
    _language = language;
  }

  Future<bool> isWatchConnected() async {
    if (!_isMobile) return false;
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isWatchConnected');
      return result ?? false;
    } catch (e) {
      LoggingService.log('Garmin isWatchConnected error: $e');
      return false;
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _connectionController.close();
    _coachingVoiceController.close();
    _beepPlayer.dispose();
  }
}
