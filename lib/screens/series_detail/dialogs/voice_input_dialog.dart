import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/voice_parsing_service.dart';
import '../../../services/localization_service.dart';
import '../../../models/move.dart';
import '../widgets/move_display_widgets.dart';
import 'voice_help_dialog.dart';

class VoiceInputDialog {
  static Future<String?> show(
    BuildContext context,
    VoiceParsingService voiceService,
    String language,
  ) async {
    if (Platform.isLinux) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input not supported on Linux')),
        );
      }
      return null;
    }

    if (await Permission.microphone.request() != PermissionStatus.granted) {
      return null;
    }

    if (!await voiceService.init()) {
      return null;
    }

    if (!context.mounted) return null;

    List<Move> finalMoves = [];
    Move? buildingMove; // Move currently being built (Hit + Counter)
    List<List<MoveOption>> currentOptions = [];
    String recognizedText = '';
    String? recordingTarget; // 'hit' or 'counter'
    Map<int, int> selectedIndices = {}; // segmentIndex -> optionIndex

    final result = await showDialog<List<Move>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void startPartRecording(String target) {
            setS(() {
              recordingTarget = target;
              recognizedText = '';
              currentOptions = [];
              selectedIndices = {};
            });
            voiceService.startListening(
              (t) {
                setS(() {
                  recognizedText = t;
                  currentOptions = voiceService.parseSentenceToOptions(t);
                  for (int i = 0; i < currentOptions.length; i++) {
                    selectedIndices.putIfAbsent(i, () => 0);
                  }
                });
              },
              localeId: language == 'fr' ? 'fr_FR' : 'en_US',
              onStatus: (status) {
                if (status == 'done' || status == 'notListening') {
                  setS(() {
                    recordingTarget = null;
                  });
                }
              },
            );
          }

          void stopPartRecording() {
            voiceService.stopListening();
            setS(() {
              recordingTarget = null;
            });
          }

          void confirmSelection() {
            if (currentOptions.isEmpty) return;

            setS(() {
              // We take the first segment found
              final idx = selectedIndices[0] ?? 0;
              if (idx < currentOptions[0].length) {
                final selectedMove = currentOptions[0][idx].move;

                if (buildingMove == null) {
                  buildingMove = selectedMove;
                } else {
                  buildingMove = buildingMove!.copyWith(
                    counterName: selectedMove.name,
                    counterCategory: selectedMove.category,
                    counterSide: selectedMove.side,
                    counterLevel: selectedMove.level,
                    counterSpecialAction: selectedMove.specialAction,
                  );
                }
              }
              recognizedText = '';
              currentOptions = [];
              selectedIndices = {};
            });
          }

          void addToFinalList() {
            if (buildingMove == null) return;
            setS(() {
              finalMoves.add(buildingMove!);
              buildingMove = null;
            });
          }

          Widget renderMoveSummary(
            String name,
            String side,
            String level,
            bool isSelected,
            bool onDark,
          ) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: (isSelected || onDark) ? Colors.white : Colors.black87,
                  ),
                ),
                if (side.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  MoveDisplayWidgets.sideCircle(
                    LocalizationService.translate(
                      side == 'L' ? 'left' : 'right',
                      language,
                    ).substring(0, 1),
                    side,
                    mini: true,
                  ),
                ],
                if (level.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  MoveDisplayWidgets.levelIcon(level, mini: true),
                ],
              ],
            );
          }

          Widget renderFullMove(Move m, {bool onDark = false}) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                renderMoveSummary(m.name, m.side, m.level, false, onDark),
                if (m.counterName != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.subdirectory_arrow_right,
                    size: 14,
                    color: onDark ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 2),
                  renderMoveSummary(
                    m.counterName!,
                    m.counterSide ?? '',
                    m.counterLevel ?? '',
                    false,
                    onDark,
                  ),
                ],
              ],
            );
          }

          return AlertDialog(
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blueGrey.shade900,
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    LocalizationService.translate('voice_notes', language),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white70),
                    onPressed: () => VoiceHelpDialog.show(context, language),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      voiceService.stopListening();
                      Navigator.pop(ctx, null);
                    },
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PART 2: Hit / Counter Selection
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // HIT SIDE
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                LocalizationService.translate('hit', language),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap:
                                    () =>
                                        recordingTarget == 'hit'
                                            ? stopPartRecording()
                                            : startPartRecording('hit'),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      recordingTarget == 'hit'
                                          ? Colors.red
                                          : Colors.blue.withValues(alpha: 0.2),
                                  child: Icon(
                                    recordingTarget == 'hit'
                                        ? Icons.stop
                                        : Icons.mic,
                                    color:
                                        recordingTarget == 'hit'
                                            ? Colors.white
                                            : Colors.blue,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(),
                        // COUNTER SIDE
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                LocalizationService.translate(
                                  'answer',
                                  language,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap:
                                    buildingMove == null
                                        ? null
                                        : () =>
                                            recordingTarget == 'counter'
                                                ? stopPartRecording()
                                                : startPartRecording(
                                                  'counter',
                                                ),
                                child: Opacity(
                                  opacity: buildingMove == null ? 0.3 : 1.0,
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        recordingTarget == 'counter'
                                            ? Colors.red
                                            : Colors.orange.withValues(
                                              alpha: 0.2,
                                            ),
                                    child: Icon(
                                      recordingTarget == 'counter'
                                          ? Icons.stop
                                          : Icons.mic,
                                      color:
                                          recordingTarget == 'counter'
                                              ? Colors.white
                                              : Colors.orange,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // PART 3: Current matching / Selection
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recognizedText.isEmpty ? 'Speak...' : recognizedText,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child:
                              currentOptions.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'No match yet',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: currentOptions.length,
                                    itemBuilder: (c, segIdx) {
                                      final options = currentOptions[segIdx];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(
                                            options.length,
                                            (optIdx) {
                                              final m = options[optIdx].move;
                                              final isSelected =
                                                  selectedIndices[segIdx] ==
                                                  optIdx;
                                              return ActionChip(
                                                onPressed:
                                                    () => setS(() {
                                                      selectedIndices[segIdx] =
                                                          optIdx;
                                                    }),
                                                backgroundColor:
                                                    isSelected
                                                        ? Colors.blue
                                                        : Colors
                                                            .blue
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                label: renderMoveSummary(
                                                  m.name,
                                                  m.side,
                                                  m.level,
                                                  isSelected,
                                                  false,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                        if (currentOptions.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: confirmSelection,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Confirm'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // PART 4: Final Selection Preview
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Selection',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (buildingMove != null)
                              ElevatedButton.icon(
                                onPressed: addToFinalList,
                                icon: const Icon(Icons.add),
                                label: const Text('Add to List'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 30),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            children: [
                              if (buildingMove != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.green.shade700,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.build,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: renderFullMove(
                                          buildingMove!,
                                          onDark: true,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        onPressed:
                                            () => setS(() => buildingMove = null),
                                      ),
                                    ],
                                  ),
                                ),
                              ...finalMoves.map(
                                (m) => ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: renderFullMove(m),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed:
                                        () => setS(() => finalMoves.remove(m)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed:
                                finalMoves.isEmpty && buildingMove == null
                                    ? null
                                    : () {
                                      if (buildingMove != null) {
                                        finalMoves.add(buildingMove!);
                                      }
                                      Navigator.pop(ctx, finalMoves);
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              LocalizationService.translate('finish', language),
                            ),
                          ),
                        ),
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

    if (result != null) {
      return json.encode(result.map((m) => m.toMap()).toList());
    }
    return null;
  }
}
