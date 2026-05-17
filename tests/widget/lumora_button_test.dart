import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/shared/widgets/lumora_button.dart';
import 'package:lumora_mobile/app/theme.dart';
import '../test_helpers.dart';

// ---------------------------------------------------------------------------
// Widget Test — LumoraButton
// Vérifie : borderRadius >= 16 (ou pill), jamais de gris brut (#808080),
// jamais de shape rectangulaire (bords droits).
// ---------------------------------------------------------------------------

void main() {
  group('LumoraButton — forme organique', () {
    testWidgets('borderRadius >= 16dp (utilise LumoraRadii.bubble)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraButton(
        text: 'Test',
        gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
      ));

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final container = tester.widgetList(containerFinder).first as Container;
      final decoration = container.decoration as BoxDecoration?;
      final borderRadius = decoration?.borderRadius as BorderRadius?;
      final radius = borderRadius?.topLeft.x ?? 0;

      expect(radius, greaterThanOrEqualTo(16.0),
          reason: 'Le borderRadius doit être >= 16dp (organique)');
    });

    testWidgets('n\'utilise jamais de couleur grise brute (#808080)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraButton(
        text: 'Test',
        gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
      ));

      expectNoBrutalGrey(tester);
    });

    testWidgets('n\'utilise jamais de shape rectangulaire (bords droits)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraButton(
        text: 'Test',
        gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
      ));

      final containerFinder = find.byType(Container);
      for (final element in tester.widgetList(containerFinder)) {
        final container = element as Container;
        final decoration = container.decoration as BoxDecoration?;
        if (decoration == null) continue;

        final borderRadius = decoration.borderRadius;
        if (borderRadius == null) {
          fail('Container sans borderRadius detecte — bords droits interdits');
        }

        final radius = (borderRadius as BorderRadius).topLeft.x;
        expect(radius, greaterThanOrEqualTo(16.0),
            reason: 'Aucun bord droit (radius < 16) ne doit etre present');
      }
    });

    testWidgets('possede un degrade lineaire (pas de couleur unie grise)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraButton(
        text: 'Test',
        gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
      ));

      final containerFinder = find.byType(Container);
      final container = tester.widgetList(containerFinder).first as Container;
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration?.gradient, isA<LinearGradient>(),
          reason: 'LumoraButton doit utiliser un degrade lineaire');
    });

    testWidgets('est flottant par defaut (isFloating = true)', (tester) async {
      await pumpLumoraWidget(tester, const LumoraButton(
        text: 'Test',
        gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
      ));

      final tweenFinder = find.byType(TweenAnimationBuilder<double>);
      expect(tweenFinder, findsOneWidget,
          reason: 'Par defaut LumoraButton doit etre flottant (TweenAnimationBuilder)');
    });
  });
}
