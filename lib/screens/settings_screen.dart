import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/database_service.dart';
import '../services/logging_service.dart';
import '../widgets/backup_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showBackupRestoreModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const BackupModal(),
    );
  }

  Future<void> _handleResetTrainingProgress(
    BuildContext context,
    String lang,
    SeriesProvider provider,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocalizationService.translate('reset_progress_title', lang),
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          LocalizationService.translate('reset_progress_warning', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocalizationService.translate('reset_progress_action', lang),
            ),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await provider.resetTrainingProgress();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All progress has been reset')),
      );
    }
  }

  Future<void> _handleResetActiveProgram(
    BuildContext context,
    String lang,
    SeriesProvider provider,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocalizationService.translate('reset_active_title', lang),
          style: const TextStyle(color: Colors.orange),
        ),
        content: Text(
          LocalizationService.translate('reset_active_warning', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocalizationService.translate('reset_program_action', lang),
            ),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await provider.resetActiveProgram();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Active program reset')));
    }
  }

  Future<void> _handleResetTrainingPrograms(
    BuildContext context,
    String lang,
    SeriesProvider provider,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocalizationService.translate('reset_programs_title', lang),
          style: const TextStyle(color: Colors.orange),
        ),
        content: Text(
          LocalizationService.translate('reset_programs_warning', lang),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocalizationService.translate('reset_program_action', lang),
            ),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await provider.resetTrainingPrograms();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Training programs reset')));
    }
  }

  Future<void> _handleResetTechnicalLibrary(
    BuildContext context,
    String lang,
    SeriesProvider provider,
  ) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocalizationService.translate('reset_knowledge_title', lang),
          style: const TextStyle(color: Colors.orange),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizationService.translate('reset_knowledge_warning', lang),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate('reset_knowledge_confirm', lang),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              LocalizationService.translate('reset_library_action', lang),
            ),
          ),
        ],
      ),
    );

    if (proceed == true) {
      try {
        await DatabaseService().resetTechnicalLibrary();

        // Reload data to reflect changes
        await provider.loadGlossary();
        await provider.loadSeries();
        await provider.loadAllPrograms();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate('reset_db_success', lang),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
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

        // Reload series and active program from the reset database
        await provider.loadSeries();
        await provider.loadActiveProgram();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate('reset_db_success', lang),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
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

  void _showLogsModal(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocalizationService.translate('logs_title', lang),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    LoggingService.allLogs.isEmpty
                        ? 'No logs available.'
                        : LoggingService.allLogs,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String? path = await LoggingService.saveLogsToDevice();
                    if (path == null || !context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${LocalizationService.translate('logs_saved', lang)}: $path',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: Text(LocalizationService.translate('save_logs', lang)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicyModal(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              lang == 'fr' ? 'Politique de Confidentialité' : 'Privacy Policy',
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: FutureBuilder(
            future: rootBundle.loadString('PRIVACY_POLICY.md'),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Markdown(data: snapshot.data!);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
      },
    );
  }

  void _showAboutModal(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService.translate('about', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'v2.1.0+1',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocalizationService.translate('license_info', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('GPLv3 License'),
              onPressed: () async {
                final url = Uri.parse(
                  'https://www.gnu.org/licenses/gpl-3.0.html',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocalizationService.translate('close', lang)),
          ),
        ],
      ),
    );
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
                leading: const Icon(Icons.person_outline),
                title: Text(
                  lang == 'fr' ? 'Nom du contributeur' : 'Contributor Name',
                ),
                subtitle: Text(
                  provider.contributorName.isEmpty
                      ? (lang == 'fr' ? 'Non défini' : 'Not set')
                      : provider.contributorName,
                  style: TextStyle(
                    color: provider.contributorName.isEmpty
                        ? Theme.of(context).hintColor
                        : null,
                  ),
                ),
                onTap: () {
                  final controller = TextEditingController(
                    text: provider.contributorName,
                  );
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        lang == 'fr'
                            ? 'Nom du contributeur'
                            : 'Contributor Name',
                      ),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: lang == 'fr' ? 'Votre nom' : 'Your name',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(lang == 'fr' ? 'Annuler' : 'Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            provider.setContributorName(controller.text.trim());
                            Navigator.pop(ctx);
                          },
                          child: Text(lang == 'fr' ? 'Enregistrer' : 'Save'),
                        ),
                      ],
                    ),
                  );
                },
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
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(LocalizationService.translate('theme_color', lang)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      [
                        Colors.red,
                        Colors.pink,
                        Colors.purple,
                        Colors.deepPurple,
                        Colors.indigo,
                        Colors.blue,
                        Colors.lightBlue,
                        Colors.cyan,
                        Colors.teal,
                        Colors.green,
                        Colors.lightGreen,
                        Colors.lime,
                        Colors.yellow,
                        Colors.amber,
                        Colors.orange,
                        Colors.deepOrange,
                        Colors.brown,
                        Colors.grey,
                        Colors.blueGrey,
                      ].map((color) {
                        final isSelected =
                            provider.themeColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () => provider.setThemeColor(color),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: Text(LocalizationService.translate('font_size', lang)),
                subtitle: Text(
                  LocalizationService.translate('font_size_desc', lang),
                ),
                trailing: Text(
                  '${(provider.fontSizeScale * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Slider(
                  value: provider.fontSizeScale,
                  min: 0.7,
                  max: 1.3,
                  divisions: 60,
                  onChanged: (val) => provider.setFontSizeScale(val),
                ),
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.translate),
                title: Text(
                  LocalizationService.translate('show_translation', lang),
                ),
                subtitle: Text(
                  LocalizationService.translate('show_translation_desc', lang),
                ),
                value: provider.showTranslation,
                onChanged: (val) => provider.setShowTranslation(val),
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
              // Garmin Watch Coaching Voice section
              ListTile(
                leading: Icon(
                  Icons.watch,
                  color: provider.garminConnected ? Colors.blue : Colors.grey,
                ),
                title: Text(lang == 'fr' ? 'Montre Garmin' : 'Garmin Watch'),
                subtitle: Row(
                  children: [
                    Icon(
                      provider.garminConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      size: 14,
                      color: provider.garminConnected
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.garminConnected
                          ? (lang == 'fr' ? 'Connectée' : 'Connected')
                          : (lang == 'fr' ? 'Non connectée' : 'Not connected'),
                      style: TextStyle(
                        color: provider.garminConnected
                            ? Colors.blue
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (provider.garminConnected &&
                        provider.garminCoachingVoiceActive) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.record_voice_over,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        lang == 'fr' ? 'Coaching actif' : 'Coaching active',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: Text(
                    lang == 'fr'
                        ? 'Coaching vocal Garmin non disponible sur ce système'
                        : 'Garmin coaching voice not available on this platform',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over),
                  title: Text(
                    lang == 'fr'
                        ? 'Accepter les messages de coaching'
                        : 'Accept Watch Coaching Messages',
                  ),
                  subtitle: Text(
                    lang == 'fr'
                        ? 'Parler les combos envoyés par la montre via TTS'
                        : 'Speak combos sent from the Garmin watch via TTS',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: provider.garminCoachingTtsEnabled,
                  onChanged: (val) => provider.setGarminCoachingTtsEnabled(val),
                ),
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
                leading: const Icon(
                  Icons.settings_backup_restore,
                  color: Colors.purple,
                ),
                title: Text(
                  lang == 'fr'
                      ? 'Sauvegarde & Restauration'
                      : 'Backup & Restore',
                ),
                subtitle: Text(
                  lang == 'fr'
                      ? 'Gérer vos sauvegardes (Full, Series, Glossaire, Media)'
                      : 'Manage your backups (Full, Series, Glossary, Media)',
                ),
                onTap: () => _showBackupRestoreModal(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history_edu),
                title: Text(LocalizationService.translate('view_logs', lang)),
                onTap: () => _showLogsModal(context, lang),
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
                  leading: const Icon(
                    Icons.history_toggle_off,
                    color: Colors.red,
                  ),
                  title: Text(
                    LocalizationService.translate('reset_progress_title', lang),
                  ),
                  subtitle: Text(
                    LocalizationService.translate('reset_progress_desc', lang),
                  ),
                  onTap: () =>
                      _handleResetTrainingProgress(context, lang, provider),
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt, color: Colors.orange),
                  title: Text(
                    LocalizationService.translate('reset_active_title', lang),
                  ),
                  subtitle: Text(
                    LocalizationService.translate('reset_active_desc', lang),
                  ),
                  onTap: () =>
                      _handleResetActiveProgram(context, lang, provider),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.model_training,
                    color: Colors.orange,
                  ),
                  title: Text(
                    LocalizationService.translate('reset_programs_title', lang),
                  ),
                  subtitle: Text(
                    LocalizationService.translate('reset_programs_desc', lang),
                  ),
                  onTap: () =>
                      _handleResetTrainingPrograms(context, lang, provider),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_stories, color: Colors.orange),
                  title: Text(
                    LocalizationService.translate(
                      'reset_knowledge_title',
                      lang,
                    ),
                  ),
                  subtitle: Text(
                    LocalizationService.translate('reset_knowledge_desc', lang),
                  ),
                  onTap: () =>
                      _handleResetTechnicalLibrary(context, lang, provider),
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
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip,
                  color: Colors.blueAccent,
                ),
                title: Text(
                  lang == 'fr'
                      ? 'Politique de Confidentialité'
                      : 'Privacy Policy',
                ),
                onTap: () => _showPrivacyPolicyModal(context, lang),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: Text(
                  '${LocalizationService.translate('report_bug', lang)}: ag@ginies.org',
                ),
                onTap: () async {
                  final url = Uri.parse(
                    'mailto:ag@ginies.org?subject=JKD App Bug Report',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _showAboutModal(context, lang),
                      child: const Text(
                        'Antoine Giniès - v2.1.0+1',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
