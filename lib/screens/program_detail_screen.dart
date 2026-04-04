import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/training_program.dart';
import '../models/program_day.dart';
import '../models/user_program_progress.dart';
import '../models/series.dart';
import '../models/move.dart';
import '../services/series_provider.dart';
import '../services/training_program_service.dart';
import '../services/localization_service.dart';
import '../widgets/program_calendar_widget.dart';
import 'program_create_screen.dart';
import 'series_detail/training/training_mode_dialogs.dart';
import 'series_detail_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  final TrainingProgram program;

  const ProgramDetailScreen({super.key, required this.program});

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
      final progress = await _programService.getUserProgress(
        widget.program.id!,
      );
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
          if (!widget.program.isSystem)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: LocalizationService.translate('edit', lang),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProgramCreateScreen(program: widget.program),
                  ),
                );
                if (result != true || !context.mounted) return;
                // Reload program data
                Navigator.pop(context);
              },
            ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _shareJson(provider, lang),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 12),
                    Text(LocalizationService.translate('share_json', lang)),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _saveJsonToFile(provider, lang),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.save),
                    const SizedBox(width: 12),
                    Text(LocalizationService.translate('save_to_device', lang)),
                  ],
                ),
              ),
              if (_progress != null && _progress!.isActive)
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
                                color: difficultyColor.withValues(alpha: 0.1),
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
                          onPressed: () =>
                              _startProgram(context, provider, lang),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            LocalizationService.translate(
                              'start_program',
                              lang,
                            ),
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.program.days.length,
      itemBuilder: (context, index) {
        final day = widget.program.days[index];
        final isCurrentDay = _progress?.currentDay == day.dayNumber;
        final isCompleted =
            _progress?.completedDays.contains(day.dayNumber) ?? false;
        final isPast = (_progress?.currentDay ?? 1) > day.dayNumber;

        return _DayCard(
          day: day,
          program: widget.program,
          progress: _progress,
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
      if (!context.mounted) return;
      await _loadProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate('program_started', lang)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _abandonProgram(
    BuildContext context,
    SeriesProvider provider,
    String lang,
  ) async {
    final navigator = Navigator.of(context);
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
      _loadProgress();
      navigator.pop();
    }
  }

  Map<String, dynamic> _buildProgramJson(SeriesProvider provider) {
    // Build JSON structure
    final days = widget.program.days.map((day) {
      // Get series titles instead of IDs
      final seriesTitles = day.seriesIds.map((seriesId) {
        final series = provider.series.firstWhere(
          (s) => s.id == seriesId,
          orElse: () => provider.series.first,
        );
        return series.title;
      }).toList();

      return {
        'day_number': day.dayNumber,
        'series_ids': seriesTitles,
        'notes': day.notes ?? '',
        'is_rest_day': day.isRestDay ? 1 : 0,
      };
    }).toList();

    return {
      'title': widget.program.title,
      'description': widget.program.description,
      'difficulty_level': widget.program.difficultyLevel,
      'duration_days': widget.program.durationDays,
      'is_system': widget.program.isSystem ? 1 : 0,
      'days': days,
    };
  }

  Future<void> _shareJson(SeriesProvider provider, String lang) async {
    try {
      final programJson = _buildProgramJson(provider);
      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert([programJson]);

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${widget.program.title.toLowerCase().replaceAll(' ', '-')}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Training Program: ${widget.program.title}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService.translate('error', lang)}: $e'),
        ),
      );
    }
  }

  Future<void> _saveJsonToFile(SeriesProvider provider, String lang) async {
    try {
      final programJson = _buildProgramJson(provider);
      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert([programJson]);

      // Ask user to select a directory
      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectory == null) {
        // User cancelled
        return;
      }

      final fileName =
          '${widget.program.title.toLowerCase().replaceAll(' ', '-')}.json';
      final file = File('$selectedDirectory/$fileName');
      await file.writeAsString(jsonString);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${LocalizationService.translate('export_success', lang)} $selectedDirectory/$fileName',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService.translate('error', lang)}: $e'),
        ),
      );
    }
  }
}

class _DayCard extends StatefulWidget {
  final ProgramDay day;
  final TrainingProgram program;
  final UserProgramProgress? progress;
  final bool isCurrentDay;
  final bool isCompleted;
  final bool isPast;
  final String lang;

  const _DayCard({
    required this.day,
    required this.program,
    required this.progress,
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
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green;
      leadingIcon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (widget.isCurrentDay) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
      borderColor = theme.colorScheme.primary;
      leadingIcon = Icons.play_circle;
      iconColor = theme.colorScheme.primary;
    } else if (widget.isPast) {
      backgroundColor = Colors.red.withValues(alpha: 0.05);
      borderColor = Colors.red.withValues(alpha: 0.3);
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
          title: Row(
            children: [
              Text(
                widget.day.isRestDay
                    ? '${LocalizationService.translate('day', widget.lang)} ${widget.day.dayNumber}: ${LocalizationService.translate('rest_day', widget.lang)}'
                    : '${LocalizationService.translate('day', widget.lang)} ${widget.day.dayNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight:
                      widget.isCurrentDay ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (widget.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (widget.progress != null)
                Builder(
                  builder: (context) {
                    final dayPct = widget.progress!.getDayPercentage(
                      widget.program,
                      widget.day.dayNumber,
                    );
                    if (dayPct > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(dayPct * 100).toInt()}%',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
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
            if (!widget.day.isRestDay &&
                widget.day.seriesAssignments != null &&
                widget.day.seriesAssignments!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.day.seriesAssignments!.map((assignment) {
                      final series = provider.series.firstWhere(
                        (s) => s.id == assignment.seriesId,
                        orElse: () => provider.series.first,
                      );

                      // Build display text with range if available
                      final displayText = assignment.itemRange != null
                          ? '${series.title} (${assignment.itemRange})'
                          : series.title;

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
                                displayText,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (widget.isCurrentDay) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final List<JkdSeries> seriesList = [];
                                for (final sa in widget.day.seriesAssignments!) {
                                  final matching = provider.series.firstWhere(
                                    (s) => s.id == sa.seriesId,
                                    orElse: () => JkdSeries(
                                      id: sa.seriesId,
                                      title: 'Unknown',
                                      category: 'Other',
                                      moves: [],
                                    ),
                                  );
                                  if (matching.title != 'Unknown') {
                                    seriesList.add(matching);
                                  }
                                }

                                if (seriesList.isEmpty) return;

                                if (seriesList.length == 1) {
                                  final s = seriesList.first;
                                  final range = widget.day.seriesAssignments!
                                      .firstWhere((a) => a.seriesId == s.id)
                                      .itemRange;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SeriesDetailScreen(
                                        series: s,
                                        itemRange: range,
                                      ),
                                    ),
                                  );
                                } else {
                                  _showSeriesSelection(
                                    context,
                                    seriesList,
                                    widget.day,
                                    widget.lang,
                                  );
                                }
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                LocalizationService.translate(
                                  'start',
                                  widget.lang,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final List<Move> allMoves = [];
                              final List<int> seriesIds = [];
                              final List<String> seriesTitles = [];
                              for (final sa in widget.day.seriesAssignments!) {
                                seriesIds.add(sa.seriesId);
                                final series = provider.series.firstWhere(
                                  (s) => s.id == sa.seriesId,
                                  orElse: () => JkdSeries(
                                    title: '',
                                    category: '',
                                    moves: [],
                                  ),
                                );
                                if (series.title.isNotEmpty) {
                                  seriesTitles.add(series.title);
                                  List<Move> filtered = series.moves;
                                  if (sa.itemRange != null) {
                                    final parts = sa.itemRange!.split('-');
                                    if (parts.length == 2) {
                                      final start =
                                          int.tryParse(parts[0]) ?? 1;
                                      final end =
                                          int.tryParse(parts[1]) ??
                                          series.moves.length;
                                      filtered = series.moves.sublist(
                                        (start - 1).clamp(
                                          0,
                                          series.moves.length,
                                        ),
                                        end.clamp(0, series.moves.length),
                                      );
                                    }
                                  }
                                  allMoves.addAll(filtered);
                                }
                              }
                              if (allMoves.isNotEmpty) {
                                TrainingModeDialogs.showTrainingSetup(
                                  context,
                                  allMoves,
                                  seriesIds: seriesIds,
                                  seriesTitle: seriesTitles.join(', '),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.school),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
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
