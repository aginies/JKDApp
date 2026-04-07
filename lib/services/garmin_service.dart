import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'logging_service.dart';

/// Bridges Garmin ConnectIQ watch messages to Flutter TTS.
///
/// The Garmin watch app sends two message types:
///   {"speak": "<combo text>"}      — speak the text via TTS when enabled
///   {"coachingVoice": true/false}  — notify that coaching voice was toggled on the watch
///
/// Platform channels are only activated on Android/iOS. On desktop (Linux/Windows/macOS)
/// all calls are no-ops and the streams never emit.
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

  bool get isConnected => _isConnected;
  bool get watchCoachingVoiceActive => _watchCoachingVoiceActive;

  StreamSubscription? _eventSubscription;
  final FlutterTts _tts = FlutterTts();
  double _speechRate = 0.5;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  void initialize({required bool ttsEnabled, required double speechRate}) {
    if (!_isMobile) return;

    _ttsEnabled = ttsEnabled;
    _speechRate = speechRate;
    _tts.setSpeechRate(_speechRate);

    // Subscribe to events first, then tell the native side to start the SDK.
    // Calling the native SDK from configureFlutterEngine causes "Reply already
    // submitted" crashes; invoking via MethodChannel defers it until the engine
    // is fully ready.
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleEvent, onError: _handleError);

    _methodChannel.invokeMethod<void>('initialize').catchError((e) {
      LoggingService.log('Garmin initialize error: $e');
    });

    LoggingService.log('GarminService initialized (ttsEnabled=$ttsEnabled)');
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
            if (text != null && _ttsEnabled) _speak(text);
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

  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(text);
    LoggingService.log('Garmin TTS: "$text"');
  }

  void setTtsEnabled(bool enabled) {
    _ttsEnabled = enabled;
  }

  void setSpeechRate(double rate) {
    _speechRate = rate;
    _tts.setSpeechRate(rate);
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
  }
}
