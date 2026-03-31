import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';

class TrainingOptions {
  final int startIndex;
  final int endIndex;
  final int interval;
  final int comboInterval;
  final bool isLooping;
  final double speechRate;

  TrainingOptions({
    required this.startIndex,
    required this.endIndex,
    required this.interval,
    required this.comboInterval,
    required this.isLooping,
    required this.speechRate,
  });
}

class TrainingOptionsDialog {
  static Future<TrainingOptions?> show(
    BuildContext context,
    String language,
    int movesCount,
    int currentInterval,
    int currentComboInterval,
    double currentSpeechRate,
  ) async {
    int trainingStartIndex = 1;
    int trainingEndIndex = movesCount;
    int trainingInterval = currentInterval;
    int trainingComboInterval = currentComboInterval;
    double trainingSpeechRate = currentSpeechRate;
    bool isLooping = false;

    final result = await showModalBottomSheet<TrainingOptions>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocalizationService.translate('training_mode', language),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocalizationService.translate('training_desc', language),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('Start', style: TextStyle(fontSize: 12)),
                      DropdownButton<int>(
                        value: trainingStartIndex,
                        items: List.generate(movesCount, (i) => i + 1)
                            .map(
                              (i) =>
                                  DropdownMenuItem(value: i, child: Text('$i')),
                            )
                            .toList(),
                        onChanged: (val) => setModalState(() {
                          trainingStartIndex = val!;
                          if (trainingEndIndex < trainingStartIndex) {
                            trainingEndIndex = trainingStartIndex;
                          }
                        }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('End', style: TextStyle(fontSize: 12)),
                      DropdownButton<int>(
                        value: trainingEndIndex,
                        items: List.generate(movesCount, (i) => i + 1)
                            .map(
                              (i) =>
                                  DropdownMenuItem(value: i, child: Text('$i')),
                            )
                            .toList(),
                        onChanged: (val) => setModalState(() {
                          trainingEndIndex = val!;
                          if (trainingStartIndex > trainingEndIndex) {
                            trainingEndIndex = trainingEndIndex;
                          }
                        }),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Loop', style: TextStyle(fontSize: 12)),
                      Switch(
                        value: isLooping,
                        onChanged: (val) =>
                            setModalState(() => isLooping = val),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${LocalizationService.translate('interval', language)}: ',
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: trainingInterval.toDouble(),
                      min: 3,
                      max: 20,
                      divisions: 17,
                      label: trainingInterval.toString(),
                      onChanged: (val) =>
                          setModalState(() => trainingInterval = val.toInt()),
                    ),
                  ),
                  Text('$trainingInterval s'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${LocalizationService.translate('combo_interval', language)}: ',
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: trainingComboInterval.toDouble(),
                      min: 500,
                      max: 5000,
                      divisions: 9,
                      label: trainingComboInterval.toString(),
                      onChanged: (val) => setModalState(
                        () => trainingComboInterval = val.toInt(),
                      ),
                    ),
                  ),
                  Text('$trainingComboInterval ms'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${LocalizationService.translate('speech_rate', language)}: ',
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: trainingSpeechRate,
                      min: 0.1,
                      max: 0.8,
                      divisions: 14,
                      label: trainingSpeechRate.toStringAsFixed(2),
                      onChanged: (val) =>
                          setModalState(() => trainingSpeechRate = val),
                    ),
                  ),
                  Text(trainingSpeechRate.toStringAsFixed(2)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(
                    context,
                    TrainingOptions(
                      startIndex: trainingStartIndex,
                      endIndex: trainingEndIndex,
                      interval: trainingInterval,
                      comboInterval: trainingComboInterval,
                      isLooping: isLooping,
                      speechRate: trainingSpeechRate,
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(LocalizationService.translate('start', language)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    return result;
  }
}
