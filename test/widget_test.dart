import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/main.dart';

void main() {
  testWidgets('LumoraApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LumoraApp());
    // Attendre la fin du timer du SplashScreen (2s) + transitions
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
