import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/search_result.dart';
import '../models/series.dart';
import '../models/training_program.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';
import '../screens/series_detail_screen.dart';
import '../screens/program_detail_screen.dart';
import '../utils/translation_utils.dart';

class GlobalSearchDelegate extends SearchDelegate<SearchResult?> {
  final BuildContext context;

  GlobalSearchDelegate(this.context);

  @override
  String get searchFieldLabel => LocalizationService.translate(
    'search_hint',
    context.read<SeriesProvider>().language,
  );

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final provider = context.read<SeriesProvider>();
    final results = query.isEmpty ? [] : provider.getGlobalSearchResults(query);

    return Stack(
      children: [
        // Background Logo
        if (results.isEmpty)
          Center(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/icon/JKD.png',
                width: 400,
                height: 400,
              ),
            ),
          ),

        // Content
        if (query.isEmpty)
          Center(
            child: Text(
              LocalizationService.translate('search_hint', provider.language),
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else if (results.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate('nothing', provider.language),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                leading: _getLeadingIcon(result),
                title: Text(result.title),
                subtitle: Text(result.subtitle),
                onTap: () {
                  _handleResultSelection(context, result, provider);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _getLeadingIcon(SearchResult result) {
    switch (result.type) {
      case SearchResultType.series:
        return const Icon(Icons.list_alt, color: Colors.blue);
      case SearchResultType.glossary:
        return const Icon(Icons.book, color: Colors.orange);
      case SearchResultType.program:
        return const Icon(Icons.fitness_center, color: Colors.green);
      case SearchResultType.move:
        return const Icon(Icons.sports_mma, color: Colors.red);
    }
  }

  void _handleResultSelection(
    BuildContext context,
    SearchResult result,
    SeriesProvider provider,
  ) {
    final lang = provider.language;

    switch (result.type) {
      case SearchResultType.series:
      case SearchResultType.move:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SeriesDetailScreen(series: result.data as JkdSeries),
          ),
        );
        break;
      case SearchResultType.program:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProgramDetailScreen(program: result.data as TrainingProgram),
          ),
        );
        break;
      case SearchResultType.glossary:
        final item = result.data as Map<String, dynamic>;
        final trans = TranslationUtils.parseTranslations(item['translations']);
        final t = trans[lang] ?? trans['en'] ?? trans['fr'] ?? '';

        // Show translation in a SnackBar since we're in a search context
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('${item['name']}: $t'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }
}
