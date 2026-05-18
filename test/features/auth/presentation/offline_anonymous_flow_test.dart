import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lumora_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'offline fallback flow: jouer anonymement -> jouer -> niveau dispo -> commencer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const ProviderScope(child: LumoraApp()));

      // Force la route auth pour eviter les effets de timing du splash.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final router = app.routerConfig as GoRouter;
      router.go('/auth');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final guestButton = find.text('Jouer anonymement');
      expect(guestButton, findsOneWidget);
      await tester.ensureVisible(guestButton);
      await tester.tap(guestButton);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Jouer').evaluate().isNotEmpty) {
          break;
        }
      }

      // Home screen
      final playButton = find.text('Jouer');
      expect(playButton, findsOneWidget);
      await tester.ensureVisible(playButton);
      await tester.tap(playButton);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const ValueKey<String>('jump-to-all-1')).evaluate().isNotEmpty) {
          break;
        }
      }

      // World map
      expect(find.text('Carte des Mondes'), findsWidgets);

      final jumpToLevelOne = find.byKey(const ValueKey<String>('jump-to-all-1'));
      expect(jumpToLevelOne, findsOneWidget);
      await tester.ensureVisible(jumpToLevelOne);
      await tester.tap(jumpToLevelOne);
      var gameEntryVisible = false;
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('Commencer').evaluate().isNotEmpty ||
            find.text('Debug Victoire').evaluate().isNotEmpty) {
          gameEntryVisible = true;
          break;
        }
      }
      expect(gameEntryVisible, isTrue);

      // Game screen idle overlay
      final startButton = find.text('Commencer');
      if (startButton.evaluate().isNotEmpty) {
        await tester.ensureVisible(startButton);
        await tester.tap(startButton);
        await tester.pump(const Duration(milliseconds: 400));
      } else {
        expect(find.text('Debug Victoire'), findsOneWidget);
      }
    },
  );
}
