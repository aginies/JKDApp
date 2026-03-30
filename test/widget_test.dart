import 'package:flutter_test/flutter_test.dart';
import 'package:jkd_app/main.dart';

void main() {
  testWidgets('App builds and shows JKD Series', (WidgetTester tester) async {
    await tester.pumpWidget(const JkdApp());
    expect(find.text('JKD Series'), findsOneWidget);
  });
}
