import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/main.dart';

void main() {
  testWidgets('LumoraApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LumoraApp());
    // Attendre la fin du timer du SplashScreen (2s) + transitions.
    // pumpAndSettle bloque ici (animations continues des boutons flottants) :
    // on pompe une durée fixe à la place, comme recommandé dans CLAUDE.md.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
