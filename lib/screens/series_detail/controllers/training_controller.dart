import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../models/move.dart';
import '../../../services/localization_service.dart';

class TrainingController {
  final FlutterTts _tts;
  final Function(int) onIndexChanged;
  final Function() onTrainingComplete;
  final BuildContext context;

  bool _isTraining = false;
  int _currentIndex = -1;
  Timer? _timer;

  TrainingController({
    required FlutterTts tts,
    required this.onIndexChanged,
    required this.onTrainingComplete,
    required this.context,
  }) : _tts = tts;

  bool get isTraining => _isTraining;
  int get currentIndex => _currentIndex;

  Future<void> initTts() async {
    if (Platform.isLinux) return;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.3);
      await _tts.setPitch(1.0);
      if (Platform.isIOS || Platform.isAndroid) {
        await _tts.setSharedInstance(true);
        if (Platform.isIOS) {
          await _tts
              .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
                IosTextToSpeechAudioCategoryOptions.duckOthers,
                IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              ]);
        }
      }
    } catch (e) {
      debugPrint("TTS Init Warning: $e");
    }
  }

  Future<void> setLanguage(String language) async {
    if (Platform.isLinux) return;
    try {
      if (language == 'fr') {
        await _tts.setLanguage('fr-FR');
      } else {
        await _tts.setLanguage('en-US');
      }
    } catch (e) {
      debugPrint("TTS Language Warning: $e");
    }
  }

  Future<void> speak(String text, String language) async {
    if (Platform.isLinux) {
      await Process.run('spd-say', ['-l', language, text]);
    } else {
      await _tts.speak(text);
    }
  }

  Future<void> stopTts() async {
    if (Platform.isLinux) {
      await Process.run('spd-say', ['-S']);
    } else {
      await _tts.stop();
    }
  }

  Future<void> startTraining({
    required List<Move> moves,
    required int startIndex,
    required int endIndex,
    required int interval,
    required bool isLooping,
    required String language,
  }) async {
    await setLanguage(language);

    // Countdown
    int countdown = 3;
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) {
            Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 1) {
                if (ctx.mounted) setS(() => countdown--);
              } else {
                t.cancel();
                if (ctx.mounted) Navigator.pop(ctx);
              }
            });
            return AlertDialog(
              backgroundColor: Colors.black.withValues(alpha: 0.8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocalizationService.translate(
                      'training_starts_in',
                      language,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$countdown',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    _isTraining = true;
    _currentIndex = startIndex - 1;
    onIndexChanged(_currentIndex);

    _playStep(
      moves: moves,
      startIndex: startIndex,
      endIndex: endIndex,
      interval: interval,
      isLooping: isLooping,
      language: language,
    );
  }

  void _playStep({
    required List<Move> moves,
    required int startIndex,
    required int endIndex,
    required int interval,
    required bool isLooping,
    required String language,
  }) async {
    if (!_isTraining) return;

    if (_currentIndex >= endIndex) {
      if (isLooping) {
        _currentIndex = startIndex - 1;
        onIndexChanged(_currentIndex);
      } else {
        stop();
        return;
      }
    }

    await speak(_buildTtsText(moves[_currentIndex], language), language);

    _timer = Timer(Duration(seconds: interval), () {
      if (_isTraining) {
        _currentIndex++;
        onIndexChanged(_currentIndex);
        _playStep(
          moves: moves,
          startIndex: startIndex,
          endIndex: endIndex,
          interval: interval,
          isLooping: isLooping,
          language: language,
        );
      }
    });
  }

  String _buildTtsText(Move move, String language) {
    StringBuffer sb = StringBuffer();
    void addInfo(Move m) {
      if (m.side.isNotEmpty) {
        sb.write(
          '${LocalizationService.translate(m.side == 'L' ? 'left' : 'right', language)} ',
        );
      }
      sb.write('${m.name} ');
      if (m.level.isNotEmpty) {
        sb.write(
          '${LocalizationService.translate(m.level.toLowerCase(), language)} ',
        );
      }
      if (m.specialAction != null) sb.write('${m.specialAction} ');
      if (m.counterName != null) {
        sb.write('${LocalizationService.translate('answer', language)} ');
        if (m.counterSide != null) {
          sb.write(
            '${LocalizationService.translate(m.counterSide == 'L' ? 'left' : 'right', language)} ',
          );
        }
        sb.write('${m.counterName} ');
        if (m.counterLevel != null) {
          sb.write(
            '${LocalizationService.translate(m.counterLevel!.toLowerCase(), language)} ',
          );
        }
      }
    }

    if (!move.isCombo) {
      addInfo(move);
    } else {
      for (var sub in move.subMoves) {
        addInfo(sub);
        sb.write('. ');
      }
    }
    return sb.toString();
  }

  void stop() {
    _timer?.cancel();
    stopTts();
    _isTraining = false;
    _currentIndex = -1;
    onTrainingComplete();
  }

  void dispose() {
    _timer?.cancel();
    // Fire-and-forget async stop, with platform check to avoid plugin errors
    if (!Platform.isLinux) {
      _tts.stop().catchError((e) {
        debugPrint("TTS stop warning: $e");
        return null;
      });
    } else {
      // On Linux, try to stop spd-say
      try {
        Process.run('spd-say', ['-S']);
      } catch (e) {
        debugPrint("spd-say stop warning: $e");
      }
    }
  }
}
