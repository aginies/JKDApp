import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/series_provider.dart';
import '../../../services/web_storage_service.dart';
import '../../../services/localization_service.dart';
import '../../../models/series.dart';

mixin SeriesDetailCloudMixin {
  JkdSeries? get series;
  BuildContext get context;
  bool get mounted;

  void showCloudUploadDialog() {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;
    final usernameController = TextEditingController(
      text: provider.contributorName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang == 'fr' ? 'Upload Cloud' : 'Cloud Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang == 'fr'
                  ? 'Entrez votre nom pour identifier l\'upload :'
                  : 'Enter your name to identify the upload:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: lang == 'fr' ? 'Nom d\'utilisateur' : 'Username',
                border: const OutlineInputBorder(),
              ),
              autofocus: provider.contributorName.isEmpty,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = usernameController.text.trim();
              if (username.isEmpty) return;

              // Persist the name to settings if new or changed
              if (username != provider.contributorName) {
                provider.setContributorName(username);
              }

              Navigator.pop(context);
              performCloudUpload(username);
            },
            child: Text(lang == 'fr' ? 'Envoyer' : 'Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> performCloudUpload(String username) async {
    if (series == null) return;

    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final webService = WebStorageService();
      await webService.uploadSeries(series!, username);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'fr'
                ? 'Série uploadée avec succès !'
                : 'Series uploaded successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == 'fr' ? 'Erreur: $e' : 'Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
