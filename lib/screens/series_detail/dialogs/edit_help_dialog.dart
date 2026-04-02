import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';

class EditHelpDialog {
  static void show(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocalizationService.translate('help', lang)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildHelpSection(
                  context,
                  Row(
                    children: [
                      _buildStyledChip('Next', Colors.indigo),
                    ],
                  ),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      children: const <TextSpan>[
                        TextSpan(text: 'Use "Next" to create a series with numbered steps. For example, to create:\n1) Jab\n2) Cross\n3) Nan Tek.\n\n'),
                        TextSpan(text: 'Step-by-step:\n', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '1. Choose "Jab (L)".\n2. Click '),
                        TextSpan(text: '"Next"', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '.\n3. Choose "Cross (R)".\n4. Click '),
                        TextSpan(text: '"Next"', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '.\n5. Choose "Nan Tek (L)".'),
                      ],
                    ),
                  ),
                ),
                _buildHelpSection(
                  context,
                  Row(
                    children: [
                      _buildStyledChip('+', Colors.lightBlue),
                      const SizedBox(width: 8),
                      _buildStyledChip('Answer', Colors.indigo),
                    ],
                  ),
                   RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      children: const <TextSpan>[
                        TextSpan(text: 'To add simultaneous actions within a single step. For example, for a combined Pack Sao (R) and Jab (L), with a defender\'s response of "Vertical Locking".\n\n'),
                        TextSpan(text: 'Step-by-step:\n', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '1. Choose "Pack Sao (R)".\n2. Click '),
                        TextSpan(text: '"+".\n', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '3. Choose "Jab (L)".\n4. Click '),
                        TextSpan(text: '"+"', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' (which will now be disabled).\n5. Click '),
                        TextSpan(text: '"Answer".\n', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '6. Choose "Vertical Locking (L)".\n7. Click "Finish combo" (top right).'),
                      ],
                    ),
                  ),
                ),
                _buildHelpSection(
                  context,
                   Row(
                    children: [
                      _buildStyledChip('->', Colors.teal),
                    ],
                  ),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      children: const <TextSpan>[
                        TextSpan(text: 'Use '),
                        TextSpan(text: '"->".\n', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: 'for trapping sequences. For example: "Pack Sao (R)" -> "Jab (L)" Answer "Vertical Locking" -> "Pack Sao" -> "Jab (L)".\n\n'),
                        TextSpan(text: 'Click "Finish" to complete the sequence.'),
                      ],
                    ),
                  ),
                ),
              ],
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

  static Widget _buildStyledChip(String label, Color color) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
      onPressed: () {},
    );
  }

  static Widget _buildHelpSection(
      BuildContext context, Widget title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 8.0),
          content,
        ],
      ),
    );
  }
}
