import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_program_progress.dart';
import '../models/training_program.dart';
import '../models/program_day.dart';
import '../models/series.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../screens/program_detail_screen.dart';
import '../screens/series_detail_screen.dart';

class ActiveProgramCard extends StatelessWidget {
  final UserProgramProgress progress;
  final TrainingProgram program;

  const ActiveProgramCard({
    super.key,
    required this.progress,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final theme = Theme.of(context);
    final lang = provider.language;
    final completionPercentage = progress.getCompletionPercentage(
      program.durationDays,
    );
    final currentStreak = progress.getCurrentStreak();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramDetailScreen(program: program),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${LocalizationService.translate('day', lang)} ${progress.currentDay}/${program.durationDays}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${(completionPercentage * 100).toInt()}% ${LocalizationService.translate('finish', lang)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            if (currentStreak > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• $currentStreak🔥',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completionPercentage,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Today's assignment
              FutureBuilder<Map<String, dynamic>?>(
                future: provider.getTodaysAssignment(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }

                  final assignment = snapshot.data!;
                  final currentDay = assignment['current_day'] as ProgramDay;
                  final seriesList = assignment['series'] as List<JkdSeries>;

                  if (currentDay.isRestDay) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today: ${LocalizationService.translate('rest_day', lang)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (currentDay.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentDay.notes!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    );
                  }

                  // Find ranges for titles
                  String todayText = 'Today: ';
                  final displayTitles = <String>[];
                  for (final s in seriesList) {
                    final matchingAssignment = currentDay.seriesAssignments
                        ?.firstWhere(
                          (a) => a.seriesId == s.id,
                          orElse: () => SeriesAssignment(seriesId: s.id!),
                        );
                    if (matchingAssignment?.itemRange != null) {
                      displayTitles.add(
                        '${s.title} (${matchingAssignment!.itemRange})',
                      );
                    } else {
                      displayTitles.add(s.title);
                    }
                  }

                  if (displayTitles.isEmpty) {
                    todayText += LocalizationService.translate('nothing', lang);
                  } else {
                    todayText += displayTitles.join(', ');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todayText,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: seriesList.isEmpty
                              ? null
                              : () {
                                  if (seriesList.length == 1) {
                                    // Direct navigation for single series
                                    final s = seriesList.first;
                                    final range = currentDay.seriesAssignments
                                        ?.firstWhere(
                                          (a) => a.seriesId == s.id,
                                          orElse: () =>
                                              SeriesAssignment(seriesId: s.id!),
                                        )
                                        .itemRange;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SeriesDetailScreen(
                                              series: s,
                                              itemRange: range,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // Show selection dialog for multiple series
                                    _showSeriesSelection(
                                      context,
                                      seriesList,
                                      currentDay,
                                      lang,
                                    );
                                  }
                                },
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            LocalizationService.translate('start', lang),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSeriesSelection(
    BuildContext context,
    List<JkdSeries> seriesList,
    ProgramDay day,
    String lang,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizationService.translate('select_series', lang),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: seriesList.length,
                  itemBuilder: (context, index) {
                    final s = seriesList[index];
                    final range = day.seriesAssignments
                        ?.firstWhere(
                          (a) => a.seriesId == s.id,
                          orElse: () => SeriesAssignment(seriesId: s.id!),
                        )
                        .itemRange;

                    return ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(s.title),
                      subtitle: range != null
                          ? Text(
                              '${LocalizationService.translate('items_range', lang)}: $range',
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SeriesDetailScreen(series: s, itemRange: range),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
