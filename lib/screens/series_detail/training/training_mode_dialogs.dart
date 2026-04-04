import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import '../../../services/localization_service.dart';
import '../builders/advanced_combo_builder.dart';
import '../dialogs/congratulations_animation.dart';
import '../../../services/logging_service.dart';
import 'combo_verification_service.dart';
import 'training_result_view.dart';

class TrainingModeDialogs {
  // Track completed indices for the current session
  static final Set<int> _completedIndices = {};

  static void showTrainingSetup(BuildContext context, List<Move> moves, {List<int>? seriesIds, String? seriesTitle}) {
    // Reset state for new setup
    _completedIndices.clear();
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      showItemSelection(context, moves, TrainingLevel.beginner, seriesIds: seriesIds, seriesTitle: seriesTitle);
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
                      showItemSelection(context, moves, TrainingLevel.advanced, seriesIds: seriesIds, seriesTitle: seriesTitle);
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
                      showItemSelection(context, moves, TrainingLevel.expert, seriesIds: seriesIds, seriesTitle: seriesTitle);
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
          }
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

  static void showItemSelection(BuildContext context, List<Move> moves, TrainingLevel level, {List<int>? seriesIds, String? seriesTitle}) {
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (seriesTitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  seriesTitle,
                  style: TextStyle(color: provider.themeColor, fontSize: 14),
                ),
              ],
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
                    final isCompleted = _completedIndices.contains(index);
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _startTraining(context, moves, index, level, seriesIds: seriesIds, seriesTitle: seriesTitle);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isCompleted
                            ? Colors.green.withValues(alpha: 0.2)
                            : provider.themeColor.withValues(alpha: 0.1),
                        foregroundColor: isCompleted ? Colors.green : provider.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isCompleted
                              ? const BorderSide(color: Colors.green, width: 2)
                              : BorderSide.none,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCompleted)
                            const Positioned(
                              top: 2,
                              right: 2,
                              child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                            ),
                        ],
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

  static void _startTraining(BuildContext context, List<Move> moves, int index, TrainingLevel level, {List<int>? seriesIds, String? seriesTitle}) async {
    final originalMove = moves[index];
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    LoggingService.log('TrainingModeDialogs: Starting builder for item #${index + 1} at level $level');
    
    final NavigatorState navigator = Navigator.of(context);
    
    try {
      final attempt = await navigator.push<Move>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            appBar: AppBar(
              title: Text(
                '${LocalizationService.translate('training_mode', lang)} ${seriesTitle ?? ''} #${index + 1} (${LocalizationService.translate(level.name, lang)})',
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
                trainingOriginalMove: originalMove,
                trainingLevel: level,
              ),
            ),
          ),
        ),
      );

      if (attempt != null) {
        LoggingService.log('TrainingModeDialogs: Attempt received, showing results');
        if (context.mounted) {
          _showResults(context, originalMove, attempt, moves, index, level, seriesIds: seriesIds, seriesTitle: seriesTitle);
        }
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
    TrainingLevel level, {
    List<int>? seriesIds,
    String? seriesTitle,
  }) {
    LoggingService.log('TrainingModeDialogs: _showResults called');
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    
    try {
      final result = ComboVerificationService.verifyMove(original, attempt, level);
      LoggingService.log('TrainingModeDialogs: Verification complete (isCorrect: ${result.isCorrect})');

      if (result.isCorrect) {
        _completedIndices.add(index);
      }

      final bool hasNext = index < allMoves.length - 1;
      final bool isSessionComplete = _completedIndices.length == allMoves.length;

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
              _startTraining(context, allMoves, index, level, seriesIds: seriesIds, seriesTitle: seriesTitle);
            },
            onNext: hasNext ? () {
              LoggingService.log('TrainingModeDialogs: Next move requested');
              Navigator.pop(ctx);
              _startTraining(context, allMoves, index + 1, level, seriesIds: seriesIds, seriesTitle: seriesTitle);
            } : null,
            onFinish: () async {
              LoggingService.log('TrainingModeDialogs: Result view closed');
              Navigator.pop(ctx);

              if (isSessionComplete) {
                // RECORD PROGRESS if we have seriesIds
                final provider = Provider.of<SeriesProvider>(context, listen: false);
                bool anyDayComplete = false;
                
                if (seriesIds != null && seriesIds.isNotEmpty) {
                  LoggingService.log('TrainingModeDialogs: Recording completion for ${seriesIds.length} series');
                  for (final sid in seriesIds) {
                    final info = await provider.recordSeriesCompletion(sid);
                    if (info != null && info['day_complete'] == true) {
                      anyDayComplete = true;
                    }
                  }
                }

                // Show completion dialog and then EXIT training mode entirely
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (finishCtx) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.translate(
                              'training_complete_title',
                              lang,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        LocalizationService.translate(
                          'training_complete_desc',
                          lang,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(finishCtx),
                          child: Text(
                            LocalizationService.translate('finish', lang),
                          ),
                        ),
                      ],
                    ),
                  );

                  // Show congrats animation
                  if (seriesIds != null && seriesIds.isNotEmpty) {
                    CongratulationsAnimation.show(context, isDayComplete: anyDayComplete);
                    
                    // Auto-exit the series detail screen to return to "Training Active"
                    Future.delayed(const Duration(milliseconds: 2000), () {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                }
                return;
              }

              // Session not complete: Return to item selection grid
              showItemSelection(context, allMoves, level, seriesIds: seriesIds);
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
