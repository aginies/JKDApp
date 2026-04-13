import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/voice_note_service.dart';
import '../services/media_service.dart';
import 'series_detail_screen.dart';
import 'settings_screen.dart';
import 'programs_list_screen.dart';
import 'series_list/widgets/random_reader_widget.dart';
import 'series_list/dialogs/cloud_library_dialog.dart';
import 'series_list/dialogs/voice_notes_dialog.dart';
import 'series_list/dialogs/glossary_dialog.dart';
import '../models/series.dart';
import '../widgets/active_program_card.dart';
import '../widgets/global_search_delegate.dart';
import 'series_detail/widgets/move_display_widgets.dart';

class SeriesListScreen extends StatefulWidget {
  const SeriesListScreen({super.key});

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen>
    with TickerProviderStateMixin {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final MediaService _mediaService = MediaService();
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
            onPressed: () =>
                VoiceNotesDialog.show(context, _voiceNoteService, lang),
            tooltip: LocalizationService.translate('voice_notes', lang),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book, color: Colors.orangeAccent),
            onPressed: () => GlossaryDialog.show(
              context,
              lang,
              _mediaService,
              _showMediaGallery,
            ),
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
                          Icon(
                            MoveDisplayWidgets.getCategoryIcon('move'),
                            size: 28,
                            color: MoveDisplayWidgets.getCategoryColor('move'),
                          ),
                          const SizedBox(width: 8),
                          Text(LocalizationService.translate('move', lang)),
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
          _buildSeriesList('Moves', lang),
          _buildActiveTrainingTab(lang),
          const ProgramsListScreen(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 4 || _tabController.index == 5
          ? null // Hide FAB on Active Training and Training Programs tab
          : Stack(
              children: [
                Positioned(
                  bottom: 20,
                  right: 100,
                  child: FloatingActionButton(
                    heroTag: 'add_series_fab',
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
                Positioned(
                  bottom: 84,
                  right: 100,
                  child: FloatingActionButton(
                    heroTag: 'cloud_download_fab',
                    backgroundColor: Colors.blueAccent,
                    onPressed: () => CloudLibraryDialog.show(context),
                    child: const Icon(
                      Icons.cloud_download,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
                    _tabController.animateTo(5), // Go to Training Programs tab
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
        if (category == 'Moves') RandomReaderWidget(language: lang),
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
                                } else if (cat == 'Moves') {
                                  asset = 'assets/icon/JKD.png';
                                }
                                return Image.asset(
                                  asset,
                                  width: 38,
                                  height: 38,
                                );
                              },
                            )
                          : Icon(
                              series.isFromCloud ? Icons.cloud : Icons.person,
                              color: series.isFromCloud
                                  ? Colors.blueAccent
                                  : Colors.orangeAccent,
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
                      trailing: context.read<SeriesProvider>().manageSeriesMode
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
