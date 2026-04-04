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
  static void showTrainingSetup(BuildContext context, List<Move> moves) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (stateCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocalizationService.translate('training_mode', lang),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Level Selection
                  _buildLevelCard(
                    context,
                    TrainingLevel.beginner,
                    LocalizationService.translate('beginner', lang),
                    Icons.star_border,
                    Colors.green,
                    () {
                      Navigator.pop(modalCtx);
                      showItemSelection(context, moves, TrainingLevel.beginner);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLevelCard(
                    context,
                    TrainingLevel.advanced,
                    LocalizationService.translate('advanced', lang),
                    Icons.star_half,
                    Colors.orange,
                    () {
                      Navigator.pop(modalCtx);
                      showItemSelection(context, moves, TrainingLevel.advanced);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLevelCard(
                    context,
                    TrainingLevel.expert,
                    LocalizationService.translate('expert', lang),
                    Icons.star,
                    Colors.red,
                    () {
                      Navigator.pop(modalCtx);
                      showItemSelection(context, moves, TrainingLevel.expert);
                    },
                  ),

                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(modalCtx),
                    child: Text(LocalizationService.translate('cancel', lang)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildLevelCard(
    BuildContext context,
    TrainingLevel level,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  static void showItemSelection(
    BuildContext context,
    List<Move> moves,
    TrainingLevel level,
  ) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocalizationService.translate('select_item_to_train', lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                  itemBuilder: (gridCtx, index) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _startTraining(context, moves, index, level);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: provider.themeColor.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: provider.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(modalCtx),
                child: Text(LocalizationService.translate('cancel', lang)),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _startTraining(
    BuildContext context,
    List<Move> moves,
    int index,
    TrainingLevel level,
  ) async {
    final originalMove = moves[index];
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    LoggingService.log(
      'TrainingModeDialogs: Starting builder for item #${index + 1} at level $level',
    );

    final NavigatorState navigator = Navigator.of(context);

    try {
      final attempt = await navigator.push<Move>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(
                '${LocalizationService.translate('training_mode', lang)} - #${index + 1} (${LocalizationService.translate(level.name, lang)})',
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
                  LoggingService.log(
                    'TrainingModeDialogs: Builder onFinish called',
                  );
                  Navigator.of(ctx).pop(move);
                },
                onCancel: () {
                  LoggingService.log(
                    'TrainingModeDialogs: Builder onCancel called',
                  );
                  Navigator.of(ctx).pop();
                },
                finishButtonLabel: LocalizationService.translate(
                  'verify',
                  lang,
                ),
              ),
            ),
          ),
        ),
      );

      if (attempt != null) {
        LoggingService.log(
          'TrainingModeDialogs: Attempt received, showing results',
        );
        if (context.mounted) {
          _showResults(context, originalMove, attempt, moves, index, level);
        }
      } else {
        LoggingService.log(
          'TrainingModeDialogs: Builder returned null (cancelled)',
        );
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
    TrainingLevel level,
  ) {
    LoggingService.log('TrainingModeDialogs: _showResults called');
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;

    try {
      final result = ComboVerificationService.verifyMove(
        original,
        attempt,
        level,
      );
      LoggingService.log(
        'TrainingModeDialogs: Verification complete (isCorrect: ${result.isCorrect})',
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (ctx) => Dialog.fullscreen(
          child: TrainingResultView(
            result: result,
            language: lang,
            onRetry: () {
              LoggingService.log('TrainingModeDialogs: Retry requested');
              Navigator.pop(ctx);
              _startTraining(context, allMoves, index, level);
            },
            onFinish: () {
              LoggingService.log(
                'TrainingModeDialogs: Training session finished',
              );
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
