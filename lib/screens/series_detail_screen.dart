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

class SeriesDetailScreen extends StatefulWidget {
  final JkdSeries? series;
  const SeriesDetailScreen({super.key, this.series});

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
  TrainingOptions? _currentTrainingOptions;

  final MediaService _mediaService = MediaService();

  final List<Move> _currentCombo = [];
  final Map<int, String> _selectedSidesInPicker = {};
  final Map<int, bool> _selectedFeintsInPicker = {};
  final Map<int, String?> _selectedSpecialsInPicker = {};
  int? _pendingActionItemId;
  String? _pendingLevel;
  int? _editingSeriesIndex;
  int? _targetSeriesIndex;
  int? _editingComboItemIndex;
  bool _isEditingCounter = false;
  bool _isPickerOpen = false;
  Map<String, dynamic>?
  _pendingAttackMove; // Store attack info when selecting counter
  final ScrollController _comboScrollController = ScrollController();
  final Map<String, ScrollController> _glossaryScrollControllers = {};
  Timer? _scrollTimer;
  int? _lastScrolledItemId;

  final Map<String, String> _methodDefinitions = {
    'SDA':
        'Simple Direct Attack: A single, direct strike without preceding feints.',
    'PIA':
        'Progressive Indirect Attack: Begins with a feint to misdirect and progresses to an open line.',
    'SIA':
        'Single Indirect Attack: A single motion that changes direction mid-flight.',
    'BTAA':
        'Broken Timing Angle Attack: Varying speed and timing to disrupt defensive rhythm.',
    'ABD':
        'Attack By Drawing: Deliberately baiting the opponent into attacking to create a counter opportunity.',
    'ABC':
        'Attack By Combination: A rapid sequence of multiple strikes to overwhelm the guard.',
  };

  @override
  void initState() {
    super.initState();
    if (widget.series != null) {
      _titleController.text = widget.series!.title;
      _selectedCategory = widget.series!.category;
      _selectedType = widget.series!.type;
      _selectedMethod = widget.series!.attackMethod;
      _moves = List.from(widget.series!.moves);
    } else {
      _isEditing = true;
    }
    _trainingController = TrainingController(
      tts: _tts,
      onIndexChanged: (index) {
        if (mounted) setState(() {});
      },
      onTrainingComplete: () {
        if (mounted) {
          setState(() {
            _currentTrainingOptions = null;
          });
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
    _titleController.dispose();
    _customMoveController.dispose();
    _comboScrollController.dispose();
    for (final controller in _glossaryScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _slugify(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

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
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
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
      provider.speechRate,
    );

    if (options != null) {
      setState(() {
        _trainingInterval = options.interval;
        _currentTrainingOptions = options;
      });
      _trainingController.startTraining(
        moves: _moves,
        startIndex: options.startIndex,
        endIndex: options.endIndex,
        interval: options.interval,
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
      if (_isPickerOpen) {
        _currentCombo.addAll(parsed);
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
    if (initialMoves != null) _currentCombo.addAll(initialMoves);
    _editingSeriesIndex = seriesIndex;
    _targetSeriesIndex = seriesIndex;
    _editingComboItemIndex = null;
    setState(() => _isPickerOpen = true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final lang = Provider.of<SeriesProvider>(context).language;
          final voiceEnabled = Provider.of<SeriesProvider>(
            context,
          ).voiceEnabled;
          final isCounterMode = _pendingAttackMove != null;

          return DefaultTabController(
            key: ValueKey(isCounterMode),
            length: isCounterMode ? 5 : 7,
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
                            onPressed: () =>
                                setS(() => _pendingAttackMove = null),
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
                              icon: const Icon(Icons.front_hand),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'trapping',
                                lang,
                              ),
                              icon: const Icon(Icons.back_hand),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'special',
                                lang,
                              ),
                              icon: const Icon(Icons.directions_run),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'other',
                                lang,
                              ),
                              icon: const Icon(Icons.more_horiz),
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
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'kicks',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('kick'),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'packs',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('packs'),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'trapping',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('trapping'),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'special',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('special'),
                              ),
                            ),
                            Tab(
                              text: LocalizationService.translate(
                                'other',
                                lang,
                              ),
                              icon: Icon(
                                MoveDisplayWidgets.getCategoryIcon('other'),
                              ),
                            ),
                            const Tab(
                              text: 'Text',
                              icon: Icon(Icons.text_fields),
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
                                _pendingAttackMove!['item'],
                                _pendingAttackMove!['cat'],
                                _pendingAttackMove!['sd'],
                                _pendingAttackMove!['lv'],
                                _pendingAttackMove!['f'],
                                _pendingAttackMove!['sp'],
                                _pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCounterGlossaryList(
                                'trapping',
                                setS,
                                _pendingAttackMove!['item'],
                                _pendingAttackMove!['cat'],
                                _pendingAttackMove!['sd'],
                                _pendingAttackMove!['lv'],
                                _pendingAttackMove!['f'],
                                _pendingAttackMove!['sp'],
                                _pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCounterGlossaryList(
                                'special',
                                setS,
                                _pendingAttackMove!['item'],
                                _pendingAttackMove!['cat'],
                                _pendingAttackMove!['sd'],
                                _pendingAttackMove!['lv'],
                                _pendingAttackMove!['f'],
                                _pendingAttackMove!['sp'],
                                _pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCounterGlossaryList(
                                'other',
                                setS,
                                _pendingAttackMove!['item'],
                                _pendingAttackMove!['cat'],
                                _pendingAttackMove!['sd'],
                                _pendingAttackMove!['lv'],
                                _pendingAttackMove!['f'],
                                _pendingAttackMove!['sp'],
                                _pendingAttackMove!['tr'],
                                1,
                                setS,
                                lang,
                              ),
                              _buildCustomTextTab(
                                setS,
                                lang,
                                isCounter: true,
                                attackItem: _pendingAttackMove!['item'],
                                attackCategory: _pendingAttackMove!['cat'],
                                side: _pendingAttackMove!['sd'],
                                level: _pendingAttackMove!['lv'],
                                isFeint: _pendingAttackMove!['f'],
                                special: _pendingAttackMove!['sp'],
                                attackTranslations: _pendingAttackMove!['tr'],
                                reps: 1,
                                pickerModalState: setS,
                              ),
                            ]
                          : [
                              _buildGlossaryWithScroll('punch', setS, lang),
                              _buildGlossaryWithScroll('kick', setS, lang),
                              _buildGlossaryWithScroll('packs', setS, lang),
                              _buildGlossaryWithScroll('trapping', setS, lang),
                              _buildGlossaryWithScroll('special', setS, lang),
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
    setState(() => _isPickerOpen = false);
  }

  void _resetPickerState() {
    _selectedSidesInPicker.clear();
    _selectedFeintsInPicker.clear();
    _selectedSpecialsInPicker.clear();
    _pendingActionItemId = null;
    _pendingLevel = null;
    _editingSeriesIndex = null;
    _targetSeriesIndex = null;
    _editingComboItemIndex = null;
    _isEditingCounter = false;
    _pendingAttackMove = null;
    _lastScrolledItemId = null;
  }

  Future<int> _getInitialIndexForCategory(String cat) async {
    if (_pendingActionItemId == null) return -1;
    final items = await DatabaseService().getGlossaryByCategory(cat);
    return items.indexWhere((item) => item['id'] == _pendingActionItemId);
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
    if (_pendingActionItemId != itemId) {
      _selectedSidesInPicker.clear();
      _selectedFeintsInPicker.clear();
      _selectedSpecialsInPicker.clear();
      _pendingActionItemId = itemId;
      _pendingLevel = null;
    }
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
    final double h = _currentCombo.any((m) => m.category == 'special')
        ? 198
        : 190;
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
                        _editingSeriesIndex != null
                            ? '${LocalizationService.translate('update_item', lang).toUpperCase()} ${_editingSeriesIndex! + 1}'
                            : '${LocalizationService.translate('current_combo', lang)} (${_currentCombo.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (_editingSeriesIndex != null) ...[
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _targetSeriesIndex != null
                              ? _targetSeriesIndex! + 1
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
                              setS(() => _targetSeriesIndex = val - 1);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (voiceEnabled && _editingSeriesIndex == null) ...[
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
                      if (_editingSeriesIndex != null)
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
                            _editingSeriesIndex != null
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
                ReorderableListView.builder(
                  scrollController: _comboScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentCombo.length,
                  onReorder: (old, newIdx) {
                    setS(() {
                      if (newIdx > old) newIdx -= 1;
                      final item = _currentCombo.removeAt(old);
                      _currentCombo.insert(newIdx, item);
                    });
                  },
                  itemBuilder: (ctx, idx) {
                    final m = _currentCombo[idx];
                    final sel =
                        _editingComboItemIndex == idx && !_isEditingCounter;
                    final cSel =
                        _editingComboItemIndex == idx && _isEditingCounter;
                    return Card(
                      key: ValueKey(m.uKey),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      shape: (sel || cSel)
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: sel
                                    ? Colors.blueAccent
                                    : Colors.orangeAccent,
                                width: 2,
                              ),
                            )
                          : null,
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(6),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    int? gid = m.glossaryId;
                                    // Robust fallback: try category match first, then global match
                                    if (gid == null) {
                                      final db = DatabaseService();
                                      var items = await db
                                          .getGlossaryByCategory(m.category);
                                      var match = items.firstWhere(
                                        (i) =>
                                            i['name']
                                                .toString()
                                                .toLowerCase() ==
                                            m.name.toLowerCase(),
                                        orElse: () => {},
                                      );

                                      if (match.isEmpty) {
                                        final all = await db.getGlossary();
                                        match = all.firstWhere(
                                          (i) =>
                                              i['name']
                                                  .toString()
                                                  .toLowerCase() ==
                                              m.name.toLowerCase(),
                                          orElse: () => {},
                                        );
                                      }

                                      if (match.isNotEmpty) {
                                        gid = match['id'];
                                      }
                                    }

                                    setS(() {
                                      _editingComboItemIndex = idx;
                                      _isEditingCounter = false;
                                      if (gid != null) {
                                        _selectedSidesInPicker[gid] = m.side;
                                        _selectedFeintsInPicker[gid] =
                                            m.isFeint;
                                        _selectedSpecialsInPicker[gid] =
                                            m.specialAction;
                                        _pendingActionItemId = gid;
                                        _pendingLevel = m.level;
                                        _lastScrolledItemId =
                                            null; // Reset to allow scrolling to new selection
                                      }
                                    });
                                    final t =
                                        MoveDisplayWidgets.getTabIndexForCategory(
                                          m.category,
                                        );
                                    if (t != -1 && ctx.mounted) {
                                      DefaultTabController.of(ctx).animateTo(t);
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            MoveDisplayWidgets.getCategoryIcon(
                                              m.category,
                                            ),
                                            size: 22,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${idx + 1}. ${m.name}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (m.side.isNotEmpty)
                                            MoveDisplayWidgets.sideCircle(
                                              LocalizationService.translate(
                                                m.side == 'L'
                                                    ? 'left'
                                                    : 'right',
                                                lang,
                                              ).substring(0, 1),
                                              m.side,
                                              mini: true,
                                            ),
                                          MoveDisplayWidgets.levelIcon(
                                            m.level,
                                            size: 10,
                                            mini: true,
                                          ),
                                          if (m.isFeint)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 4.0,
                                              ),
                                              child: MoveDisplayWidgets.drawBox(
                                                mini: true,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (m.counterName != null)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        final cat = m.counterCategory ?? '';
                                        int? gid = m.counterGlossaryId;

                                        if (gid == null &&
                                            m.counterName != null) {
                                          // Fallback to name search if ID is missing (legacy data)
                                          final items = await DatabaseService()
                                              .getGlossaryByCategory(cat);
                                          final match = items.firstWhere(
                                            (i) => i['name'] == m.counterName,
                                            orElse: () => {},
                                          );
                                          if (match.isNotEmpty) {
                                            gid = match['id'];
                                          }
                                        }

                                        setS(() {
                                          _editingComboItemIndex = idx;
                                          _isEditingCounter = true;
                                          if (gid != null) {
                                            _selectedSidesInPicker[gid] =
                                                m.counterSide ?? '';
                                            _selectedSpecialsInPicker[gid] =
                                                m.counterSpecialAction;
                                            _pendingActionItemId = gid;
                                            _pendingLevel = m.counterLevel;
                                            _lastScrolledItemId =
                                                null; // Reset to allow scrolling to new selection
                                          }
                                        });
                                        final t =
                                            MoveDisplayWidgets.getTabIndexForCategory(
                                              cat,
                                            );
                                        if (t != -1 && ctx.mounted) {
                                          DefaultTabController.of(
                                            ctx,
                                          ).animateTo(t);
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Divider(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                MoveDisplayWidgets.getCategoryIcon(
                                                  m.counterCategory ?? '',
                                                ),
                                                size: 18,
                                                color: Colors.orangeAccent,
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  '↳ ${m.counterName}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orangeAccent,
                                                    decoration: cSel
                                                        ? TextDecoration
                                                              .underline
                                                        : null,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Center(
                                  child: ReorderableDragStartListener(
                                    index: idx,
                                    child: const Icon(
                                      Icons.drag_handle,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: -10,
                              top: -10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                onPressed: () => setS(() {
                                  _currentCombo.removeAt(idx);
                                  if (_editingComboItemIndex == idx) {
                                    _editingComboItemIndex = null;
                                    _isEditingCounter = false;
                                  }
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_currentCombo.length > 1) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white70,
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
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
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
          if (_lastScrolledItemId != targetItemId) {
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
                  _lastScrolledItemId = targetItemId;
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
            final side = _selectedSidesInPicker[id] ?? '';
            final isF = _selectedFeintsInPicker[id] ?? false;
            final spec = _selectedSpecialsInPicker[id];
            // Expanded highlight logic: match by ID or by name/cat if ID is null (legacy)
            final bool isE =
                _pendingActionItemId == id ||
                (_pendingActionItemId == null &&
                    _editingComboItemIndex != null &&
                    (!_isEditingCounter
                        ? _currentCombo[_editingComboItemIndex!].name ==
                              item['name']
                        : _currentCombo[_editingComboItemIndex!].counterName ==
                              item['name']) &&
                    (!_isEditingCounter
                        ? _currentCombo[_editingComboItemIndex!].category == cat
                        : _currentCombo[_editingComboItemIndex!]
                                  .counterCategory ==
                              cat));
            final String pL = item['possible_level'] ?? 'H,M,L';
            final bool sH = pL.contains('H'),
                sM = pL.contains('M'),
                sL = pL.contains('L');
            Map<String, String> tr = {};
            try {
              tr = Map<String, String>.from(json.decode(item['translations']));
            } catch (_) {}
            final translation = tr[lang] ?? tr['en'] ?? tr['fr'] ?? '';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: isE
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Colors.blueAccent,
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
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat == 'special'
                                ? (tr['en'] ?? item['name'])
                                : item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (cat != 'special' && translation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 40.0),
                          child: Text(
                            translation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (cat == 'special')
                            ElevatedButton(
                              onPressed: () => setS(() {
                                _pendingActionItemId = id;
                                _pendingLevel = '';
                              }),
                              child: const Text('ADD'),
                            )
                          else if (cat == 'trapping' || cat == 'packs') ...[
                            _sideButtonWithArrow(
                              LocalizationService.translate('left', lang),
                              'L',
                              Colors.blue,
                              () => setS(() {
                                _pendingActionItemId = id;
                                _pendingLevel = '';
                                _selectedSidesInPicker[id] = 'L';
                              }),
                              lang,
                              id,
                            ),
                            _sideButtonWithArrow(
                              LocalizationService.translate('right', lang),
                              'R',
                              Colors.red,
                              () => setS(() {
                                _pendingActionItemId = id;
                                _pendingLevel = '';
                                _selectedSidesInPicker[id] = 'R';
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
                                onSelected: (v) =>
                                    setS(() => _selectedFeintsInPicker[id] = v),
                              ),
                              ActionChip(
                                label: Text(
                                  spec ??
                                      LocalizationService.translate(
                                        'special',
                                        lang,
                                      ),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                onPressed: () => _pickSpecialForMove(id, setS),
                              ),
                            ],
                          ],
                          const SizedBox(width: 8),
                          if (cat != 'special')
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
                      if (_pendingActionItemId == id)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildWorkflowButtons(
                            item,
                            cat,
                            side,
                            _pendingLevel ?? '',
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService().getGlossaryByCategory(cat),
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
            final side = _selectedSidesInPicker[id] ?? '';
            final spec = _selectedSpecialsInPicker[id];
            final String pL = item['possible_level'] ?? 'H,M,L';
            Map<String, String> tr = {};
            try {
              tr = Map<String, String>.from(json.decode(item['translations']));
            } catch (_) {}
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
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (cat == 'special')
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
                                        'special',
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
    final bool sel = _pendingActionItemId == id && _pendingLevel == l;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(60, 32),
        backgroundColor: sel ? Theme.of(context).primaryColor : null,
        foregroundColor: sel ? Colors.white : null,
      ),
      onPressed: () => setS(() {
        _activateGlossaryItem(id);
        _pendingLevel = l;
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
    final bool isE = _editingComboItemIndex != null;
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
                      ? _currentCombo[_editingComboItemIndex!]
                      : null;
                  final Move n;
                  if (isE && _isEditingCounter) {
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
                    _currentCombo[_editingComboItemIndex!] = n;
                    _editingComboItemIndex = null;
                    _isEditingCounter = false;
                  } else {
                    _currentCombo.add(n);
                  }
                  _pendingActionItemId = null;
                  _pendingLevel = null;
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
                  _pendingAttackMove = {
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
                  };
                  _pendingActionItemId = null;
                  _pendingLevel = null;
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
                      ? _currentCombo[_editingComboItemIndex!]
                      : null;
                  final Move n;
                  if (isE && _isEditingCounter) {
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
                    _currentCombo[_editingComboItemIndex!] = n;
                  } else {
                    _currentCombo.add(n);
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
                if (isE) _editingComboItemIndex = null;
                _pendingActionItemId = null;
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
    final bool sel = _selectedSidesInPicker[id] == sd;
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
      final isE = _editingComboItemIndex != null;
      if (isE && _isEditingCounter) {
        final ex = _currentCombo[_editingComboItemIndex!];
        _currentCombo[_editingComboItemIndex!] = Move(
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
        _editingComboItemIndex = null;
        _isEditingCounter = false;
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
          _currentCombo[_editingComboItemIndex!] = n;
          _editingComboItemIndex = null;
        } else {
          _currentCombo.add(n);
        }
      }
      _pendingAttackMove = null;
      _pendingActionItemId = null;
      _pendingLevel = null;
    });
    if (_editingComboItemIndex != null) {
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
      final Move finalMove = _currentCombo.length == 1
          ? _currentCombo.first
          : Move(
              name: 'Combo: ${_currentCombo.first.name} + ...',
              category: 'combo',
              subMoves: List.from(_currentCombo),
            );
      if (_editingSeriesIndex != null) {
        _moves.removeAt(_editingSeriesIndex!);
        int target = _targetSeriesIndex ?? _editingSeriesIndex!;
        if (target >= _moves.length) {
          _moves.add(finalMove);
        } else {
          _moves.insert(target, finalMove);
        }
      } else {
        _moves.add(finalMove);
      }
      _currentCombo.clear();
      _editingSeriesIndex = null;
      _targetSeriesIndex = null;
      _editingComboItemIndex = null;
    });
  }

  List<Widget> _buildMoveListTiles(String lang) {
    return [
      for (int i = 0; i < _moves.length; i++)
        Padding(
          key: ValueKey(_moves[i].uKey),
          padding: const EdgeInsets.only(left: 15.0, bottom: 8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  final t = _moves[i].getTranslation(lang);
                  if (t.isNotEmpty) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_moves[i].name}: $t'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                onDoubleTap: _isEditing
                    ? () {
                        if (_moves[i].isCombo) {
                          _pickMove(
                            initialMoves: _moves[i].subMoves,
                            seriesIndex: i,
                          );
                        } else {
                          _pickMove(initialMoves: [_moves[i]], seriesIndex: i);
                        }
                      }
                    : () =>
                          _showMediaGallery(_moves[i].category, _moves[i].name),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: _trainingController.currentIndex == i
                      ? Colors.green.withValues(alpha: 0.3)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      minLeadingWidth: 0,
                      horizontalTitleGap: 12,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (_moves[i].repetitions > 1)
                                Chip(
                                  label: Text(
                                    'x${_moves[i].repetitions}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors.blueGrey,
                                ),
                              if (!_moves[i].isCombo) ...[
                                Icon(
                                  MoveDisplayWidgets.getCategoryIcon(
                                    _moves[i].category,
                                  ),
                                  size: 32,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: _moves[i].getTranslation(lang),
                                  child: Text(
                                    _moves[i].name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                MoveDisplayWidgets.sideCircle(
                                  LocalizationService.translate(
                                    _moves[i].side == 'L' ? 'left' : 'right',
                                    lang,
                                  ).substring(0, 1),
                                  _moves[i].side,
                                ),
                                MoveDisplayWidgets.levelIcon(
                                  _moves[i].level,
                                  size: 14,
                                ),
                                if (_moves[i].isFeint)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: MoveDisplayWidgets.drawBox(),
                                  ),
                                if (_moves[i].specialAction != null)
                                  Chip(
                                    label: Text(
                                      _moves[i].specialAction!,
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                    backgroundColor: Colors.purple.withValues(
                                      alpha: 0.3,
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ],
                          ),
                          if (_moves[i].isCombo)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 0.0,
                                top: 4.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _moves[i].subMoves.asMap().entries.map((
                                  entry,
                                ) {
                                  final subIdx = entry.key;
                                  final sub = entry.value;
                                  final bool isSingle =
                                      _moves[i].subMoves.length == 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onDoubleTap: () => _showMediaGallery(
                                            sub.category,
                                            sub.name,
                                          ),
                                          child: Wrap(
                                            spacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              if (isSingle)
                                                const Icon(
                                                  Icons.keyboard_arrow_right,
                                                  size: 18,
                                                  color: Colors.grey,
                                                )
                                              else
                                                Text(
                                                  '${subIdx + 1}.',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Icon(
                                                MoveDisplayWidgets.getCategoryIcon(
                                                  sub.category,
                                                ),
                                                size: 24,
                                                color: Colors.grey,
                                              ),
                                              Text(
                                                sub.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              MoveDisplayWidgets.sideCircle(
                                                LocalizationService.translate(
                                                  sub.side == 'L'
                                                      ? 'left'
                                                      : 'right',
                                                  lang,
                                                ).substring(0, 1),
                                                sub.side,
                                                mini: false,
                                              ),
                                              MoveDisplayWidgets.levelIcon(
                                                sub.level,
                                                size: 12,
                                              ),
                                              if (sub.isFeint)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 4.0,
                                                      ),
                                                  child:
                                                      MoveDisplayWidgets.drawBox(
                                                        mini: true,
                                                      ),
                                                ),
                                              if (sub.specialAction != null)
                                                Chip(
                                                  label: Text(
                                                    sub.specialAction!,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.purple
                                                      .withValues(alpha: 0.2),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (sub.counterName != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                              left: 0.0,
                                            ),
                                            child: InkWell(
                                              onDoubleTap: () =>
                                                  _showMediaGallery(
                                                    sub.counterCategory ?? '',
                                                    sub.counterName!,
                                                  ),
                                              child: Wrap(
                                                spacing: 6,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .subdirectory_arrow_right,
                                                    size: 22,
                                                    color: Colors.orange,
                                                  ),
                                                  Icon(
                                                    MoveDisplayWidgets.getCategoryIcon(
                                                      sub.counterCategory ?? '',
                                                    ),
                                                    size: 22,
                                                    color: Colors.orangeAccent,
                                                  ),
                                                  Text(
                                                    sub.counterName!,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.orangeAccent,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  MoveDisplayWidgets.sideCircle(
                                                    LocalizationService.translate(
                                                      sub.counterSide == 'L'
                                                          ? 'left'
                                                          : 'right',
                                                      lang,
                                                    ).substring(0, 1),
                                                    sub.counterSide ?? '',
                                                    mini: true,
                                                  ),
                                                  MoveDisplayWidgets.levelIcon(
                                                    sub.counterLevel ?? '',
                                                    size: 10,
                                                    mini: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (!_moves[i].isCombo &&
                              _moves[i].counterName != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                left: 0.0,
                              ),
                              child: InkWell(
                                onDoubleTap: () => _showMediaGallery(
                                  _moves[i].counterCategory ?? '',
                                  _moves[i].counterName!,
                                ),
                                child: Wrap(
                                  spacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.subdirectory_arrow_right,
                                      size: 28,
                                      color: Colors.orange,
                                    ),
                                    Icon(
                                      MoveDisplayWidgets.getCategoryIcon(
                                        _moves[i].counterCategory ?? '',
                                      ),
                                      size: 28,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      _moves[i].counterName!,
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    MoveDisplayWidgets.sideCircle(
                                      LocalizationService.translate(
                                        _moves[i].counterSide == 'L'
                                            ? 'left'
                                            : 'right',
                                        lang,
                                      ).substring(0, 1),
                                      _moves[i].counterSide ?? '',
                                      mini: true,
                                    ),
                                    MoveDisplayWidgets.levelIcon(
                                      _moves[i].counterLevel ?? '',
                                      size: 10,
                                      mini: true,
                                    ),
                                    if (_moves[i].counterSpecialAction != null)
                                      Chip(
                                        label: Text(
                                          _moves[i].counterSpecialAction!,
                                          style: const TextStyle(fontSize: 8),
                                        ),
                                        backgroundColor: Colors.purple
                                            .withValues(alpha: 0.2),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: (_moves[i].isCombo)
                          ? null
                          : Text(_moves[i].getTranslation(lang)),
                      trailing: _isEditing
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.blueGrey,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      final map = _moves[i].toMap();
                                      map['id'] = null;
                                      final copy = Move.fromMap(map);
                                      _moves.insert(i + 1, copy);
                                    });
                                  },
                                  tooltip: LocalizationService.translate(
                                    'clone',
                                    lang,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteItem(context, i, lang),
                                ),
                                const SizedBox(width: 16),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(
                                    Icons.drag_handle,
                                    size: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -15,
                top: 0,
                bottom: 0,
                child: Center(
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.redAccent,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
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
    final specs = await DatabaseService().getGlossaryByCategory('special');
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
                    setS(() => _selectedSpecialsInPicker[id] = null);
                    Navigator.pop(ctx);
                  },
                );
              }
              final s = specs[idx - 1];
              return ListTile(
                title: Text(s['name']),
                onTap: () {
                  setS(() => _selectedSpecialsInPicker[id] = s['name']);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _pickCounterMove(
    Map<String, dynamic> at,
    String ac,
    String as,
    String al,
    bool af,
    String? asp,
    Map<String, String> atr,
    int r,
    StateSetter pS,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final lang = Provider.of<SeriesProvider>(context).language;
        return StatefulBuilder(
          builder: (ctx, setS) => DefaultTabController(
            length: 5,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.95,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      LocalizationService.translate('pick_answer', lang),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(
                        text: LocalizationService.translate('packs', lang),
                        icon: Icon(Icons.front_hand),
                      ),
                      Tab(
                        text: LocalizationService.translate('trapping', lang),
                        icon: Icon(Icons.back_hand),
                      ),
                      Tab(
                        text: LocalizationService.translate('special', lang),
                        icon: Icon(Icons.directions_run),
                      ),
                      Tab(
                        text: LocalizationService.translate('other', lang),
                        icon: Icon(Icons.more_horiz),
                      ),
                      const Tab(text: 'Text', icon: Icon(Icons.text_fields)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCounterGlossaryList(
                          'packs',
                          setS,
                          at,
                          ac,
                          as,
                          al,
                          af,
                          asp,
                          atr,
                          r,
                          pS,
                          lang,
                        ),
                        _buildCounterGlossaryList(
                          'trapping',
                          setS,
                          at,
                          ac,
                          as,
                          al,
                          af,
                          asp,
                          atr,
                          r,
                          pS,
                          lang,
                        ),
                        _buildCounterGlossaryList(
                          'special',
                          setS,
                          at,
                          ac,
                          as,
                          al,
                          af,
                          asp,
                          atr,
                          r,
                          pS,
                          lang,
                        ),
                        _buildCounterGlossaryList(
                          'other',
                          setS,
                          at,
                          ac,
                          as,
                          al,
                          af,
                          asp,
                          atr,
                          r,
                          pS,
                          lang,
                        ),
                        _buildCustomTextTab(
                          setS,
                          lang,
                          isCounter: true,
                          attackItem: at,
                          attackCategory: ac,
                          side: as,
                          level: al,
                          isFeint: af,
                          special: asp,
                          attackTranslations: atr,
                          reps: r,
                          pickerModalState: pS,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          _selectedSidesInPicker[id] = selected ? sd : '';
        });
      },
    );
  }

  Future<void> _handleExportJson() async {
    if (widget.series == null) return;
    String? dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    final fileName = 'jkd-series-${_slugify(widget.series!.title)}.json';
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
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/JKD.png', height: 32),
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
          if (!_isEditing && widget.series != null)
            IconButton(
              icon: const Icon(
                Icons.play_circle_fill,
                color: Colors.greenAccent,
              ),
              onPressed: _showTrainingOptions,
              tooltip: LocalizationService.translate('training_mode', lang),
            ),
          if (_isEditing)
            IconButton(icon: const Icon(Icons.check), onPressed: _saveSeries)
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
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(LocalizationService.translate('edit', lang)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'print',
                  child: ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(
                      LocalizationService.translate('export_to_pdf', lang),
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
              ],
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 300,
        ), // Same duration as page transition
        transitionBuilder: (Widget child, Animation<double> animation) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        child: Padding(
          key: ValueKey(_isEditing), // Key is crucial for AnimatedSwitcher
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
          child: Column(
            children: [
              if (_trainingController.isTraining)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.green),
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
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
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
                          setState(() => _selectedCategory = 'Jun Fan Gung Fu');
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
                        children: _methodDefinitions.keys
                            .map(
                              (method) => Tooltip(
                                message: _methodDefinitions[method]!,
                                child: ChoiceChip(
                                  label: Text(method),
                                  selected: _selectedMethod == method,
                                  onSelected: (val) => setState(
                                    () => _selectedMethod = val ? method : null,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
              ] else ...[
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        '${LocalizationService.translate('category', lang)}: $_selectedCategory',
                      ),
                    ),
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
                    : ListView(children: _buildMoveListTiles(lang)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
