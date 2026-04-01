import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/training_program.dart';
import '../services/series_provider.dart';
import '../services/training_program_service.dart';
import '../services/localization_service.dart';
import 'program_detail_screen.dart';

class ProgramsListScreen extends StatefulWidget {
  const ProgramsListScreen({super.key});

  @override
  State<ProgramsListScreen> createState() => _ProgramsListScreenState();
}

class _ProgramsListScreenState extends State<ProgramsListScreen> {
  final TrainingProgramService _programService = TrainingProgramService();
  List<TrainingProgram> _programs = [];
  String _selectedDifficulty = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() => _isLoading = true);
    try {
      final programs = await _programService.getAllPrograms();
      setState(() {
        _programs = programs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading programs: $e')),
        );
      }
    }
  }

  List<TrainingProgram> get _filteredPrograms {
    if (_selectedDifficulty == 'all') {
      return _programs;
    }
    return _programs
        .where((p) => p.difficultyLevel == _selectedDifficulty)
        .toList();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate('training_programs', lang)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedDifficulty = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: _selectedDifficulty == 'all'
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      LocalizationService.translate('all', lang),
                      style: TextStyle(
                        fontWeight: _selectedDifficulty == 'all'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'beginner',
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: _selectedDifficulty == 'beginner'
                          ? _getDifficultyColor('beginner')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      LocalizationService.translate('beginner', lang),
                      style: TextStyle(
                        fontWeight: _selectedDifficulty == 'beginner'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'intermediate',
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: _selectedDifficulty == 'intermediate'
                          ? _getDifficultyColor('intermediate')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      LocalizationService.translate('intermediate', lang),
                      style: TextStyle(
                        fontWeight: _selectedDifficulty == 'intermediate'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'advanced',
                child: Row(
                  children: [
                    Icon(
                      Icons.military_tech,
                      color: _selectedDifficulty == 'advanced'
                          ? _getDifficultyColor('advanced')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      LocalizationService.translate('advanced', lang),
                      style: TextStyle(
                        fontWeight: _selectedDifficulty == 'advanced'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredPrograms.isEmpty
              ? Center(
                  child: Text(
                    LocalizationService.translate('no_programs_found', lang),
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredPrograms.length,
                  itemBuilder: (context, index) {
                    final program = _filteredPrograms[index];
                    return _buildProgramCard(context, program, provider);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProgramCreateScreen(),
            ),
          );
          if (result == true) {
            _loadPrograms();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    TrainingProgram program,
    SeriesProvider provider,
  ) {
    final theme = Theme.of(context);
    final lang = provider.language;
    final difficultyColor = _getDifficultyColor(program.difficultyLevel);
    final difficultyIcon = _getDifficultyIcon(program.difficultyLevel);

    // Check if user has progress on this program
    final hasActiveProgram = provider.hasActiveProgram &&
        provider.activeProgram?.programId == program.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  Expanded(
                    child: Text(
                      program.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: difficultyColor, width: 1),
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
                          _capitalizeDifficulty(program.difficultyLevel),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: difficultyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${program.durationDays} ${LocalizationService.translate('days', lang)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                program.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasActiveProgram) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: provider.activeProgram!
                            .getCompletionPercentage(program.durationDays),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${LocalizationService.translate('day', lang)} ${provider.activeProgram!.currentDay}/${program.durationDays}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: hasActiveProgram
                    ? ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProgramDetailScreen(program: program),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(
                          LocalizationService.translate('resume', lang),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () async {
                          // Check if user has active program
                          if (provider.hasActiveProgram) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  LocalizationService.translate('warning', lang),
                                ),
                                content: Text(
                                  LocalizationService.translate(
                                    'abandon_current_program',
                                    lang,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      LocalizationService.translate('cancel', lang),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      LocalizationService.translate('abandon', lang),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm != true) return;
                            await provider.abandonActiveProgram();
                          }

                          // Start new program
                          try {
                            await provider.startProgram(program.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    LocalizationService.translate(
                                      'program_started',
                                      lang,
                                    ),
                                  ),
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProgramDetailScreen(program: program),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(
                          LocalizationService.translate('start', lang),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
