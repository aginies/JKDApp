import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/training_program.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import 'program_detail_screen.dart';
import 'program_create_screen.dart';

class ProgramsListScreen extends StatefulWidget {
  const ProgramsListScreen({super.key});

  @override
  State<ProgramsListScreen> createState() => _ProgramsListScreenState();
}

class _ProgramsListScreenState extends State<ProgramsListScreen> {
  String _selectedDifficulty = 'all';

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Icons.school;
      case 'intermediate':
        return Icons.trending_up;
      case 'advanced':
        return Icons.military_tech;
      case 'expert':
        return Icons.workspace_premium;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<SeriesProvider>(context);
    final lang = provider.language;

    // Get and sort programs
    final List<TrainingProgram> programs = List.from(provider.allPrograms);
    programs.sort((a, b) {
      if (a.isSystem != b.isSystem) return a.isSystem ? -1 : 1;
      const difficultyOrder = {
        'beginner': 0,
        'intermediate': 1,
        'advanced': 2,
        'expert': 3,
      };
      final diffA = difficultyOrder[a.difficultyLevel.toLowerCase()] ?? 99;
      final diffB = difficultyOrder[b.difficultyLevel.toLowerCase()] ?? 99;
      if (diffA != diffB) return diffA.compareTo(diffB);
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    // Filter programs
    final filteredPrograms = _selectedDifficulty == 'all'
        ? programs
        : programs
              .where((p) => p.difficultyLevel == _selectedDifficulty)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate('training_programs', lang)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _selectedDifficulty = value),
            itemBuilder: (context) => [
              _buildFilterItem(
                'all',
                Icons.list,
                LocalizationService.translate('all', lang),
                theme,
              ),
              _buildFilterItem(
                'beginner',
                Icons.school,
                LocalizationService.translate('beginner', lang),
                theme,
              ),
              _buildFilterItem(
                'intermediate',
                Icons.trending_up,
                LocalizationService.translate('intermediate', lang),
                theme,
              ),
              _buildFilterItem(
                'advanced',
                Icons.military_tech,
                LocalizationService.translate('advanced', lang),
                theme,
              ),
              _buildFilterItem(
                'expert',
                Icons.workspace_premium,
                LocalizationService.translate('expert', lang),
                theme,
              ),
            ],
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredPrograms.isEmpty
          ? Center(
              child: Text(
                LocalizationService.translate('no_programs_found', lang),
                style: theme.textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPrograms.length,
              itemBuilder: (context, index) {
                return _buildProgramCard(
                  context,
                  filteredPrograms[index],
                  provider,
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 120.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProgramCreateScreen(),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildFilterItem(
    String value,
    IconData icon,
    String label,
    ThemeData theme,
  ) {
    final isSelected = _selectedDifficulty == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? theme.colorScheme.primary
                : (value == 'all' ? null : _getDifficultyColor(value)),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
    final hasActiveProgram =
        provider.hasActiveProgram &&
        provider.activeProgram?.programId == program.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramDetailScreen(program: program),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program.title.replaceAll(
                  'Weeks',
                  LocalizationService.translate('weeks', lang),
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
                      border: Border.all(color: difficultyColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(difficultyIcon, size: 16, color: difficultyColor),
                        const SizedBox(width: 4),
                        Text(
                          LocalizationService.translate(
                            program.difficultyLevel.toLowerCase(),
                            lang,
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
                        value: provider.activeProgram!.getCompletionPercentage(
                          program.durationDays,
                        ),
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProgramDetailScreen(program: program),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(
                          LocalizationService.translate('resume', lang),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _handleStartProgram(
                          context,
                          program,
                          provider,
                          lang,
                        ),
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

  Future<void> _handleStartProgram(
    BuildContext context,
    TrainingProgram program,
    SeriesProvider provider,
    String lang,
  ) async {
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

    try {
      await provider.startProgram(program.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate('program_started', lang),
            ),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramDetailScreen(program: program),
          ),
        );
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
