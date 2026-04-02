enum SearchResultType { series, glossary, program, move }

class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final dynamic data;

  SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.data,
  });
}
