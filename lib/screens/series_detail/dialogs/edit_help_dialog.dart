import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';
import '../widgets/builder_help_content.dart';

class EditHelpDialog {
  static void show(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) {
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
                Flexible(child: BuilderHelpContent(lang: lang)),
              ],
            ),
          ),
        );
      },
    );
  }
}
