import 'package:flutter_test/flutter_test.dart';

import 'package:careo_new/main.dart';

void main() {
  testWidgets('CARE-O app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CareoApp());

    await tester.pumpAndSettle();

    expect(find.byType(CareoApp), findsOneWidget);
  });
}