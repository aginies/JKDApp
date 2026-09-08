import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/usage_statistics_service.dart';
import '../services/garmin_service.dart';
import '../services/audio_session_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WarmupScreen extends StatefulWidget {
  const WarmupScreen({super.key});

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _hrSubscription;
  int _currentHRFromWatch = 0;

  // Configuration
  int _workDuration = 30;
  int _restDuration = 10;
  int _totalDurationMinutes = 10;

  final Map<String, List<String>> _exerciseCategories = {
    'Squats': [
      'Squats (Classical)',
      'Squats (Low)',
      'Squats (Jump)',
      'Squats (beat)',
    ],
    'Push-ups': [
      'Push-ups (Classical)',
      'Push-ups (Diamond)',
      'Push-ups (Wide)',
      'Push-up 2026',
    ],
    'Crunches': [
      'Crunches (Abs)',
      'Crunches (Leg at 90)',
      'Crunches (Leg at 180)',
      'Ciseaux (Scissors)',
    ],
    'Jumping Jacks': ['Jumping Jacks'],
    'Burpees': ['Burpees'],
    'Mountain Climbers': ['Mountain Climbers', 'Mountain Climbers Diagonal'],
    'Lunges': ['Lunges', 'Lunges (Beat)'],
  };

  final Map<String, String> _frCategories = {
    'Squats': 'Squats',
    'Push-ups': 'Pompes',
    'Crunches': 'Abdominaux',
    'Jumping Jacks': 'Jumping Jacks',
    'Burpees': 'Burpees',
    'Mountain Climbers': 'Mountain Climbers',
    'Lunges': 'Fentes',
  };

  final Map<String, String> _frExercises = {
    'Squats (Classical)': 'Squat (Classique)',
    'Squats (Low)': 'Squat (Bas)',
    'Squats (Jump)': 'Squat (Sauté)',
    'Squats (Beat)': 'Squat (Battement)',
    'Push-ups (Classical)': 'Pompes (Classiques)',
    'Push-ups (Diamond)': 'Pompes (Diamant)',
    'Push-ups (Wide)': 'Pompes (Larges)',
    'Push-up 2026': 'Pompes 2026',
    'Crunches (Abs)': 'Abdominaux',
    'Crunches (Leg at 90)': 'Abdos (Jambes à 90°)',
    'Crunches (Leg at 180)': 'Abdos (Jambes à 180°)',
    'Ciseaux (Scissors)': 'Ciseaux',
    'Jumping Jacks': 'Jumping Jacks',
    'Burpees': 'Burpees',
    'Mountain Climbers': 'Mountain Climbers',
    'Mountain Climbers Diagonal': 'Montée Climbers Croisée',
    'Lunges': 'Fentes',
    'Lunges (Beat)': 'Fentes (Battement)',
  };

  final Set<String> _selectedCategories = {};
  List<String> _workoutSequence = [];

  String _getCategoryName(String name, String lang) {
    if (lang == 'fr' && _frCategories.containsKey(name)) {
      return _frCategories[name]!;
    }
    return name;
  }

  String _getExerciseName(String name, String lang) {
    if (lang == 'fr' && _frExercises.containsKey(name)) {
      return _frExercises[name]!;
    }
    return name;
  }

  // Timer State
  bool _isRunning = false;
  bool _isPaused = false;
  int _currentExerciseIndex = 0;
  bool _isWorkPeriod = true;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _hrSubscription = GarminService().onHeartRateReceived.listen((hr) {
      if (mounted) {
        setState(() {
          _currentHRFromWatch = hr;
        });
      }
    });
  }

  Future<void> _initTts() async {
    if (Platform.isLinux) return;
    try {
      final lang = Provider.of<SeriesProvider>(context, listen: false).language;
      await _tts.setLanguage(lang == 'fr' ? 'fr-FR' : 'en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);

      // Support background music ducking
      if (Platform.isIOS || Platform.isAndroid) {
        await _tts.setSharedInstance(true);
        // Keep the shared AVAudioSession active between lines (iOS):
        // otherwise flutter_tts deactivates it after every utterance and
        // background music un-ducks between lines of a long session.
        await _tts.autoStopSharedSession(false);
        if (Platform.isIOS) {
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              IosTextToSpeechAudioCategoryOptions.duckOthers,
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            ],
          );
        } else if (Platform.isAndroid) {
          await _tts.setAudioAttributesForNavigation();
        }
      }
    } catch (e) {
      debugPrint("Warmup TTS Init Warning: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hrSubscription?.cancel();
    _stopTts();
    _audioPlayer.dispose();
    AudioSessionService.releaseFocus();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _stopTts() async {
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

  void _startWarmup() {
    if (_selectedCategories.isEmpty) return;

    // Generate Workout Sequence
    final roundDuration = _workDuration + _restDuration;
    final totalSeconds = _totalDurationMinutes * 60;
    int numRounds = (totalSeconds / roundDuration).floor();

    // Ensure at least enough rounds for one of each selected category
    if (numRounds < _selectedCategories.length) {
      numRounds = _selectedCategories.length;
    }

    final random = math.Random();
    List<String> sequence = [];
    String? lastCategory;

    for (int i = 0; i < numRounds; i++) {
      // Pick a category that is different from the last one (if possible)
      List<String> availableCategories = _selectedCategories.toList();
      if (availableCategories.length > 1 && lastCategory != null) {
        availableCategories.remove(lastCategory);
      }

      final category =
          availableCategories[random.nextInt(availableCategories.length)];
      lastCategory = category;

      // Pick a random variation from that category
      final variations = _exerciseCategories[category]!;
      final variation = variations[random.nextInt(variations.length)];
      sequence.add(variation);
    }

    // Ensure all selected categories appear at least once if rounds allow
    if (numRounds >= _selectedCategories.length) {
      for (var cat in _selectedCategories) {
        bool exists = sequence.any(
          (ex) => _exerciseCategories[cat]!.contains(ex),
        );
        if (!exists) {
          // Replace a random entry (not the same category neighbor)
          // Simplified: find first occurrence that doesn't break "no-repeat" rule
          for (int j = 0; j < sequence.length; j++) {
            // Check neighbors
            String? prevCat;
            if (j > 0) {
              prevCat = _exerciseCategories.entries
                  .firstWhere((e) => e.value.contains(sequence[j - 1]))
                  .key;
            }
            String? nextCat;
            if (j < sequence.length - 1) {
              nextCat = _exerciseCategories.entries
                  .firstWhere((e) => e.value.contains(sequence[j + 1]))
                  .key;
            }

            if (prevCat != cat && nextCat != cat) {
              final variations = _exerciseCategories[cat]!;
              sequence[j] = variations[random.nextInt(variations.length)];
              break;
            }
          }
        }
      }
    }

    setState(() {
      _workoutSequence = sequence;
      _isRunning = true;
      _isPaused = false;
      _currentExerciseIndex = 0;
      _isWorkPeriod = true;
      _secondsRemaining = _workDuration;
    });

    // Record activity in usage statistics
    UsageStatisticsService().recordActivity('Warmup');

    final keepScreenOn = Provider.of<SeriesProvider>(context, listen: false).keepScreenOn;
    if (keepScreenOn) {
      WakelockPlus.enable();
    }

    // Hold audio focus for the whole warmup session so background music
    // stays ducked between lines (released in _stopWarmup()/dispose()).
    AudioSessionService.acquireFocus();

    _runTimer();
    _speakExercise();
  }

  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        if (_secondsRemaining > 0) {
          if (!_isWorkPeriod && _secondsRemaining == 4) {
            _countdownAndStart();
          }

          if (_secondsRemaining <= 3) {
            _playBeep(0.5); // Beep during each of the last 3 seconds
          }

          _secondsRemaining--;
        } else {
          _nextPeriod();
        }
      });
    });
  }

  void _nextPeriod() async {
    _playBeep(1.0); // Long beep
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;

    if (_isWorkPeriod) {
      // Switch to Rest
      setState(() {
        _isWorkPeriod = false;
        _secondsRemaining = _restDuration;
      });

      String restMsg = lang == 'fr' ? 'Repos' : 'Rest';
      if (_currentExerciseIndex < _workoutSequence.length - 1) {
        final nextEx = _workoutSequence[_currentExerciseIndex + 1];
        final nextExName = _getExerciseName(nextEx, lang);
        final nextLabel = lang == 'fr' ? 'Prochain' : 'Next';
        // Only announce the next exercise name at start of rest, no countdown yet
        await _speak('$restMsg. $nextLabel: $nextExName');
      } else {
        await _speak(restMsg);
      }
    } else {
      // Switch to next Exercise Work
      if (_currentExerciseIndex < _workoutSequence.length - 1) {
        setState(() {
          _currentExerciseIndex++;
          _isWorkPeriod = true;
          _secondsRemaining = _workDuration;
        });
        // Countdown already happened during rest
      } else {
        // Finished
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        await _speak(lang == 'fr' ? 'Échauffement terminé' : 'Warm up complete');
        AudioSessionService.releaseFocus();
        WakelockPlus.disable();
      }
    }
  }

  Future<void> _countdownAndStart() async {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;

    await _speak('3');
    await _speak('2');
    await _speak('1');
    await _speak(lang == 'fr' ? 'Go !' : 'Go !');
  }

  Future<void> _speakExercise() async {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    final exercise = _workoutSequence[_currentExerciseIndex];
    final exerciseName = _getExerciseName(exercise, lang);
    await _speak(exerciseName);
    await _speak('Go !');
  }

  Future<void> _speak(String text) async {
    if (Platform.isLinux) {
      try {
        final lang = Provider.of<SeriesProvider>(
          context,
          listen: false,
        ).language;
        await Process.run('spd-say', ['-l', lang, '-w', text]);
      } catch (e) {
        debugPrint("spd-say warning: $e");
      }
    } else {
      try {
        await _tts.speak(text, focus: true);
      } catch (e) {
        debugPrint("TTS speak error: $e");
      }
    }
  }

  void _playBeep(double volume) {
    // Rely on TTS or system beeps for now
  }

  void _stopWarmup() {
    _timer?.cancel();
    _stopTts();
    AudioSessionService.releaseFocus();
    WakelockPlus.disable();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SeriesProvider>(context).language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _isRunning
          ? _buildTimerUI(lang, isDark)
          : _buildConfigUI(lang, isDark),
    );
  }

  Widget _buildConfigUI(String lang, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.translate('exercises', lang),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _exerciseCategories.keys.map((cat) {
              final isSelected = _selectedCategories.contains(cat);
              return FilterChip(
                label: Text(_getCategoryName(cat, lang)),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedCategories.add(cat);
                    } else {
                      _selectedCategories.remove(cat);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const Divider(height: 32),
          _buildSlider(
            label: LocalizationService.translate('duration', lang),
            value: _totalDurationMinutes.toDouble(),
            min: 1,
            max: 30,
            onChanged: (val) =>
                setState(() => _totalDurationMinutes = val.toInt()),
            unit: ' min',
          ),
          _buildSlider(
            label: LocalizationService.translate('work', lang),
            value: _workDuration.toDouble(),
            min: 15,
            max: 120,
            onChanged: (val) => setState(() => _workDuration = val.toInt()),
            unit: 's',
          ),
          _buildSlider(
            label: LocalizationService.translate('rest', lang),
            value: _restDuration.toDouble(),
            min: 5,
            max: 30,
            onChanged: (val) => setState(() => _restDuration = val.toInt()),
            unit: 's',
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedCategories.isEmpty ? null : _startWarmup,
              icon: const Icon(Icons.play_arrow),
              label: Text(LocalizationService.translate('start_warmup', lang)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${value.toInt()}$unit',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimerUI(String lang, bool isDark) {
    final currentExercise = _workoutSequence[_currentExerciseIndex];
    final currentExerciseName = _getExerciseName(currentExercise, lang);
    final color = _isWorkPeriod ? Colors.green : Colors.red;
    final nextExercise = _currentExerciseIndex < _workoutSequence.length - 1
        ? _workoutSequence[_currentExerciseIndex + 1]
        : null;
    final nextExerciseName = nextExercise != null
        ? _getExerciseName(nextExercise, lang)
        : null;

    // Calculate total progress
    final totalRounds = _workoutSequence.length;
    final roundDuration = _workDuration + _restDuration;
    final totalWorkoutSeconds = totalRounds * roundDuration;

    // Seconds already elapsed in completed rounds
    final completedRoundsSeconds = _currentExerciseIndex * roundDuration;
    // Seconds elapsed in current round
    int currentRoundElapsed = 0;
    if (_isWorkPeriod) {
      currentRoundElapsed = _workDuration - _secondsRemaining;
    } else {
      currentRoundElapsed = _workDuration + (_restDuration - _secondsRemaining);
    }

    final totalElapsedSeconds = completedRoundsSeconds + currentRoundElapsed;
    final totalPercent = (totalElapsedSeconds / totalWorkoutSeconds).clamp(
      0.0,
      1.0,
    );
    final totalRemainingSeconds = totalWorkoutSeconds - totalElapsedSeconds;

    String formatDuration(int totalSecs) {
      final mins = (totalSecs / 60).floor();
      final secs = totalSecs % 60;
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }

    Color getHRColor(int hr) {
      if (hr < 100) return Colors.grey;
      if (hr < 120) return Colors.blue;
      if (hr < 140) return Colors.green;
      if (hr < 160) return Colors.orange;
      return Colors.red;
    }

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(totalPercent * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          formatDuration(totalRemainingSeconds),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: totalPercent,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      minHeight: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _isWorkPeriod
                    ? LocalizationService.translate('work', lang).toUpperCase()
                    : LocalizationService.translate('rest', lang).toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentExerciseName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!_isWorkPeriod && nextExerciseName != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${lang == 'fr' ? 'Prochain' : 'Next'}: $nextExerciseName',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value:
                          _secondsRemaining /
                          (_isWorkPeriod ? _workDuration : _restDuration),
                      strokeWidth: 12,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.2),
                    ),
                  ),
                  Text(
                    '$_secondsRemaining',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: _togglePause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    iconSize: 48,
                  ),
                  const SizedBox(width: 32),
                  IconButton.filled(
                    onPressed: _stopWarmup,
                    icon: const Icon(Icons.stop),
                    iconSize: 48,
                    style: IconButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${_currentExerciseIndex + 1} / ${_workoutSequence.length}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const Spacer(),
            ],
          ),
          if (_currentHRFromWatch > 0)
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                children: [
                  Icon(Icons.favorite, color: getHRColor(_currentHRFromWatch)),
                  const SizedBox(width: 4),
                  Text(
                    '$_currentHRFromWatch',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: getHRColor(_currentHRFromWatch),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
