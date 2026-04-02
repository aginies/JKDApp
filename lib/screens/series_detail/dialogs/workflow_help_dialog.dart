import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';

class WorkflowHelpDialog extends StatelessWidget {
  final String language;

  const WorkflowHelpDialog({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Text(LocalizationService.translate('workflow_help_title', language)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language == 'fr'
                  ? 'Comment utiliser l\'interface:'
                  : 'How to use the interface:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildHelpSection(
              language == 'fr' ? 'Créer un Combo' : 'Create Combo',
              language == 'fr'
                  ? 'Sélectionnez les mouvements dans l\'ordre désiré'
                  : 'Select moves in the desired order',
              Icons.add_circle,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Mode Simultané' : 'Simultaneous Mode',
              language == 'fr'
                  ? 'Activez pour ajouter des mouvements simultanés'
                  : 'Enable to add simultaneous moves',
              Icons.add_circle_outline,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Contre-attaques' : 'Counter-attacks',
              language == 'fr'
                  ? 'Cliquez sur une attaque pour ajouter une contre-attaque'
                  : 'Click on an attack to add a counter-attack',
              Icons.shield,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Édition' : 'Editing',
              language == 'fr'
                  ? 'Double-cliquez pour modifier, glissez pour réorganiser'
                  : 'Double-tap to edit, drag to reorder',
              Icons.edit,
            ),
            _buildHelpSection(
              language == 'fr' ? 'Galerie Média' : 'Media Gallery',
              language == 'fr'
                  ? 'Double-cliquez sur un mouvement pour voir les photos'
                  : 'Double-tap on a move to view photos',
              Icons.photo_library,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocalizationService.translate('finish', language)),
        ),
      ],
    );
  }

  Widget _buildHelpSection(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, String language) {
    showDialog(
      context: context,
      builder: (context) => WorkflowHelpDialog(language: language),
    );
  }
}
