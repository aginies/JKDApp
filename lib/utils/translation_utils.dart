import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for handling translation parsing across the app
class TranslationUtils {
  /// Parses translations from various input formats (String, Map, null)
  /// Returns empty map if parsing fails or input is null
  static Map<String, String> parseTranslations(dynamic translationsField) {
    try {
      if (translationsField == null) return {};

      if (translationsField is Map) {
        return translationsField.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      }

      if (translationsField is String) {
        if (translationsField.isEmpty) return {};

        final decoded = json.decode(translationsField);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }

      return {};
    } catch (e) {
      debugPrint('Error parsing translations from $translationsField: $e');
      return {};
    }
  }
}
