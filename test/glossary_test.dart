import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jkd_app/utils/translation_utils.dart';
import 'package:jkd_app/utils/category_utils.dart';

void main() {
  group('Glossary Utility Tests', () {
    test('TranslationUtils.parseTranslations handles various inputs', () {
      // JSON string input
      final jsonInput = '{"en": "Hello", "fr": "Bonjour"}';
      final parsed1 = TranslationUtils.parseTranslations(jsonInput);
      expect(parsed1['en'], 'Hello');
      expect(parsed1['fr'], 'Bonjour');

      // Map input
      final mapInput = {'en': 'Goodbye', 'fr': 'Au revoir'};
      final parsed2 = TranslationUtils.parseTranslations(mapInput);
      expect(parsed2['en'], 'Goodbye');
      expect(parsed2['fr'], 'Au revoir');

      // Empty/null input
      expect(TranslationUtils.parseTranslations(null), {});
      expect(TranslationUtils.parseTranslations(''), {});
      expect(TranslationUtils.parseTranslations('invalid json'), {});
    });

    test('CategoryUtils returns correct icons and colors', () {
      expect(CategoryUtils.getCategoryIcon('punch'), Icons.sports_mma);
      expect(CategoryUtils.getCategoryIcon('kick'), Icons.sports_martial_arts);
      expect(CategoryUtils.getCategoryColor('punch'), Colors.purple);
      expect(CategoryUtils.getCategoryColor('kick'), Colors.red);
      expect(CategoryUtils.getCategoryIcon('unknown'), Icons.help_outline);
      expect(CategoryUtils.getCategoryColor('unknown'), Colors.grey);
    });

    test('CategoryUtils.getCategoryDirName capitalizes correctly', () {
      expect(CategoryUtils.getCategoryDirName('punches'), 'Punches');
      expect(CategoryUtils.getCategoryDirName('jkd_moves'), 'Jkd_moves');
      expect(CategoryUtils.getCategoryDirName(''), 'Other');
    });
  });
}
