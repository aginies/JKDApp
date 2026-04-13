import 'package:flutter/material.dart';
import '../../../services/voice_note_service.dart';
import '../../../services/localization_service.dart';

class VoiceNotesDialog {
  static void show(
    BuildContext context,
    VoiceNoteService voiceNoteService,
    String lang,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.95,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      LocalizationService.translate('voice_notes', lang),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildRecordingControls(
                    context,
                    voiceNoteService,
                    setModalState,
                    lang,
                  ),
                  const Divider(),
                  Expanded(
                    child: _buildVoiceNotesList(
                      context,
                      voiceNoteService,
                      setModalState,
                      lang,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildRecordingControls(
    BuildContext context,
    VoiceNoteService voiceNoteService,
    StateSetter setModalState,
    String lang,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          IconButton(
            iconSize: 64,
            icon: const Icon(Icons.radio_button_checked, color: Colors.red),
            onPressed: () async {
              final path = await voiceNoteService.startRecording();
              if (path != null && context.mounted) {
                _showRecordingDialog(
                  context,
                  voiceNoteService,
                  lang,
                  path,
                  setModalState,
                );
              }
            },
          ),
          Text(LocalizationService.translate('record', lang)),
        ],
      ),
    );
  }

  static void _showRecordingDialog(
    BuildContext context,
    VoiceNoteService voiceNoteService,
    String lang,
    String path,
    StateSetter setModalState,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('record', lang)),
        content: const Text('Recording in progress...'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await voiceNoteService.stopRecording();
              if (context.mounted) {
                Navigator.pop(context);
                _showSaveDialog(
                  context,
                  voiceNoteService,
                  lang,
                  path,
                  setModalState,
                );
              }
            },
            child: Text(LocalizationService.translate('stop', lang)),
          ),
        ],
      ),
    );
  }

  static void _showSaveDialog(
    BuildContext context,
    VoiceNoteService voiceNoteService,
    String lang,
    String path,
    StateSetter setModalState,
  ) async {
    final existingRecords = await voiceNoteService.getRecords();
    String baseName = LocalizationService.translate('new_recording', lang);
    String uniqueName = baseName;
    int counter = 1;

    while (existingRecords.any((r) => r['name'] == uniqueName)) {
      counter++;
      uniqueName = '$baseName #$counter';
    }

    final nameController = TextEditingController(text: uniqueName);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Recording'),
        content: TextField(controller: nameController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              await voiceNoteService.saveRecord(nameController.text, path);
              if (context.mounted) {
                Navigator.pop(context);
                setModalState(() {}); // REFRESH LIST
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static Widget _buildVoiceNotesList(
    BuildContext context,
    VoiceNoteService voiceNoteService,
    StateSetter setModalState,
    String lang,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: voiceNoteService.getRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        if (records.isEmpty) {
          return Center(
            child: Text(LocalizationService.translate('nothing', lang)),
          );
        }

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final r = records[index];
            return ListTile(
              leading: IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.green),
                onPressed: () => voiceNoteService.play(r['file_path']),
              ),
              title: Text(r['name']),
              subtitle: Text(r['created_at'].toString().split('T')[0]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showRenameDialog(
                      context,
                      voiceNoteService,
                      lang,
                      r['id'],
                      r['name'],
                      setModalState,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () async {
                      await voiceNoteService.deleteRecord(
                        r['id'],
                        r['file_path'],
                      );
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void _showRenameDialog(
    BuildContext context,
    VoiceNoteService voiceNoteService,
    String lang,
    int id,
    String oldName,
    StateSetter setModalState,
  ) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('rename', lang)),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              await voiceNoteService.renameRecord(id, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                setModalState(() {});
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
