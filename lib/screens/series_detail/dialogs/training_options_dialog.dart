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
    int trainingInterval = currentInterval.clamp(1, 12);
    int trainingComboInterval = currentComboInterval.clamp(500, 4000);
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
              const SizedBox(height: 24),
              // Moves Range Slider
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Moves: $trainingStartIndex - $trainingEndIndex',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
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
                  RangeSlider(
                    values: RangeValues(
                      trainingStartIndex.toDouble(),
                      trainingEndIndex.toDouble(),
                    ),
                    min: 1,
                    max: movesCount.toDouble(),
                    divisions: movesCount > 1 ? movesCount - 1 : 1,
                    labels: RangeLabels(
                      trainingStartIndex.toString(),
                      trainingEndIndex.toString(),
                    ),
                    onChanged: movesCount > 1
                        ? (RangeValues values) {
                            setModalState(() {
                              trainingStartIndex = values.start.round();
                              trainingEndIndex = values.end.round();
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Interval Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${LocalizationService.translate('interval', language)}: ',
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      value: trainingInterval.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: trainingInterval.toString(),
                      onChanged: (val) =>
                          setModalState(() => trainingInterval = val.toInt()),
                    ),
                  ),
                  Text(
                    '$trainingInterval s',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Combo Interval Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${LocalizationService.translate('combo_interval', language)}: ',
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      value: trainingComboInterval.toDouble(),
                      min: 500,
                      max: 4000,
                      divisions: 7,
                      label: trainingComboInterval.toString(),
                      onChanged: (val) => setModalState(
                        () => trainingComboInterval = val.toInt(),
                      ),
                    ),
                  ),
                  Text(
                    '$trainingComboInterval ms',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Speech Rate Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${LocalizationService.translate('speech_rate', language)}: ',
                    ),
                  ),
                  SizedBox(
                    width: 200,
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
                  Text(
                    trainingSpeechRate.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
