import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/move.dart';
import '../models/series.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/export_service.dart';
import '../services/web_storage_service.dart';
import 'series_detail/dialogs/voice_input_dialog.dart';
import 'series_detail/dialogs/training_options_dialog.dart';
import 'series_detail/dialogs/congratulations_animation.dart';
import 'series_detail/training/training_mode_dialogs.dart';

import 'series_detail/dialogs/edit_help_dialog.dart';
import 'series_detail/services/media_gallery_service.dart';
import 'series_detail/services/voice_processing_service.dart';
import 'series_detail/services/training_management_service.dart'
    as training_service;
import 'series_detail/mixins/series_detail_utils.dart';
import 'series_detail/mixins/series_detail_dialogs_mixin.dart';
import 'series_detail/controllers/training_controller.dart';
import 'series_detail/widgets/marquee_widget.dart';
import 'series_detail/widgets/move_list_display_widget.dart';
import 'series_detail/widgets/graphical_move_view.dart';
import 'series_list/widgets/random_reader_widget.dart';
import 'series_detail/builders/advanced_combo_builder.dart';
import 'series_detail/constants/series_detail_constants.dart';

class SeriesDetailScreen extends StatefulWidget {
  final JkdSeries? series;
  final String? itemRange; // e.g., "1-4"
  const SeriesDetailScreen({super.key, this.series, this.itemRange});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen>
    with SeriesDetailUtils, SeriesDetailDialogsMixin {
  final _titleController = TextEditingController();
  String _selectedCategory = 'Jun Fan Gung Fu';
  String _selectedType = 'Attack';
  String? _selectedMethod;
  bool _localShowTranslation = true;
  List<Move> _moves = [];
  bool _isEditing = false;
  bool _isGraphicalView = false;

  final FlutterTts _tts = FlutterTts();
  late TrainingController _trainingController;
  int _trainingInterval = 3;
  int _comboInterval = 800;
  TrainingOptions? _currentTrainingOptions;

  // Service instances
  final MediaGalleryService _mediaGalleryService = MediaGalleryService();
  final VoiceProcessingService _voiceProcessingService =
      VoiceProcessingService();
  final training_service.TrainingManagementService _trainingManagementService =
      training_service.TrainingManagementService();

  // Getters required by SeriesDetailUtils and SeriesDetailDialogsMixin
  @override
  JkdSeries? get series => widget.series;

  @override
  List<Move> get moves => _moves;

  @override
  ScrollController get movesScrollController => _movesScrollController;

  final ScrollController _movesScrollController = ScrollController();
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.series != null) {
      _titleController.text = widget.series!.title;
      _selectedCategory = widget.series!.category;
      _selectedType = widget.series!.type;
      _selectedMethod = widget.series!.attackMethod;

      if (widget.itemRange != null) {
        // Parse range like "1-4"
        final parts = widget.itemRange!.split('-');
        if (parts.length == 2) {
          final start = int.tryParse(parts[0]) ?? 1;
          final end = int.tryParse(parts[1]) ?? widget.series!.moves.length;

          // Filter moves based on range (1-indexed)
          final startIdx = (start - 1).clamp(0, widget.series!.moves.length);
          final endIdx = end.clamp(startIdx, widget.series!.moves.length);

          _moves = widget.series!.moves.sublist(startIdx, endIdx);
        } else {
          _moves = List.from(widget.series!.moves);
        }
      } else {
        _moves = List.from(widget.series!.moves);
      }
    } else {
      _isEditing = true;
    }
    _trainingController = TrainingController(
      tts: _tts,
      onIndexChanged: (index) {
        if (mounted) {
          setState(() {});
          if (index >= 0 && index < _moves.length) {
            _scrollToIndex(index);
          }
        }
      },
      onSubIndexChanged: (subIndex) {
        if (mounted) {
          setState(() {});
        }
      },
      onTrainingComplete: () async {
        if (mounted) {
          setState(() {
            _currentTrainingOptions = null;
          });

          // Check if this series completion is part of active program
          final provider = Provider.of<SeriesProvider>(context, listen: false);
          if (widget.series != null && widget.series!.id != null) {
            final completionInfo = await provider.recordSeriesCompletion(
              widget.series!.id!,
            );
            if (completionInfo != null && context.mounted) {
              final dayDone = completionInfo['day_complete'] == true;
              CongratulationsAnimation.show(context, isDayComplete: dayDone);
              _showCompletionDialog(completionInfo, provider);
            }
          }
        }
      },
      context: context,
    );
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    _trainingController.initTts(speechRate: provider.speechRate);
    _localShowTranslation = provider.showTranslation;
  }

  void _showCloudUploadDialog() {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;
    final usernameController = TextEditingController(text: provider.contributorName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang == 'fr' ? 'Upload Cloud' : 'Cloud Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang == 'fr'
                  ? 'Entrez votre nom pour identifier l\'upload :'
                  : 'Enter your name to identify the upload:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: lang == 'fr' ? 'Nom d\'utilisateur' : 'Username',
                border: const OutlineInputBorder(),
              ),
              autofocus: provider.contributorName.isEmpty,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = usernameController.text.trim();
              if (username.isEmpty) return;

              // Persist the name to settings if new or changed
              if (username != provider.contributorName) {
                provider.setContributorName(username);
              }

              Navigator.pop(context);
              _performCloudUpload(username);
            },
            child: Text(lang == 'fr' ? 'Envoyer' : 'Upload'),
          ),
        ],
      ),
    );
  }
  Future<void> _performCloudUpload(String username) async {
    if (widget.series == null) return;

    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final webService = WebStorageService();
      await webService.uploadSeries(widget.series!, username);

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'fr'
                ? 'Série uploadée avec succès !'
                : 'Series uploaded successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'fr' ? 'Erreur: $e' : 'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _trainingController.dispose();
    _titleController.dispose();
    _movesScrollController.dispose();
    super.dispose();
  }

  void _normalizeSubLetters() {
    _moves = normalizeSubLetters(_moves);
  }

  void _scrollToIndex(int index) {
    scrollToIndex(index);
  }

  void _showMediaGallery(String category, String moveName) {
    _mediaGalleryService.showMediaGallery(context, category, moveName);
  }

  void _saveSeries() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    final series = JkdSeries(
      id: widget.series?.id,
      title: _titleController.text,
      category: _selectedCategory,
      type: _selectedType,
      attackMethod: _selectedMethod,
      notes: '',
      moves: _moves,
    );
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    if (widget.series == null) {
      await provider.addSeries(series);
    } else {
      await provider.updateSeries(series);
    }

    if (context.mounted) {
      // Show a temporary success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                LocalizationService.translate(
                  widget.series == null ? 'series_added' : 'series_updated',
                  provider.language,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Dismiss the dialog and pop the screen after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.of(context).pop(); // Dismiss success dialog
          Navigator.of(context).pop(); // Pop the series detail screen
        }
      });
    }
  }

  void _showTrainingOptions() async {
    final options = await _trainingManagementService.showTrainingOptions(
      context,
      _moves,
      _trainingInterval,
      _comboInterval,
      _trainingController,
    );

    if (options != null) {
      setState(() {
        _trainingInterval = options.interval;
        _comboInterval = options.comboInterval;
        _currentTrainingOptions = options;
        _isGraphicalView = true;
      });
    }
  }

  void _startVoiceInput() async {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    final result = await VoiceInputDialog.show(
      context,
      _voiceProcessingService.voiceService,
      lang,
    );
    if (result != null && result.trim().isNotEmpty) {
      _processVoiceInput(result);
    }
  }

  void _showCompletionDialog(
    Map<String, dynamic> completionInfo,
    SeriesProvider provider,
  ) {
    _trainingManagementService.showCompletionDialog(
      context,
      completionInfo,
      provider,
    );
  }

  void _processVoiceInput(String input) {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    final parsed = _voiceProcessingService.processVoiceInput(input, lang);
    if (parsed.isEmpty) return;

    setState(() {
      if (parsed.length == 1) {
        _moves.add(parsed.first);
      } else {
        _moves.add(
          Move(
            name: 'Combo: ${parsed.first.name} + ...',
            category: 'combo',
            subMoves: parsed,
          ),
        );
      }
    });
  }

  void _openComboBuilder({int? editIndex}) async {
    final result = await Navigator.of(context).push<Move>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          final lang = Provider.of<SeriesProvider>(ctx, listen: false).language;
          return Scaffold(
            body: SafeArea(
              child: AdvancedComboBuilder(
                initialMove: editIndex != null ? _moves[editIndex] : null,
                onFinish: (move) => Navigator.of(ctx).pop(move),
                onCancel: () => Navigator.of(ctx).pop(),
              ),
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: FloatingActionButton(
                heroTag: 'combo_builder_help',
                onPressed: () => EditHelpDialog.show(ctx, lang),
                child: const Icon(Icons.help_outline),
              ),
            ),
          );
        },
      ),
    );
    if (result != null && context.mounted) {
      setState(() {
        if (editIndex != null) {
          _moves[editIndex] = result;
        } else {
          _moves.add(result);
        }
        _normalizeSubLetters();
      });
    }
  }

  List<Widget> _buildMoveListTiles(String lang) {
    return MoveListDisplayWidget.buildTiles(
      moves: _moves,
      language: lang,
      isEditing: _isEditing,
      trainingController: _trainingController,
      context: context,
      category: _selectedCategory,
      showTranslation: _localShowTranslation,
      onEdit: (index) =>
          () => _openComboBuilder(editIndex: index),
      onClone: (index) => () {
        setState(() {
          final map = _moves[index].toMap();
          map['id'] = null;
          final copy = Move.fromMap(map);
          _moves.insert(index + 1, copy);
        });
      },
      onDelete: (index) =>
          () => confirmDeleteItem(context, index, lang),
      onShowMediaGallery: _showMediaGallery,
      onSetState: (moves, atIndex) => setState(() {
        _moves = moves;
      }),
    );
  }

  /// Focused view during TTS training — shows only the currently-spoken item
  /// centered in the available space, using graphical or list style based on
  /// the current view mode.
  Widget _buildTrainingFocusView(String lang) {
    final idx = _trainingController.currentIndex;
    final move = _moves[idx];

    // Compute the display number for this item (skipping 'move' category)
    int displayNumber = 0;
    for (int i = 0; i <= idx; i++) {
      if (_moves[i].category != 'move') displayNumber++;
    }
    final int totalNumbered = _moves.where((m) => m.category != 'move').length;
    final String itemLabel = move.category != 'move'
        ? '$displayNumber / $totalNumbered'
        : '${idx + 1} / ${_moves.length}';

    Widget itemView;

    if (_isGraphicalView) {
      // Single graphical card, centered
      final cards = GraphicalMoveView.buildCards(
        moves: [move],
        language: lang,
        context: context,
        onShowMediaGallery: _showMediaGallery,
        trainingController: _trainingController,
        singleItemIndex: idx,
        showTranslation: _localShowTranslation,
      );
      itemView = cards.isNotEmpty ? cards.first : const SizedBox.shrink();
    } else {
      // Single list tile, centered
      final tiles = MoveListDisplayWidget.buildTiles(
        moves: [move],
        language: lang,
        isEditing: false,
        trainingController: _trainingController,
        context: context,
        category: _selectedCategory,
        showTranslation: _localShowTranslation,
        onEdit: (_) => () {},
        onClone: (_) => () {},
        onDelete: (_) => () {},
        onShowMediaGallery: _showMediaGallery,
        onSetState: (a, b) {},
        singleItemIndex: idx,
      );
      itemView = tiles.isNotEmpty ? tiles.first : const SizedBox.shrink();
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                itemLabel,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              itemView,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SeriesProvider>(context).language;
    return Scaffold(
      floatingActionButton: _isFullscreen
          ? FloatingActionButton(
              heroTag: 'exit_fullscreen',
              tooltip: LocalizationService.translate('exit_fullscreen', lang),
              onPressed: () => setState(() => _isFullscreen = false),
              child: const Icon(Icons.fullscreen_exit),
            )
          : (!_isEditing &&
                _currentTrainingOptions == null &&
                _selectedCategory != 'Moves')
          ? FloatingActionButton(
              heroTag: 'training_mode_btn',
              onPressed: () => TrainingModeDialogs.showTrainingSetup(
                context,
                _moves,
                seriesIds: widget.series?.id != null
                    ? [widget.series!.id!]
                    : null,
                seriesTitle: widget.series?.title,
              ),
              backgroundColor: Colors.orangeAccent,
              child: const Icon(Icons.school, size: 28, color: Colors.white),
            )
          : null,
      appBar: (_currentTrainingOptions != null || _isFullscreen)
          ? null
          : AppBar(
              title: Row(
                children: [
                  Builder(
                    builder: (context) {
                      String asset = 'assets/icon/JKD.png';
                      if (widget.series != null) {
                        final cat = widget.series!.category;
                        if (cat == 'Jun Fan Gung Fu') {
                          asset = 'assets/icon/jfgf.png';
                        } else if (cat == 'Jun Fan Kick Boxing') {
                          asset = 'assets/icon/jfkb.png';
                        } else if (cat == 'Kali') {
                          asset = 'assets/icon/kali.png';
                        } else if (cat == 'Moves') {
                          asset = 'assets/icon/JKD.png';
                        }
                      }
                      return Image.asset(asset, height: 32);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MarqueeWidget(
                      child: Text(
                        widget.series == null
                            ? LocalizationService.translate('new_series', lang)
                            : widget.series!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (!_isEditing &&
                    widget.series != null &&
                    widget.series!.category != 'Moves')
                  Builder(
                    builder: (context) {
                      final provider = Provider.of<SeriesProvider>(context);
                      final isDone = provider.isSeriesCompletedToday(
                        widget.series!.id!,
                      );
                      return IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: isDone ? Colors.grey : Colors.orangeAccent,
                        ),
                        onPressed: isDone ? null : _showTrainingOptions,
                        tooltip: lang == 'fr' ? 'Mode Lecteur' : 'Player Mode',
                      );
                    },
                  ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveSeries,
                  )
                else if (widget.series != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings),
                    onSelected: (value) {
                      if (value == 'edit') {
                        setState(() => _isEditing = true);
                      } else if (value == 'print') {
                        showPrintOptions(lang);
                      } else if (value == 'export') {
                        handleExportJson();
                      } else if (value == 'share') {
                        ExportService.shareSeriesJson(
                          [widget.series!],
                          fileName:
                              'jkd-series-${widget.series!.title.replaceAll(' ', '-').toLowerCase()}.json',
                        );
                      } else if (value == 'cloud_upload') {
                        _showCloudUploadDialog();
                      }
                    },
                    itemBuilder: (context) {
                      final isSystemJkdMoves =
                          widget.series!.isSystem &&
                          widget.series!.category == 'Moves';
                      return [
                        if (!isSystemJkdMoves)
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: const Icon(Icons.edit),
                              title: Text(
                                LocalizationService.translate('edit', lang),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        PopupMenuItem(
                          value: 'print',
                          child: ListTile(
                            leading: const Icon(Icons.print),
                            title: Text(
                              LocalizationService.translate(
                                'export_to_pdf',
                                lang,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            leading: const Icon(Icons.share),
                            title: Text(
                              LocalizationService.translate('share_json', lang),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cloud_upload',
                          child: ListTile(
                            leading: const Icon(Icons.cloud_upload),
                            title: Text(
                              lang == 'fr' ? 'Upload Cloud' : 'Cloud Upload',
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: ListTile(
                            leading: Icon(Icons.save_alt),
                            title: Text('Export to JSON'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: Padding(
            key: ValueKey(_isEditing),
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                if (_trainingController.isTraining && !_isFullscreen)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'TRAINING: ${_trainingController.currentIndex + 1} / ${_currentTrainingOptions?.endIndex ?? _moves.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_currentTrainingOptions?.isLooping ??
                                  false) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.loop,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _trainingController.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                            color: Colors.greenAccent,
                          ),
                          onPressed: () {
                            if (_trainingController.isPaused) {
                              _trainingController.resume();
                            } else {
                              _trainingController.pause();
                            }
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop, color: Colors.red),
                          onPressed: () {
                            _trainingController.stop();
                            setState(() {
                              _currentTrainingOptions = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                if (_isEditing) ...[
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: LocalizationService.translate(
                        'series_title',
                        lang,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Jun Fan Gung Fu'),
                        selected: _selectedCategory == 'Jun Fan Gung Fu',
                        onSelected: (val) {
                          if (val) {
                            setState(
                              () => _selectedCategory = 'Jun Fan Gung Fu',
                            );
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Jun Fan Kick Boxing'),
                        selected: _selectedCategory == 'Jun Fan Kick Boxing',
                        onSelected: (val) {
                          if (val) {
                            setState(
                              () => _selectedCategory = 'Jun Fan Kick Boxing',
                            );
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Moves'),
                        selected: _selectedCategory == 'Moves',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = 'Moves');
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Kali'),
                        selected: _selectedCategory == 'Kali',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = 'Kali');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedCategory != 'Moves' &&
                      _selectedCategory != 'Kali') ...[
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(lang == 'fr' ? 'Attaque' : 'Attack'),
                          selected: _selectedType == 'Attack',
                          onSelected: (val) {
                            if (val) setState(() => _selectedType = 'Attack');
                          },
                        ),
                        ChoiceChip(
                          label: Text(lang == 'fr' ? 'Défense' : 'Defense'),
                          selected: _selectedType == 'Defense',
                          onSelected: (val) {
                            if (val) setState(() => _selectedType = 'Defense');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedType == 'Attack')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 8,
                            runSpacing: 4,
                            children: SeriesDetailConstants
                                .methodDefinitions
                                .keys
                                .map(
                                  (method) => Tooltip(
                                    message: SeriesDetailConstants
                                        .methodDefinitions[method]!,
                                    child: ChoiceChip(
                                      label: Text(method),
                                      selected: _selectedMethod == method,
                                      onSelected: (val) => setState(
                                        () => _selectedMethod = val
                                            ? method
                                            : null,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                  ],
                ],
                if (!_isEditing &&
                    !_isFullscreen &&
                    _currentTrainingOptions == null) ...[
                  Row(
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(_selectedCategory)),
                          if (_selectedCategory != 'Moves' &&
                              _selectedCategory != 'Kali')
                            Chip(label: Text(_selectedType)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _localShowTranslation
                              ? Icons.translate
                              : Icons.g_translate,
                          size: 22,
                          color: _localShowTranslation
                              ? Colors.teal
                              : Colors.grey,
                        ),
                        tooltip: lang == 'fr' ? 'Traductions' : 'Translations',
                        onPressed: () {
                          setState(() {
                            _localShowTranslation = !_localShowTranslation;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, size: 24),

                        tooltip: LocalizationService.translate(
                          'fullscreen',
                          lang,
                        ),
                        onPressed: () => setState(() => _isFullscreen = true),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isGraphicalView
                              ? Icons.view_list
                              : Icons.grid_view_rounded,
                          size: 22,
                        ),
                        tooltip: _isGraphicalView ? 'List view' : 'Card view',
                        onPressed: () {
                          setState(() {
                            _isGraphicalView = !_isGraphicalView;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ],
                if (!_isFullscreen)
                  SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        if (_isEditing) ...[
                          const SizedBox(width: 8),
                          Consumer<SeriesProvider>(
                            builder: (context, provider, child) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (provider.voiceEnabled) ...[
                                  FloatingActionButton.small(
                                    heroTag: 'voice_btn',
                                    onPressed: _startVoiceInput,
                                    backgroundColor: Colors.redAccent,
                                    child: const Icon(
                                      Icons.mic,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                FloatingActionButton.small(
                                  heroTag: 'add_btn',
                                  onPressed: _openComboBuilder,
                                  child: const Icon(Icons.add, size: 20),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  ),
                if (!_isEditing && widget.series?.category == 'Moves')
                  RandomReaderWidget(
                    language: lang,
                    forcedSeriesId: widget.series!.id,
                    showSelection: true,
                  ),
                Expanded(
                  child: _isEditing
                      ? ReorderableListView(
                          scrollController: _movesScrollController,
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final movedItem = _moves.removeAt(oldIndex);
                              _moves.insert(newIndex, movedItem);
                              _normalizeSubLetters();
                            });
                          },
                          children: _buildMoveListTiles(lang),
                        )
                      : _trainingController.isTraining &&
                            _trainingController.currentIndex >= 0 &&
                            _trainingController.currentIndex < _moves.length
                      ? _buildTrainingFocusView(lang)
                      : _isGraphicalView
                      ? SingleChildScrollView(
                          controller: _movesScrollController,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 12,
                              children: GraphicalMoveView.buildCards(
                                moves: _moves,
                                language: lang,
                                context: context,
                                onShowMediaGallery: _showMediaGallery,
                                trainingController: _trainingController,
                                showTranslation: _localShowTranslation,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          controller: _movesScrollController,
                          children: _buildMoveListTiles(lang),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
