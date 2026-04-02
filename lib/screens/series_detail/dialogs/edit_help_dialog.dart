import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/localization_service.dart';

class EditHelpDialog {
  static void show(BuildContext context, String lang) {
    // Determine which markdown file to load based on language
    final mdLang = (lang == 'fr') ? 'fr' : 'en';
    final assetPath = 'assets/help/edit_help_$mdLang.md';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocalizationService.translate('help', lang)),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: FutureBuilder<String>(
              future: rootBundle.loadString(assetPath),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading help: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Markdown(data: snapshot.data!, shrinkWrap: true);
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(LocalizationService.translate('close', lang)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
