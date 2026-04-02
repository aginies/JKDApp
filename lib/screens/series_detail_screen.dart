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
import 'series_detail/dialogs/voice_help_dialog.dart';
import 'series_detail/dialogs/voice_input_dialog.dart';
import 'series_detail/dialogs/training_options_dialog.dart';

import 'series_detail/dialogs/edit_help_dialog.dart';
import 'series_detail/services/media_gallery_service.dart';
import 'series_detail/services/voice_processing_service.dart';
import 'series_detail/services/training_management_service.dart'
    as training_service;
import 'series_detail/mixins/series_detail_utils.dart';
import 'series_detail/controllers/training_controller.dart';
import 'series_detail/widgets/move_display_widgets.dart';
import 'series_detail/widgets/marquee_widget.dart';
import 'series_detail/widgets/move_list_display_widget.dart';
import 'series_detail/widgets/combo_card_widget.dart';
import 'series_detail/constants/series_detail_constants.dart';
import 'series_detail/state/picker_state.dart';
import 'series_detail/glossary/glossary_ui_builder.dart';
import 'series_detail/widgets/glossary_tab_widget.dart';
import '../utils/string_utils.dart';

class SeriesDetailScreen extends StatefulWidget {
  final JkdSeries? series;
  final String? itemRange; // e.g., "1-4"
  const SeriesDetailScreen({super.key, this.series, this.itemRange});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen>
    with SeriesDetailUtils {
  final _titleController = TextEditingController();
  final _customMoveController = TextEditingController();
  String _selectedCategory = 'Jun Fan Gung Fu';
  String _selectedType = 'Attack';
  String? _selectedMethod;
  List<Move> _moves = [];
  bool _isEditing = false;

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

  // Getters required by SeriesDetailUtils mixin
  @override
  List<Move> get moves => _moves;

  @override
  ScrollController get movesScrollController => _movesScrollController;

  @override
  PickerState get pickerState => _pickerState;

  // Picker state management
  final PickerState _pickerState = PickerState();
  final List<Move> _currentCombo = [];
  final ScrollController _comboScrollController = ScrollController();
  final GlobalKey<AnimatedListState> _comboListKey =
      GlobalKey<AnimatedListState>();
  final ScrollController _movesScrollController = ScrollController();
  final TransformationController _transformationController =
      TransformationController();
  Timer? _scrollTimer;
  bool _isFullscreen = false;

  // Buffered move waiting for simultaneous merge (when + is pressed)
  Move? _pendingSimultaneousMove;

  // Buffered counter move waiting for simultaneous/chain merge (when + or → is pressed in counter mode)
  Move? _pendingCounterSimMove;
  bool _pendingCounterIsChain = false;

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
    GlossaryUIBuilder.disposeAllControllers();
    super.dispose();
  }

  List<String> _getAvailableSubLetters(int? targetIndex, int? editingIndex) {
    return getAvailableSubLetters(targetIndex, editingIndex);
  }

  String _getDisplayNumber(int index) {
    return getDisplayNumber(index);
  }

  void _normalizeSubLetters() {
    _moves = normalizeSubLetters(_moves);
  }

  void _scrollToIndex(int index) {
    scrollToIndex(index);
  }

  void _addItemToCombo(Move item) {
    _currentCombo.add(item);
    _comboListKey.currentState?.insertItem(
      _currentCombo.length - 1,
      duration: const Duration(
        milliseconds: SeriesDetailConstants.comboAnimationMs,
      ),
    );
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

  void _addCombinedActionToCombo(Move newItem, {bool isCounter = false}) {
    if (_currentCombo.isEmpty) {
      _addItemToCombo(newItem);
      return;
    }

    final lastIndex = _currentCombo.length - 1;
    final lastMove = _currentCombo[lastIndex];

    if (isCounter) {
      // Appending to counter side
      if (lastMove.counterName == null) {
        // If no counter yet, just set it
        _currentCombo[lastIndex] = lastMove.copyWith(
          counterName: newItem.name,
          counterCategory: newItem.category,
          counterSide: newItem.side,
          counterLevel: newItem.level,
          counterSpecialAction: newItem.specialAction,
          counterGlossaryId: newItem.glossaryId,
          counterTranslations: newItem.translations,
        );
      } else {
        // Append to existing counter name
        _currentCombo[lastIndex] = lastMove.copyWith(
          counterName: '${lastMove.counterName} + ${newItem.name}',
        );
      }
    } else {
      // Appending to hit (primary) side
      if (lastMove.category == 'simultaneous') {
        final updatedSubMoves = List<Move>.from(lastMove.subMoves)
          ..add(newItem);
        _currentCombo[lastIndex] = lastMove.copyWith(
          subMoves: updatedSubMoves,
          name: updatedSubMoves.map((m) => m.name).join(' + '),
        );
      } else {
        _currentCombo[lastIndex] = Move(
          name: '${lastMove.name} + ${newItem.name}',
          category: 'simultaneous',
          subMoves: [lastMove, newItem],
          // Preserve counter if it exists
          counterName: lastMove.counterName,
          counterCategory: lastMove.counterCategory,
          counterSide: lastMove.counterSide,
          counterLevel: lastMove.counterLevel,
          counterSpecialAction: lastMove.counterSpecialAction,
          counterGlossaryId: lastMove.counterGlossaryId,
          counterTranslations: lastMove.counterTranslations,
        );
      }
    }
  }

  void _handleEditComboItem(
    int index,
    bool isCounter,
    StateSetter setS,
    BuildContext ctx,
  ) async {
    if (index < 0 || index >= _currentCombo.length) return;
    final m = _currentCombo[index];

    // Determine the glossary ID to auto-expand the item in the list
    final int? glossaryId = isCounter ? m.counterGlossaryId : m.glossaryId;

    setS(() {
      _pickerState.setEditingComboItemIndex(index);
      _pickerState.setIsEditingCounter(isCounter);
      // Auto-expand the glossary item in the list
      if (glossaryId != null) {
        _pickerState.setPendingActionItem(glossaryId);
      }
    });

    if (!mounted) return;
    String cat = isCounter ? (m.counterCategory ?? '') : m.category;

    // For simultaneous moves, use the first sub-move's category for tab navigation
    if (!isCounter && cat == 'simultaneous' && m.subMoves.isNotEmpty) {
      cat = m.subMoves.first.category;
    }

    final t = MoveDisplayWidgets.getTabIndexForCategory(cat);
    if (t != -1) {
      _pickerState.setRequestedTabIndex(t);
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
          onShowMediaGallery: (cat, name) {},
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
    _voiceProcessingService.processVoiceInputWithContext(
      input,
      lang,
      _pickerState,
      _currentCombo,
      _moves,
      _comboListKey,
      () => setState(() {}),
    );
  }

  void _onWorkflowAction(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
    bool isCustom,
  ) {
    debugPrint('SeriesDetailScreen: _onWorkflowAction called');
    setState(() {
      final isE = _pickerState.editingComboItemIndex != null;
      final ex = isE
          ? _currentCombo[_pickerState.editingComboItemIndex!]
          : null;

      // If there's a pending simultaneous move and we're not editing,
      // combine it with the current move
      if (_pendingSimultaneousMove != null && !isE) {
        final currentMove = Move(
          glossaryId: isCustom ? null : item['id'],
          name: isCustom ? _customMoveController.text : item['name'],
          category: cat,
          translations: translations,
          side: side,
          level: level,
          isFeint: isFeint,
          specialAction: special,
          repetitions: 1,
        );
        final combined = Move(
          name: '${_pendingSimultaneousMove!.name} + ${currentMove.name}',
          category: 'simultaneous',
          subMoves: [_pendingSimultaneousMove!, currentMove],
        );
        _addItemToCombo(combined);
        _pendingSimultaneousMove = null;
        _pickerState.clearPendingAction();
        _customMoveController.clear();
        return;
      }

      final Move n;
      if (isE && _pickerState.isEditingCounter) {
        n = ex!.copyWith(
          counterName: isCustom ? _customMoveController.text : item['name'],
          counterGlossaryId: isCustom ? null : item['id'],
          counterCategory: cat,
          counterSide: side,
          counterLevel: level,
          counterSpecialAction: special,
          counterTranslations: translations,
        );
      } else {
        n = Move(
          glossaryId: isCustom ? null : item['id'],
          counterGlossaryId: ex?.counterGlossaryId,
          name: isCustom ? _customMoveController.text : item['name'],
          category: cat,
          side: side,
          level: level,
          isFeint: isFeint,
          specialAction: special,
          translations: translations,
          repetitions: 1,
          counterName: ex?.counterName,
          counterCategory: ex?.counterCategory,
          counterSide: ex?.counterSide,
          counterLevel: ex?.counterLevel,
          counterSpecialAction: ex?.counterSpecialAction,
          counterTranslations: ex?.counterTranslations ?? {},
        );
      }

      if (isE) {
        _currentCombo[_pickerState.editingComboItemIndex!] = n;
        _pickerState.clearEditingState();
      } else {
        _addItemToCombo(n);
      }
      _pickerState.clearPendingAction();
      _customMoveController.clear();
    });
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
    int r, {
    String? cLevelOverride,
  }) {
    debugPrint('SeriesDetailScreen: _addCounterMove called');
    setState(() {
      // --- Resolve the final counter move by consuming pending buffer ---
      final incomingCounter = Move(
        glossaryId: c['id'],
        name: c['name'],
        category: cat,
        side: cs,
        translations: ctr,
      );

      final Move resolvedCounter;
      if (_pendingCounterSimMove != null) {
        // Combine buffered counter with the incoming counter
        if (_pendingCounterIsChain) {
          // Chain merge: buffered → incoming
          if (_pendingCounterSimMove!.category == 'chain') {
            resolvedCounter = _pendingCounterSimMove!.copyWith(
              chain: [..._pendingCounterSimMove!.chain, incomingCounter],
              name:
                  '${_pendingCounterSimMove!.name} -> ${incomingCounter.name}',
            );
          } else {
            resolvedCounter = Move(
              name:
                  '${_pendingCounterSimMove!.name} -> ${incomingCounter.name}',
              category: 'chain',
              chain: [_pendingCounterSimMove!, incomingCounter],
            );
          }
        } else {
          // Simultaneous merge: buffered + incoming
          if (_pendingCounterSimMove!.category == 'simultaneous') {
            resolvedCounter = _pendingCounterSimMove!.copyWith(
              subMoves: [..._pendingCounterSimMove!.subMoves, incomingCounter],
              name: '${_pendingCounterSimMove!.name} + ${incomingCounter.name}',
            );
          } else {
            resolvedCounter = Move(
              name: '${_pendingCounterSimMove!.name} + ${incomingCounter.name}',
              category: 'simultaneous',
              subMoves: [_pendingCounterSimMove!, incomingCounter],
            );
          }
        }
        _pendingCounterSimMove = null;
        _pendingCounterIsChain = false;
      } else {
        resolvedCounter = incomingCounter;
      }

      // Use the first sub-element's fields for flat counter storage,
      // but the resolved name/category for the combined display
      final String finalCounterName = resolvedCounter.name;
      final String finalCounterCategory = resolvedCounter.category;
      // Side from the first counter move (the one the user picked first)
      final String finalCounterSide = resolvedCounter.category == 'simultaneous'
          ? (resolvedCounter.subMoves.isNotEmpty
                ? resolvedCounter.subMoves.first.side
                : resolvedCounter.side)
          : resolvedCounter.category == 'chain'
          ? (resolvedCounter.chain.isNotEmpty
                ? resolvedCounter.chain.first.side
                : resolvedCounter.side)
          : resolvedCounter.side;
      final Map<String, String> finalCounterTranslations =
          resolvedCounter.translations;

      final isE = _pickerState.editingComboItemIndex != null;

      if (isE && _pickerState.isEditingCounter) {
        final ex = _currentCombo[_pickerState.editingComboItemIndex!];
        _currentCombo[_pickerState.editingComboItemIndex!] = ex.copyWith(
          counterGlossaryId: resolvedCounter.glossaryId,
          counterName: finalCounterName,
          counterCategory: finalCounterCategory,
          counterSide: finalCounterSide,
          counterLevel: cLevelOverride ?? ex.level,
          counterSpecialAction: null,
          counterTranslations: finalCounterTranslations,
        );
        _pickerState.setEditingComboItemIndex(null);
        _pickerState.setIsEditingCounter(false);
      } else {
        final n = Move(
          glossaryId: at['id'],
          counterGlossaryId: resolvedCounter.glossaryId,
          name: at['name'],
          category: ac,
          translations: atr,
          side: as,
          level: al,
          isFeint: af,
          specialAction: asp,
          repetitions: r,
          counterName: finalCounterName,
          counterCategory: finalCounterCategory,
          counterSide: finalCounterSide,
          counterLevel: cLevelOverride ?? al,
          counterSpecialAction: null,
          counterTranslations: finalCounterTranslations,
        );
        if (isE) {
          _currentCombo[_pickerState.editingComboItemIndex!] = n;
          _pickerState.setEditingComboItemIndex(null);
        } else {
          _addItemToCombo(n);
        }
      }

      _pickerState.setPendingAttackMove(null);
      _pickerState.setPendingActionItem(null);
      _pickerState.setPendingLevel(null);
    });
  }

  void _onChainAction(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  ) {
    debugPrint('SeriesDetailScreen: _onChainAction called');
    setState(() {
      // If there's a pending simultaneous move, combine first then add
      if (_pendingSimultaneousMove != null) {
        final currentMove = Move(
          glossaryId: item['id'],
          name: item['name'],
          category: cat,
          translations: translations,
          side: side,
          level: level,
          isFeint: isFeint,
          specialAction: special,
          repetitions: 1,
        );
        final combined = Move(
          name: '${_pendingSimultaneousMove!.name} + ${currentMove.name}',
          category: 'simultaneous',
          subMoves: [_pendingSimultaneousMove!, currentMove],
        );
        _addItemToCombo(combined);
        _pendingSimultaneousMove = null;
        _pickerState.clearPendingAction();
        _customMoveController.clear();
        return;
      }

      final bool isCounterMode =
          _pickerState.pendingAttackMove != null ||
          _pickerState.isEditingCounter;

      // In counter mode: buffer this counter move for chain merge
      if (isCounterMode) {
        final counterMove = Move(
          glossaryId: item['id'],
          name: item['name'],
          category: cat,
          translations: translations,
          side: side,
          level: level,
          isFeint: isFeint,
          specialAction: special,
          repetitions: 1,
        );

        if (_pendingCounterSimMove != null) {
          // Already have a pending counter — chain them
          if (_pendingCounterSimMove!.category == 'chain') {
            _pendingCounterSimMove = _pendingCounterSimMove!.copyWith(
              chain: [..._pendingCounterSimMove!.chain, counterMove],
              name: '${_pendingCounterSimMove!.name} -> ${counterMove.name}',
            );
          } else {
            _pendingCounterSimMove = Move(
              name: '${_pendingCounterSimMove!.name} -> ${counterMove.name}',
              category: 'chain',
              chain: [_pendingCounterSimMove!, counterMove],
            );
          }
          _pendingCounterIsChain = true;
        } else {
          _pendingCounterSimMove = counterMove;
          _pendingCounterIsChain = true;
        }
        _pickerState.clearPendingAction();
        _customMoveController.clear();
        return;
      }

      Move n;
      n = Move(
        glossaryId: item['id'],
        name: item['name'],
        category: cat,
        translations: translations,
        side: side,
        level: level,
        isFeint: isFeint,
        specialAction: special,
        repetitions: 1,
      );

      // Direct chain: merge onto the last combo item
      if (_currentCombo.isNotEmpty) {
        final lastIndex = _currentCombo.length - 1;
        final lastMove = _currentCombo[lastIndex];

        if (lastMove.category == 'chain') {
          // Already a chain — append to it
          final updatedChain = List<Move>.from(lastMove.chain)..add(n);
          _currentCombo[lastIndex] = lastMove.copyWith(
            chain: updatedChain,
            name: updatedChain.map((m) => m.name).join(' -> '),
          );
        } else {
          // Wrap [lastMove, n] into a new chain
          final chainMoves = [lastMove, n];
          _currentCombo[lastIndex] = Move(
            name: chainMoves.map((m) => m.name).join(' -> '),
            category: 'chain',
            chain: chainMoves,
            // Preserve counter if it exists on the last move
            counterName: lastMove.counterName,
            counterCategory: lastMove.counterCategory,
            counterSide: lastMove.counterSide,
            counterLevel: lastMove.counterLevel,
            counterSpecialAction: lastMove.counterSpecialAction,
            counterGlossaryId: lastMove.counterGlossaryId,
            counterTranslations: lastMove.counterTranslations,
          );
        }
      } else {
        // No items yet, just add as a standalone move
        _addItemToCombo(n);
      }

      _pickerState.clearPendingAction();
      _pickerState.setPendingAttackMove(null);
      _customMoveController.clear();

      // Scroll to end of preview
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _comboScrollController.animateTo(
          _comboScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _onSimultaneousAction(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  ) {
    debugPrint('SeriesDetailScreen: _onSimultaneousAction called');
    setState(() {
      final n = Move(
        glossaryId: item['id'],
        name: item['name'],
        category: cat,
        translations: translations,
        side: side,
        level: level,
        isFeint: isFeint,
        specialAction: special,
        repetitions: 1,
      );

      final bool isCounterMode =
          _pickerState.pendingAttackMove != null ||
          _pickerState.isEditingCounter;
      if (isCounterMode) {
        // In counter mode: buffer this counter move for simultaneous merge
        if (_pendingCounterSimMove != null) {
          // Already have a pending counter — combine them
          _pendingCounterSimMove = Move(
            name: '${_pendingCounterSimMove!.name} + ${n.name}',
            category: 'simultaneous',
            subMoves: _pendingCounterSimMove!.category == 'simultaneous'
                ? [..._pendingCounterSimMove!.subMoves, n]
                : [_pendingCounterSimMove!, n],
          );
          _pendingCounterIsChain = false;
        } else {
          _pendingCounterSimMove = n;
          _pendingCounterIsChain = false;
        }
        _pickerState.clearPendingAction();
        _customMoveController.clear();
        return;
      }

      if (_currentCombo.isNotEmpty) {
        // Combo has items — merge with last item as before
        _addCombinedActionToCombo(n);
      } else if (_pendingSimultaneousMove != null) {
        // Already have a pending move — combine them and add to combo
        final combined = Move(
          name: '${_pendingSimultaneousMove!.name} + ${n.name}',
          category: 'simultaneous',
          subMoves: [_pendingSimultaneousMove!, n],
        );
        _addItemToCombo(combined);
        _pendingSimultaneousMove = null;
      } else {
        // Combo is empty, no pending — buffer this move
        _pendingSimultaneousMove = n;
      }

      _pickerState.clearPendingAction();
      _customMoveController.clear();
    });
  }

  void _onAnswerAction(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  ) {
    debugPrint('SeriesDetailScreen: _onAnswerAction called');
    setState(() {
      if (_pendingSimultaneousMove != null) {
        // Combine the pending move with the current move simultaneously,
        // add to combo, then enter counter-edit mode for the combined item.
        final currentMove = Move(
          glossaryId: item['id'],
          name: item['name'],
          category: cat,
          translations: translations,
          side: side,
          level: level,
          isFeint: isFeint,
          specialAction: special,
          repetitions: 1,
        );
        final combined = Move(
          name: '${_pendingSimultaneousMove!.name} + ${currentMove.name}',
          category: 'simultaneous',
          subMoves: [_pendingSimultaneousMove!, currentMove],
        );
        _addItemToCombo(combined);
        _pendingSimultaneousMove = null;

        // Enter counter-edit mode for the combined item we just added
        _pickerState.setEditingComboItemIndex(_currentCombo.length - 1);
        _pickerState.setIsEditingCounter(true);
        _pickerState.setPendingActionItem(null);
        _pickerState.setPendingLevel(null);
      } else {
        // Normal answer flow: store pending attack move and enter counter mode
        _pickerState.setPendingAttackMove({
          'item': item,
          'cat': cat,
          'sd': side,
          'lv': level,
          'f': isFeint,
          'sp': special,
          'tr': translations,
        });
        _pickerState.setPendingActionItem(null);
        _pickerState.setPendingLevel(null);
      }
    });
  }

  void _onFinishAction(
    Map<String, dynamic> item,
    String cat,
    String side,
    String level,
    bool isFeint,
    String? special,
    Map<String, String> translations,
  ) {
    debugPrint('SeriesDetailScreen: _onFinishAction called');
    _onWorkflowAction(
      item,
      cat,
      side,
      level,
      isFeint,
      special,
      translations,
      false,
    );
    _finishAndAddCombo();
    Navigator.pop(context);
  }

  void _pickMove({
    List<Move>? initialMoves,
    int? seriesIndex,
    bool autoEditFirst = false,
  }) async {
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
        if (autoEditFirst && initialMoves.isNotEmpty) {
          _pickerState.setEditingComboItemIndex(0);
          _pickerState.setIsEditingCounter(false);
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
    if (!autoEditFirst) {
      _pickerState.setEditingComboItemIndex(null);
    }
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

          // If auto-editing first item, handle tab navigation here
          if (autoEditFirst && _currentCombo.isNotEmpty) {
            String cat = _currentCombo.first.category;
            if (cat == 'simultaneous' &&
                _currentCombo.first.subMoves.isNotEmpty) {
              cat = _currentCombo.first.subMoves.first.category;
            }
            final t = MoveDisplayWidgets.getTabIndexForCategory(cat);
            if (t != -1) {
              _pickerState.setRequestedTabIndex(t);
            }
            // Auto-expand the glossary item
            final glossaryId = _currentCombo.first.glossaryId;
            if (glossaryId != null) {
              _pickerState.setPendingActionItem(glossaryId);
            }
            autoEditFirst = false; // Prevent re-triggering on rebuilds
          }

          final availableSubLetters = _getAvailableSubLetters(
            _pickerState.targetSeriesIndex,
            _pickerState.editingSeriesIndex,
          );

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.95,
            child: Column(
              children: [
                _buildComboPreview(
                  setS,
                  lang,
                  voiceEnabled,
                  availableSubLetters,
                ),
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
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.blue),
                      onPressed: () => _showEditHelpDialog(),
                      tooltip: 'Help',
                    ),
                  ],
                ),
                Expanded(
                  child: GlossaryTabWidget(
                    pickerState: _pickerState,
                    currentCombo: _currentCombo,
                    setState: setS,
                    customMoveController: _customMoveController,
                    onActivateGlossaryItem: () => setS(() {}),
                    onShowMediaGallery: _showMediaGallery,
                    onPickSpecial: (id) => _pickSpecialForMove(id, setS),
                    onWorkflowAction:
                        (
                          item,
                          cat,
                          side,
                          level,
                          isFeint,
                          special,
                          translations,
                          isCustom,
                        ) {
                          setS(() {
                            _onWorkflowAction(
                              item,
                              cat,
                              side,
                              level,
                              isFeint,
                              special,
                              translations,
                              isCustom,
                            );
                          });
                        },
                    onSimultaneousAction:
                        (
                          item,
                          cat,
                          side,
                          level,
                          isFeint,
                          special,
                          translations,
                        ) {
                          setS(() {
                            _onSimultaneousAction(
                              item,
                              cat,
                              side,
                              level,
                              isFeint,
                              special,
                              translations,
                            );
                          });
                        },
                    onChainAction:
                        (
                          item,
                          cat,
                          side,
                          level,
                          isFeint,
                          special,
                          translations,
                        ) {
                          setS(() {
                            _onChainAction(
                              item,
                              cat,
                              side,
                              level,
                              isFeint,
                              special,
                              translations,
                            );
                          });
                        },
                    onAnswerAction:
                        (
                          item,
                          cat,
                          side,
                          level,
                          isFeint,
                          special,
                          translations,
                        ) {
                          setS(() {
                            _onAnswerAction(
                              item,
                              cat,
                              side,
                              level,
                              isFeint,
                              special,
                              translations,
                            );
                          });
                        },
                    onFinishAction: _onFinishAction,
                    onFinishCombo: () {
                      _finishAndAddCombo();
                      Navigator.pop(context);
                    },
                    onCancelAction: () {
                      setS(() {
                        _pickerState.clearEditingState();
                        _pickerState.clearPendingAction();
                        _pickerState.setPendingAttackMove(null);
                        _pendingSimultaneousMove = null;
                        _pendingCounterSimMove = null;
                        _pendingCounterIsChain = false;
                      });
                    },
                    onAddCounterMove:
                        (
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
                          cLevelOverride,
                        ) {
                          setS(() {
                            _addCounterMove(
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
                              cLevelOverride: cLevelOverride,
                            );
                          });
                        },
                  ),
                ),
              ],
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
    _pendingSimultaneousMove = null;
    _pendingCounterSimMove = null;
    _pendingCounterIsChain = false;
    _customMoveController.clear();
  }

  Widget _buildComboPreview(
    StateSetter setS,
    String lang,
    bool voiceEnabled,
    List<String> availableSubLetters,
  ) {
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _pickerState.editingSeriesIndex != null
                                ? Colors.blueAccent.withValues(alpha: 0.5)
                                : Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _pickerState.editingSeriesIndex != null
                              ? '${LocalizationService.translate('update_item', lang).toUpperCase()} ${_getDisplayNumber(_pickerState.editingSeriesIndex!)}'
                              : '${LocalizationService.translate('current_combo', lang)} (${_currentCombo.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_pickerState.editingSeriesIndex != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          child: DropdownButton<int>(
                            value: _pickerState.targetSeriesIndex != null
                                ? _pickerState.targetSeriesIndex! + 1
                                : 1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade300,
                            ),
                            isDense: true,
                            underline: const SizedBox(),
                            dropdownColor: Colors.black87,
                            items: List.generate(
                              _moves.length,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(_getDisplayNumber(i)),
                              ),
                            ).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setS(
                                  () => _pickerState.setTargetSeriesIndex(
                                    val - 1,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Sub-letter selector (a, b, c, ...)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
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
                              value:
                                  (availableSubLetters.contains(
                                        _pickerState.selectedSubLetter,
                                      ) ||
                                      _pickerState.selectedSubLetter == null)
                                  ? (_pickerState.selectedSubLetter ?? '_')
                                  : '_',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade300,
                              ),
                              isDense: true,
                              underline: const SizedBox(),
                              dropdownColor: Colors.black87,
                              items: [
                                const DropdownMenuItem(
                                  value: '_',
                                  child: Text('_'),
                                ),
                                ...availableSubLetters.map(
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
                if (_pendingSimultaneousMove != null)
                  Positioned(
                    top: 4,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            MoveDisplayWidgets.getCategoryIcon(
                              _pendingSimultaneousMove!.category,
                            ),
                            size: 16,
                            color: MoveDisplayWidgets.getCategoryColor(
                              _pendingSimultaneousMove!.category,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_pendingSimultaneousMove!.name} +',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '…',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_pendingCounterSimMove != null)
                  Positioned(
                    top: 4,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'D:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            MoveDisplayWidgets.getCategoryIcon(
                              _pendingCounterSimMove!.displayCategory,
                            ),
                            size: 16,
                            color: MoveDisplayWidgets.getCategoryColor(
                              _pendingCounterSimMove!.displayCategory,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_pendingCounterSimMove!.name} ${_pendingCounterIsChain ? '->' : '+'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '…',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      onShowMediaGallery: _showMediaGallery,
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

  void _finishAndAddCombo() {
    if (_currentCombo.isEmpty) return;
    setState(() {
      Move finalMove;
      if (_currentCombo.length == 1) {
        finalMove = _currentCombo.first;
      } else {
        final bool containsChain = _currentCombo.any((m) => m.isChain);
        if (containsChain) {
          // Flatten chains to prevent nesting
          List<Move> flattenedChain = [];
          for (var m in _currentCombo) {
            if (m.isChain) {
              flattenedChain.addAll(m.chain);
            } else {
              flattenedChain.add(m);
            }
          }
          finalMove = Move(
            name: flattenedChain.map((m) => m.name).join(' -> '),
            category: 'chain',
            chain: flattenedChain,
          );
        } else {
          finalMove = Move(
            name: 'Combo: ${_currentCombo.first.name} + ...',
            category: 'combo',
            subMoves: List.from(_currentCombo),
          );
        }
      }

      // Apply sub-letter if selected
      finalMove = finalMove.copyWith(subLetter: _pickerState.selectedSubLetter);

      if (_pickerState.editingSeriesIndex != null) {
        final int oldIdx = _pickerState.editingSeriesIndex!;
        int target = _pickerState.targetSeriesIndex ?? oldIdx;

        _moves.removeAt(oldIdx);

        // Clamping to avoid index out of bounds after removal
        if (target > _moves.length) {
          target = _moves.length;
        }

        _moves.insert(target, finalMove);
      } else {
        _moves.add(finalMove);
      }

      _normalizeSubLetters();

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
        if (_moves[index].category == 'simultaneous') {
          _pickMove(
            initialMoves: _moves[index].subMoves,
            seriesIndex: index,
            autoEditFirst: true,
          );
        } else if (_moves[index].isCombo) {
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
                    setS(() => _pickerState.setSelectedSpecial(id, null));
                    Navigator.pop(ctx);
                  },
                );
              }
              final s = specs[idx - 1];
              return ListTile(
                title: Text(s['name']),
                onTap: () {
                  setS(() => _pickerState.setSelectedSpecial(id, s['name']));
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
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

  void _showEditHelpDialog() {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    EditHelpDialog.show(context, lang);
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
          : (_isEditing
                ? FloatingActionButton(
                    onPressed: _showEditHelpDialog,
                    child: const Icon(Icons.help_outline),
                  )
                : null),
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
                if (!_isEditing && widget.series != null)
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () => setState(() => _isFullscreen = true),
                    tooltip: LocalizationService.translate('fullscreen', lang),
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
                ],
                if (!_isEditing &&
                    !_isFullscreen &&
                    _currentTrainingOptions == null) ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(_selectedCategory)),
                      if (_selectedCategory != 'JKD Moves')
                        Chip(label: Text(_selectedType)),
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
                              final movedItem = _moves.removeAt(oldIndex);
                              _moves.insert(newIndex, movedItem);
                              _normalizeSubLetters();
                            });
                          },
                          children: _buildMoveListTiles(lang),
                        )
                      : InteractiveViewer(
                          transformationController: _transformationController,
                          panEnabled:
                              false, // Standard scroll handles vertical movement
                          scaleEnabled: Platform.isAndroid || Platform.isIOS,
                          minScale: 0.4,
                          maxScale: 3.0,
                          boundaryMargin: const EdgeInsets.all(
                            2000,
                          ), // Allow zooming out
                          child: ListView(
                            controller: _movesScrollController,
                            children: _buildMoveListTiles(lang),
                          ),
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
