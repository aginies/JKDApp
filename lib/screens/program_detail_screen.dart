import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/training_program.dart';
import '../models/program_day.dart';
import '../models/user_program_progress.dart';
import '../services/series_provider.dart';
import '../services/training_program_service.dart';
import '../services/localization_service.dart';
import '../widgets/program_calendar_widget.dart';

class ProgramDetailScreen extends StatefulWidget {
  final TrainingProgram program;

  const ProgramDetailScreen({
    super.key,
    required this.program,
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final TrainingProgramService _programService = TrainingProgramService();
  UserProgramProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _programService.getUserProgress(widget.program.id!);
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Icons.school;
      case 'intermediate':
        return Icons.trending_up;
      case 'advanced':
        return Icons.military_tech;
      default:
        return Icons.help_outline;
    }
  }

  String _capitalizeDifficulty(String difficulty) {
    if (difficulty.isEmpty) return difficulty;
    return difficulty[0].toUpperCase() + difficulty.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<SeriesProvider>(context);
    final lang = provider.language;
    final difficultyColor = _getDifficultyColor(widget.program.difficultyLevel);
    final difficultyIcon = _getDifficultyIcon(widget.program.difficultyLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.title),
        actions: [
          if (_progress != null && _progress!.isActive)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => _abandonProgram(context, provider, lang),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(LocalizationService.translate('abandon', lang)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: difficultyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: difficultyColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    difficultyIcon,
                                    size: 16,
                                    color: difficultyColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _capitalizeDifficulty(
                                      widget.program.difficultyLevel,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: difficultyColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.program.durationDays} ${LocalizationService.translate('days', lang)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.program.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Calendar Section (if progress exists)
                  if (_progress != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        LocalizationService.translate('progress', lang),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ProgramCalendarWidget(
                        progress: _progress,
                        program: widget.program,
                      ),
                    ),
                    const Divider(height: 32),
                  ],

                  // Days List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      LocalizationService.translate('daily_schedule', lang),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDaysList(context, provider, lang),

                  // Start/Resume Button
                  if (_progress == null || !_progress!.isActive) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _startProgram(context, provider, lang),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            LocalizationService.translate('start_program', lang),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDaysList(
    BuildContext context,
    SeriesProvider provider,
    String lang,
  ) {
    final theme = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.program.days.length,
      itemBuilder: (context, index) {
        final day = widget.program.days[index];
        final isCurrentDay = _progress?.currentDay == day.dayNumber;
        final isCompleted = _progress?.completedDays.contains(day.dayNumber) ?? false;
        final isPast = (_progress?.currentDay ?? 1) > day.dayNumber;

        return _DayCard(
          day: day,
          isCurrentDay: isCurrentDay,
          isCompleted: isCompleted,
          isPast: isPast,
          lang: lang,
        );
      },
    );
  }

  Future<void> _startProgram(
    BuildContext context,
    SeriesProvider provider,
    String lang,
  ) async {
    // Check if user has active program
    if (provider.hasActiveProgram) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocalizationService.translate('warning', lang)),
          content: Text(
            LocalizationService.translate('abandon_current_program', lang),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(LocalizationService.translate('cancel', lang)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(LocalizationService.translate('abandon', lang)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      await provider.abandonActiveProgram();
    }

    // Start program
    try {
      await provider.startProgram(widget.program.id!);
      if (mounted) {
        await _loadProgress();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate('program_started', lang),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _abandonProgram(
    BuildContext context,
    SeriesProvider provider,
    String lang,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.translate('abandon_program', lang)),
        content: Text(
          LocalizationService.translate('abandon_program_confirm', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              LocalizationService.translate('abandon', lang),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.abandonActiveProgram();
      if (mounted) {
        await _loadProgress();
        Navigator.pop(context);
      }
    }
  }
}

class _DayCard extends StatefulWidget {
  final ProgramDay day;
  final bool isCurrentDay;
  final bool isCompleted;
  final bool isPast;
  final String lang;

  const _DayCard({
    required this.day,
    required this.isCurrentDay,
    required this.isCompleted,
    required this.isPast,
    required this.lang,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final theme = Theme.of(context);

    Color? backgroundColor;
    Color? borderColor;
    IconData? leadingIcon;
    Color? iconColor;

    if (widget.isCompleted) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      leadingIcon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (widget.isCurrentDay) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
      borderColor = theme.colorScheme.primary;
      leadingIcon = Icons.play_circle;
      iconColor = theme.colorScheme.primary;
    } else if (widget.isPast) {
      backgroundColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.3);
      leadingIcon = Icons.cancel;
      iconColor = Colors.red;
    } else {
      leadingIcon = Icons.circle_outlined;
      iconColor = theme.colorScheme.secondary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 1)
            : BorderSide.none,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(leadingIcon, color: iconColor),
          title: Text(
            widget.day.isRestDay
                ? '${LocalizationService.translate('day', widget.lang)} ${widget.day.dayNumber}: ${LocalizationService.translate('rest_day', widget.lang)}'
                : '${LocalizationService.translate('day', widget.lang)} ${widget.day.dayNumber}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: widget.isCurrentDay ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: widget.day.notes != null
              ? Text(
                  widget.day.notes!,
                  maxLines: _isExpanded ? null : 1,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                )
              : null,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            if (!widget.day.isRestDay && widget.day.seriesIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.day.seriesIds.map((id) {
                    final series = provider.series.firstWhere(
                      (s) => s.id == id,
                      orElse: () => provider.series.first,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              series.title,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
