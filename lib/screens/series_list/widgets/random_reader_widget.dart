import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../../models/series.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import '../../../services/localization_service.dart';

class RandomReaderWidget extends StatefulWidget {
  final String language;
  const RandomReaderWidget({super.key, required this.language});

  @override
  State<RandomReaderWidget> createState() => _RandomReaderWidgetState();
}

class _RandomReaderWidgetState extends State<RandomReaderWidget> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _selectedSeriesId;
  String _selectedGuard = 'L';
  double _delaySeconds = 1.5;
  String _currentMoveDisplay = "";
  String _currentSeriesTitle = "";
  String? _lastSpokenSeriesTitle;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSelection();
  }

  void _initSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SeriesProvider>(context, listen: false);
      final jkdSeries = provider.getFilteredSeries('JKD Moves');
      if (jkdSeries.isNotEmpty && _selectedSeriesId == null) {
        setState(() {
          _selectedSeriesId = jkdSeries.first.id.toString();
        });
      }
    });
  }

  Future<void> _initTts() async {
    if (Platform.isLinux) return;
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    await _tts.setSpeechRate(provider.speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    if (widget.language == 'fr') {
      await _tts.setLanguage('fr-FR');
    } else {
      await _tts.setLanguage('en-US');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!Platform.isLinux) {
      _tts.stop();
    }
    super.dispose();
  }

  void _play() {
    if (_selectedSeriesId == null) return;
    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _startRandomReader();
    });
  }

  void _pause() {
    setState(() {
      _isPaused = true;
      _timer?.cancel();
      if (!Platform.isLinux) {
        _tts.stop();
      }
    });
  }

  void _stop() {
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _timer?.cancel();
      _currentMoveDisplay = "";
      _currentSeriesTitle = "";
      _lastSpokenSeriesTitle = null;
      if (!Platform.isLinux) {
        _tts.stop();
      }
    });
  }

  Future<void> _startRandomReader() async {
    // 1. Announce series name ONCE at the very beginning
    await _announceSeries();
    if (!_isPlaying || _isPaused) return;

    // 2. Wait 1 second as requested
    await Future.delayed(const Duration(seconds: 1));
    if (!_isPlaying || _isPaused) return;

    // 3. Start the move loop
    _readRandomMove();
    _timer = Timer.periodic(
      Duration(milliseconds: (_delaySeconds * 1000).toInt() + 300),
      (timer) {
        if (_isPlaying && !_isPaused) {
          _readRandomMove();
        } else {
          timer.cancel();
        }
      },
    );
  }

  Future<void> _announceSeries() async {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final jkdSeries = provider.getFilteredSeries('JKD Moves');
    final targetSeries = jkdSeries.firstWhere(
      (s) => s.id.toString() == _selectedSeriesId,
      orElse: () => jkdSeries.first,
    );

    setState(() {
      _currentSeriesTitle = targetSeries.title;
      _lastSpokenSeriesTitle = targetSeries.title;
    });

    if (Platform.isLinux) {
      await Process.run('spd-say', ['-l', 'en', '-w', targetSeries.title]);
    } else {
      await _tts.setLanguage('en-US');
      await _tts.speak(targetSeries.title);
    }
  }

  Future<void> _readRandomMove() async {
    if (!_isPlaying || _isPaused || _selectedSeriesId == null) return;

    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final jkdSeries = provider.getFilteredSeries('JKD Moves');

    final targetSeries = jkdSeries.firstWhere(
      (s) => s.id.toString() == _selectedSeriesId,
      orElse: () => jkdSeries.first,
    );

    final availableMoves =
        targetSeries.moves.where((m) => m.side == _selectedGuard).toList();

    if (availableMoves.isEmpty) {
      _stop();
      return;
    }

    final move = availableMoves[_random.nextInt(availableMoves.length)];
    String prefix = "";
    if (move.name.contains(':')) {
      prefix = "${move.name.split(':').first.trim()}: ";
    }

    String moveNumber = "";
    if (move.name.contains(':')) {
      moveNumber = move.name.split(':').first.trim();
    } else {
      moveNumber = move.name;
    }

    setState(() {
      _currentSeriesTitle = targetSeries.title;
      String translatedName = move.getTranslation(widget.language);
      if (translatedName.isEmpty) {
        translatedName = move.name.contains(':')
            ? move.name.split(':').last.trim()
            : move.name;
      }
      _currentMoveDisplay = prefix + translatedName;
    });

    if (Platform.isLinux) {
      try {
        await Process.run('spd-say', ['-l', widget.language, '-w', moveNumber]);
      } catch (e) {
        debugPrint("spd-say warning: $e");
      }
    } else {
      // Ensure language is set for the move number
      if (widget.language == 'fr') {
        await _tts.setLanguage('fr-FR');
      } else {
        await _tts.setLanguage('en-US');
      }
      await _tts.speak(moveNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context);
    final jkdSeries = provider.getFilteredSeries('JKD Moves');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                widget.language == 'fr' ? 'Lecteur Aléatoire' : 'Random Reader',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (!_isPlaying)
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green, size: 32),
                  onPressed: _play,
                )
              else ...[
                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, 
                    color: _isPaused ? Colors.green : Colors.orange, 
                    size: 32
                  ),
                  onPressed: _isPaused ? _play : _pause,
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.red, size: 32),
                  onPressed: _stop,
                ),
              ],
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language == 'fr' ? 'Série' : 'Series',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _selectedSeriesId,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.blue.withValues(alpha: 0.2)),
                      items: jkdSeries.map((s) => DropdownMenuItem(
                        value: s.id.toString(),
                        child: Text(s.title, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (_isPlaying && !_isPaused) ? null : (val) => setState(() => _selectedSeriesId = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language == 'fr' ? 'Garde' : 'Guard',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _selectedGuard,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.blue.withValues(alpha: 0.2)),
                      items: [
                        DropdownMenuItem(
                          value: 'L',
                          child: Text(
                            LocalizationService.translate('left', widget.language),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'R',
                          child: Text(
                            LocalizationService.translate('right', widget.language),
                          ),
                        ),
                      ],
                      onChanged: (_isPlaying && !_isPaused) ? null : (val) => setState(() => _selectedGuard = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language == 'fr' ? 'Délai' : 'Delay',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<double>(
                      value: _delaySeconds,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.blue.withValues(alpha: 0.2)),
                      items: [0.4, 0.6, 0.8, 1.0, 1.5, 2.0, 2.5].map((d) => DropdownMenuItem(
                        value: d,
                        child: Text('${d}s'),
                      )).toList(),
                      onChanged: (_isPlaying && !_isPaused) ? null : (val) => setState(() => _delaySeconds = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentMoveDisplay.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _currentSeriesTitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentMoveDisplay.toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.blue[300] : Colors.blue[900],
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      LocalizationService.translate(
                        _selectedGuard == 'L' ? 'left' : 'right',
                        widget.language,
                      ).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
