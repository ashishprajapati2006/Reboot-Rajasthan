import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saaf_surksha/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // App name should render on the design system example home.
    expect(find.text('SAAF-SURKSHA'), findsWidgets);

    // At least one Material widget should exist.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
