import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumora_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration step = const Duration(milliseconds: 200),
    int maxSteps = 80,
  }) async {
    for (var i = 0; i < maxSteps; i++) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    fail('Element non trouve: $finder');
  }

  Future<void> _tapWhenVisible(
    WidgetTester tester,
    Finder finder, {
    Duration settle = const Duration(milliseconds: 500),
  }) async {
    await _waitFor(tester, finder);
    await tester.ensureVisible(finder.first);
    await tester.tap(finder.first);
    await tester.pump(settle);
  }

  testWidgets(
    'device offline flow: jouer anonymement -> jouer -> prochain niveau -> commencer',
    (tester) async {
      app.main();

      // Splash -> Auth
      await _waitFor(tester, find.text('Jouer anonymement'));

      // Auth -> Home (fallback offline sans Firebase)
      await _tapWhenVisible(tester, find.text('Jouer anonymement'));
      await _waitFor(tester, find.text('Jouer'));

      // Home -> World Map
      await _tapWhenVisible(tester, find.text('Jouer'));
      await _waitFor(tester, find.byKey(const ValueKey<String>('jump-to-all-1')));

      // World Map -> Game
      await _tapWhenVisible(tester, find.byKey(const ValueKey<String>('jump-to-all-1')));

      // Jeu: bouton de lancement visible puis cliquable (si l'overlay idle est actif)
      final startButton = find.text('Commencer');
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (startButton.evaluate().isNotEmpty ||
            find.text('Debug Victoire').evaluate().isNotEmpty) {
          break;
        }
      }

      if (startButton.evaluate().isNotEmpty) {
        await tester.ensureVisible(startButton.first);
        await tester.tap(startButton.first);
        await tester.pump(const Duration(milliseconds: 600));
      }

      // Validation finale: on est bien dans l'ecran de jeu.
      expect(
        find.text('Debug Victoire').evaluate().isNotEmpty ||
            find.text('Commencer').evaluate().isNotEmpty,
        isTrue,
      );
    },
  );
}
