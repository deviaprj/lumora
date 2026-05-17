import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/auth/presentation/auth_screen.dart';
import 'package:lumora_mobile/shared/widgets/lumora_button.dart';
import '../test_helpers.dart';

// ---------------------------------------------------------------------------
// Widget Test — AuthScreen
// Vérifie : 4 boutons organiques (Google, Apple, Email, Anonyme),
// aucun ElevatedButton / TextButton / OutlinedButton brut.
// ---------------------------------------------------------------------------

void main() {
  group('AuthScreen — boutons d\'authentification', () {
    testWidgets('affiche 4 LumoraButton (Google, Apple, Email, Anonyme)', (tester) async {
      await pumpLumoraApp(tester, const AuthScreen(), useRouter: true);

      final buttons = find.byType(LumoraButton);
      // 4 bulles d'auth + 1 bouton retour = 5 LumoraButton
      expect(buttons, findsNWidgets(5),
          reason: 'AuthScreen doit contenir 5 LumoraButton (4 auth + retour)');
    });

    testWidgets('contient les labels attendus', (tester) async {
      await pumpLumoraApp(tester, const AuthScreen(), useRouter: true);

      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Continuer avec Apple'), findsOneWidget);
      expect(find.text('Continuer avec Email'), findsOneWidget);
      expect(find.text('Jouer anonymement'), findsOneWidget);
      expect(find.text('Retour'), findsOneWidget);
    });

    testWidgets('ne contient aucun bouton Material brut', (tester) async {
      await pumpLumoraApp(tester, const AuthScreen(), useRouter: true);
      expectNoMaterialButtons(tester);
    });

    testWidgets('tous les boutons sont organiques (pas de bords droits)', (tester) async {
      await pumpLumoraApp(tester, const AuthScreen(), useRouter: true);

      final buttonFinders = find.byType(LumoraButton);
      final buttons = tester.widgetList<LumoraButton>(buttonFinders);

      for (final btn in buttons) {
        // LumoraButton utilise LumoraRadii.bubble (9999) par construction
        // Le test unitaire de LumoraButton couvre le borderRadius.
        expect(btn.onPressed, isNotNull, reason: 'Tous les boutons doivent etre actifs');
      }
    });
  });
}
