import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/media_backup_service.dart';
import '../services/database_service.dart';
import '../models/series.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showExportDialog(
    BuildContext context,
    String lang,
    List<JkdSeries> allSeries,
  ) {
    String exportType = 'category';
    String selectedCategory = 'Jun Fan Gung Fu';
    JkdSeries? selectedSeries = allSeries.isNotEmpty ? allSeries.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(LocalizationService.translate('export_title', lang)),
              content: SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: exportType,
                  onChanged: (val) => setModalState(() => exportType = val!),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text(
                          LocalizationService.translate(
                            'export_category',
                            lang,
                          ),
                        ),
                        value: 'category',
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocalizationService.translate('cancel', lang)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    List<JkdSeries> toExport = [];
                    String fileName = 'jkd_export.json';

                    if (exportType == 'category') {
                      toExport = allSeries
                          .where((s) => s.category == selectedCategory)
                          .toList();
                      fileName =
                          'jkd-${selectedCategory.replaceAll(' ', '-').toLowerCase()}-series.json';
                    } else if (exportType == 'single' &&
                        selectedSeries != null) {
                      toExport = [selectedSeries!];
                      fileName =
                          'jkd-series-${selectedSeries!.title.replaceAll(' ', '-').toLowerCase()}.json';
                    }

                    if (toExport.isEmpty) {
                      if (context.mounted) Navigator.pop(context);
                      return;
                    }

                    await ExportService.shareSeriesJson(
                      toExport,
                      fileName: fileName,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(LocalizationService.translate('share', lang)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? selectedDirectory = await FilePicker.platform
                        .getDirectoryPath();
                    if (selectedDirectory == null) return;

                    List<JkdSeries> toExport = [];
                    String fileName = 'jkd_export.json';

                    if (exportType == 'category') {
                      toExport = allSeries
                          .where((s) => s.category == selectedCategory)
                          .toList();
                      fileName =
                          'jkd-${selectedCategory.replaceAll(' ', '-').toLowerCase()}-series.json';
                    } else if (exportType == 'single' &&
                        selectedSeries != null) {
                      toExport = [selectedSeries!];
                      fileName =
                          'jkd-series-${selectedSeries!.title.replaceAll(' ', '-').toLowerCase()}.json';
                    }

                    if (toExport.isEmpty) {
                      if (context.mounted) Navigator.pop(context);
                      return;
                    }

                    final path = await ExportService.exportToJson(
                      toExport,
                      fileName: fileName,
                      customDirectory: selectedDirectory,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (path != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${LocalizationService.translate('export_success', lang)} $path',
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              LocalizationService.translate('error', lang),
                            ),
                            content: Text(
                              'Failed to export series. Please ensure:\n'
                              '• You have write permission to the selected directory\n'
                              '• There is enough disk space\n'
                              '• The directory path is valid',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  LocalizationService.translate('finish', lang),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    LocalizationService.translate('save_to_device', lang),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleImport(BuildContext context, String lang) async {
    final success = await ImportService.importSeries();
    if (context.mounted) {
      if (success) {
        await Provider.of<SeriesProvider>(context, listen: false).loadSeries();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.translate('import_success', lang),
              ),
            ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(LocalizationService.translate('error', lang)),
            content: Text(
              'Failed to import series. Please ensure:\n'
              '• The file is a valid JSON format\n'
              '• The file contains series data\n'
              '• You have permission to read the file',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocalizationService.translate('finish', lang)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleGlossaryBackup(BuildContext context, String lang) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('backup_glossary', lang)),
        content: Text(
          LocalizationService.translate('glossary_backup_desc', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, 'share'),
            child: Text(LocalizationService.translate('share', lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(LocalizationService.translate('save_to_device', lang)),
          ),
        ],
      ),
    );

    if (action == 'share') {
      await ExportService.shareGlossaryJson();
    } else if (action == 'save') {
      String? targetDir = await FilePicker.platform.getDirectoryPath();
      if (targetDir == null) return;
      final path = await ExportService.exportGlossaryToJson(
        customDirectory: targetDir,
      );
      if (context.mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${LocalizationService.translate('export_success', lang)} $path',
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(LocalizationService.translate('error', lang)),
              content: const Text(
                'Failed to export glossary. Please ensure:\n'
                '• You have write permission to the selected directory\n'
                '• There is enough disk space\n'
                '• The directory path is valid',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleGlossaryRestore(BuildContext context, String lang) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;
    final String fileName = result.files.single.name;

    if (!context.mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('restore_glossary', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restore Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Source File: $fileName',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Warning: This will overwrite your current glossary entries!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocalizationService.translate('finish', lang)),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final success = await ImportService.importGlossary();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.translate('import_success', lang),
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(LocalizationService.translate('error', lang)),
              content: const Text(
                'Failed to import glossary. Please ensure:\n'
                '• The file is a valid JSON format\n'
                '• The file contains glossary data\n'
                '• You have permission to read the file\n\n'
                'Warning: Importing glossary replaces all existing glossary items.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleMediaBackup(
    BuildContext context,
    String lang,
    String? sourcePath,
  ) async {
    if (sourcePath == null) return;

    final String timestamp = DateFormat(
      'yyyy-MM-dd_HH-mm',
    ).format(DateTime.now());
    final String zipFileName = 'jkd_media_backup_$timestamp.zip';

    if (!context.mounted) return;

    final proceed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('backup_images', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Source: $sourcePath', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Target File: $zipFileName',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, 'share'),
            child: Text(LocalizationService.translate('share', lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(LocalizationService.translate('save_to_device', lang)),
          ),
        ],
      ),
    );

    if (proceed == 'share') {
      final tempDir = await getTemporaryDirectory();
      final path = await MediaBackupService.backupGalleryToZip(
        sourcePath,
        tempDir.path,
        zipFileName: zipFileName,
      );

      if (path != null) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(path)], text: 'JKD Media Backup');
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(LocalizationService.translate('error', lang)),
              content: const Text(
                'Failed to create media backup. Please ensure:\n'
                '• The media directory exists and is accessible\n'
                '• There is enough disk space for the backup\n'
                '• You have permission to read the media files',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            ),
          );
        }
      }
    } else if (proceed == 'save') {
      String? saveDir = await FilePicker.platform.getDirectoryPath();
      if (saveDir == null) return;

      final path = await MediaBackupService.backupGalleryToZip(
        sourcePath,
        saveDir,
        zipFileName: zipFileName,
      );

      if (context.mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${LocalizationService.translate('backup_success', lang)} $path',
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(LocalizationService.translate('error', lang)),
              content: const Text(
                'Failed to save media backup. Please ensure:\n'
                '• The media directory exists and is accessible\n'
                '• You have write permission to the target directory\n'
                '• There is enough disk space for the backup',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleMediaRestore(
    BuildContext context,
    String lang,
    String? targetPath,
  ) async {
    if (targetPath == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) return;
    final String zipPath = result.files.single.path!;

    if (!context.mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('restore_images', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restore Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Archive: ${result.files.single.name}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Destination: $targetPath',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocalizationService.translate('finish', lang)),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final success = await MediaBackupService.restoreGalleryFromZip(
        targetPath,
        zipPath,
      );
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.translate('restore_success', lang),
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(LocalizationService.translate('error', lang)),
              content: const Text(
                'Failed to restore media from backup. Please ensure:\n'
                '• The ZIP file is a valid media backup\n'
                '• The ZIP file is not corrupted\n'
                '• You have write permission to the media directory\n'
                '• There is enough disk space',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResetDatabase(
    BuildContext context,
    String lang,
    SeriesProvider provider,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocalizationService.translate('reset_db_title', lang),
          style: const TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizationService.translate('reset_db_warning', lang),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate('reset_db_confirm', lang),
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocalizationService.translate('reset_database', lang)),
          ),
        ],
      ),
    );

    if (proceed == true) {
      try {
        await DatabaseService().resetDatabase();

        // Reload series from the reset database
        await provider.loadSeries();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService.translate('reset_db_success', lang),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(LocalizationService.translate('error', lang)),
              content: Text(
                'Failed to reset database. This is a critical error.\n\n'
                'Error details: $e\n\n'
                'Please try restarting the app. If the problem persists, '
                'you may need to reinstall the app.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SeriesProvider>(
      builder: (context, provider, child) {
        final lang = provider.language;
        return Scaffold(
          appBar: AppBar(title: Text(lang == 'fr' ? 'Paramètres' : 'Settings')),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(LocalizationService.translate('language', lang)),
                trailing: DropdownButton<String>(
                  value: provider.language,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                  ],
                  onChanged: (val) {
                    if (val != null) provider.setLanguage(val);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_medium),
                title: Text(LocalizationService.translate('theme', lang)),
                trailing: DropdownButton<JkdThemeMode>(
                  value: provider.themeMode,
                  items: [
                    DropdownMenuItem(
                      value: JkdThemeMode.system,
                      child: Text(
                        LocalizationService.translate('system_theme', lang),
                      ),
                    ),
                    DropdownMenuItem(
                      value: JkdThemeMode.light,
                      child: Text(
                        LocalizationService.translate('light_theme', lang),
                      ),
                    ),
                    DropdownMenuItem(
                      value: JkdThemeMode.dark,
                      child: Text(
                        LocalizationService.translate('dark_theme', lang),
                      ),
                    ),
                    DropdownMenuItem(
                      value: JkdThemeMode.amoled,
                      child: Text(
                        LocalizationService.translate('amoled_theme', lang),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) provider.setThemeMode(val);
                  },
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.mic),
                title: Text(
                  LocalizationService.translate('voice_recognition', lang),
                ),
                subtitle: Platform.isLinux
                    ? Text(
                        lang == 'fr'
                            ? 'Non disponible sur Linux'
                            : 'Not available on Linux',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      )
                    : null,
                value: Platform.isLinux ? false : provider.voiceEnabled,
                onChanged: Platform.isLinux
                    ? null
                    : (val) => provider.setVoiceEnabled(val),
              ),
              if (provider.voiceEnabled) ...[
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: Text(
                    LocalizationService.translate('speech_rate', lang),
                  ),
                  trailing: Text(
                    provider.speechRate.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Slider(
                    value: provider.speechRate,
                    min: 0.1,
                    max: 0.8,
                    divisions: 14,
                    onChanged: (val) => provider.setSpeechRate(val),
                  ),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(
                  LocalizationService.translate('gallery_path', lang),
                ),
                subtitle: Text(provider.galleryPath ?? 'Not set'),
                trailing: TextButton(
                  onPressed: () async {
                    String? selectedDirectory = await FilePicker.platform
                        .getDirectoryPath();
                    if (selectedDirectory != null) {
                      provider.setGalleryPath(selectedDirectory);
                    }
                  },
                  child: Text(
                    LocalizationService.translate('select_folder', lang),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.backup),
                title: Text(
                  LocalizationService.translate('backup_export', lang),
                ),
                subtitle: Text(
                  LocalizationService.translate('export_desc', lang),
                ),
                onTap: () => _showExportDialog(context, lang, provider.series),
              ),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: Text(
                  LocalizationService.translate('import_series', lang),
                ),
                subtitle: Text(
                  LocalizationService.translate('import_desc', lang),
                ),
                onTap: () => _handleImport(context, lang),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.blueAccent),
                title: Text(
                  LocalizationService.translate('backup_glossary', lang),
                ),
                subtitle: Text(
                  LocalizationService.translate('glossary_backup_desc', lang),
                ),
                onTap: () => _handleGlossaryBackup(context, lang),
              ),
              ListTile(
                leading: const Icon(
                  Icons.auto_stories,
                  color: Colors.orangeAccent,
                ),
                title: Text(
                  LocalizationService.translate('restore_glossary', lang),
                ),
                subtitle: Text(
                  LocalizationService.translate('glossary_restore_desc', lang),
                ),
                onTap: () => _handleGlossaryRestore(context, lang),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.orangeAccent),
                title: Text(
                  LocalizationService.translate('backup_images', lang),
                ),
                subtitle: Text(
                  LocalizationService.translate('media_backup', lang),
                ),
                onTap: () =>
                    _handleMediaBackup(context, lang, provider.galleryPath),
              ),
              ListTile(
                leading: const Icon(Icons.unarchive, color: Colors.greenAccent),
                title: Text(
                  LocalizationService.translate('restore_images', lang),
                ),
                onTap: () =>
                    _handleMediaRestore(context, lang, provider.galleryPath),
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.edit_note),
                title: Text(
                  LocalizationService.translate('manage_series', lang),
                ),
                subtitle: Text(
                  LocalizationService.translate('manage_series_desc', lang),
                ),
                value: provider.developerMode,
                onChanged: (val) => provider.setDeveloperMode(val),
              ),
              if (provider.developerMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Developer Sync',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Project Path'),
                  subtitle: Text(provider.projectPath ?? 'Not set'),
                  trailing: TextButton(
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform
                          .getDirectoryPath();
                      if (selectedDirectory != null) {
                        provider.setProjectPath(selectedDirectory);
                      }
                    },
                    child: Text(
                      LocalizationService.translate('select_folder', lang),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.red),
                  title: Text(
                    LocalizationService.translate('reset_database', lang),
                  ),
                  subtitle: Text(
                    LocalizationService.translate('reset_database_desc', lang),
                  ),
                  onTap: () => _handleResetDatabase(context, lang, provider),
                ),
              ],
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'JKD v1.0',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Author: Antoine Giniès',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
