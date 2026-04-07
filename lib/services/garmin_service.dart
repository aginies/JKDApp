import 'dart:async';
import 'dart:io';

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
/// can advance to the next combo (when auto-advance + voice are both active).
/// This keeps the watch display and the phone's speech fully in sync.
///
/// "L" / "R" tokens are expanded to Left/Right (or Gauche/Droite in French).
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

    LoggingService.log('GarminService initialized (ttsEnabled=$ttsEnabled, lang=$_language)');
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
              _speak(_expandSideTokens(text));
            } else {
              // TTS disabled but watch is waiting: still ack so it can advance.
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
        LoggingService.log('Garmin SDK ready (${event['deviceCount']} devices)');
        break;

      case 'error':
        LoggingService.log('Garmin SDK: ${event['message']}');
        break;
    }
  }

  void _handleError(dynamic error) {
    LoggingService.log('Garmin EventChannel error: $error');
  }

  /// Replaces standalone "L" → Left/Gauche and "R" → Right/Droite.
  String _expandSideTokens(String text) {
    final bool fr = _language == 'fr';
    return text
        .replaceAllMapped(RegExp(r'\bL\b'), (_) => fr ? 'Gauche' : 'Left')
        .replaceAllMapped(RegExp(r'\bR\b'), (_) => fr ? 'Droite' : 'Right');
  }

  Future<void> _speak(String text) async {
    final completer = Completer<void>();

    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setCancelHandler(() {
      if (!completer.isCompleted) completer.complete();
    });

    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(text);
    LoggingService.log('Garmin TTS: "$text"');

    await completer.future;
    _sendTtsComplete();
  }

  void _sendTtsComplete() {
    _methodChannel.invokeMethod<void>('sendTtsComplete').catchError((e) {
      LoggingService.log('Garmin sendTtsComplete error: $e');
    });
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
      final result = await _methodChannel.invokeMethod<bool>('isWatchConnected');
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
  }
}
