import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/voice_parsing_service.dart';
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

    String text = '';
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          voiceService.startListening((t) {
            setS(() {
              text = t;
            });
          }, localeId: language == 'fr' ? 'fr_FR' : 'en_US');

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.mic, color: Colors.red),
                const SizedBox(width: 8),
                const Expanded(child: Text('Listening...')),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  onPressed: () {
                    voiceService.stopListening();
                    Navigator.pop(ctx);
                    VoiceHelpDialog.show(context, language);
                  },
                  tooltip: 'Help',
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(text.isEmpty ? 'Speak...' : text),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  voiceService.stopListening();
                  Navigator.pop(ctx, null);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  voiceService.stopListening();
                  Navigator.pop(ctx, text);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );

    return result;
  }
}
