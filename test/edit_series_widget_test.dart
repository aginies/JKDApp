import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jkd_app/models/series.dart';
import 'package:jkd_app/screens/series_detail_screen.dart';
import 'package:jkd_app/services/series_provider.dart';
import 'package:provider/provider.dart';
import 'package:jkd_app/services/localization_service.dart';

class MockSeriesProvider extends SeriesProvider {
  JkdSeries? lastAddedSeries;
  JkdSeries? lastUpdatedSeries;

  MockSeriesProvider() : super.empty();

  @override
  Future<void> addSeries(JkdSeries series) async {
    lastAddedSeries = series;
  }

  @override
  Future<void> updateSeries(JkdSeries series) async {
    lastUpdatedSeries = series;
  }

  @override
  String get language => 'en';

  @override
  bool get voiceEnabled => false;
}

void main() {
  testWidgets('SeriesDetailScreen shows existing series data and updates it', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final series = JkdSeries(
        id: 1,
        title: 'Original Title',
        category: 'Jun Fan Gung Fu',
        type: 'Attack',
      );

      final mockProvider = MockSeriesProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SeriesProvider>.value(
            value: mockProvider,
            child: SeriesDetailScreen(series: series),
          ),
        ),
      );

      // Verify initial values in view mode
      expect(find.text('Original Title'), findsOneWidget);
      
      // Switch to edit mode via PopupMenu
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text(LocalizationService.translate('edit', 'en')));
      await tester.pumpAndSettle();
      
      // Find the title TextField and enter new text
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Updated Title');
      
      // Tap the check (save) button
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      
      // Verify provider was called
      expect(mockProvider.lastUpdatedSeries?.title, 'Updated Title');
      
      // Clean up to avoid pending timers
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });

  testWidgets('SeriesDetailScreen can create a new series', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final mockProvider = MockSeriesProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SeriesProvider>.value(
            value: mockProvider,
            child: const SeriesDetailScreen(series: null), // New series
          ),
        ),
      );

      // Should be in edit mode immediately
      expect(find.byType(TextField), findsOneWidget);
      
      await tester.enterText(find.byType(TextField), 'New Series Title');
      
      // Tap the check (save) button
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      
      // Verify provider was called
      expect(mockProvider.lastAddedSeries?.title, 'New Series Title');

      // Clean up to avoid pending timers
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });

  testWidgets('SeriesDetailScreen can change category and type', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final mockProvider = MockSeriesProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SeriesProvider>.value(
            value: mockProvider,
            child: const SeriesDetailScreen(series: null),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test Series');

      // Change category to 'Jun Fan Kick Boxing'
      await tester.tap(find.text('Jun Fan Kick Boxing'));
      await tester.pumpAndSettle();

      // Change type to 'Defense'
      await tester.tap(find.text(LocalizationService.translate('type', 'en') == 'Type' ? 'Defense' : 'Défense'));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(mockProvider.lastAddedSeries?.category, 'Jun Fan Kick Boxing');
      expect(mockProvider.lastAddedSeries?.type, 'Defense');

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });

  testWidgets('SeriesDetailScreen can set attack method', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final mockProvider = MockSeriesProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SeriesProvider>.value(
            value: mockProvider,
            child: const SeriesDetailScreen(series: null),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test Attack Method');

      // Default is 'Attack' type, so method chips should be visible
      expect(find.text('PIA'), findsOneWidget);
      await tester.tap(find.text('PIA'));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(mockProvider.lastAddedSeries?.attackMethod, 'PIA');

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}
