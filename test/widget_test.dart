import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CARE-O basic Flutter test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('CARE-O'),
        ),
      ),
    );

    expect(find.text('CARE-O'), findsOneWidget);
  });
}