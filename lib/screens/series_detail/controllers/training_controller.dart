import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../models/move.dart';
import '../../../services/localization_service.dart';
import '../../../services/garmin_service.dart';

class TtsLine {
  final String text;
  final int delayMs;
  TtsLine(this.text, this.delayMs);
}

class TrainingController {
  final FlutterTts _tts;
  final Function(int) onIndexChanged;
  final Function(int) onSubIndexChanged;
  final Function() onTrainingComplete;
  final BuildContext context;
  final GarminService _garminService = GarminService();

  bool _isTraining = false;
  bool _isPaused = false;
  int _currentIndex = -1;
  int _subIndex = -1; // -1 = not speaking any sub-item yet
  Timer? _timer;

  // Stored parameters for resume
  List<Move>? _moves;
  int? _startIndex;
  int? _endIndex;
  int? _interval;
  int? _comboInterval;
  bool? _isLooping;
  String? _language;

  TrainingController({
    required FlutterTts tts,
    required this.onIndexChanged,
    required this.onSubIndexChanged,
    required this.onTrainingComplete,
    required this.context,
  }) : _tts = tts;

  bool get isTraining => _isTraining;
  bool get isPaused => _isPaused;
  int get currentIndex => _currentIndex;
  int get subIndex => _subIndex;

  Future<void> initTts({double speechRate = 0.50}) async {
    if (Platform.isLinux) return;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(speechRate);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
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

  Future<void> speak(List<TtsLine> lines, String language) async {
    // Sync current move to watch at start of speaking
    if (_moves != null && _currentIndex >= 0 && _currentIndex < _moves!.length) {
      _garminService.syncMoveToWatch(
        text: _getWatchMoveText(_moves![_currentIndex]),
        index: _currentIndex + 1,
        total: _moves!.length,
      );
    }

    // Start from _subIndex (or 0 if sentinel -1)
    final int startFrom = _subIndex < 0 ? 0 : _subIndex;
    for (int i = startFrom; i < lines.length; i++) {
      if (!_isTraining || _isPaused) break;

      // Highlight BEFORE speaking so the UI shows the active sub-item
      _subIndex = i;
      onSubIndexChanged(_subIndex);

      final line = lines[i];
      if (Platform.isLinux) {
        try {
          await Process.run('spd-say', ['-l', language, '-w', line.text]);
        } catch (e) {
          debugPrint("spd-say warning: $e");
        }
      } else {
        await _tts.speak(line.text);
      }

      if (!_isTraining || _isPaused) break;

      if (line.delayMs > 0 && i < lines.length - 1) {
        await Future.delayed(Duration(milliseconds: line.delayMs));
      }
    }

    // After all lines spoken, mark sub-index past end for _playStep check
    if (_isTraining && !_isPaused) {
      _subIndex = lines.length;
    }
  }

  Future<void> stopTts() async {
    if (Platform.isLinux) {
      try {
        await Process.run('spd-say', ['-S']);
      } catch (e) {
        debugPrint("spd-say stop warning: $e");
      }
    } else {
      await _tts.stop();
    }
  }

  Future<void> startTraining({
    required List<Move> moves,
    required int startIndex,
    required int endIndex,
    required int interval,
    required int comboInterval,
    required bool isLooping,
    required String language,
    double speechRate = 0.50,
  }) async {
    _moves = moves;
    _startIndex = startIndex;
    _endIndex = endIndex;
    _interval = interval;
    _comboInterval = comboInterval;
    _isLooping = isLooping;
    _language = language;

    await setLanguage(language);
    if (!Platform.isLinux) {
      await _tts.setSpeechRate(speechRate);
    }

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
    _isPaused = false;
    _currentIndex = startIndex - 1;
    _subIndex = -1;
    onIndexChanged(_currentIndex);

    _playStep(
      moves: moves,
      startIndex: startIndex,
      endIndex: endIndex,
      interval: interval,
      comboInterval: comboInterval,
      isLooping: isLooping,
      language: language,
    );
  }

  void pause() {
    if (!_isTraining || _isPaused) return;
    _isPaused = true;
    _timer?.cancel();
    stopTts();
    onIndexChanged(_currentIndex); // Trigger UI update for pause state
  }

  void resume() {
    if (!_isTraining || !_isPaused) return;
    _isPaused = false;
    onIndexChanged(_currentIndex);
    if (_moves != null &&
        _startIndex != null &&
        _endIndex != null &&
        _interval != null &&
        _comboInterval != null &&
        _isLooping != null &&
        _language != null) {
      _playStep(
        moves: _moves!,
        startIndex: _startIndex!,
        endIndex: _endIndex!,
        interval: _interval!,
        comboInterval: _comboInterval!,
        isLooping: _isLooping!,
        language: _language!,
      );
    }
  }

  void _playStep({
    required List<Move> moves,
    required int startIndex,
    required int endIndex,
    required int interval,
    required int comboInterval,
    required bool isLooping,
    required String language,
  }) async {
    if (!_isTraining || _isPaused) return;

    if (_currentIndex >= endIndex) {
      if (isLooping) {
        _currentIndex = startIndex - 1;
        _subIndex = -1;
        onIndexChanged(_currentIndex);
      } else {
        stop();
        return;
      }
    }

    final lines = _buildTtsTextList(
      moves[_currentIndex],
      language,
      comboInterval,
    );
    await speak(lines, language);

    if (_isPaused) return;

    // If we finished all lines for this move, move to next after interval
    if (_subIndex >= lines.length) {
      _subIndex = -1; // Sentinel: no sub-item active between moves
      onSubIndexChanged(_subIndex);
      _timer = Timer(Duration(seconds: interval), () {
        if (_isTraining && !_isPaused) {
          _currentIndex++;
          onIndexChanged(_currentIndex);
          _playStep(
            moves: moves,
            startIndex: startIndex,
            endIndex: endIndex,
            interval: interval,
            comboInterval: comboInterval,
            isLooping: isLooping,
            language: language,
          );
        }
      });
    } else {
      // We paused in the middle of a combo, resume() will handle it
    }
  }

  List<TtsLine> _buildTtsTextList(
    Move move,
    String language,
    int comboInterval,
  ) {
    List<TtsLine> lines = [];

    void addMoveLines(Move m) {
      StringBuffer sb = StringBuffer();
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

      // If there is an answer, add the hit with 1s delay
      if (m.counterName != null) {
        lines.add(TtsLine(sb.toString().trim(), 1000));
        StringBuffer csb = StringBuffer();
        csb.write('${LocalizationService.translate('answer', language)} ');
        if (m.counterSide != null) {
          csb.write(
            '${LocalizationService.translate(m.counterSide == 'L' ? 'left' : 'right', language)} ',
          );
        }
        csb.write('${m.counterName} ');
        if (m.counterLevel != null) {
          csb.write(
            '${LocalizationService.translate(m.counterLevel!.toLowerCase(), language)} ',
          );
        }
        lines.add(TtsLine(csb.toString().trim(), comboInterval));
      } else {
        // No answer, just the hit with combo delay
        lines.add(TtsLine(sb.toString().trim(), comboInterval));
      }
    }

    if (move.isChain) {
      for (var m in move.chain) {
        addMoveLines(m);
      }
    } else if (!move.isCombo) {
      addMoveLines(move);
    } else {
      for (var sub in move.subMoves) {
        addMoveLines(sub);
      }
    }
    return lines;
  }

  void stop() {
    _timer?.cancel();
    stopTts();
    _isTraining = false;
    _isPaused = false;
    _currentIndex = -1;
    _subIndex = -1;
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

  String _getWatchMoveText(Move move) {
    if (move.isChain) {
      return move.chain.map((m) => _getWatchMoveText(m)).join(' -> ');
    } else if (move.isCombo) {
      return move.subMoves.map((m) => _getWatchMoveText(m)).join(' + ');
    } else {
      StringBuffer sb = StringBuffer();
      if (move.side.isNotEmpty) sb.write('${move.side} ');
      sb.write(move.name);
      if (move.level.isNotEmpty) sb.write(' ${move.level}');
      if (move.counterName != null) {
        sb.write(' -> ');
        if (move.counterSide != null) sb.write('${move.counterSide} ');
        sb.write(move.counterName);
        if (move.counterLevel != null) sb.write(' ${move.counterLevel}');
      }
      return sb.toString();
    }
  }
}
