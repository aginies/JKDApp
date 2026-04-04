import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import '../../../services/localization_service.dart';
import '../builders/advanced_combo_builder.dart';
import '../../../services/logging_service.dart';
import 'combo_verification_service.dart';
import 'training_result_view.dart';

class TrainingModeDialogs {
  static void showItemSelection(BuildContext context, List<Move> moves) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocalizationService.translate('select_item_to_train', lang),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: moves.length,
                  itemBuilder: (ctx, index) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startTraining(context, moves, index);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: provider.themeColor.withValues(alpha: 0.1),
                        foregroundColor: provider.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocalizationService.translate('cancel', lang)),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _startTraining(BuildContext context, List<Move> moves, int index) async {
    final originalMove = moves[index];
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    LoggingService.log('TrainingModeDialogs: Starting builder for item #${index + 1}');
    
    // Capture the navigator and its context before the await
    final NavigatorState navigator = Navigator.of(context);
    
    try {
      final attempt = await navigator.push<Move>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(
                '${LocalizationService.translate('training_mode', lang)} - #${index + 1}',
              ),
              backgroundColor: provider.themeColor.withValues(alpha: 0.1),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            body: SafeArea(
              child: AdvancedComboBuilder(
                onFinish: (move) {
                  LoggingService.log('TrainingModeDialogs: Builder onFinish called');
                  Navigator.of(ctx).pop(move);
                },
                onCancel: () {
                  LoggingService.log('TrainingModeDialogs: Builder onCancel called');
                  Navigator.of(ctx).pop();
                },
                finishButtonLabel: LocalizationService.translate('verify', lang),
              ),
            ),
          ),
        ),
      );

      if (attempt != null) {
        LoggingService.log('TrainingModeDialogs: Attempt received, showing results');
        // Use the navigator's context to show results, as it stays mounted
        _showResults(navigator.context, originalMove, attempt, moves, index);
      } else {
        LoggingService.log('TrainingModeDialogs: Builder returned null (cancelled)');
      }
    } catch (e, stack) {
      LoggingService.log('TrainingModeDialogs: Error in training flow: $e');
      debugPrint(stack.toString());
    }
  }

  static void _showResults(
    BuildContext context,
    Move original,
    Move attempt,
    List<Move> allMoves,
    int index,
  ) {
    LoggingService.log('TrainingModeDialogs: _showResults called');
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    
    try {
      final result = ComboVerificationService.verifyMove(original, attempt);
      LoggingService.log('TrainingModeDialogs: Verification complete (isCorrect: ${result.isCorrect})');

      showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: false, // Allow full screen feel if needed
        builder: (ctx) => Dialog.fullscreen(
          child: TrainingResultView(
            result: result,
            language: lang,
            onRetry: () {
              LoggingService.log('TrainingModeDialogs: Retry requested');
              Navigator.pop(ctx);
              _startTraining(context, allMoves, index);
            },
            onFinish: () {
              LoggingService.log('TrainingModeDialogs: Training session finished');
              Navigator.pop(ctx);
            },
          ),
        ),
      );
      LoggingService.log('TrainingModeDialogs: Dialog pushed');
    } catch (e, stack) {
      LoggingService.log('TrainingModeDialogs: Error displaying results: $e');
      debugPrint(stack.toString());
    }
  }
}
