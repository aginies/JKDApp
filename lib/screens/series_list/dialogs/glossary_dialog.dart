import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/series_provider.dart';
import '../../../services/localization_service.dart';
import '../../../services/database_service.dart';
import '../../../services/media_service.dart';
import '../../../utils/category_utils.dart';
import '../../../utils/translation_utils.dart';
import '../../../widgets/empty_state_illustration.dart';
import '../../series_detail/widgets/kali_angle_icon.dart';
import '../../series_detail/widgets/kali_angle_designer.dart';

class GlossaryDialog extends StatefulWidget {
  final String lang;
  final MediaService mediaService;
  final Function(String category, String moveName) onShowMediaGallery;

  const GlossaryDialog({
    super.key,
    required this.lang,
    required this.mediaService,
    required this.onShowMediaGallery,
  });

  static void show(
    BuildContext context,
    String lang,
    MediaService mediaService,
    Function(String category, String moveName) onShowMediaGallery,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlossaryDialog(
          lang: lang,
          mediaService: mediaService,
          onShowMediaGallery: onShowMediaGallery,
        );
      },
    );
  }

  @override
  State<GlossaryDialog> createState() => _GlossaryDialogState();
}

class _GlossaryDialogState extends State<GlossaryDialog> {
  String _glossarySearchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 10,
        child: Column(
          children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: LocalizationService.translate(
                            'search_hint',
                            widget.lang,
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
                                    setState(() {
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
                        onChanged: (val) =>
                            setState(() => _glossarySearchQuery = val),
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
                          Theme.of(context).brightness == Brightness.dark
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
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('punch')),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'kicks',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('kick')),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'packs',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('packs')),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'trapping',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('trapping')),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'move',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('move')),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'kali',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('kali')),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'angles',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('angles')),
                      ),
                      Tab(
                        text: widget.lang == 'fr'
                            ? 'Angles Persos'
                            : 'Custom Angles',
                        icon: const Icon(Icons.architecture),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'general',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('general')),
                      ),
                      Tab(
                        text: LocalizationService.translate(
                          'other',
                          widget.lang,
                        ),
                        icon: Icon(CategoryUtils.getCategoryIcon('other')),
                      ),
                    ],
                  );
                },
              ),
            Expanded(
              child: _glossarySearchQuery.isEmpty
                  ? TabBarView(
                      children: [
                        _buildGlossaryList('punch'),
                        _buildGlossaryList('kick'),
                        _buildGlossaryList('packs'),
                        _buildGlossaryList('trapping'),
                        _buildGlossaryList('move'),
                        _buildGlossaryList('kali'),
                        _buildGlossaryList('angles'),
                        _buildCustomAnglesTab(),
                        _buildGlossaryList('general'),
                        _buildGlossaryList('other'),
                      ],
                    )
                  : _buildGlobalGlossarySearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalGlossarySearchResults() {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final query = _glossarySearchQuery.toLowerCase();

    final results = provider.glossary.where((item) {
      final name = item['name'].toString().toLowerCase();
      final trans = TranslationUtils.parseTranslations(item['translations']);
      final t = (trans[widget.lang] ?? trans['en'] ?? '').toLowerCase();
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
        return _buildGlossaryItemCard(item, category);
      },
    );
  }

  Widget _buildGlossaryList(String category) {
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
            return _buildGlossaryItemCard(items[index], category);
          },
        );
      },
    );
  }

  Widget _buildCustomAnglesTab() {
    return Consumer<SeriesProvider>(
      builder: (context, provider, child) {
        final customAngles = provider.customAngles;

        return Stack(
          children: [
            customAngles.isEmpty
                ? const EmptyStateIllustration(titleKey: 'nothing')
                : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: customAngles.length,
                  itemBuilder: (context, index) {
                    final custom = customAngles[index];
                    final item = {
                      'id': custom.id,
                      'name': custom.name,
                      'translations': '{}',
                    };
                    return _buildGlossaryItemCard(
                      item,
                      'kali',
                      isCustom: true,
                      onDelete: () => _confirmDelete(context, provider, item),
                    );
                  },
                ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'glossary_add_custom_angle_fab',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => const KaliAngleDesigner(),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    SeriesProvider provider,
    Map<String, dynamic> item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Angle?'),
        content: Text('Delete "${item['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteCustomAngle(item['id']);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryItemCard(
    Map<String, dynamic> item,
    String category, {
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final themeColor = provider.themeColor;
    final galleryPath = provider.galleryPath;
    final trans = TranslationUtils.parseTranslations(item['translations']);
    final translation = trans[widget.lang] ?? trans['en'] ?? trans['fr'] ?? '';
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
        onTap: () => widget.onShowMediaGallery(category, item['name']),
        onDoubleTap: () => widget.onShowMediaGallery(category, item['name']),
        onLongPress: isCustom ? onDelete : null,
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
                child: (category == 'angles' || isCustom)
                    ? Builder(
                        builder: (context) {
                          int? angleId;
                          if (isCustom) {
                            angleId = item['id'] as int?;
                          } else {
                            final name = item['name'].toString();
                            final match =
                                RegExp(r'Angle\s+(\d+)').firstMatch(name);
                            angleId =
                                match != null
                                    ? int.tryParse(match.group(1) ?? '')
                                    : null;
                          }

                          if (angleId != null) {
                            return KaliAngleIcon(
                              angle: angleId,
                              size: 32,
                              color: CategoryUtils.getCategoryColor('kali'),
                              showCircle: false,
                            );
                          }
                          return Icon(
                            CategoryUtils.getCategoryIcon(category),
                            color: CategoryUtils.getCategoryColor(category),
                            size: 32,
                          );
                        },
                      )
                    : Icon(
                        CategoryUtils.getCategoryIcon(category),
                        color: CategoryUtils.getCategoryColor(category),
                        size: 32,
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
                  future: widget.mediaService.getImagesForMove(
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
}
