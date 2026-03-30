import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/voice_parsing_service.dart';
import '../../../services/localization_service.dart';
import '../../../services/database_service.dart';
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
    bool showGlossary = false;

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
                  currentOptions =
                      voiceService.parseSentenceToOptions(t, language);
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
                    fontSize: 13,
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
                    size: 16,
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

          Widget buildGlossaryListView(String cat) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseService().getGlossaryByCategory(cat),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final item = items[idx];
                    Map<String, String> tr = {};
                    try {
                      tr = Map<String, String>.from(
                        json.decode(item['translations'] ?? '{}'),
                      );
                    } catch (_) {}
                    final translation = tr[language] ?? tr['en'] ?? tr['fr'] ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(MoveDisplayWidgets.getCategoryIcon(cat)),
                        title: Text(
                          cat == 'special' ? (tr['en'] ?? item['name']) : item['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: translation.isNotEmpty ? Text(translation) : null,
                      ),
                    );
                  },
                );
              },
            );
          }

          return DefaultTabController(
            length: 7,
            child: AlertDialog(
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.zero,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
              title: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blueGrey.shade900,
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      showGlossary
                          ? LocalizationService.translate('glossary', language)
                          : LocalizationService.translate('voice_notes', language),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        showGlossary ? Icons.arrow_back : Icons.menu_book,
                        color: Colors.white70,
                      ),
                      onPressed: () => setS(() => showGlossary = !showGlossary),
                      tooltip: showGlossary ? 'Back' : 'Glossary',
                    ),
                    if (!showGlossary)
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
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.8,
                child:
                    showGlossary
                        ? Column(
                          children: [
                            TabBar(
                              isScrollable: true,
                              tabs: [
                                Tab(
                                  text: LocalizationService.translate(
                                    'punches',
                                    language,
                                  ),
                                  icon: Icon(
                                    MoveDisplayWidgets.getCategoryIcon('punch'),
                                  ),
                                ),
                                Tab(
                                  text: LocalizationService.translate(
                                    'kicks',
                                    language,
                                  ),
                                  icon: Icon(
                                    MoveDisplayWidgets.getCategoryIcon('kick'),
                                  ),
                                ),
                                Tab(
                                  text: LocalizationService.translate(
                                    'packs',
                                    language,
                                  ),
                                  icon: Icon(
                                    MoveDisplayWidgets.getCategoryIcon('packs'),
                                  ),
                                ),
                                Tab(
                                  text: LocalizationService.translate(
                                    'trapping',
                                    language,
                                  ),
                                  icon: Icon(
                                    MoveDisplayWidgets.getCategoryIcon(
                                      'trapping',
                                    ),
                                  ),
                                ),
                                Tab(
                                  text: LocalizationService.translate(
                                    'special',
                                    language,
                                  ),
                                  icon: Icon(
                                    MoveDisplayWidgets.getCategoryIcon(
                                      'special',
                                    ),
                                  ),
                                ),
                                Tab(
                                  text: LocalizationService.translate(
                                    'other',
                                    language,
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
                                children: [
                                  buildGlossaryListView('punch'),
                                  buildGlossaryListView('kick'),
                                  buildGlossaryListView('packs'),
                                  buildGlossaryListView('trapping'),
                                  buildGlossaryListView('special'),
                                  buildGlossaryListView('other'),
                                  const Center(child: Text('Custom Text Entries')),
                                ],
                              ),
                            ),
                          ],
                        )
                        : Column(
                          children: [
                            // PART 2: Hit / Counter Selection
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    // HIT SIDE
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            LocalizationService.translate(
                                              'hit',
                                              language,
                                            ).toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap:
                                                () =>
                                                    recordingTarget == 'hit'
                                                        ? stopPartRecording()
                                                        : startPartRecording(
                                                          'hit',
                                                        ),
                                            child: CircleAvatar(
                                              radius: 30,
                                              backgroundColor:
                                                  recordingTarget == 'hit'
                                                      ? Colors.red
                                                      : Colors.blue.withValues(
                                                        alpha: 0.2,
                                                      ),
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
                                    const VerticalDivider(
                                      thickness: 1,
                                      width: 32,
                                    ),
                                    // COUNTER SIDE
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            LocalizationService.translate(
                                              'answer',
                                              language,
                                            ).toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap:
                                                buildingMove == null
                                                    ? null
                                                    : () =>
                                                        recordingTarget ==
                                                                'counter'
                                                            ? stopPartRecording()
                                                            : startPartRecording(
                                                              'counter',
                                                            ),
                                            child: Opacity(
                                              opacity:
                                                  buildingMove == null
                                                      ? 0.3
                                                      : 1.0,
                                              child: CircleAvatar(
                                                radius: 30,
                                                backgroundColor:
                                                    recordingTarget == 'counter'
                                                        ? Colors.red
                                                        : Colors
                                                            .orange
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                child: Icon(
                                                  recordingTarget == 'counter'
                                                      ? Icons.stop
                                                      : Icons.mic,
                                                  color:
                                                      recordingTarget ==
                                                              'counter'
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
                            ),
                            const Divider(height: 1),

                            // PART 3: Current matching / Selection
                            Expanded(
                              flex: 1,
                              child: Container(
                                width: double.infinity,
                                color: Colors.black.withValues(alpha: 0.05),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recognizedText.isEmpty
                                          ? 'Speak...'
                                          : recognizedText,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 14,
                                        color: Colors.blueGrey,
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
                                                  'Waiting for match...',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              )
                                              : ListView.builder(
                                                itemCount: currentOptions.length,
                                                itemBuilder: (c, segIdx) {
                                                  final options =
                                                      currentOptions[segIdx];
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8.0,
                                                        ),
                                                    child: Wrap(
                                                      spacing: 10,
                                                      runSpacing: 10,
                                                      children: List.generate(
                                                        options.length,
                                                        (optIdx) {
                                                          final m =
                                                              options[optIdx]
                                                                  .move;
                                                          final isSelected =
                                                              selectedIndices[
                                                                    segIdx] ==
                                                                optIdx;
                                                          return ActionChip(
                                                            onPressed:
                                                                () => setS(() {
                                                                  selectedIndices[
                                                                        segIdx] =
                                                                      optIdx;
                                                                }),
                                                            backgroundColor:
                                                                isSelected
                                                                    ? Colors
                                                                        .indigo
                                                                    : Colors
                                                                        .indigo
                                                                        .withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            label:
                                                                renderMoveSummary(
                                                                  m.name,
                                                                  m.side,
                                                                  m.level,
                                                                  isSelected,
                                                                  isSelected,
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
                                        child: ElevatedButton.icon(
                                          onPressed: confirmSelection,
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: const Text('Confirm Match'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade700,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1),

                            // PART 4: Final Selection Preview
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'SELECTION',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (buildingMove != null)
                                          ElevatedButton.icon(
                                            onPressed: addToFinalList,
                                            icon: const Icon(Icons.add),
                                            label: const Text('Add to List'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.green.shade700,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Colors.green.shade700,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.build,
                                                    size: 18,
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
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed:
                                                        () => setS(
                                                          () =>
                                                              buildingMove =
                                                                  null,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ...finalMoves.map(
                                            (m) => Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                title: renderFullMove(m),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .remove_circle_outline,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => setS(
                                                        () =>
                                                            finalMoves.remove(
                                                              m,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: ElevatedButton(
                                        onPressed:
                                            finalMoves.isEmpty &&
                                                    buildingMove == null
                                                ? null
                                                : () {
                                                  if (buildingMove != null) {
                                                    finalMoves.add(
                                                      buildingMove!,
                                                    );
                                                  }
                                                  Navigator.pop(
                                                    ctx,
                                                    finalMoves,
                                                  );
                                                },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.indigo.shade800,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(120, 40),
                                        ),
                                        child: Text(
                                          LocalizationService.translate(
                                            'finish',
                                            language,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
