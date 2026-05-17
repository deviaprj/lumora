import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:lumora_mobile/features/game/presentation/game_screen.dart';
import 'package:lumora_mobile/shared/widgets/lumora_button.dart';
import '../test_helpers.dart';

// ---------------------------------------------------------------------------
// Widget Test — GameScreen
// Vérifie : timer circulaire, bouton pause bulle, bouton indice ampoule,
// présence GameWidget (Flame), absence de bords droits.
// ---------------------------------------------------------------------------

void main() {
  group('GameScreen — overlay UI organique', () {
    Future<void> pumpGameScreen(WidgetTester tester) async {
      // pumpAndSettle ne fonctionne pas car le parallax anime en continu
      await pumpLumoraApp(tester, const GameScreen(), useRouter: true, settle: false);
      // Laisser le FutureBuilder de GameWidget résoudre le chargement
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('affiche le GameWidget (Flame)', (tester) async {
      await pumpGameScreen(tester);
      expect(find.byWidgetPredicate((w) => w is GameWidget), findsOneWidget,
          reason: 'GameScreen doit contenir un GameWidget Flame');
    });

    testWidgets('contient le timer circulaire (OrganicTimer)', (tester) async {
      await pumpGameScreen(tester);
      // OrganicTimer est un SizedBox contenant des CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsWidgets,
          reason: 'Le timer circulaire doit etre present');
    });

    testWidgets('contient le bouton pause (bulle organique)', (tester) async {
      await pumpGameScreen(tester);
      final pauseFinder = find.widgetWithIcon(LumoraButton, Icons.pause_rounded);
      expect(pauseFinder, findsOneWidget,
          reason: 'Le bouton pause doit etre une bulle organique (LumoraButton)');
    });

    testWidgets('contient le bouton indice (ampoule organique)', (tester) async {
      await pumpGameScreen(tester);
      final hintFinder = find.widgetWithIcon(LumoraButton, Icons.lightbulb_rounded);
      expect(hintFinder, findsOneWidget,
          reason: 'Le bouton indice doit etre une ampoule organique (LumoraButton)');
    });

    testWidgets('affiche les vies (cœurs flottants)', (tester) async {
      await pumpGameScreen(tester);
      // Icons.favorite_rounded ou Icons.favorite_border_rounded
      final hearts = find.byIcon(Icons.favorite_rounded);
      final borderHearts = find.byIcon(Icons.favorite_border_rounded);
      expect(
        hearts.evaluate().length + borderHearts.evaluate().length,
        greaterThanOrEqualTo(5),
        reason: 'La barre de vies doit afficher au moins 5 coeurs',
      );
    });

    testWidgets('aucun bord droit visible dans l\'overlay', (tester) async {
      await pumpGameScreen(tester);

      final containers = find.byType(Container);
      for (final element in tester.widgetList<Container>(containers)) {
        final decoration = element.decoration as BoxDecoration?;
        if (decoration == null) continue;
        if (decoration.borderRadius == null && decoration.shape != BoxShape.circle) {
          fail('Container avec bords droits detecte dans le GameScreen overlay');
        }
      }
    });

    testWidgets('le niveau est affiche dans une bulle arrondie', (tester) async {
      await pumpGameScreen(tester);
      expect(find.textContaining('Niv.'), findsOneWidget);
    });
  });
}
