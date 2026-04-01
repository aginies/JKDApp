import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';

class VoiceHelpDialog extends StatelessWidget {
  final String language;

  const VoiceHelpDialog({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Text(LocalizationService.translate('voice_help_title', language)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language == 'fr'
                  ? 'Comment utiliser la saisie vocale:'
                  : 'How to use voice input:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildHelpSection(
              language == 'fr' ? 'Côtés' : 'Sides',
              language == 'fr' ? 'gauche, droite / droit' : 'left, right',
              Icons.swap_horiz,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Niveaux' : 'Levels',
              language == 'fr'
                  ? 'haut, milieu / centre, bas'
                  : 'high, mid / middle, low',
              Icons.height,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Combinaison' : 'Combination',
              language == 'fr' ? 'plus, +' : 'plus, +',
              Icons.add,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Enchaînement' : 'Next Move',
              language == 'fr'
                  ? 'suivant, ensuite, puis, et, next, then, and'
                  : 'next, then, and',
              Icons.arrow_forward,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Riposte' : 'Counter',
              language == 'fr'
                  ? 'réponse, contre, answer, counter'
                  : 'answer, counter',
              Icons.reply,
            ),
            const Divider(height: 24),
            Text(
              language == 'fr' ? 'Exemples:' : 'Examples:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildExample(
              language == 'fr' ? '"gauche jab haut"' : '"left jab high"',
              language == 'fr' ? 'Jab gauche niveau haut' : 'Left high jab',
            ),
            _buildExample(
              language == 'fr' ? '"jab plus cross"' : '"jab plus cross"',
              language == 'fr'
                  ? 'Jab et cross en simultané'
                  : 'Jab and cross simultaneously',
            ),
            _buildExample(
              language == 'fr'
                  ? '"droite cross puis gauche hook"'
                  : '"right cross then left hook"',
              language == 'fr'
                  ? 'Cross droit suivi d\'un crochet gauche'
                  : 'Right cross followed by left hook',
            ),
            _buildExample(
              language == 'fr'
                  ? '"jab réponse pak sao"'
                  : '"jab answer pak sao"',
              language == 'fr'
                  ? 'Jab avec riposte pak sao'
                  : 'Jab with pak sao counter',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildHelpSection(String title, String keywords, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  keywords,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String voice, String meaning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  voice,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Text(
              '→ $meaning',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, String language) {
    showDialog(
      context: context,
      builder: (ctx) => VoiceHelpDialog(language: language),
    );
  }
}
