// Service for managing glossary data operations
// Handles database queries, translation parsing, and caching

import 'dart:convert';
import '../../../models/move.dart';
import '../../../services/database_service.dart';
import '../state/picker_state.dart';

class GlossaryDataService {
  // Simple cache: Map<String, List<Map<String, dynamic>>>
  static final Map<String, List<Map<String, dynamic>>> _cache = {};

  /// Get estimated item height for scroll calculations
  static const double estimatedItemHeight = 125.0;

  /// Fetch glossary items by category with caching
  static Future<List<Map<String, dynamic>>> fetchGlossaryByCategory(
    String category, {
    String? hitTypeFilter,
  }) async {
    // Check cache first
    if (_cache.containsKey(category)) {
      final cached = List<Map<String, dynamic>>.from(_cache[category]!);
      return hitTypeFilter == null || hitTypeFilter == 'both'
          ? cached
          : _filterByHitType(cached, hitTypeFilter);
    }

    // Fetch from database
    final items = await DatabaseService().getGlossaryByCategory(category);

    // Parse and cache
    final parsed = _parseTranslations(items);
    _cache[category] = parsed;

    // Apply filter if needed
    return hitTypeFilter == null || hitTypeFilter == 'both'
        ? parsed
        : _filterByHitType(parsed, hitTypeFilter);
  }

  /// Filter glossary items by hit type
  static List<Map<String, dynamic>> _filterByHitType(
    List<Map<String, dynamic>> items,
    String hitType,
  ) {
    return items
        .where(
          (item) =>
              (item['possible_type_attack'] ?? 'both') == 'both' ||
              item['possible_type_attack'] == hitType,
        )
        .toList();
  }

  /// Parse translations for all items
  static List<Map<String, dynamic>> _parseTranslations(
    List<Map<String, dynamic>> items,
  ) {
    return items.map((item) {
      final Map<String, dynamic> newItem = Map<String, dynamic>.from(item);
      newItem['parsed_tr'] = parseTranslations(item['translations']);
      return newItem;
    }).toList();
  }

  // Parse JSON translations string to Map<String, String>
  static Map<String, String> parseTranslations(dynamic translations) {
    if (translations == null) return {};
    try {
      return Map<String, String>.from(json.decode(translations));
    } catch (_) {
      return {};
    }
  }

  // Get translation for an item in specified language
  static String getTranslation(Map<String, String> translations, String lang) {
    return translations[lang] ?? translations['en'] ?? translations['fr'] ?? '';
  }

  // Clear cache for a specific category
  static void clearCache(String category) {
    _cache.remove(category);
  }

  // Clear all cached data
  static void clearAllCache() {
    _cache.clear();
  }

  // Check if item should be expanded/highlighted
  static bool shouldExpandItem(
    int id,
    String category,
    PickerState pickerState,
    bool isCounterMode,
    List<Move> currentCombo, {
    Map<String, dynamic>? attackMove,
  }) {
    // Direct ID match
    if (pickerState.pendingActionItemId == id) return true;

    // Editing mode match
    if (pickerState.editingComboItemIndex != null) {
      final editingMove = currentCombo[pickerState.editingComboItemIndex!];

      if (pickerState.isEditingCounter) {
        return editingMove.counterName == category &&
            editingMove.counterCategory == category;
      } else {
        return editingMove.name == category && editingMove.category == category;
      }
    }

    return false;
  }
}
