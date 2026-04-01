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
        return _DayConfig(
          dayNumber: day.dayNumber,
          seriesAssignments: day.seriesIds
              .map((id) => _SeriesAssignment(seriesId: id))
              .toList(),
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
            _dayConfigs.add(_DayConfig(
              dayNumber: i + 1,
              seriesAssignments: [],
              notes: '',
              isRestDay: false,
            ));
          }
        } else if (newCount < _dayConfigs.length) {
          // Remove days
          _dayConfigs = _dayConfigs.sublist(0, newCount);
        }
      });
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;
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
      return ProgramDay(
        programId: widget.program?.id ?? 0,
        dayNumber: config.dayNumber,
        seriesIds: config.seriesAssignments
            .map((a) => a.seriesId)
            .where((id) => id != null)
            .cast<int>()
            .toList(),
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
        // Create new program
        await db.createProgram(program);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.translate('program_started', lang))),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing program
        await db.updateProgram(program);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LocalizationService.translate('series_updated', lang))),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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

    final jsonString = const JsonEncoder.withIndent('  ').convert([programJson]);

    // Save to file
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_titleController.text.toLowerCase().replaceAll(' ', '-')}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      if (mounted) {
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Training Program: ${_titleController.text}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
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
        title: Text(widget.program == null ? 'Create Program' : 'Edit Program'),
        actions: [
          if (isDeveloperMode)
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: 'Export JSON',
              onPressed: _exportToJson,
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
              decoration: const InputDecoration(
                labelText: 'Program Title',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
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
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'beginner',
                        child: Text(LocalizationService.translate('beginner', lang)),
                      ),
                      DropdownMenuItem(
                        value: 'intermediate',
                        child: Text(LocalizationService.translate('intermediate', lang)),
                      ),
                      DropdownMenuItem(
                        value: 'advanced',
                        child: Text(LocalizationService.translate('advanced', lang)),
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
              'Daily Schedule',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure what to practice each day',
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

  Widget _buildDayCard(_DayConfig config, int index, ThemeData theme, String lang) {
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
                  },
                ),
                const Divider(),

                // Series assignments
                if (!config.isRestDay) ...[
                  Row(
                    children: [
                      Text(
                        'Assigned Series',
                        style: theme.textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Series',
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
                        subtitle: assignment.itemRange != null
                            ? Text('Items ${assignment.itemRange}')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editSeriesRange(index, assignIndex),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                setState(() {
                                  _dayConfigs[index]
                                      .seriesAssignments
                                      .removeAt(assignIndex);
                                });
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
    }
  }

  Future<void> _editSeriesRange(int dayIndex, int assignIndex) async {
    final assignment = _dayConfigs[dayIndex].seriesAssignments[assignIndex];
    final series = _allSeries.firstWhere((s) => s.id == assignment.seriesId);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RangePickerDialog(
        seriesTitle: series.title,
        totalMoves: series.moves.length,
        currentRange: assignment.itemRange,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _dayConfigs[dayIndex].seriesAssignments[assignIndex].itemRange = result;
      });
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
    return AlertDialog(
      title: const Text('Select Series'),
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
              subtitle: Text('${series.category} • ${series.moves.length} moves'),
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
  late TextEditingController _startController;
  late TextEditingController _endController;
  bool _useAllItems = true;

  @override
  void initState() {
    super.initState();
    if (widget.currentRange != null) {
      _useAllItems = false;
      final parts = widget.currentRange!.split('-');
      _startController = TextEditingController(text: parts[0]);
      _endController = TextEditingController(text: parts.length > 1 ? parts[1] : parts[0]);
    } else {
      _startController = TextEditingController(text: '1');
      _endController = TextEditingController(text: widget.totalMoves.toString());
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Items Range: ${widget.seriesTitle}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total moves in series: ${widget.totalMoves}'),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Practice all items'),
            value: _useAllItems,
            onChanged: (value) {
              setState(() => _useAllItems = value);
            },
          ),
          if (!_useAllItems) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_useAllItems) {
              Navigator.pop(context, null); // null means all items
            } else {
              final start = int.tryParse(_startController.text) ?? 1;
              final end = int.tryParse(_endController.text) ?? widget.totalMoves;
              Navigator.pop(context, '$start-$end');
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
