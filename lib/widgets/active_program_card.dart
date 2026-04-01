import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_program_progress.dart';
import '../models/training_program.dart';
import '../services/series_provider.dart';
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
    final completionPercentage = progress.getCompletionPercentage(program.durationDays);
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
                              'Day ${progress.currentDay}/${program.durationDays}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${(completionPercentage * 100).toInt()}% complete',
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
                  final currentDay = assignment['current_day'];
                  final series = assignment['series'] as List;

                  if (currentDay.isRestDay) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today: Rest Day',
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today: ${series.map((s) => s.title).join(', ')}',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to first series in today's assignment
                            if (series.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeriesDetailScreen(
                                    series: series.first,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Training'),
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
}
