import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/training_program.dart';
import '../models/program_day.dart';
import '../models/series.dart';
import '../services/series_provider.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProgramCreateScreen extends StatefulWidget {
  final TrainingProgram? program; // For editing existing program

  const ProgramCreateScreen({super.key, this.program});

  @override
  State<ProgramCreateScreen> createState() => _ProgramCreateScreenState();
}

class _ProgramCreateScreenState extends State<ProgramCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _daysController = TextEditingController(text: '7');

  String _selectedDifficulty = 'beginner';
  List<_DayConfig> _dayConfigs = [];
  List<JkdSeries> _allSeries = [];

  @override
  void initState() {
    super.initState();
    _loadSeries();

    if (widget.program != null) {
      // Editing existing program
      _titleController.text = widget.program!.title;
      _descriptionController.text = widget.program!.description;
      _daysController.text = widget.program!.durationDays.toString();
      _selectedDifficulty = widget.program!.difficultyLevel;

      // Load day configs from existing program
      _dayConfigs = widget.program!.days.map((day) {
        // Use seriesAssignments if available (new format), otherwise convert from seriesIds (old format)
        final assignments =
            day.seriesAssignments?.map((assignment) {
              return _SeriesAssignment(
                seriesId: assignment.seriesId,
                itemRange: assignment.itemRange,
              );
            }).toList() ??
            day.seriesIds.map((id) => _SeriesAssignment(seriesId: id)).toList();

        return _DayConfig(
          dayNumber: day.dayNumber,
          seriesAssignments: assignments,
          notes: day.notes ?? '',
          isRestDay: day.isRestDay,
        );
      }).toList();
    } else {
      // New program - create 7 days by default
      _initializeDays(7);
    }
  }

  Future<void> _loadSeries() async {
    final db = DatabaseService();
    final series = await db.getAllSeries();
    setState(() {
      _allSeries = series;
    });
  }

  void _initializeDays(int count) {
    _dayConfigs = List.generate(
      count,
      (index) => _DayConfig(
        dayNumber: index + 1,
        seriesAssignments: [],
        notes: '',
        isRestDay: false,
      ),
    );
  }

  void _onDaysChanged(String value) {
    final newCount = int.tryParse(value);
    if (newCount != null && newCount > 0 && newCount <= 365) {
      setState(() {
        if (newCount > _dayConfigs.length) {
          // Add more days
          for (int i = _dayConfigs.length; i < newCount; i++) {
            _dayConfigs.add(
              _DayConfig(
                dayNumber: i + 1,
                seriesAssignments: [],
                notes: '',
                isRestDay: false,
              ),
            );
          }
        } else if (newCount < _dayConfigs.length) {
          // Remove days
          _dayConfigs = _dayConfigs.sublist(0, newCount);
        }
      });
      _updateDescription();
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dayConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one day to the program')),
      );
      return;
    }

    final db = DatabaseService();
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    // Create program days
    final days = _dayConfigs.map((config) {
      // Convert internal _SeriesAssignment to model SeriesAssignment
      final assignments = config.seriesAssignments
          .where((a) => a.seriesId != null)
          .map(
            (a) =>
                SeriesAssignment(seriesId: a.seriesId!, itemRange: a.itemRange),
          )
          .toList();

      return ProgramDay(
        programId: widget.program?.id ?? 0,
        dayNumber: config.dayNumber,
        seriesAssignments: assignments,
        notes: config.notes.isEmpty ? null : config.notes,
        isRestDay: config.isRestDay,
      );
    }).toList();

    final program = TrainingProgram(
      id: widget.program?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      difficultyLevel: _selectedDifficulty,
      durationDays: int.parse(_daysController.text),
      isSystem: false, // User-created program
      createdAt: widget.program?.createdAt ?? DateTime.now(),
      days: days,
    );

    try {
      if (widget.program == null) {
        // Create new program via provider to trigger UI refresh
        await provider.createProgram(program);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate('program_started', lang),
            ),
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        // Update existing program via provider to trigger UI refresh
        await provider.updateProgram(program);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate('series_updated', lang),
            ),
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteProgram() async {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.translate('delete_series', lang)),
        content: Text(
          '${LocalizationService.translate('confirm_delete', lang)} "${widget.program!.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              LocalizationService.translate('delete', lang),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = DatabaseService();
        await db.deleteProgram(widget.program!.id!);
        await provider.loadAllPrograms();
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _exportToJson() async {
    if (!_formKey.currentState!.validate()) return;

    // Build JSON structure
    final days = _dayConfigs.map((config) {
      // Get series titles instead of IDs
      final seriesTitles = config.seriesAssignments
          .where((a) => a.seriesId != null)
          .map((a) {
            final series = _allSeries.firstWhere(
              (s) => s.id == a.seriesId,
              orElse: () => JkdSeries(
                id: 0,
                title: 'Unknown',
                category: 'Other',
                moves: [],
              ),
            );
            return series.title;
          })
          .toList();

      return {
        'day_number': config.dayNumber,
        'series_ids': seriesTitles,
        'notes': config.notes,
        'is_rest_day': config.isRestDay ? 1 : 0,
      };
    }).toList();

    final programJson = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'difficulty_level': _selectedDifficulty,
      'duration_days': int.parse(_daysController.text),
      'is_system': 0,
      'days': days,
    };

    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert([programJson]);

    // Save to file
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${_titleController.text.toLowerCase().replaceAll(' ', '-')}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      if (!mounted) return;
      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Training Program: ${_titleController.text}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export error: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<SeriesProvider>(context);
    final lang = provider.language;
    final isDeveloperMode = provider.developerMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.program == null
              ? LocalizationService.translate('create_program', lang)
              : LocalizationService.translate('edit_program', lang),
        ),
        actions: [
          if (isDeveloperMode)
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: LocalizationService.translate('export_json', lang),
              onPressed: _exportToJson,
            ),
          if (widget.program != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: LocalizationService.translate('delete', lang),
              onPressed: _deleteProgram,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: LocalizationService.translate('update_item', lang),
            onPressed: _saveProgram,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: LocalizationService.translate('program_title', lang),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: LocalizationService.translate(
                  'program_description',
                  lang,
                ),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Difficulty and Days row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: LocalizationService.translate(
                        'difficulty',
                        lang,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'beginner',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.school,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              LocalizationService.translate('beginner', lang),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'intermediate',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 20,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              LocalizationService.translate(
                                'intermediate',
                                lang,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'advanced',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.military_tech,
                              size: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              LocalizationService.translate('advanced', lang),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDifficulty = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _daysController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.translate('days', lang),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num < 1 || num > 365) {
                        return 'Enter 1-365';
                      }
                      return null;
                    },
                    onChanged: _onDaysChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Days configuration
            Text(
              LocalizationService.translate('daily_schedule', lang),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationService.translate('daily_config', lang),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // Day cards
            ..._dayConfigs.asMap().entries.map((entry) {
              final index = entry.key;
              final config = entry.value;
              return _buildDayCard(config, index, theme, lang);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(
    _DayConfig config,
    int index,
    ThemeData theme,
    String lang,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              '${LocalizationService.translate('day', lang)} ${config.dayNumber}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (config.isRestDay)
              Chip(
                label: Text(LocalizationService.translate('rest_day', lang)),
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                labelStyle: const TextStyle(fontSize: 12),
              ),
            if (!config.isRestDay && config.seriesAssignments.isNotEmpty)
              Chip(
                label: Text('${config.seriesAssignments.length} series'),
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                labelStyle: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rest day toggle
                SwitchListTile(
                  title: Text(LocalizationService.translate('rest_day', lang)),
                  value: config.isRestDay,
                  onChanged: (value) {
                    setState(() {
                      _dayConfigs[index].isRestDay = value;
                      if (value) {
                        _dayConfigs[index].seriesAssignments.clear();
                      }
                    });
                    _updateDescription();
                  },
                ),
                const Divider(),

                // Series assignments
                if (!config.isRestDay) ...[
                  Row(
                    children: [
                      Text(
                        LocalizationService.translate('assigned_series', lang),
                        style: theme.textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: LocalizationService.translate(
                          'add_series',
                          lang,
                        ),
                        onPressed: () => _addSeriesToDay(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // List of assigned series
                  ...config.seriesAssignments.asMap().entries.map((entry) {
                    final assignIndex = entry.key;
                    final assignment = entry.value;
                    final series = _allSeries.firstWhere(
                      (s) => s.id == assignment.seriesId,
                      orElse: () => JkdSeries(
                        id: 0,
                        title: 'Select series...',
                        category: 'Other',
                        moves: [],
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(series.title),
                        subtitle: Text(
                          assignment.itemRange != null
                              ? 'Items ${assignment.itemRange}'
                              : LocalizationService.translate(
                                  'practice_all_items',
                                  lang,
                                ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _editSeriesRange(index, assignIndex),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                setState(() {
                                  _dayConfigs[index].seriesAssignments.removeAt(
                                    assignIndex,
                                  );
                                });
                                _updateDescription();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                // Notes
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: config.notes,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate('notes', lang),
                    border: const OutlineInputBorder(),
                    hintText: 'Focus points, tips, etc.',
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    _dayConfigs[index].notes = value;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSeriesToDay(int dayIndex) async {
    final selected = await showDialog<JkdSeries>(
      context: context,
      builder: (context) => _SeriesPickerDialog(allSeries: _allSeries),
    );

    if (selected != null && mounted) {
      setState(() {
        _dayConfigs[dayIndex].seriesAssignments.add(
          _SeriesAssignment(seriesId: selected.id),
        );
      });

      // Immediately prompt for range selection
      final assignIndex = _dayConfigs[dayIndex].seriesAssignments.length - 1;
      await _editSeriesRange(dayIndex, assignIndex);
    }
  }

  Future<void> _editSeriesRange(int dayIndex, int assignIndex) async {
    final assignment = _dayConfigs[dayIndex].seriesAssignments[assignIndex];
    final series = _allSeries.firstWhere((s) => s.id == assignment.seriesId);

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _RangePickerDialog(
        seriesTitle: series.title,
        totalMoves: series.moves.length,
        currentRange: assignment.itemRange,
      ),
    );

    // result can be:
    // - null: user cancelled
    // - "": user selected "practice all items"
    // - "1-4": user selected a range
    if (result != null && mounted) {
      final newItemRange = result.isEmpty ? null : result;
      setState(() {
        _dayConfigs[dayIndex].seriesAssignments[assignIndex].itemRange =
            newItemRange;
      });
      _updateDescription();
    } else {}
  }

  void _updateDescription() {
    // Auto-generate description based on selected series
    final seriesByDay = <int, List<String>>{};

    for (final dayConfig in _dayConfigs) {
      if (dayConfig.isRestDay || dayConfig.seriesAssignments.isEmpty) continue;

      final seriesList = <String>[];
      for (final assignment in dayConfig.seriesAssignments) {
        if (assignment.seriesId == null) continue;
        final series = _allSeries.firstWhere(
          (s) => s.id == assignment.seriesId,
          orElse: () =>
              JkdSeries(id: 0, title: 'Unknown', category: 'Other', moves: []),
        );

        if (assignment.itemRange != null) {
          seriesList.add('${series.title} (${assignment.itemRange})');
        } else {
          seriesList.add(series.title);
        }
      }

      if (seriesList.isNotEmpty) {
        seriesByDay[dayConfig.dayNumber] = seriesList;
      }
    }

    // Build description
    final descriptionParts = <String>[];
    seriesByDay.forEach((day, series) {
      descriptionParts.add('Day $day: ${series.join(", ")}');
    });

    if (descriptionParts.isNotEmpty) {
      // Show first 5 days instead of 3 for better overview
      final newDescription =
          descriptionParts.take(5).join('. ') +
          (descriptionParts.length > 5 ? '...' : '.');
      _descriptionController.text = newDescription;
    } else {
      // No series assigned, clear description
      _descriptionController.text = '';
    }
  }
}

// Helper classes
class _DayConfig {
  final int dayNumber;
  List<_SeriesAssignment> seriesAssignments;
  String notes;
  bool isRestDay;

  _DayConfig({
    required this.dayNumber,
    required this.seriesAssignments,
    required this.notes,
    required this.isRestDay,
  });
}

class _SeriesAssignment {
  final int? seriesId;
  String? itemRange; // e.g., "1-4" or null for all

  _SeriesAssignment({this.seriesId, this.itemRange});
}

// Series picker dialog
class _SeriesPickerDialog extends StatelessWidget {
  final List<JkdSeries> allSeries;

  const _SeriesPickerDialog({required this.allSeries});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    return AlertDialog(
      title: Text(LocalizationService.translate('select_series', lang)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: allSeries.length,
          itemBuilder: (context, index) {
            final series = allSeries[index];
            return ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(series.title),
              subtitle: Text(
                '${series.category} • ${series.moves.length} moves',
              ),
              onTap: () => Navigator.pop(context, series),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Range picker dialog
class _RangePickerDialog extends StatefulWidget {
  final String seriesTitle;
  final int totalMoves;
  final String? currentRange;

  const _RangePickerDialog({
    required this.seriesTitle,
    required this.totalMoves,
    this.currentRange,
  });

  @override
  State<_RangePickerDialog> createState() => _RangePickerDialogState();
}

class _RangePickerDialogState extends State<_RangePickerDialog> {
  bool _useAllItems = true;
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    if (widget.currentRange != null) {
      _useAllItems = false;
      final parts = widget.currentRange!.split('-');
      final start = double.parse(parts[0]);
      final end = double.parse(parts.length > 1 ? parts[1] : parts[0]);
      _currentRange = RangeValues(start, end);
    } else {
      _currentRange = RangeValues(1, widget.totalMoves.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    return AlertDialog(
      title: Text(
        '${LocalizationService.translate('items_range', lang)}: ${widget.seriesTitle}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total moves in series: ${widget.totalMoves}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              LocalizationService.translate('practice_all_items', lang),
            ),
            value: _useAllItems,
            onChanged: (value) {
              setState(() => _useAllItems = value);
            },
          ),
          if (!_useAllItems) ...[
            const SizedBox(height: 24),
            Text(
              '${LocalizationService.translate('from', lang)}: ${_currentRange.start.round()} - ${LocalizationService.translate('to', lang)}: ${_currentRange.end.round()}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              min: 1,
              max: widget.totalMoves.toDouble(),
              divisions: widget.totalMoves - 1,
              values: _currentRange,
              labels: RangeLabels(
                _currentRange.start.round().toString(),
                _currentRange.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _currentRange = values;
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: theme.textTheme.bodySmall),
                Text(
                  widget.totalMoves.toString(),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocalizationService.translate('cancel', lang)),
        ),
        TextButton(
          onPressed: () {
            if (_useAllItems) {
              Navigator.pop(context, ""); // empty string means all items
            } else {
              final start = _currentRange.start.round();
              final end = _currentRange.end.round();
              final result = '$start-$end';
              Navigator.pop(context, result);
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
