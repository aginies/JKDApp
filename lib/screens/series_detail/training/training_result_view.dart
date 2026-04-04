import 'package:flutter/material.dart';
import '../../../models/move.dart';
import '../../../services/localization_service.dart';
import '../widgets/graphical_move_view.dart';
import 'combo_verification_service.dart';

class TrainingResultView extends StatelessWidget {
  final VerificationResult result;
  final String language;
  final VoidCallback onRetry;
  final VoidCallback onFinish;

  const TrainingResultView({
    super.key,
    required this.result,
    required this.language,
    required this.onRetry,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${LocalizationService.translate('training_result', language)} - ${LocalizationService.translate(result.level.name, language)}',
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success/Failure Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: result.isCorrect
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: result.isCorrect ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      result.isCorrect ? Icons.check_circle : Icons.error,
                      color: result.isCorrect ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.isCorrect
                          ? LocalizationService.translate(
                              'correct_combo',
                              language,
                            )
                          : LocalizationService.translate(
                              'incorrect_combo',
                              language,
                            ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: result.isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User Attempt Section
            _buildSectionTitle(
              LocalizationService.translate('your_attempt', language),
              theme,
            ),
            const SizedBox(height: 8),
            _buildMovePreview(result.attempt, context),

            const SizedBox(height: 24),

            // Original Section
            _buildSectionTitle(
              LocalizationService.translate('original_move', language),
              theme,
            ),
            const SizedBox(height: 8),
            _buildMovePreview(result.original, context),

            if (result.differences.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(
                LocalizationService.translate('differences', language),
                theme,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.differences
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_right,
                                size: 16,
                                color: Colors.red,
                              ),
                              Expanded(
                                child: Text(
                                  d,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      LocalizationService.translate('retry', language),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check),
                    label: Text(
                      LocalizationService.translate('finish', language),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMovePreview(Move move, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        children: GraphicalMoveView.buildCards(
          moves: [move],
          language: language,
          context: context,
          onShowMediaGallery: (cat, name) {},
        ),
      ),
    );
  }
}
