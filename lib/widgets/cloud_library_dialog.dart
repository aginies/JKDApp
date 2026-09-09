import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/series_provider.dart';
import '../services/web_storage_service.dart';
import '../models/series.dart';
import '../models/move.dart';
import '../models/custom_kali_angle.dart';

class CloudLibraryDialog extends StatefulWidget {
  final String? filterCategory;
  const CloudLibraryDialog({super.key, this.filterCategory});

  static void show(BuildContext context, {String? filterCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CloudLibraryDialog(filterCategory: filterCategory),
    );
  }

  @override
  State<CloudLibraryDialog> createState() => _CloudLibraryDialogState();
}

class _CloudLibraryDialogState extends State<CloudLibraryDialog> {
  late Future<List<Map<String, dynamic>>> _availableSeriesFuture;
  final WebStorageService _webService = WebStorageService();

  @override
  void initState() {
    super.initState();
    _availableSeriesFuture = _webService.fetchAvailableSeries().then((items) {
      if (widget.filterCategory != null) {
        return items
            .where((item) => item['category'] == widget.filterCategory)
            .toList();
      }
      return items;
    });
  }

  void _refreshList() {
    setState(() {
      _availableSeriesFuture = _webService.fetchAvailableSeries().then((items) {
        if (widget.filterCategory != null) {
          return items
              .where((item) => item['category'] == widget.filterCategory)
              .toList();
        }
        return items;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang == 'fr' ? 'Bibliothèque Cloud' : 'Cloud Library',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _refreshList,
                        tooltip: 'Refresh',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _availableSeriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          lang == 'fr'
                              ? 'Erreur: ${snapshot.error}'
                              : 'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        lang == 'fr'
                            ? 'Aucune série disponible'
                            : 'No series available',
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final dateStr =
                          item['date'] ?? DateTime.now().toIso8601String();
                      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                      final formattedDate =
                          "${date.day}/${date.month}/${date.year}";

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.cloud, color: Colors.white),
                        ),
                        title: Text(
                          item['title'] ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "@${item['user']} • $formattedDate",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                item['category'] ??
                                    (lang == 'fr' ? 'Autre' : 'Other'),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.download,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _downloadAndImportSeries(
                            context,
                            item['filename'],
                            item['category'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndImportSeries(
    BuildContext context,
    String filename,
    String? category,
  ) async {
    final provider = Provider.of<SeriesProvider>(context, listen: false);
    final lang = provider.language;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final jsonContent = await _webService.downloadJson(filename);
      final dynamic decodedData = jsonDecode(jsonContent);

      if (category == 'Custom Angles') {
        // Handle Custom Angles import
        final List<dynamic> jsonList = decodedData is List
            ? decodedData
            : [decodedData];
        final imported = jsonList
            .map((j) => CustomKaliAngle.fromJson(j))
            .toList();
        await provider.importCustomAngles(imported);
      } else {
        // Handle standard Series import
        final Map<String, dynamic> data = decodedData as Map<String, dynamic>;
        final List<dynamic> movesData = data['moves'] ?? [];
        final List<Move> moves = movesData
            .map((m) => Move.fromMap(m as Map<String, dynamic>))
            .toList();

        final newSeries = JkdSeries(
          title: data['title'],
          category: data['category'] ?? 'JKD',
          type: data['type'] ?? 'Attack',
          attackMethod: data['attack_method'],
          notes: data['notes'] ?? '',
          moves: moves,
          isSystem: false,
          isFromCloud: true,
        );

        await provider.addSeries(newSeries);
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              category == 'Custom Angles'
                  ? (lang == 'fr'
                        ? 'Angles importés avec succès !'
                        : 'Angles imported successfully!')
                  : (lang == 'fr'
                        ? 'Série importée avec succès !'
                        : 'Series imported successfully!'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'fr'
                  ? 'Échec du téléchargement: $e'
                  : 'Download failed: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
