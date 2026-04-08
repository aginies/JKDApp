import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/media_backup_service.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../models/series.dart';
import '../models/training_program.dart';
import '../models/program_day.dart';

class BackupModal extends StatefulWidget {
  const BackupModal({super.key});

  @override
  State<BackupModal> createState() => _BackupModalState();
}

class _BackupModalState extends State<BackupModal> {
  bool _isProcessing = false;

  void _setLoading(bool val) {
    if (mounted) setState(() => _isProcessing = val);
  }

  String _getTimestamp() =>
      DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context);
    final lang = provider.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocalizationService.translate('backup_restore_title', lang),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(
                LocalizationService.translate('export_title', lang),
              ),
              _buildBackupTile(
                title: lang == 'fr'
                    ? 'Tout exporter (Full Backup)'
                    : 'Export Everything (Full Backup)',
                subtitle: lang == 'fr'
                    ? 'Série, Glossaire, Media dans un ZIP'
                    : 'Series, Glossary, Media in a ZIP',
                icon: Icons.all_inclusive,
                color: Colors.purple,
                onTap: () => _handleGlobalBackup(provider),
              ),
              _buildBackupTile(
                title: LocalizationService.translate(
                  'restore_everything',
                  lang,
                ),
                subtitle: lang == 'fr'
                    ? 'Restaurer depuis un fichier ZIP global'
                    : 'Restore from a full ZIP backup',
                icon: Icons.restore_page,
                color: Colors.purpleAccent,
                onTap: () => _handleGlobalRestore(provider),
              ),
              const Divider(height: 32),
              _buildSectionTitle(
                LocalizationService.translate('export_title', lang),
              ),
              _buildBackupTile(
                title: LocalizationService.translate(
                  'export_description',
                  lang,
                ),
                subtitle: lang == 'fr'
                    ? 'Exporter vos séries personnalisées'
                    : 'Export your custom series',
                icon: Icons.backup,
                color: Colors.blue,
                onTap: () => _showSeriesExportDialog(provider),
              ),
              _buildBackupTile(
                title: lang == 'fr'
                    ? 'Exporter Séries Personnelles'
                    : 'Export Personal Series',
                subtitle: lang == 'fr'
                    ? 'Sauvegarder uniquement vos propres séries (non-système)'
                    : 'Backup only your own series (non-system)',
                icon: Icons.person_pin,
                color: Colors.indigo,
                onTap: () => _handlePersonalSeriesBackup(provider),
              ),
              _buildBackupTile(
                title: LocalizationService.translate('import_series', lang),
                subtitle: LocalizationService.translate('import_desc', lang),
                icon: Icons.file_upload,
                color: Colors.blueAccent,
                onTap: () => _handleSeriesImport(provider),
              ),
              const Divider(height: 32),
              _buildSectionTitle(
                LocalizationService.translate('backup_glossary', lang),
              ),
              _buildBackupTile(
                title: lang == 'fr'
                    ? 'Exporter le Glossaire'
                    : 'Export Glossary',
                subtitle: LocalizationService.translate(
                  'glossary_backup_desc',
                  lang,
                ),
                icon: Icons.menu_book,
                color: Colors.orange,
                onTap: () => _handleGlossaryBackup(),
              ),
              _buildBackupTile(
                title: LocalizationService.translate('restore_glossary', lang),
                subtitle: LocalizationService.translate(
                  'glossary_restore_desc',
                  lang,
                ),
                icon: Icons.auto_stories,
                color: Colors.orangeAccent,
                onTap: () => _handleGlossaryRestore(provider),
              ),
              const Divider(height: 32),
              _buildSectionTitle(
                lang == 'fr'
                    ? 'Programmes d\'Entraînement'
                    : 'Training Programs',
              ),
              _buildBackupTile(
                title: lang == 'fr'
                    ? 'Exporter les Programmes'
                    : 'Export Training Programs',
                subtitle: lang == 'fr'
                    ? 'Sauvegarder vos programmes personnalisés'
                    : 'Backup your custom programs',
                icon: Icons.model_training,
                color: Colors.teal,
                onTap: () => _handleTrainingBackup(),
              ),
              _buildBackupTile(
                title: lang == 'fr'
                    ? 'Importer des Programmes'
                    : 'Import Training Programs',
                subtitle: lang == 'fr'
                    ? 'Restaurer depuis un fichier JSON'
                    : 'Restore from a JSON file',
                icon: Icons.upload_file,
                color: Colors.tealAccent,
                onTap: () => _handleTrainingRestore(provider),
              ),
              const Divider(height: 32),
              _buildSectionTitle(
                lang == 'fr' ? 'Media & Images' : 'Media & Images',
              ),
              _buildBackupTile(
                title: LocalizationService.translate('backup_images', lang),
                subtitle: LocalizationService.translate('media_backup', lang),
                icon: Icons.archive,
                color: Colors.green,
                onTap: () => _handleMediaBackup(provider.galleryPath),
              ),
              _buildBackupTile(
                title: LocalizationService.translate('restore_images', lang),
                subtitle: lang == 'fr'
                    ? 'Restaurer les photos du ZIP'
                    : 'Restore photos from ZIP',
                icon: Icons.unarchive,
                color: Colors.greenAccent,
                onTap: () => _handleMediaRestore(provider),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBackupTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        onTap: onTap,
      ),
    );
  }

  // --- Handlers ---

  Future<void> _handleGlobalBackup(SeriesProvider provider) async {
    final action = await _showActionDialog('Full Backup');
    if (action == null) return;

    _setLoading(true);
    final path = await BackupService.createGlobalBackup(provider.galleryPath);
    _setLoading(false);

    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create global backup')),
        );
      }
      return;
    }

    if (action == 'share') {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'JKD Full App Backup'),
      );
    } else {
      String? saveDir = await FilePicker.platform.getDirectoryPath();
      if (saveDir != null) {
        final fileName = p.basename(path);
        final targetPath = p.join(saveDir, fileName);
        await File(path).copy(targetPath);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Backup saved: $fileName')));
        }
      }
    }
  }

  Future<void> _handleGlobalRestore(SeriesProvider provider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Full Restore'),
        content: const Text(
          'WARNING: This will overwrite EVERYTHING (Series, Glossary, Settings, Progress, Media).\n\nAre you sure?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RESTORE ALL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _setLoading(true);
      final success = await BackupService.restoreGlobalBackup(
        result.files.single.path!,
        provider.galleryPath,
      );

      if (success) {
        await provider.loadSeries();
        await provider.loadGlossary();
        await provider.loadActiveProgram();
      }

      _setLoading(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Full restore successful!' : 'Full restore failed',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showSeriesExportDialog(SeriesProvider provider) {
    final lang = provider.language;
    final allSeries = provider.series;

    showDialog(
      context: context,
      builder: (context) {
        String exportType = 'all';
        String selectedCategory = 'Jun Fan Gung Fu';
        JkdSeries? selectedSeries = allSeries.isNotEmpty
            ? allSeries.first
            : null;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(LocalizationService.translate('export_title', lang)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        lang == 'fr' ? 'Toutes les séries' : 'All Series',
                      ),
                      value: 'all',
                      // ignore: deprecated_member_use
                      groupValue: exportType,
                      // ignore: deprecated_member_use
                      onChanged: (val) =>
                          setModalState(() => exportType = val!),
                    ),
                    RadioListTile<String>(
                      title: Text(
                        LocalizationService.translate('export_category', lang),
                      ),
                      value: 'category',
                      // ignore: deprecated_member_use
                      groupValue: exportType,
                      // ignore: deprecated_member_use
                      onChanged: (val) =>
                          setModalState(() => exportType = val!),
                    ),
                    if (exportType == 'category')
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'Jun Fan Gung Fu',
                              child: Text('Jun Fan Gung Fu'),
                            ),
                            DropdownMenuItem(
                              value: 'Jun Fan Kick Boxing',
                              child: Text('Jun Fan Kick Boxing'),
                            ),
                            DropdownMenuItem(
                              value: 'Moves',
                              child: Text('Moves'),
                            ),

                            DropdownMenuItem(
                              value: 'Kali',
                              child: Text('Kali'),
                            ),
                          ],
                          onChanged: (val) =>
                              setModalState(() => selectedCategory = val!),
                        ),
                      ),
                    RadioListTile<String>(
                      title: Text(
                        LocalizationService.translate('export_single', lang),
                      ),
                      value: 'single',
                      // ignore: deprecated_member_use
                      groupValue: exportType,
                      // ignore: deprecated_member_use
                      onChanged: (val) =>
                          setModalState(() => exportType = val!),
                    ),
                    if (exportType == 'single')
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: DropdownButton<JkdSeries>(
                          value: selectedSeries,
                          isExpanded: true,
                          hint: Text(
                            LocalizationService.translate(
                              'select_series',
                              lang,
                            ),
                          ),
                          items: allSeries
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.title),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedSeries = val),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocalizationService.translate('cancel', lang)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    List<JkdSeries> toExport = [];
                    String baseName = 'jkd-series-export';

                    if (exportType == 'all') {
                      toExport = allSeries;
                      baseName = 'jkd-all-series';
                    } else if (exportType == 'category') {
                      toExport = allSeries
                          .where((s) => s.category == selectedCategory)
                          .toList();
                      baseName =
                          'jkd-${selectedCategory.toLowerCase().replaceAll(' ', '-')}';
                    } else if (exportType == 'single' &&
                        selectedSeries != null) {
                      toExport = [selectedSeries!];
                      baseName =
                          'jkd-series-${selectedSeries!.title.toLowerCase().replaceAll(' ', '-')}';
                    }

                    if (toExport.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }

                    Navigator.pop(context);
                    _handleSeriesExport(provider, toExport, baseName);
                  },
                  child: Text(lang == 'fr' ? 'Continuer' : 'Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSeriesExport(
    SeriesProvider provider,
    List<JkdSeries> toExport,
    String baseName,
  ) async {
    final action = await _showActionDialog('Export Series');
    if (action == null) return;

    _setLoading(true);
    final fileName = '$baseName-${_getTimestamp()}.json';
    if (action == 'share') {
      await ExportService.shareSeriesJson(toExport, fileName: fileName);
    } else {
      final path = await ExportService.exportToJson(
        toExport,
        fileName: fileName,
      );
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported: ${p.basename(path)}')),
        );
      }
    }
    _setLoading(false);
  }

  Future<void> _handlePersonalSeriesBackup(SeriesProvider provider) async {
    final personalSeries = provider.series.where((s) => !s.isSystem).toList();

    if (personalSeries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No personal series found to backup')),
        );
      }
      return;
    }

    await _handleSeriesExport(provider, personalSeries, 'jkd-personal-series');
  }

  Future<void> _handleSeriesImport(SeriesProvider provider) async {
    _setLoading(true);
    final success = await ImportService.importSeries(provider);
    _setLoading(false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Import successful' : 'Import failed'),
        ),
      );
    }
  }

  Future<void> _handleGlossaryBackup() async {
    final action = await _showActionDialog('Export Glossary');
    if (action == null) return;

    _setLoading(true);
    if (action == 'share') {
      await ExportService.shareGlossaryJson();
    } else {
      final path = await ExportService.exportGlossaryToJson();
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported: ${p.basename(path)}')),
        );
      }
    }
    _setLoading(false);
  }

  Future<void> _handleGlossaryRestore(SeriesProvider provider) async {
    _setLoading(true);
    final success = await ImportService.importGlossary(provider);
    _setLoading(false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Glossary restored' : 'Restore failed'),
        ),
      );
    }
  }

  Future<void> _handleTrainingBackup() async {
    final action = await _showActionDialog('Export Training Programs');
    if (action == null) return;

    _setLoading(true);
    try {
      final dbService = DatabaseService();
      final allPrograms = await dbService.getAllPrograms();
      // Only export custom programs (non-system)
      final customPrograms = allPrograms.where((p) => !p.isSystem).toList();

      if (customPrograms.isEmpty) {
        _setLoading(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No custom training programs to export'),
            ),
          );
        }
        return;
      }

      final List<Map<String, dynamic>> jsonData = customPrograms.map((p) {
        final map = p.toMap();
        map['days'] = p.days.map((d) => d.toMap()).toList();
        return map;
      }).toList();

      final String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonData);
      final fileName = 'jkd-training-programs-${_getTimestamp()}.json';

      if (action == 'share') {
        final tempDir = await getTemporaryDirectory();
        final file = File(p.join(tempDir.path, fileName));
        await file.writeAsString(jsonString);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'JKD Training Programs Backup',
          ),
        );
      } else {
        String? targetDir = await FilePicker.platform.getDirectoryPath();
        if (targetDir != null) {
          final file = File(p.join(targetDir, fileName));
          await file.writeAsString(jsonString);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Exported: ${p.basename(file.path)}')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Training backup error: $e');
    }
    _setLoading(false);
  }

  Future<void> _handleTrainingRestore(SeriesProvider provider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    _setLoading(true);
    try {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);

      for (var item in data) {
        final Map<String, dynamic> programMap = Map<String, dynamic>.from(item);
        final List<dynamic> daysData = programMap['days'] ?? [];

        final List<ProgramDay> days = daysData.map((d) {
          final day = ProgramDay.fromMap(Map<String, dynamic>.from(d));
          return day.copyWith(id: null); // Reset ID for DB to generate new one
        }).toList();
        final program = TrainingProgram.fromMap(programMap, days: days);

        final newProgram = program.copyWith(
          id: null, // New ID
          isSystem: false, // Imported are always custom
        );

        await provider.createProgram(newProgram);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Training programs imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Training restore error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import training programs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    _setLoading(false);
  }

  Future<void> _handleMediaBackup(String? sourcePath) async {
    if (sourcePath == null) return;
    final action = await _showActionDialog('Media Backup');
    if (action == null) return;

    _setLoading(true);
    final tempDir = await getTemporaryDirectory();
    final path = await MediaBackupService.backupGalleryToZip(
      sourcePath,
      tempDir.path,
    );
    _setLoading(false);

    if (path == null) return;

    if (action == 'share') {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'JKD Media Backup'),
      );
    } else {
      String? saveDir = await FilePicker.platform.getDirectoryPath();
      if (saveDir != null) {
        final fileName = p.basename(path);
        final targetPath = p.join(saveDir, fileName);
        await File(path).copy(targetPath);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Backup saved: $fileName')));
        }
      }
    }
  }

  Future<void> _handleMediaRestore(SeriesProvider provider) async {
    final targetPath = provider.galleryPath;
    if (targetPath == null) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) return;

    _setLoading(true);
    final success = await MediaBackupService.restoreGalleryFromZip(
      targetPath,
      result.files.single.path!,
    );
    if (success) {
      await provider.loadSeries(); // Refresh to show icons
    }
    _setLoading(false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Media restored' : 'Restore failed')),
      );
    }
  }

  Future<String?> _showActionDialog(String title) async {
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          lang == 'fr'
              ? 'Choisissez une méthode de sauvegarde'
              : 'Choose a backup method',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: Text(LocalizationService.translate('share', lang)),
            onPressed: () => Navigator.pop(context, 'share'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_alt),
            label: Text(LocalizationService.translate('save_to_device', lang)),
            onPressed: () => Navigator.pop(context, 'save'),
          ),
        ],
      ),
    );
  }
}

class RadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
