import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/move.dart';
import '../../../services/series_provider.dart';
import '../../../services/voice_parsing_service.dart';
import '../dialogs/voice_input_dialog.dart';
import '../../../models/picker_state.dart';

/// Service for handling voice input functionality in series detail screen
class VoiceProcessingService {
  final VoiceParsingService _voiceService = VoiceParsingService();

  /// Start voice input dialog and process results
  Future<void> startVoiceInput(BuildContext context) async {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    final result = await VoiceInputDialog.show(context, _voiceService, lang);
    if (result != null && result.trim().isNotEmpty) {
      // Return the result for processing by the caller
      return;
    }
  }

  /// Process voice input and return parsed moves
  List<Move> processVoiceInput(String input, String language) {
    if (input.trim().isEmpty) return [];

    List<Move> parsed = [];
    try {
      final decoded = json.decode(input);
      if (decoded is List) {
        parsed = decoded.map((m) => Move.fromMap(m)).toList();
      }
    } catch (_) {
      // If not JSON, it might be raw text from a legacy caller or error
      parsed = _voiceService.parseSentenceToCombo(input, language);
    }

    return parsed;
  }

  /// Process voice input with context-aware handling for picker state
  void processVoiceInputWithContext(
    String input,
    String language,
    PickerState pickerState,
    List<Move> currentCombo,
    List<Move> moves,
    GlobalKey<AnimatedListState> comboListKey,
    VoidCallback onStateChanged,
  ) {
    final parsed = processVoiceInput(input, language);
    if (parsed.isEmpty) return;

    if (pickerState.isPickerOpen) {
      // Add to current combo when picker is open
      for (var move in parsed) {
        currentCombo.add(move);
        comboListKey.currentState?.insertItem(
          currentCombo.length - 1,
          duration: const Duration(milliseconds: 400),
        );
      }
    } else {
      // Add to moves list when not in picker mode
      if (parsed.length == 1) {
        moves.add(parsed.first);
      } else {
        moves.add(
          Move(
            name: 'Combo: ${parsed.first.name} + ...',
            category: 'combo',
            subMoves: parsed,
          ),
        );
      }
    }

    onStateChanged();
  }

  /// Get voice service instance for direct usage
  VoiceParsingService get voiceService => _voiceService;
}
