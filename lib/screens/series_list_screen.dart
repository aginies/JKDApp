import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/voice_note_service.dart';
import '../services/database_service.dart';
import '../services/media_service.dart';
import 'series_detail_screen.dart';
import 'settings_screen.dart';
import 'programs_list_screen.dart';
import 'series_list/widgets/random_reader_widget.dart';
import '../models/series.dart';
import '../utils/translation_utils.dart';
import '../widgets/active_program_card.dart';
import '../utils/category_utils.dart';
import '../widgets/global_search_delegate.dart';
import '../widgets/empty_state_illustration.dart';
import 'package:flutter/services.dart';

class SeriesListScreen extends StatefulWidget {
  const SeriesListScreen({super.key});

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen>
    with TickerProviderStateMixin {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final MediaService _mediaService = MediaService();
  String _glossarySearchQuery = '';
  late AnimationController _rotationController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide FAB based on tab
    });
  }

  @override
  void dispose() {
    _voiceNoteService.dispose();
    _rotationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    return CategoryUtils.getCategoryIcon(category);
  }

  void _showMediaGallery(String category, String moveName) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;
    final galleryPath = provider.galleryPath;
    if (galleryPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate('gallery_path', lang)),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$moveName - ${LocalizationService.translate('instructional_photos', lang)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_a_photo,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () async {
                      final file = await _mediaService.captureAndSaveImage(
                        galleryPath,
                        category,
                        moveName,
                      );
                      if (file != null) setModalState(() {});
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder<List<File>>(
                  future: _mediaService.getImagesForMove(
                    galleryPath,
                    category,
                    moveName,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final images = snapshot.data ?? [];
                    if (images.isEmpty) {
                      return Center(
                        child: Text(
                          LocalizationService.translate('no_images', lang),
                        ),
                      );
                    }
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final imageFile = images[index];
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => _showFullScreenImage(imageFile),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    imageFile,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Image?'),
                                      content: const Text(
                                        'Are you sure you want to delete this instructional photo?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    final deleted = await _mediaService
                                        .deleteImage(imageFile);
                                    if (deleted) {
                                      setModalState(() {});
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocalizationService.translate('finish', lang)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFullScreenImage(File imageFile) => showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Image.file(imageFile),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );

  void _showGlossaryModal(BuildContext context, String lang) {
    _glossarySearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: DefaultTabController(
                length: 9,
                child: Column(
                  children: [
                    // Handle bar for the bottom sheet
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: TextEditingController.fromValue(
                                  TextEditingValue(
                                    text: _glossarySearchQuery,
                                    selection: TextSelection.collapsed(
                                      offset: _glossarySearchQuery.length,
                                    ),
                                  ),
                                ),
                                decoration: InputDecoration(
                                  hintText: LocalizationService.translate(
                                    'search_hint',
                                    lang,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: _glossarySearchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            setModalState(() {
                                              _glossarySearchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                onChanged: (val) => setModalState(
                                  () => _glossarySearchQuery = val,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_glossarySearchQuery.isEmpty)
                      Builder(
                        builder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return TabBar(
                            isScrollable: true,
                            indicatorSize: TabBarIndicatorSize.label,
                            indicatorColor: isDark
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).primaryColor,
                            labelColor: isDark
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            tabs: [
                              Tab(
                                text: LocalizationService.translate(
                                  'punches',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('punch')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'kicks',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('kick')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'packs',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('packs')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'trapping',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('trapping')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'move',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('move')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'jkd_moves',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('jkd_moves')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'kali',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('kali')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'general',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('general')),
                              ),
                              Tab(
                                text: LocalizationService.translate(
                                  'other',
                                  lang,
                                ),
                                icon: Icon(_getCategoryIcon('other')),
                              ),
                            ],
                          );
                        },
                      ),
                    Expanded(
                      child: _glossarySearchQuery.isEmpty
                          ? TabBarView(
                              children: [
                                _buildGlossaryList('punch', lang),
                                _buildGlossaryList('kick', lang),
                                _buildGlossaryList('packs', lang),
                                _buildGlossaryList('trapping', lang),
                                _buildGlossaryList('move', lang),
                                _buildGlossaryList('jkd_moves', lang),
                                _buildGlossaryList('kali', lang),
                                _buildGlossaryList('general', lang),
                                _buildGlossaryList('other', lang),
                              ],
                            )
                          : _buildGlobalGlossarySearchResults(lang),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalGlossarySearchResults(String lang) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final query = _glossarySearchQuery.toLowerCase();

    final results = provider.glossary.where((item) {
      final name = item['name'].toString().toLowerCase();
      final trans = TranslationUtils.parseTranslations(item['translations']);
      final t = (trans[lang] ?? trans['en'] ?? '').toLowerCase();
      return name.contains(query) || t.contains(query);
    }).toList();

    if (results.isEmpty) {
      return const EmptyStateIllustration(titleKey: 'nothing');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final category = item['category'] ?? 'other';
        return _buildGlossaryItemCard(item, lang, category);
      },
    );
  }

  Widget _buildGlossaryList(String category, String lang) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService().getGlossaryByCategory(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;

        if (items.isEmpty) {
          return const EmptyStateIllustration(titleKey: 'nothing');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildGlossaryItemCard(items[index], lang, category);
          },
        );
      },
    );
  }

  Widget _buildGlossaryItemCard(
    Map<String, dynamic> item,
    String lang,
    String category,
  ) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final themeColor = provider.themeColor;
    final galleryPath = provider.galleryPath;
    final trans = TranslationUtils.parseTranslations(item['translations']);
    final translation = trans[lang] ?? trans['en'] ?? trans['fr'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.01),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMediaGallery(category, item['name']),
        onDoubleTap: () => _showMediaGallery(category, item['name']),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                      themeColor.withValues(alpha: isDark ? 0.1 : 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: CategoryUtils.getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (translation.isNotEmpty)
                      Text(
                        translation,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (galleryPath != null)
                FutureBuilder<List<File>>(
                  future: _mediaService.getImagesForMove(
                    galleryPath,
                    category,
                    item['name'],
                  ),
                  builder: (context, snapshot) {
                    final hasImages =
                        snapshot.hasData && snapshot.data!.isNotEmpty;
                    return Icon(
                      Icons.image,
                      size: 18,
                      color: hasImages ? Colors.blue : Colors.grey[300],
                    );
                  },
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoiceNotesModal(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.95,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      LocalizationService.translate('voice_notes', lang),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildRecordingControls(context, setModalState, lang),
                  const Divider(),
                  Expanded(child: _buildVoiceNotesList(setModalState, lang)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecordingControls(
    BuildContext context,
    StateSetter setModalState,
    String lang,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          IconButton(
            iconSize: 64,
            icon: const Icon(Icons.radio_button_checked, color: Colors.red),
            onPressed: () async {
              final path = await _voiceNoteService.startRecording();
              if (path != null && context.mounted) {
                _showRecordingDialog(context, lang, path, setModalState);
              }
            },
          ),
          Text(LocalizationService.translate('record', lang)),
        ],
      ),
    );
  }

  void _showRecordingDialog(
    BuildContext context,
    String lang,
    String path,
    StateSetter setModalState,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('record', lang)),
        content: const Text('Recording in progress...'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _voiceNoteService.stopRecording();
              if (context.mounted) {
                Navigator.pop(context);
                _showSaveDialog(context, lang, path, setModalState);
              }
            },
            child: Text(LocalizationService.translate('stop', lang)),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(
    BuildContext context,
    String lang,
    String path,
    StateSetter setModalState,
  ) async {
    final existingRecords = await _voiceNoteService.getRecords();
    String baseName = LocalizationService.translate('new_recording', lang);
    String uniqueName = baseName;
    int counter = 1;

    while (existingRecords.any((r) => r['name'] == uniqueName)) {
      counter++;
      uniqueName = '$baseName #$counter';
    }

    final nameController = TextEditingController(text: uniqueName);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Recording'),
        content: TextField(controller: nameController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _voiceNoteService.saveRecord(nameController.text, path);
              if (context.mounted) {
                Navigator.pop(context);
                setModalState(() {}); // REFRESH LIST
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesList(StateSetter setModalState, String lang) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _voiceNoteService.getRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        if (records.isEmpty) {
          return Center(
            child: Text(LocalizationService.translate('nothing', lang)),
          );
        }

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final r = records[index];
            return ListTile(
              leading: IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.green),
                onPressed: () => _voiceNoteService.play(r['file_path']),
              ),
              title: Text(r['name']),
              subtitle: Text(r['created_at'].toString().split('T')[0]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showRenameDialog(
                      context,
                      lang,
                      r['id'],
                      r['name'],
                      setModalState,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () async {
                      await _voiceNoteService.deleteRecord(
                        r['id'],
                        r['file_path'],
                      );
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(
    BuildContext context,
    String lang,
    int id,
    String oldName,
    StateSetter setModalState,
  ) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('rename', lang)),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _voiceNoteService.renameRecord(id, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                setModalState(() {});
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SeriesProvider provider,
    JkdSeries series,
  ) {
    final lang = provider.language;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('delete_series', lang)),
        content: Text(
          '${LocalizationService.translate('confirm_delete', lang)} "${series.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSeries(series.id!);
              Navigator.pop(context);
            },
            child: Text(
              LocalizationService.translate('delete', lang),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClone(
    BuildContext context,
    SeriesProvider provider,
    JkdSeries series,
  ) {
    final lang = provider.language;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${LocalizationService.translate('clone', lang)} "${series.title}"?',
        ),
        content: Text(LocalizationService.translate('confirm_clone', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          ),
          TextButton(
            onPressed: () {
              provider.cloneSeries(series);
              Navigator.pop(context);
            },
            child: Text(LocalizationService.translate('clone', lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeriesProvider>();
    final lang = provider.language;
    final isLoading = provider.isLoading;

    if (isLoading) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Hero(
            tag: 'app_logo',
            child: RotationTransition(
              turns: _rotationController,
              child: Image.asset('assets/icon/JKD.png'),
            ),
          ),
        ),
        title: Text(LocalizationService.translate('library_title', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: GlobalSearchDelegate(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic_external_on, color: Colors.blueAccent),
            onPressed: () => _showVoiceNotesModal(context, lang),
            tooltip: LocalizationService.translate('voice_notes', lang),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book, color: Colors.orangeAccent),
            onPressed: () => _showGlossaryModal(context, lang),
            tooltip: 'Glossary',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Material(
            elevation: 2.0,
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: isDark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).primaryColor,
                  indicatorWeight: 4,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: isDark
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icon/jfgf.png',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text('Jun Fan Gung Fu'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icon/jfkb.png',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text('Jun Fan Kick Boxing'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icon/kali.png',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text('Kali'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icon/JKD.png',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 8),
                          const Text('JKD Moves'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_circle_fill, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.translate(
                              'active_training',
                              lang,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService.translate(
                              'training_programs',
                              lang,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeriesList('Jun Fan Gung Fu', lang),
          _buildSeriesList('Jun Fan Kick Boxing', lang),
          _buildSeriesList('Kali', lang),
          _buildSeriesList('JKD Moves', lang),
          _buildActiveTrainingTab(lang),
          const ProgramsListScreen(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 4 || _tabController.index == 5
          ? null // Hide FAB on Active Training and Training Programs tab
          : Padding(
              padding: const EdgeInsets.only(right: 120.0),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SeriesDetailScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
    );
  }

  Widget _buildActiveTrainingTab(String lang) {
    final provider = context.watch<SeriesProvider>();
    final hasActiveProgram = provider.hasActiveProgram;
    final activeProgram = provider.activeProgram;
    final activeProgramDetails = provider.activeProgramDetails;

    if (!hasActiveProgram ||
        activeProgram == null ||
        activeProgramDetails == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                LocalizationService.translate('no_active_training', lang),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    _tabController.animateTo(4), // Go to Training Programs tab
                child: Text(
                  LocalizationService.translate('start_program', lang),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          ActiveProgramCard(
            progress: activeProgram,
            program: activeProgramDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesList(String category, String lang) {
    // Only listen to filtered series for this specific category
    final filtered = context.select(
      (SeriesProvider p) => p.getFilteredSeries(category),
    );

    final provider = context.watch<SeriesProvider>();
    final hasActiveProgram = provider.hasActiveProgram;

    if (filtered.isEmpty && !hasActiveProgram) {
      return Center(
        child: Text(
          '${LocalizationService.translate('no_series', lang)} $category',
        ),
      );
    }

    return Column(
      children: [
        if (category == 'JKD Moves') RandomReaderWidget(language: lang),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final series = filtered[index];
              final isEven = index % 2 == 0;
              final theme = Theme.of(context);

              // Gradient colors based on system/user and theme
              final isDark = theme.brightness == Brightness.dark;
              final gradientColors = series.isSystem
                  ? (isDark
                        ? [
                            Colors.blue.withValues(alpha: 0.15),
                            Colors.purple.withValues(alpha: 0.1),
                          ]
                        : [
                            Colors.blue.withValues(alpha: 0.08),
                            Colors.purple.withValues(alpha: 0.05),
                          ])
                  : (isDark
                        ? [
                            Colors.teal.withValues(alpha: 0.15),
                            Colors.green.withValues(alpha: 0.1),
                          ]
                        : [
                            Colors.teal.withValues(alpha: 0.08),
                            Colors.green.withValues(alpha: 0.05),
                          ]);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                elevation: isEven ? 1 : 0.7,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  SeriesDetailScreen(series: series),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(
                                  1.0,
                                  0.0,
                                ); // Slides in from the right
                                const end = Offset.zero;
                                final tween = Tween(begin: begin, end: end);
                                final offsetAnimation = animation.drive(tween);
                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                        ),
                      );
                    },
                    child: ListTile(
                      leading: series.isSystem
                          ? Builder(
                              builder: (context) {
                                String asset = 'assets/icon/JKD.png';
                                final cat = series.category;
                                if (cat == 'Jun Fan Gung Fu') {
                                  asset = 'assets/icon/jfgf.png';
                                } else if (cat == 'Jun Fan Kick Boxing') {
                                  asset = 'assets/icon/jfkb.png';
                                } else if (cat == 'Kali') {
                                  asset = 'assets/icon/kali.png';
                                } else if (cat == 'JKD Moves') {
                                  asset = 'assets/icon/JKD.png';
                                }
                                return Image.asset(
                                  asset,
                                  width: 38,
                                  height: 38,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.orangeAccent,
                              size: 38,
                            ),
                      title: Text(series.title),
                      subtitle: Text(
                        '${series.moves.length} ${LocalizationService.translate('moves', lang)}',
                        style: const TextStyle(
                          color: Colors.pink,
                          fontSize: 12,
                        ),
                      ),
                      trailing: context.read<SeriesProvider>().developerMode
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.blueGrey,
                                  ),
                                  onPressed: () => _confirmClone(
                                    context,
                                    context.read<SeriesProvider>(),
                                    series,
                                  ),
                                  tooltip: LocalizationService.translate(
                                    'clone',
                                    lang,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(
                                    context,
                                    context.read<SeriesProvider>(),
                                    series,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
