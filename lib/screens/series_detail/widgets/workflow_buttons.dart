import 'package:flutter/material.dart';
import '../../../services/localization_service.dart';

class WorkflowButtons extends StatelessWidget {
  final String language;
  final bool isEditingMode;
  final VoidCallback onNext;
  final VoidCallback onAnswer;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  const WorkflowButtons({
    super.key,
    required this.language,
    required this.isEditingMode,
    required this.onNext,
    required this.onAnswer,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: onNext,
              child: Text(
                isEditingMode
                    ? LocalizationService.translate('update_item', language)
                    : LocalizationService.translate('next', language),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: onAnswer,
              child: Text(
                LocalizationService.translate('answer', language),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: onFinish,
              child: Text(
                LocalizationService.translate('finish', language),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
              ),
              onPressed: onCancel,
              child: Text(
                LocalizationService.translate('cancel', language),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
