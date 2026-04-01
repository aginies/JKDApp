import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import '../models/move.dart';
import '../models/series.dart';
import '../services/series_provider.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';
import '../services/pdf_service.dart';
import '../services/export_service.dart';
import '../services/media_service.dart';
import '../services/voice_parsing_service.dart';
import 'series_detail/dialogs/voice_help_dialog.dart';
import 'series_detail/dialogs/voice_input_dialog.dart';
import 'series_detail/dialogs/training_options_dialog.dart';
import 'series_detail/controllers/training_controller.dart';
import 'series_detail/widgets/move_display_widgets.dart';
import 'series_detail/widgets/marquee_widget.dart';
import 'series_detail/widgets/move_list_display_widget.dart';
import 'series_detail/widgets/combo_card_widget.dart';
import 'series_detail/constants/series_detail_constants.dart';
import 'series_detail/state/picker_state.dart';
import '../utils/string_utils.dart';

class SeriesDetailScreen extends StatefulWidget {
  final JkdSeries? series;
  final String? itemRange; // e.g., "1-4"
  const SeriesDetailScreen({super.key, this.series, this.itemRange});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  final _titleController = TextEditingController();
  final _customMoveController = TextEditingController();
  String _selectedCategory = 'Jun Fan Gung Fu';
  String _selectedType = 'Attack';
  String? _selectedMethod;
  List<Move> _moves = [];
  bool _isEditing = false;

  final FlutterTts _tts = FlutterTts();
  final VoiceParsingService _voiceService = VoiceParsingService();
  late TrainingController _trainingController;
  int _trainingInterval = 7;
  int _comboInterval = 2500;
  TrainingOptions? _currentTrainingOptions;

  final MediaService _mediaService = MediaService();

  // Picker state management
  final PickerState _pickerState = PickerState();
  final List<Move> _currentCombo = [];
  final ScrollController _comboScrollController = ScrollController();
  final GlobalKey<AnimatedListState> _comboListKey =
      GlobalKey<AnimatedListState>();
  final ScrollController _movesScrollController = ScrollController();
  final Map<String, ScrollController> _glossaryScrollControllers = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _glossaryFutures = {};
  Timer? _scrollTimer;

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
            if (completionInfo != null && mounted) {
              _showCompletionDialog(completionInfo, provider);
            }
          }
        }
      },
      context: context,
    );
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    _trainingController.initTts(speechRate: provider.speechRate);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _trainingController.dispose();
    _pickerState.dispose();
    _titleController.dispose();
    _customMoveController.dispose();
    _comboScrollController.dispose();
    _movesScrollController.dispose();
    for (final controller in _glossaryScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_movesScrollController.hasClients) return;

    final double targetOffset =
        (index * SeriesDetailConstants.estimatedMoveItemHeight).clamp(
          0.0,
          _movesScrollController.position.maxScrollExtent,
        );

    _movesScrollController.animateTo(
      targetOffset,
      duration: const Duration(
        milliseconds: SeriesDetailConstants.scrollAnimationMs,
      ),
      curve: Curves.easeInOut,
    );
  }

  void _addItemToCombo(Move item, StateSetter setS) {
    setS(() {
      _currentCombo.add(item);
      _comboListKey.currentState?.insertItem(
        _currentCombo.length - 1,
        duration: const Duration(
          milliseconds: SeriesDetailConstants.comboAnimationMs,
        ),
      );
    });
    // Auto-scroll to end after animation
    Future.delayed(
      const Duration(milliseconds: SeriesDetailConstants.comboAnimationMs + 50),
      () {
        if (_comboScrollController.hasClients) {
          _comboScrollController.animateTo(
            _comboScrollController.position.maxScrollExtent,
            duration: const Duration(
              milliseconds: SeriesDetailConstants.removeAnimationMs,
            ),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  void _handleEditComboItem(
    int index,
    bool isCounter,
    StateSetter setS,
    BuildContext ctx,
  ) async {
    if (index < 0 || index >= _currentCombo.length) return;
    final m = _currentCombo[index];
    setS(() {
      _pickerState.setEditingComboItemIndex(index);
      _pickerState.setIsEditingCounter(isCounter);
    });

    if (!mounted) return;
    final cat = isCounter ? (m.counterCategory ?? '') : m.category;
    final t = MoveDisplayWidgets.getTabIndexForCategory(
      cat,
      isCounter: isCounter,
    );
    if (t != -1) {
      DefaultTabController.of(ctx).animateTo(t);
    }
  }

  void _removeItemFromCombo(int index, StateSetter setS, String lang) {
    if (index < 0 || index >= _currentCombo.length) return;
    final removedItem = _currentCombo[index];
    setS(() {
      _currentCombo.removeAt(index);
      _comboListKey.currentState?.removeItem(
        index,
        (context, animation) => ComboCardWidget(
          move: removedItem,
          index: index,
          language: lang,
          animation: animation,
          onRemove: () {},
          onEdit: (idx, isCounter) {},
          isRemoving: true,
        ),
        duration: const Duration(
          milliseconds: SeriesDetailConstants.removeAnimationMs,
        ),
      );
      if (_pickerState.editingComboItemIndex == index) {
        _pickerState.clearEditingState();
      } else if (_pickerState.editingComboItemIndex != null &&
          _pickerState.editingComboItemIndex! > index) {
        _pickerState.setEditingComboItemIndex(
          _pickerState.editingComboItemIndex! - 1,
        );
      }
    });
  }

  void _showMediaGallery(String category, String moveName) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;
    final galleryPath = provider.galleryPath;
    if (galleryPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate('gallery_path', lang)),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$moveName - ${LocalizationService.translate('instructional_photos', lang)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.green),
                    tooltip: 'Select from files',
                    onPressed: () async {
                      final file = await _mediaService.pickAndSaveImage(
                        galleryPath,
                        category,
                        moveName,
                      );
                      if (file != null) setModalState(() {});
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_a_photo,
                      color: Colors.blueAccent,
                    ),
                    tooltip: 'Take photo',
                    onPressed: () async {
                      final file = await _mediaService.captureAndSaveImage(
                        galleryPath,
                        category,
                        moveName,
                      );
                      if (file != null) setModalState(() {});
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder<List<File>>(
                  future: _mediaService.getImagesForMove(
                    galleryPath,
                    category,
                    moveName,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final images = snapshot.data ?? [];
                    if (images.isEmpty) {
                      return Center(
                        child: Text(
                          LocalizationService.translate('no_images', lang),
                        ),
                      );
                    }
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(images, index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(images[index], fit: BoxFit.cover),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFullScreenImage(List<File> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: StatefulBuilder(
          builder: (context, setState) {
            int currentIndex = initialIndex;
            final PageController pageController = PageController(
              initialPage: initialIndex,
            );

            return Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: InteractiveViewer(
                        child: Image.file(images[index], fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
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

    if (mounted) {
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
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss success dialog
          Navigator.of(context).pop(); // Pop the series detail screen
        }
      });
    }
  }

  void _showTrainingOptions() async {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;
    final options = await TrainingOptionsDialog.show(
      context,
      lang,
      _moves.length,
      _trainingInterval,
      _comboInterval,
      provider.speechRate,
    );

    if (options != null) {
      setState(() {
        _trainingInterval = options.interval;
        _comboInterval = options.comboInterval;
        _currentTrainingOptions = options;
      });
      _trainingController.startTraining(
        moves: _moves,
        startIndex: options.startIndex,
        endIndex: options.endIndex,
        interval: options.interval,
        comboInterval: options.comboInterval,
        isLooping: options.isLooping,
        language: lang,
        speechRate: provider.speechRate,
      );
    }
  }

  void _startVoiceInput() async {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    final result = await VoiceInputDialog.show(context, _voiceService, lang);
    if (result != null && result.trim().isNotEmpty) {
      _processVoiceInput(result);
    }
  }

  void _showCompletionDialog(
    Map<String, dynamic> completionInfo,
    SeriesProvider provider,
  ) {
    final lang = provider.language;
    final dayCompleted = completionInfo['dayCompleted'] == true;

    if (dayCompleted) {
      // Day completed! Show celebration dialog
      final dayNumber = completionInfo['dayNumber'] as int;
      final streak = completionInfo['streak'] as int;
      final progress = (completionInfo['progress'] as double) * 100;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Colors.amber, size: 80),
              const SizedBox(height: 16),
              Text(
                '${LocalizationService.translate('day', lang)} $dayNumber ${LocalizationService.translate('finish', lang)}!',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (streak > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '$streak ${LocalizationService.translate('days', lang)}!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 8),
              Text(
                '${progress.toStringAsFixed(1)}% ${LocalizationService.translate('progress', lang)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocalizationService.translate('finish', lang)),
            ),
          ],
        ),
      );
    } else {
      // Series completed but day not finished yet
      final completedSeries = completionInfo['completedSeries'] as int;
      final totalSeries = completionInfo['totalSeries'] as int;
      final currentSeriesCount =
          completionInfo['currentSeriesCount'] as int? ?? 0;

      String message;
      if (currentSeriesCount >= 2) {
        // Series is fully complete (2 reps done)
        message =
            '${LocalizationService.translate('finish', lang)}! ✓ ($completedSeries/$totalSeries ${LocalizationService.translate('series_title', lang)})';
      } else {
        // Series partially complete (1 rep done)
        message =
            '${LocalizationService.translate('finish', lang)}! ($currentSeriesCount/2 reps) - $completedSeries/$totalSeries ${LocalizationService.translate('series_title', lang)}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: currentSeriesCount >= 2
              ? Colors.green
              : Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  void _processVoiceInput(String input) {
    if (input.trim().isEmpty) return;
    List<Move> parsed = [];
    try {
      final decoded = json.decode(input);
      if (decoded is List) {
        parsed = decoded.map((m) => Move.fromMap(m)).toList();
      }
    } catch (_) {
      // If not JSON, it might be raw text from a legacy caller or error
      final lang = Provider.of<SeriesProvider>(context, listen: false).language;
      parsed = _voiceService.parseSentenceToCombo(input, lang);
    }

    if (parsed.isEmpty) return;
    setState(() {
      if (_pickerState.isPickerOpen) {
        // Since we are in a modal bottom sheet with a separate StateSetter (setS),
        // we need to be careful. However, _processVoiceInput usually runs via
        // a dialog that pops back. If we are in the picker, we should ideally
        // use the setS provided to the picker, but this method uses setState.
        // For now, let's at least add them.
        for (var m in parsed) {
          _currentCombo.add(m);
          _comboListKey.currentState?.insertItem(
            _currentCombo.length - 1,
            duration: const Duration(milliseconds: 400),
          );
        }
      } else {
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
      }
    });
  }

  void _pickMove({List<Move>? initialMoves, int? seriesIndex}) async {
    _resetPickerState();
    if (initialMoves != null) {
      _currentCombo.addAll(initialMoves);
      // Wait for bottom sheet to open and AnimatedList to be ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < initialMoves.length; i++) {
          _comboListKey.currentState?.insertItem(
            i,
            duration: const Duration(milliseconds: 400),
          );
        }
      });
    }
    _pickerState.setEditingSeriesIndex(seriesIndex);
    _pickerState.setTargetSeriesIndex(seriesIndex);
    if (seriesIndex != null &&
        seriesIndex >= 0 &&
        seriesIndex < _moves.length) {
      _pickerState.setSelectedSubLetter(_moves[seriesIndex].subLetter);
    }
    _pickerState.setEditingComboItemIndex(null);
    setState(() => _pickerState.setIsPickerOpen(true));
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final lang = Provider.of<SeriesProvider>(context).language;
          final voiceEnabled = Provider.of<SeriesProvider>(
            context,
          ).voiceEnabled;
          final isCounterMode = _pickerState.pendingAttackMove != null;

          return DefaultTabController(
            key: ValueKey(isCounterMode),
            length: isCounterMode ? 6 : 8,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.95,
              child: Column(
                children: [
                  _buildComboPreview(setS, lang, voiceEnabled),
                  if (isCounterMode)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => setS(
                              () => _pickerState.setPendingAttackMove(null),
                            ),
                          ),
                          Text(
                            LocalizationService.translate('pick_answer', lang),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  TabBar(
                    isScrollable: true,
                    tabs: isCounterMode
                        ? [
                            Tab(
                              text: LocalizationService.translate(
                                'packs',
                                lang,
                              ),
                              icon: Icon(
                                Icons.front_hand,
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'packs',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'trapping',
                                lang,
                              ),
                              icon: Icon(
                                Icons.back_hand,
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'trapping',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate('move', lang),
                              icon: Icon(
                                Icons.directions_run,
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'move',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'jkd_moves',
                                lang,
                              ),
                              icon: const Icon(
                                Icons.directions_run,
                                color: Colors.blue,
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'other',
                                lang,
                              ),
                              icon: Icon(
                                Icons.more_horiz,
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'other',
                                ),
                              ),
                            ),
                            const Tab(
                              text: 'Text',
                              icon: Icon(Icons.text_fields),
                            ),
                          ]
                        : [
                            Tab(
                              text: LocalizationService.translate(
                                'punches',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('punch'),
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'punch',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'kicks',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('kick'),
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'kick',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'packs',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('packs'),
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'packs',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'trapping',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('trapping'),
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'trapping',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate('move', lang),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('move'),
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'move',
                                ),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'jkd_moves',
                                lang,
                              ),
                              icon: const Icon(
                                Icons.directions_run,
                                color: Colors.blue,
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'other',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('other'),
                                color: MoveDisplayWidgets.getCategoryColor(
                                  'other',
                                ),
                              ),
                            ),
                            const Tab(
                              text: 'Text',
                              icon: Icon(Icons.text_fields, color: Colors.teal),
                            ),
                          ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: isCounterMode
                          ? [
                              _buildCounterGlossaryList(
                                'packs',
                                setS,
                                _pickerState.pendingAttackMove!['item'],
                                _pickerState.pendingAttackMove!['cat'],
                                _pickerState.pendingAttackMove!['sd'],
                                _pickerState.pendingAttackMove!['lv'],
                                _pickerState.pendingAttackMove!['f'],
                                _pickerState.pendingAttackMove!['sp'],
                                _pickerState.pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCounterGlossaryList(
                                'trapping',
                                setS,
                                _pickerState.pendingAttackMove!['item'],
                                _pickerState.pendingAttackMove!['cat'],
                                _pickerState.pendingAttackMove!['sd'],
                                _pickerState.pendingAttackMove!['lv'],
                                _pickerState.pendingAttackMove!['f'],
                                _pickerState.pendingAttackMove!['sp'],
                                _pickerState.pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCounterGlossaryList(
                                'move',
                                setS,
                                _pickerState.pendingAttackMove!['item'],
                                _pickerState.pendingAttackMove!['cat'],
                                _pickerState.pendingAttackMove!['sd'],
                                _pickerState.pendingAttackMove!['lv'],
                                _pickerState.pendingAttackMove!['f'],
                                _pickerState.pendingAttackMove!['sp'],
                                _pickerState.pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCounterGlossaryList(
                                'jkd_moves',
                                setS,
                                _pickerState.pendingAttackMove!['item'],
                                _pickerState.pendingAttackMove!['cat'],
                                _pickerState.pendingAttackMove!['sd'],
                                _pickerState.pendingAttackMove!['lv'],
                                _pickerState.pendingAttackMove!['f'],
                                _pickerState.pendingAttackMove!['sp'],
                                _pickerState.pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCounterGlossaryList(
                                'other',
                                setS,
                                _pickerState.pendingAttackMove!['item'],
                                _pickerState.pendingAttackMove!['cat'],
                                _pickerState.pendingAttackMove!['sd'],
                                _pickerState.pendingAttackMove!['lv'],
                                _pickerState.pendingAttackMove!['f'],
                                _pickerState.pendingAttackMove!['sp'],
                                _pickerState.pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCustomTextTab(
                                setS,
                                lang,
                                isCounter: true,
                                attackItem:
                                    _pickerState.pendingAttackMove!['item'],
                                attackCategory:
                                    _pickerState.pendingAttackMove!['cat'],
                                side: _pickerState.pendingAttackMove!['sd'],
                                level: _pickerState.pendingAttackMove!['lv'],
                                isFeint: _pickerState.pendingAttackMove!['f'],
                                special: _pickerState.pendingAttackMove!['sp'],
                                attackTranslations:
                                    _pickerState.pendingAttackMove!['tr'],
                                reps: 1,
                                pickerModalState: setS,
                              ),
                            ]
                          : [
                              _buildGlossaryWithScroll('punch', setS, lang),
                              _buildGlossaryWithScroll('kick', setS, lang),
                              _buildGlossaryWithScroll('packs', setS, lang),
                              _buildGlossaryWithScroll('trapping', setS, lang),
                              _buildGlossaryWithScroll('move', setS, lang),
                              _buildGlossaryWithScroll('jkd_moves', setS, lang),
                              _buildGlossaryWithScroll('other', setS, lang),
                              _buildCustomTextTab(setS, lang),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    setState(() => _pickerState.setIsPickerOpen(false));
  }

  void _resetPickerState() {
    _pickerState.reset();
    _currentCombo.clear();
    _customMoveController.clear();
  }

  Future<int> _getInitialIndexForCategory(String cat) async {
    if (_pickerState.pendingActionItemId == null) return -1;
    final items = await DatabaseService().getGlossaryByCategory(cat);
    return items.indexWhere(
      (item) => item['id'] == _pickerState.pendingActionItemId,
    );
  }

  Widget _buildGlossaryWithScroll(String cat, StateSetter setS, String lang) {
    return FutureBuilder<int>(
      future: _getInitialIndexForCategory(cat),
      builder: (context, snapshot) {
        return _buildGlossaryList(cat, setS, lang, initialIndex: snapshot.data);
      },
    );
  }

  void _activateGlossaryItem(int itemId) {
    _pickerState.activateGlossaryItem(itemId);
  }

  Widget _buildCustomTextTab(
    StateSetter setS,
    String lang, {
    bool isCounter = false,
    Map<String, dynamic>? attackItem,
    String? attackCategory,
    String? side,
    String? level,
    bool? isFeint,
    String? special,
    Map<String, String>? attackTranslations,
    int? reps,
    StateSetter? pickerModalState,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _customMoveController,
            decoration: const InputDecoration(
              labelText: 'Custom Move Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setS(() {}),
          ),
          const SizedBox(height: 20),
          if (!isCounter)
            _buildWorkflowButtons(
              {'name': _customMoveController.text, 'translations': '{}'},
              'text',
              '',
              '',
              false,
              null,
              {},
              setS,
              lang,
              isCustom: true,
            )
          else
            ElevatedButton(
              onPressed: () {
                if (_customMoveController.text.isEmpty) return;
                _addCounterMove(
                  {'name': _customMoveController.text},
                  'text',
                  '',
                  attackItem!,
                  attackCategory!,
                  side!,
                  level!,
                  isFeint!,
                  special,
                  attackTranslations!,
                  {},
                  reps!,
                  pickerModalState!,
                );
              },
              child: Text(LocalizationService.translate('add', lang)),
            ),
        ],
      ),
    );
  }

  Widget _buildComboPreview(StateSetter setS, String lang, bool voiceEnabled) {
    final double h = _currentCombo.any((m) => m.category == 'move') ? 198 : 190;
    return Container(
      constraints: BoxConstraints(minHeight: 170, maxHeight: h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pickerState.editingSeriesIndex != null
                            ? '${LocalizationService.translate('update_item', lang).toUpperCase()} ${_pickerState.editingSeriesIndex! + 1}'
                            : '${LocalizationService.translate('current_combo', lang)} (${_currentCombo.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (_pickerState.editingSeriesIndex != null) ...[
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _pickerState.targetSeriesIndex != null
                              ? _pickerState.targetSeriesIndex! + 1
                              : 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                          isDense: true,
                          underline: const SizedBox(),
                          items: List.generate(
                            _moves.length,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}'),
                            ),
                          ).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setS(
                                () =>
                                    _pickerState.setTargetSeriesIndex(val - 1),
                              );
                            }
                          },
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Sub-letter selector (a, b, c, ...)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'sub:',
                              style: TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _pickerState.selectedSubLetter ?? '_',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _pickerState.selectedSubLetter != null
                                    ? Colors.orangeAccent
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                              ),
                              isDense: true,
                              underline: const SizedBox(),
                              items: [
                                const DropdownMenuItem(
                                  value: '_',
                                  child: Text('_'),
                                ),
                                ...'abcdefg'
                                    .split('')
                                    .map(
                                      (l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(l),
                                      ),
                                    ),
                              ],
                              onChanged: (val) {
                                setS(
                                  () => _pickerState.setSelectedSubLetter(
                                    val == '_' ? null : val,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (voiceEnabled &&
                          _pickerState.editingSeriesIndex == null) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          onPressed: () {
                            VoiceHelpDialog.show(context, lang);
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Voice Help',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.mic,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: _startVoiceInput,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Voice Input',
                        ),
                      ],
                      const SizedBox(width: 12),
                      if (_pickerState.editingSeriesIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(0, 26),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              LocalizationService.translate('cancel', lang),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_currentCombo.isNotEmpty)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 26),
                          ),
                          onPressed: () {
                            _finishAndAddCombo();
                            Navigator.pop(context);
                          },
                          child: Text(
                            _pickerState.editingSeriesIndex != null
                                ? LocalizationService.translate(
                                    'update_item',
                                    lang,
                                  )
                                : LocalizationService.translate(
                                    'finish_combo',
                                    lang,
                                  ),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                AnimatedList(
                  key: _comboListKey,
                  controller: _comboScrollController,
                  scrollDirection: Axis.horizontal,
                  initialItemCount: _currentCombo.length,
                  itemBuilder: (ctx, idx, animation) {
                    if (idx >= _currentCombo.length) {
                      return const SizedBox.shrink();
                    }
                    final m = _currentCombo[idx];
                    return ComboCardWidget(
                      move: m,
                      index: idx,
                      language: lang,
                      animation: animation,
                      onRemove: () => _removeItemFromCombo(idx, setS, lang),
                      onEdit: (index, isCounter) =>
                          _handleEditComboItem(index, isCounter, setS, ctx),
                      isSelected:
                          _pickerState.editingComboItemIndex == idx &&
                          !_pickerState.isEditingCounter,
                      isCounterSelected:
                          _pickerState.editingComboItemIndex == idx &&
                          _pickerState.isEditingCounter,
                    );
                  },
                ),
                if (_currentCombo.length > 1) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: (!Platform.isAndroid && !Platform.isIOS)
                              ? Colors.black87
                              : Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: (!Platform.isAndroid && !Platform.isIOS)
                                ? 26
                                : 20,
                          ),
                          onPressed: () {
                            _comboScrollController.animateTo(
                              _comboScrollController.offset - 168,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: (!Platform.isAndroid && !Platform.isIOS)
                              ? Colors.black87
                              : Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: (!Platform.isAndroid && !Platform.isIOS)
                                ? 26
                                : 20,
                          ),
                          onPressed: () {
                            _comboScrollController.animateTo(
                              _comboScrollController.offset + 168,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryList(
    String cat,
    StateSetter setS,
    String lang, {
    int? initialIndex,
  }) {
    final scrollController = _glossaryScrollControllers.putIfAbsent(
      cat,
      () => ScrollController(),
    );
    final provider = Provider.of<SeriesProvider>(context, listen: false);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService().getGlossaryByCategory(cat),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;

        if (initialIndex != null &&
            initialIndex >= 0 &&
            initialIndex < items.length) {
          final targetItemId = items[initialIndex]['id'];
          // Only scroll if we haven't already scrolled to this item
          if (_pickerState.lastScrolledItemId != targetItemId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _scrollTimer?.cancel();
              _scrollTimer = Timer(const Duration(milliseconds: 100), () {
                if (!mounted) return;
                if (scrollController.hasClients &&
                    scrollController.position.hasContentDimensions) {
                  const double estimatedItemHeight = 125.0;
                  final viewportHeight =
                      scrollController.position.viewportDimension;

                  // Calculate offset to center the item in the viewport
                  double offset =
                      (initialIndex * estimatedItemHeight) -
                      (viewportHeight / 2) +
                      (estimatedItemHeight / 2);

                  // Clamp offset to valid range
                  if (offset < 0) {
                    offset = 0;
                  } else if (offset >
                      scrollController.position.maxScrollExtent) {
                    offset = scrollController.position.maxScrollExtent;
                  }

                  scrollController.jumpTo(offset);
                  _pickerState.setLastScrolledItemId(targetItemId);
                }
              });
            });
          }
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final item = items[idx];
            final id = item['id'];
            final side = _pickerState.selectedSides[id] ?? '';
            final isF = _pickerState.selectedFeints[id] ?? false;
            final spec = _pickerState.selectedSpecials[id];
            // Expanded highlight logic: match by ID or by name/cat if ID is null (legacy)
            final bool isE =
                _pickerState.pendingActionItemId == id ||
                (_pickerState.pendingActionItemId == null &&
                    _pickerState.editingComboItemIndex != null &&
                    (!_pickerState.isEditingCounter
                        ? _currentCombo[_pickerState.editingComboItemIndex!]
                                  .name ==
                              item['name']
                        : _currentCombo[_pickerState.editingComboItemIndex!]
                                  .counterName ==
                              item['name']) &&
                    (!_pickerState.isEditingCounter
                        ? _currentCombo[_pickerState.editingComboItemIndex!]
                                  .category ==
                              cat
                        : _currentCombo[_pickerState.editingComboItemIndex!]
                                  .counterCategory ==
                              cat));
            final String pL = item['possible_level'] ?? 'H,M,L';
            final bool sH = pL.contains('H'),
                sM = pL.contains('M'),
                sL = pL.contains('L');
            final String pD = item['possible_direction'] ?? '';
            final bool hasDirection = pD.isNotEmpty;

            // Parse translations from JSON string
            Map<String, String> tr = {};
            if (item['translations'] != null) {
              try {
                tr = Map<String, String>.from(
                  json.decode(item['translations']),
                );
              } catch (_) {
                tr = {};
              }
            }
            final translation = tr[lang] ?? tr['en'] ?? tr['fr'] ?? '';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: isE
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: MoveDisplayWidgets.getCategoryColor(cat),
                        width: 2,
                      ),
                    )
                  : null,
              child: InkWell(
                onDoubleTap: () => _showMediaGallery(cat, item['name']),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            MoveDisplayWidgets.getCategoryIcon(cat),
                            size: 32,
                            color: MoveDisplayWidgets.getCategoryColor(cat),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat == 'move'
                                ? (tr['en'] ?? item['name'])
                                : item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (provider.showTranslation &&
                          cat != 'move' &&
                          translation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 40.0),
                          child: Text(
                            translation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (item['possible_direction'] != null) ...[
                            _pickerSideButton(
                              LocalizationService.translate('left', lang),
                              'L',
                              side,
                              Colors.blue,
                              id,
                              setS,
                              lang,
                              withArrow: true,
                            ),
                            _pickerSideButton(
                              LocalizationService.translate('right', lang),
                              'R',
                              side,
                              Colors.red,
                              id,
                              setS,
                              lang,
                              withArrow: true,
                            ),
                          ] else if (cat == 'move')
                            ElevatedButton(
                              onPressed: () => setS(() {
                                _pickerState.setPendingActionItem(id);
                                _pickerState.setPendingLevel('');
                              }),
                              child: const Text('ADD'),
                            )
                          else if (cat == 'trapping' || cat == 'packs') ...[
                            _sideButtonWithArrow(
                              LocalizationService.translate('left', lang),
                              'L',
                              Colors.blue,
                              () => setS(() {
                                _pickerState.setPendingActionItem(id);
                                _pickerState.setPendingLevel('');
                                _pickerState.selectedSides[id] = 'L';
                              }),
                              lang,
                              id,
                            ),
                            _sideButtonWithArrow(
                              LocalizationService.translate('right', lang),
                              'R',
                              Colors.red,
                              () => setS(() {
                                _pickerState.setPendingActionItem(id);
                                _pickerState.setPendingLevel('');
                                _pickerState.selectedSides[id] = 'R';
                              }),
                              lang,
                              id,
                            ),
                          ] else ...[
                            _pickerSideButton(
                              LocalizationService.translate('left', lang),
                              'L',
                              side,
                              Colors.blue,
                              id,
                              setS,
                              lang,
                              withArrow: true,
                            ),
                            _pickerSideButton(
                              LocalizationService.translate('right', lang),
                              'R',
                              side,
                              Colors.red,
                              id,
                              setS,
                              lang,
                              withArrow: true,
                            ),
                            if (cat == 'punch' || cat == 'kick') ...[
                              FilterChip(
                                label: Text(
                                  LocalizationService.translate('draw', lang),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                selected: isF,
                                onSelected: (v) => setS(
                                  () => _pickerState.selectedFeints[id] = v,
                                ),
                              ),
                              ActionChip(
                                label: Text(
                                  spec ??
                                      LocalizationService.translate(
                                        'move',
                                        lang,
                                      ),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                onPressed: () => _pickSpecialForMove(id, setS),
                              ),
                            ],
                          ],
                          const SizedBox(width: 8),
                          if (cat != 'move' && !hasDirection)
                            Wrap(
                              spacing: 4,
                              children: [
                                if (sH)
                                  _levelSelectionButton('High', id, setS, lang),
                                if (sM)
                                  _levelSelectionButton('Mid', id, setS, lang),
                                if (sL)
                                  _levelSelectionButton('Low', id, setS, lang),
                              ],
                            ),
                        ],
                      ),
                      if (_pickerState.pendingActionItemId == id)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildWorkflowButtons(
                            item,
                            cat,
                            side,
                            _pickerState.pendingLevel ?? '',
                            isF,
                            spec,
                            tr,
                            setS,
                            lang,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCounterGlossaryList(
    String cat,
    StateSetter setS,
    Map<String, dynamic> attack,
    String aCat,
    String aSide,
    String aLev,
    bool aF,
    String? aS,
    Map<String, String> aTr,
    int reps,
    StateSetter pickerS,
    String lang,
  ) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final glossaryFuture = _glossaryFutures.putIfAbsent(cat, () async {
      final items = await DatabaseService().getGlossaryByCategory(cat);
      return items.map((item) {
        final Map<String, dynamic> mutableItem = Map.from(item);
        try {
          mutableItem['parsed_translations'] = Map<String, String>.from(
            json.decode(item['translations']),
          );
        } catch (_) {
          mutableItem['parsed_translations'] = <String, String>{};
        }
        return mutableItem;
      }).toList();
    });

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: glossaryFuture,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = snap.data!;
        if (cat == 'packs') {
          final String hit = attack['hit_type'] ?? 'both';
          if (hit != 'both') {
            items = items
                .where(
                  (i) =>
                      (i['possible_type_attack'] ?? 'both') == 'both' ||
                      i['possible_type_attack'] == hit,
                )
                .toList();
          }
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final item = items[idx];
            final id = item['id'];
            final side = _pickerState.selectedSides[id] ?? '';
            final spec = _pickerState.selectedSpecials[id];
            final String pL = item['possible_level'] ?? 'H,M,L';
            final Map<String, String> tr =
                (item['parsed_translations'] as Map<String, String>?) ?? {};
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: InkWell(
                onDoubleTap: () => _showMediaGallery(cat, item['name']),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            MoveDisplayWidgets.getCategoryIcon(cat),
                            size: 28,
                            color: MoveDisplayWidgets.getCategoryColor(cat),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (provider.showTranslation &&
                          cat != 'move' &&
                          tr.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final translation =
                                tr[lang] ?? tr['en'] ?? tr['fr'] ?? '';
                            if (translation.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 36.0,
                                top: 2.0,
                              ),
                              child: Text(
                                translation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      if (cat == 'move')
                        ElevatedButton(
                          onPressed: () => _addCounterMove(
                            item,
                            cat,
                            '',
                            attack,
                            aCat,
                            aSide,
                            aLev,
                            aF,
                            aS,
                            aTr,
                            tr,
                            reps,
                            pickerS,
                          ),
                          child: Text(
                            LocalizationService.translate('add', lang),
                          ),
                        )
                      else if (cat == 'trapping' || cat == 'packs')
                        Wrap(
                          spacing: 4,
                          children: [
                            _sideButtonWithArrow(
                              LocalizationService.translate('left', lang),
                              'L',
                              Colors.blue,
                              () => _addCounterMove(
                                item,
                                cat,
                                'L',
                                attack,
                                aCat,
                                aSide,
                                aLev,
                                aF,
                                aS,
                                aTr,
                                tr,
                                reps,
                                pickerS,
                              ),
                              lang,
                              id,
                            ),
                            _sideButtonWithArrow(
                              LocalizationService.translate('right', lang),
                              'R',
                              Colors.red,
                              () => _addCounterMove(
                                item,
                                cat,
                                'R',
                                attack,
                                aCat,
                                aSide,
                                aLev,
                                aF,
                                aS,
                                aTr,
                                tr,
                                reps,
                                pickerS,
                              ),
                              lang,
                              id,
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 4,
                          children: [
                            _pickerSideButton(
                              LocalizationService.translate('left', lang),
                              'L',
                              side,
                              Colors.blue,
                              id,
                              setS,
                              lang,
                              withArrow: true,
                            ),
                            _pickerSideButton(
                              LocalizationService.translate('right', lang),
                              'R',
                              side,
                              Colors.red,
                              id,
                              setS,
                              lang,
                              withArrow: true,
                            ),
                            if (cat == 'punch' || cat == 'kick')
                              ActionChip(
                                label: Text(
                                  spec ??
                                      LocalizationService.translate(
                                        'move',
                                        lang,
                                      ),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                onPressed: () => _pickSpecialForMove(id, setS),
                              ),
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 4,
                              children: [
                                if (pL.contains('H'))
                                  _counterLevelButton(
                                    'High',
                                    item,
                                    cat,
                                    side,
                                    attack,
                                    aCat,
                                    aSide,
                                    aLev,
                                    aF,
                                    aS,
                                    aTr,
                                    tr,
                                    reps,
                                    spec,
                                    pickerS,
                                    lang,
                                    withArrow: true,
                                  ),
                                if (pL.contains('M'))
                                  _counterLevelButton(
                                    'Mid',
                                    item,
                                    cat,
                                    side,
                                    attack,
                                    aCat,
                                    aSide,
                                    aLev,
                                    aF,
                                    aS,
                                    aTr,
                                    tr,
                                    reps,
                                    spec,
                                    pickerS,
                                    lang,
                                    withArrow: true,
                                  ),
                                if (pL.contains('L'))
                                  _counterLevelButton(
                                    'Low',
                                    item,
                                    cat,
                                    side,
                                    attack,
                                    aCat,
                                    aSide,
                                    aLev,
                                    aF,
                                    aS,
                                    aTr,
                                    tr,
                                    reps,
                                    spec,
                                    pickerS,
                                    lang,
                                    withArrow: true,
                                  ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _levelSelectionButton(
    String l,
    int id,
    StateSetter setS,
    String lang,
  ) {
    IconData icon = l == 'High'
        ? Icons.north_east
        : (l == 'Low' ? Icons.south_east : Icons.arrow_forward);
    final bool sel =
        _pickerState.pendingActionItemId == id &&
        _pickerState.pendingLevel == l;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(60, 32),
        backgroundColor: sel ? Theme.of(context).primaryColor : null,
        foregroundColor: sel ? Colors.white : null,
      ),
      onPressed: () => setS(() {
        _activateGlossaryItem(id);
        // Toggle: if already selected, deselect (set to empty string)
        _pickerState.setPendingLevel(sel ? '' : l);
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocalizationService.translate(
              l.toLowerCase(),
              lang,
            ).substring(0, 1),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12),
        ],
      ),
    );
  }

  Widget _buildWorkflowButtons(
    Map<String, dynamic> it,
    String cat,
    String sd,
    String lv,
    bool f,
    String? sp,
    Map<String, String> tr,
    StateSetter setS,
    String lang, {
    bool isCustom = false,
  }) {
    final bool isE = _pickerState.editingComboItemIndex != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: () {
                setS(() {
                  final ex = isE
                      ? _currentCombo[_pickerState.editingComboItemIndex!]
                      : null;
                  final Move n;
                  if (isE && _pickerState.isEditingCounter) {
                    n = ex!.copyWith(
                      counterName: isCustom
                          ? _customMoveController.text
                          : it['name'],
                      counterGlossaryId: isCustom ? null : it['id'],
                      counterCategory: cat,
                      counterSide: sd,
                      counterLevel: lv,
                      counterSpecialAction: sp,
                    );
                  } else {
                    n = Move(
                      glossaryId: isCustom ? null : it['id'],
                      counterGlossaryId: ex?.counterGlossaryId,
                      name: isCustom ? _customMoveController.text : it['name'],
                      category: cat,
                      translations: tr,
                      side: sd,
                      level: lv,
                      isFeint: f,
                      specialAction: sp,
                      repetitions: 1,
                      counterName: ex?.counterName,
                      counterCategory: ex?.counterCategory,
                      counterSide: ex?.counterSide,
                      counterLevel: ex?.counterLevel,
                      counterSpecialAction: ex?.counterSpecialAction,
                    );
                  }
                  if (isE) {
                    _currentCombo[_pickerState.editingComboItemIndex!] = n;
                    _pickerState.setEditingComboItemIndex(null);
                    _pickerState.setIsEditingCounter(false);
                  } else {
                    _addItemToCombo(n, setS);
                  }
                  _pickerState.setPendingActionItem(null);
                  _pickerState.setPendingLevel(null);
                });
              },
              child: Text(
                isE
                    ? LocalizationService.translate('update_item', lang)
                    : LocalizationService.translate('next', lang),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: () {
                setS(() {
                  _pickerState.setPendingAttackMove({
                    'item': isCustom
                        ? {
                            'name': _customMoveController.text,
                            'translations': '{}',
                            'hit_type': 'both',
                          }
                        : it,
                    'cat': cat,
                    'sd': sd,
                    'lv': lv,
                    'f': f,
                    'sp': sp,
                    'tr': tr,
                  });
                  _pickerState.setPendingActionItem(null);
                  _pickerState.setPendingLevel(null);
                });
              },
              child: Text(
                LocalizationService.translate('answer', lang),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: () {
                setS(() {
                  final ex = isE
                      ? _currentCombo[_pickerState.editingComboItemIndex!]
                      : null;
                  final Move n;
                  if (isE && _pickerState.isEditingCounter) {
                    n = ex!.copyWith(
                      counterName: isCustom
                          ? _customMoveController.text
                          : it['name'],
                      counterGlossaryId: isCustom ? null : it['id'],
                      counterCategory: cat,
                      counterSide: sd,
                      counterLevel: lv,
                      counterSpecialAction: sp,
                    );
                  } else {
                    n = Move(
                      glossaryId: isCustom ? null : it['id'],
                      counterGlossaryId: ex?.counterGlossaryId,
                      name: isCustom ? _customMoveController.text : it['name'],
                      category: cat,
                      translations: tr,
                      side: sd,
                      level: lv,
                      isFeint: f,
                      specialAction: sp,
                      repetitions: 1,
                      counterName: ex?.counterName,
                      counterCategory: ex?.counterCategory,
                      counterSide: ex?.counterSide,
                      counterLevel: ex?.counterLevel,
                      counterSpecialAction: ex?.counterSpecialAction,
                    );
                  }
                  if (isE) {
                    _currentCombo[_pickerState.editingComboItemIndex!] = n;
                  } else {
                    _addItemToCombo(n, setS);
                  }
                });
                _finishAndAddCombo();
                Navigator.pop(context);
              },
              child: Text(
                LocalizationService.translate('finish', lang),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: () => setS(() {
                if (isE) _pickerState.setEditingComboItemIndex(null);
                _pickerState.setPendingActionItem(null);
              }),
              child: Text(
                LocalizationService.translate('cancel', lang),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sideButtonWithArrow(
    String l,
    String sd,
    Color c,
    VoidCallback onP,
    String lang,
    int id,
  ) {
    final icon = sd == 'L' ? Icons.arrow_back : Icons.arrow_forward;
    final bool sel = _pickerState.selectedSides[id] == sd;
    return ActionChip(
      onPressed: () {
        _activateGlossaryItem(id);
        onP();
      },
      backgroundColor: sel ? c : c.withValues(alpha: 0.15),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sd == 'L') ...[
            Icon(icon, size: 12, color: sel ? Colors.white : c),
            const SizedBox(width: 4),
          ],
          Text(
            l,
            style: TextStyle(
              fontSize: 10,
              color: sel ? Colors.white : c,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (sd == 'R') ...[
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: sel ? Colors.white : c),
          ],
        ],
      ),
    );
  }

  void _addCounterMove(
    Map<String, dynamic> c,
    String cat,
    String cs,
    Map<String, dynamic> at,
    String ac,
    String as,
    String al,
    bool af,
    String? asp,
    Map<String, String> atr,
    Map<String, String> ctr,
    int r,
    StateSetter pS, {
    String? cLevelOverride,
  }) {
    pS(() {
      final isE = _pickerState.editingComboItemIndex != null;
      if (isE && _pickerState.isEditingCounter) {
        final ex = _currentCombo[_pickerState.editingComboItemIndex!];
        _currentCombo[_pickerState.editingComboItemIndex!] = Move(
          glossaryId: ex.glossaryId,
          counterGlossaryId: c['id'],
          name: ex.name,
          category: ex.category,
          translations: ex.translations,
          side: ex.side,
          level: ex.level,
          isFeint: ex.isFeint,
          specialAction: ex.specialAction,
          repetitions: ex.repetitions,
          counterName: c['name'],
          counterCategory: cat,
          counterSide: cs,
          counterLevel: cLevelOverride ?? ex.level,
          counterSpecialAction: null,
        );
        _pickerState.setEditingComboItemIndex(null);
        _pickerState.setIsEditingCounter(false);
      } else {
        final n = Move(
          glossaryId: at['id'],
          counterGlossaryId: c['id'],
          name: at['name'],
          category: ac,
          translations: atr,
          side: as,
          level: al,
          isFeint: af,
          specialAction: asp,
          repetitions: r,
          counterName: c['name'],
          counterCategory: cat,
          counterSide: cs,
          counterLevel: cLevelOverride ?? al,
          counterSpecialAction: null,
        );
        if (isE) {
          _currentCombo[_pickerState.editingComboItemIndex!] = n;
          _pickerState.setEditingComboItemIndex(null);
        } else {
          _addItemToCombo(n, pS);
        }
      }
      _pickerState.setPendingAttackMove(null);
      _pickerState.setPendingActionItem(null);
      _pickerState.setPendingLevel(null);
    });
    if (_pickerState.editingComboItemIndex != null) {
      Navigator.pop(context);
    }
  }

  Widget _counterLevelButton(
    String l,
    Map<String, dynamic> c,
    String cat,
    String cs,
    Map<String, dynamic> at,
    String ac,
    String as,
    String al,
    bool af,
    String? asp,
    Map<String, String> atr,
    Map<String, String> ctr,
    int r,
    String? csp,
    StateSetter pS,
    String lang, {
    bool withArrow = false,
  }) {
    IconData icon = l == 'High'
        ? Icons.north_east
        : (l == 'Low' ? Icons.south_east : Icons.arrow_forward);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(60, 32),
      ),
      onPressed: () => _addCounterMove(
        c,
        cat,
        cs,
        at,
        ac,
        as,
        al,
        af,
        asp,
        atr,
        ctr,
        r,
        pS,
        cLevelOverride: l,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocalizationService.translate(
              l.toLowerCase(),
              lang,
            ).substring(0, 1),
            style: const TextStyle(fontSize: 11),
          ),
          if (withArrow) ...[const SizedBox(width: 4), Icon(icon, size: 12)],
        ],
      ),
    );
  }

  void _finishAndAddCombo() {
    if (_currentCombo.isEmpty) return;
    setState(() {
      Move finalMove = _currentCombo.length == 1
          ? _currentCombo.first
          : Move(
              name: 'Combo: ${_currentCombo.first.name} + ...',
              category: 'combo',
              subMoves: List.from(_currentCombo),
            );

      // Apply sub-letter if selected
      if (_pickerState.selectedSubLetter != null) {
        finalMove = finalMove.copyWith(
          subLetter: _pickerState.selectedSubLetter,
        );
      }

      if (_pickerState.editingSeriesIndex != null) {
        _moves.removeAt(_pickerState.editingSeriesIndex!);
        int target =
            _pickerState.targetSeriesIndex ?? _pickerState.editingSeriesIndex!;
        if (target >= _moves.length) {
          _moves.add(finalMove);
        } else {
          _moves.insert(target, finalMove);
        }
      } else {
        _moves.add(finalMove);
      }
      _currentCombo.clear();
      _pickerState.setEditingSeriesIndex(null);
      _pickerState.setTargetSeriesIndex(null);
      _pickerState.setEditingComboItemIndex(null);
    });
  }

  List<Widget> _buildMoveListTiles(String lang) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    return MoveListDisplayWidget.buildTiles(
      moves: _moves,
      language: lang,
      isEditing: _isEditing,
      trainingController: _trainingController,
      context: context,
      category: _selectedCategory,
      showTranslation: provider.showTranslation,
      onEdit: (index) => () {
        if (_moves[index].isCombo) {
          _pickMove(initialMoves: _moves[index].subMoves, seriesIndex: index);
        } else {
          _pickMove(initialMoves: [_moves[index]], seriesIndex: index);
        }
      },
      onClone: (index) => () {
        setState(() {
          final map = _moves[index].toMap();
          map['id'] = null;
          final copy = Move.fromMap(map);
          _moves.insert(index + 1, copy);
        });
      },
      onDelete: (index) =>
          () => _confirmDeleteItem(context, index, lang),
      onShowMediaGallery: _showMediaGallery,
      onSetState: (moves, atIndex) => setState(() {
        _moves = moves;
      }),
    );
  }

  void _confirmDeleteItem(BuildContext context, int index, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('delete_item', lang)),
        content: Text(
          LocalizationService.translate('confirm_delete_item', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _moves.removeAt(index));
              Navigator.pop(context);
            },
            child: Text(
              LocalizationService.translate('finish', lang),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _pickSpecialForMove(int id, StateSetter setS) async {
    final specs = await DatabaseService().getGlossaryByCategory('move');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Special Action'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: specs.length + 1,
            itemBuilder: (ctx, idx) {
              if (idx == 0) {
                return ListTile(
                  title: const Text('None'),
                  onTap: () {
                    setS(() => _pickerState.selectedSpecials[id] = null);
                    Navigator.pop(ctx);
                  },
                );
              }
              final s = specs[idx - 1];
              return ListTile(
                title: Text(s['name']),
                onTap: () {
                  setS(() => _pickerState.selectedSpecials[id] = s['name']);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pickerSideButton(
    String label,
    String sd,
    String curr,
    Color c,
    int id,
    StateSetter setS,
    String lang, {
    bool withArrow = false,
  }) {
    bool isS = curr == sd;
    final icon = sd == 'L' ? Icons.arrow_back : Icons.arrow_forward;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withArrow && sd == 'L') ...[
            Icon(icon, size: 12, color: isS ? Colors.white : c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isS ? Colors.white : c,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (withArrow && sd == 'R') ...[
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: isS ? Colors.white : c),
          ],
        ],
      ),
      selected: isS,
      selectedColor: c.withValues(alpha: 0.7),
      backgroundColor: c.withValues(alpha: 0.15),
      onSelected: (selected) {
        setS(() {
          _activateGlossaryItem(id);
          _pickerState.selectedSides[id] = selected ? sd : '';
        });
      },
    );
  }

  Future<void> _handleExportJson() async {
    if (widget.series == null) return;
    String? dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    final fileName =
        'jkd-series-${StringUtils.slugify(widget.series!.title)}.json';
    if (!mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('File: $fileName'), Text('Dir: $dir')],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('FINISH'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      final path = await ExportService.exportToJson(
        [widget.series!],
        fileName: fileName,
        customDirectory: dir,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(path != null ? 'Success: $path' : 'Error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SeriesProvider>(context).language;
    return Scaffold(
      appBar: _currentTrainingOptions != null
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
                        } else if (cat == 'JKD Moves') {
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
                    widget.series!.category != 'JKD Moves')
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.greenAccent,
                    ),
                    onPressed: _showTrainingOptions,
                    tooltip: LocalizationService.translate(
                      'training_mode',
                      lang,
                    ),
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
                        PdfService.exportSeriesToPdf(widget.series!, lang);
                      } else if (value == 'export') {
                        _handleExportJson();
                      } else if (value == 'share') {
                        ExportService.shareSeriesJson(
                          [widget.series!],
                          fileName:
                              'jkd-series-${widget.series!.title.replaceAll(' ', '-').toLowerCase()}.json',
                        );
                      }
                    },
                    itemBuilder: (context) {
                      final isSystemJkdMoves =
                          widget.series!.isSystem &&
                          widget.series!.category == 'JKD Moves';
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
                if (_trainingController.isTraining)
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
                        label: const Text('JKD Moves'),
                        selected: _selectedCategory == 'JKD Moves',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = 'JKD Moves');
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
                  if (_selectedCategory != 'JKD Moves') ...[
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
                ] else ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          '${LocalizationService.translate('category', lang)}: $_selectedCategory',
                        ),
                      ),
                      if (_selectedCategory != 'JKD Moves')
                        Chip(
                          label: Text(
                            '${LocalizationService.translate('type', lang)}: $_selectedType',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 48,
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
                                onPressed: () => _pickMove(),
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
                Expanded(
                  child: _isEditing
                      ? ReorderableListView(
                          scrollController: _movesScrollController,
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = _moves.removeAt(oldIndex);
                              _moves.insert(newIndex, item);
                            });
                          },
                          children: _buildMoveListTiles(lang),
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
