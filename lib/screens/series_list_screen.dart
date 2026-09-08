import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../services/voice_note_service.dart';
import '../services/media_service.dart';
import 'series_detail/services/media_gallery_service.dart';
import 'series_detail_screen.dart';
import 'settings_screen.dart';
import 'programs_list_screen.dart';
import 'warmup_screen.dart';
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
  final MediaGalleryService _mediaGalleryService = MediaGalleryService();
  late AnimationController _rotationController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to show/hide FAB based on tab
      }
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
    _mediaGalleryService.showMediaGallery(context, category, moveName);
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
                          const Icon(Icons.fitness_center, size: 28),
                          const SizedBox(width: 8),
                          Text(LocalizationService.translate('warmup', lang)),
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
          const WarmupScreen(),
          _buildActiveTrainingTab(lang),
          const ProgramsListScreen(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 4 ||
              _tabController.index == 5 ||
              _tabController.index == 6
          ? null // Hide FAB on Warmup, Active Training and Training Programs tab
          : SizedBox(
              // Finite size — a Stack with only Positioned children expands
              // to the whole Scaffold, which the Scaffold then treats as a
              // full-screen FAB rect and pushes floating SnackBars off-screen.
              // 156 = 100 right-inset + 56 FAB; 140 = 84 top-FAB offset + 56 FAB.
              width: 156,
              height: 140,
              child: Stack(
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
