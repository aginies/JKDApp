import 'dart:convert';
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
import 'series_detail/widgets/move_display_widgets.dart';
import '../models/series.dart';

class SeriesListScreen extends StatefulWidget {
  const SeriesListScreen({super.key});

  @override
  State<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends State<SeriesListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final MediaService _mediaService = MediaService();
  String _glossarySearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _voiceNoteService.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'punch':
        return Icons.sports_mma;
      case 'kick':
        return Icons.sports_martial_arts;
      case 'packs':
        return Icons.front_hand;
      case 'trapping':
        return Icons.back_hand;
      case 'move':
        return Icons.directions_run;
      case 'general':
        return Icons.info_outline;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
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
                        return GestureDetector(
                          onTap: () => _showFullScreenImage(images[index]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(images[index], fit: BoxFit.cover),
                          ),
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 7,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.95,
                child: Column(
                  children: [
                    AppBar(
                      title: TextField(
                        decoration: InputDecoration(
                          hintText: LocalizationService.translate(
                            'search_hint',
                            lang,
                          ),
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) =>
                            setModalState(() => _glossarySearchQuery = val),
                      ),
                      automaticallyImplyLeading: false,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(
                          text: LocalizationService.translate('punches', lang),
                          icon: Icon(_getCategoryIcon('punch')),
                        ),
                        Tab(
                          text: LocalizationService.translate('kicks', lang),
                          icon: Icon(_getCategoryIcon('kick')),
                        ),
                        Tab(
                          text: LocalizationService.translate('packs', lang),
                          icon: Icon(_getCategoryIcon('packs')),
                        ),
                        Tab(
                          text: LocalizationService.translate('trapping', lang),
                          icon: Icon(_getCategoryIcon('trapping')),
                        ),
                        Tab(
                          text: LocalizationService.translate('move', lang),
                          icon: Icon(_getCategoryIcon('move')),
                        ),
                        Tab(
                          text: LocalizationService.translate('general', lang),
                          icon: Icon(_getCategoryIcon('general')),
                        ),
                        Tab(
                          text: LocalizationService.translate('other', lang),
                          icon: Icon(_getCategoryIcon('other')),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildGlossaryList('punch', lang),
                          _buildGlossaryList('kick', lang),
                          _buildGlossaryList('packs', lang),
                          _buildGlossaryList('trapping', lang),
                          _buildGlossaryList('move', lang),
                          _buildGlossaryList('general', lang),
                          _buildGlossaryList('other', lang),
                        ],
                      ),
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

  Widget _buildGlossaryList(String category, String lang) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService().getGlossaryByCategory(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = snapshot.data!;

        if (_glossarySearchQuery.isNotEmpty) {
          final query = _glossarySearchQuery.toLowerCase();
          items = items.where((item) {
            final name = item['name'].toString().toLowerCase();
            Map<String, String> trans = {};
            try {
              trans = Map<String, String>.from(
                json.decode(item['translations']),
              );
            } catch (_) {}
            final t = (trans[lang] ?? trans['en'] ?? '').toLowerCase();
            return name.contains(query) || t.contains(query);
          }).toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Text(LocalizationService.translate('nothing', lang)),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            Map<String, String> trans = {};
            try {
              trans = Map<String, String>.from(
                json.decode(item['translations']),
              );
            } catch (_) {}
            final translation = trans[lang] ?? trans['en'] ?? trans['fr'] ?? '';

            return InkWell(
              onDoubleTap: () => _showMediaGallery(category, item['name']),
              child: ListTile(
                leading: Icon(_getCategoryIcon(category)),
                title: Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(translation),
              ),
            );
          },
        );
      },
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
    final provider = Provider.of<SeriesProvider>(context);
    final lang = provider.language;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Hero(
              tag: 'app_logo',
              child: Image.asset('assets/icon/JKD.png'),
            ),
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: LocalizationService.translate(
                      'search_hint',
                      lang,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => provider.setSearchQuery(val),
                )
              : Text(LocalizationService.translate('library_title', lang)),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  }
                });
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
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon/jfgf.png', width: 30, height: 30),
                    const SizedBox(width: 8),
                    const Text('Jun Fan Gung Fu'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon/jfkb.png', width: 30, height: 30),
                    const SizedBox(width: 8),
                    const Text('Jun Fan Kick Boxing'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon/kali.png', width: 30, height: 30),
                    const SizedBox(width: 8),
                    const Text('Kali'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSeriesList(provider, 'Jun Fan Gung Fu', lang),
            _buildSeriesList(provider, 'Jun Fan Kick Boxing', lang),
            _buildSeriesList(provider, 'Kali', lang),
          ],
        ),
        floatingActionButton: FloatingActionButton(
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

  Widget _buildSeriesList(
    SeriesProvider provider,
    String category,
    String lang,
  ) {
    final filtered = provider.getFilteredSeries(category);

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          '${LocalizationService.translate('no_series', lang)} $category',
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final series = filtered[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          clipBehavior: Clip.antiAlias, // Ensures the ripple is contained
          child: InkWell(
            // Wrap with InkWell for explicit ripple effect
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) =>
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
              leading: Builder(
                builder: (context) {
                  // Determine dominant category
                  String dominantCategory = 'other';
                  if (series.moves.isNotEmpty) {
                    final Map<String, int> counts = {};
                    for (var m in series.moves) {
                      counts[m.category] = (counts[m.category] ?? 0) + 1;
                    }
                    dominantCategory = counts.entries
                        .reduce((a, b) => a.value > b.value ? a : b)
                        .key;
                  }

                  return Stack(
                    children: [
                      if (series.isSystem)
                        Builder(
                          builder: (context) {
                            String asset = 'assets/icon/JKD.png';
                            if (category == 'Jun Fan Gung Fu') {
                              asset = 'assets/icon/jfgf.png';
                            } else if (category == 'Jun Fan Kick Boxing') {
                              asset = 'assets/icon/jfkb.png';
                            } else if (category == 'Kali') {
                              asset = 'assets/icon/kali.png';
                            }
                            return Image.asset(asset, width: 32, height: 32);
                          },
                        )
                      else
                        const Icon(
                          Icons.person,
                          color: Colors.orangeAccent,
                          size: 32,
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 0.5),
                          ),
                          child: Icon(
                            MoveDisplayWidgets.getCategoryIcon(
                              dominantCategory,
                            ),
                            color: MoveDisplayWidgets.getCategoryColor(
                              dominantCategory,
                            ),
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              title: Text(series.title),
              subtitle: Text(
                '${series.moves.length} ${LocalizationService.translate('moves', lang)}',
                style: const TextStyle(color: Colors.pink, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blueGrey),
                    onPressed: () => _confirmClone(context, provider, series),
                    tooltip: LocalizationService.translate('clone', lang),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, provider, series),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
