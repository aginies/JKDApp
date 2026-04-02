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
        final theme = Theme.of(context);
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(LocalizationService.translate('help', lang)),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
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
                      return Markdown(
                        data: snapshot.data!,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme)
                            .copyWith(
                              p: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                              h1: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 18,
                              ),
                              h2: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 16,
                              ),
                              h3: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 14,
                              ),
                              tableBody: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                              ),
                              listBullet: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
