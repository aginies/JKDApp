import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import '../../../services/localization_service.dart';
import '../controllers/training_controller.dart';
import '../dialogs/training_options_dialog.dart';

/// Service for handling training functionality in series detail screen
class TrainingManagementService {
  /// Show training options dialog and start training if configured
  Future<TrainingOptions?> showTrainingOptions(
    BuildContext context,
    List<Move> moves,
    int currentTrainingInterval,
    int currentComboInterval,
    TrainingController trainingController,
  ) async {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;
    final options = await TrainingOptionsDialog.show(
      context,
      lang,
      moves.length,
      currentTrainingInterval,
      currentComboInterval,
      provider.speechRate,
    );

    if (options != null) {
      trainingController.startTraining(
        moves: moves,
        startIndex: options.startIndex,
        endIndex: options.endIndex,
        interval: options.interval,
        comboInterval: options.comboInterval,
        isLooping: options.isLooping,
        language: lang,
        speechRate: options.speechRate,
      );

      return options;
    }

    return null;
  }

  /// Show completion dialog after training is finished
  void showCompletionDialog(
    BuildContext context,
    Map<String, dynamic> completionInfo,
    SeriesProvider provider,
  ) {
    final lang = provider.language;
    final dayCompleted = completionInfo['dayCompleted'] == true;

    if (dayCompleted) {
      // Day completed! Show celebration dialog
      final dayNumber = completionInfo['dayNumber'] as int;
      final streak = completionInfo['streak'] as int;
      final progress = (completionInfo['progress'] as double) * 100;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Colors.amber, size: 80),
              const SizedBox(height: 16),
              Text(
                '${LocalizationService.translate('day', lang)} $dayNumber ${LocalizationService.translate('finish', lang)}!',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (streak > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '$streak ${LocalizationService.translate('days', lang)}!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 8),
              Text(
                '${progress.toStringAsFixed(1)}% ${LocalizationService.translate('progress', lang)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocalizationService.translate('finish', lang)),
            ),
          ],
        ),
      );
    } else {
      // Series completed but day not finished yet
      final completedSeries = completionInfo['completedSeries'] as int;
      final totalSeries = completionInfo['totalSeries'] as int;
      final currentSeriesCount =
          completionInfo['currentSeriesCount'] as int? ?? 0;

      String message;
      if (currentSeriesCount >= 2) {
        // Series is fully complete (2 reps done)
        message =
            '${LocalizationService.translate('finish', lang)}! ✓ ($completedSeries/$totalSeries ${LocalizationService.translate('series_title', lang)})';
      } else {
        // Series partially complete (1 rep done)
        message =
            '${LocalizationService.translate('finish', lang)}! ($currentSeriesCount/2 reps) - $completedSeries/$totalSeries ${LocalizationService.translate('series_title', lang)}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: currentSeriesCount >= 2
              ? Colors.green
              : Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }
}
