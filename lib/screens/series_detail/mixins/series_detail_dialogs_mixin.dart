import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/series.dart';
import '../../../models/move.dart';
import '../../../services/localization_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/export_service.dart';
import '../../../utils/string_utils.dart';

mixin SeriesDetailDialogsMixin {
  /// These properties should be provided by the class using this mixin
  JkdSeries? get series;
  List<Move> get moves;
  BuildContext get context;
  bool get mounted;
  void setState(VoidCallback fn);

  void showPrintOptions(String lang) {
    if (series == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocalizationService.translate('export_to_pdf', lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.grid_view, color: Colors.blue),
              title: const Text('Graphical Card View'),
              subtitle: const Text('Visual cards, mirrors the app interface'),
              onTap: () {
                Navigator.pop(context);
                PdfService.exportSeriesToPdf(series!, lang, isGraphical: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.teal),
              title: const Text('Compact List View'),
              subtitle: const Text('Text-focused, space-efficient list'),
              onTap: () {
                Navigator.pop(context);
                PdfService.exportSeriesToPdf(series!, lang, isGraphical: false);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void confirmDeleteItem(BuildContext context, int index, String lang) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('delete_item', lang)),
        content: Text(
          LocalizationService.translate('confirm_delete_item', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              setState(() => moves.removeAt(index));
              Navigator.pop(context);
            },
            child: Text(
              LocalizationService.translate('finish', lang),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> handleExportJson() async {
    if (series == null) return;
    String? dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    final fileName = 'jkd-series-${StringUtils.slugify(series!.title)}.json';
    if (!context.mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('File: $fileName'), Text('Dir: $dir')],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('FINISH'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      final path = await ExportService.exportToJson(
        [series!],
        fileName: fileName,
        customDirectory: dir,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? 'Exported to $path' : 'Export failed'),
          ),
        );
      }
    }
  }
}
