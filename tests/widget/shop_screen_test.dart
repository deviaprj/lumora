import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/monetization/presentation/shop_screen.dart';
import 'package:lumora_mobile/shared/widgets/lumora_card.dart';
import 'package:lumora_mobile/shared/widgets/lumora_button.dart';
import '../test_helpers.dart';

// ---------------------------------------------------------------------------
// Widget Test — ShopScreen
// Vérifie : cartes organiques (LumoraCard), scroll horizontal (PageView),
// absence de grille carree (GridView).
// ---------------------------------------------------------------------------

void main() {
  group('ShopScreen — mise en page organique', () {
    testWidgets('utilise des LumoraCard pour les produits', (tester) async {
      await pumpLumoraApp(tester, const ShopScreen(), useRouter: true);
      expect(find.byType(LumoraCard), findsWidgets,
          reason: 'Les produits doivent etre dans des LumoraCard organiques');
    });

    testWidgets('scroll horizontal via PageView (pas de grille)', (tester) async {
      await pumpLumoraApp(tester, const ShopScreen(), useRouter: true);
      expect(find.byType(PageView), findsOneWidget,
          reason: 'La boutique doit utiliser un scroll horizontal PageView');
      expect(find.byType(GridView), findsNothing,
          reason: 'Aucune grille carree ne doit etre presente');
    });

    testWidgets('affiche les produits attendus', (tester) async {
      await pumpLumoraApp(tester, const ShopScreen(), useRouter: true);
      // PageView.builder construit seulement les pages visibles (2 premieres)
      expect(find.text('Pack 5 Vies'), findsOneWidget);
      expect(find.text('Pack 20 Vies'), findsOneWidget);
    });

    testWidgets('le badge Populaire est present sur Pack 20 Vies', (tester) async {
      await pumpLumoraApp(tester, const ShopScreen(), useRouter: true);
      expect(find.text('Populaire'), findsOneWidget);
    });

    testWidgets('contient des LumoraButton (CTA Acheter)', (tester) async {
      await pumpLumoraApp(tester, const ShopScreen(), useRouter: true);
      expect(find.text('Acheter'), findsWidgets);
      // Tous les boutons doivent etre LumoraButton
      expect(find.byType(LumoraButton), findsWidgets);
    });

    testWidgets('absence totale de boutons Material bruts', (tester) async {
      await pumpLumoraApp(tester, const ShopScreen(), useRouter: true);
      expectNoMaterialButtons(tester);
    });
  });
}
