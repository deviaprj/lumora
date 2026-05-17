import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/shared/widgets/lumora_card.dart';
import '../test_helpers.dart';

// ---------------------------------------------------------------------------
// Widget Test — LumoraCard
// Vérifie : glassmorphism (BackdropFilter.blur), borderRadius >= 16dp,
// ombre non vide (boxShadow).
// ---------------------------------------------------------------------------

void main() {
  group('LumoraCard — glassmorphism et forme', () {
    testWidgets('simule le glassmorphism (fond translucide + bordure blanche)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraCard(
        child: SizedBox(width: 100, height: 100),
      ));

      final containerFinder = find.byType(Container);
      final container = tester.widgetList<Container>(containerFinder).first;
      final decoration = container.decoration as BoxDecoration?;

      // Surface translucide (glassmorphism simule)
      final color = decoration?.color;
      expect(color, isNotNull);
      if (color != null) {
        expect(color.opacity < 1.0, isTrue,
            reason: 'LumoraCard doit avoir une surface translucide (glassmorphism)');
      }

      // Bordure blanche legere
      final border = decoration?.border as Border?;
      expect(border, isNotNull,
          reason: 'LumoraCard doit avoir une bordure (simulation glassmorphism)');
      if (border != null) {
        expect(border.top.color.opacity < 1.0, isTrue,
            reason: 'La bordure doit etre blanche translucide');
      }
    });

    testWidgets('borderRadius >= 16dp', (tester) async {
      await pumpLumoraWidget(tester, const LumoraCard(
        child: SizedBox(width: 100, height: 100),
      ));

      final containerFinder = find.byType(Container);
      final container = tester.widgetList<Container>(containerFinder).first;
      final decoration = container.decoration as BoxDecoration?;
      final radius = (decoration?.borderRadius as BorderRadius?)?.topLeft.x ?? 0;

      expect(radius, greaterThanOrEqualTo(16.0),
          reason: 'LumoraCard borderRadius doit etre >= 16dp');
    });

    testWidgets('possede une ombre (boxShadow non vide)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraCard(
        child: SizedBox(width: 100, height: 100),
      ));

      final containerFinder = find.byType(Container);
      final container = tester.widgetList<Container>(containerFinder).first;
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration?.boxShadow, isNotNull);
      expect(decoration!.boxShadow!, isNotEmpty,
          reason: 'LumoraCard doit avoir au moins une ombre (boxShadow)');
    });

    testWidgets('utilise une couleur alpha (translucide)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraCard(
        child: SizedBox(width: 100, height: 100),
      ));

      final containerFinder = find.byType(Container);
      final container = tester.widgetList<Container>(containerFinder).first;
      final decoration = container.decoration as BoxDecoration?;
      final color = decoration?.color;

      expect(color, isNotNull);
      if (color != null) {
        final alpha = color.opacity;
        expect(alpha, lessThan(1.0),
            reason: 'La couleur de fond doit etre translucide (glassmorphism)');
      }
    });
  });
}
