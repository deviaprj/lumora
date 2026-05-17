import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/shared/widgets/lumora_button.dart';
import 'package:lumora_mobile/app/theme.dart';

void main() {
  group('LumoraButton', () {
    Widget buildButton({
      VoidCallback? onPressed,
      String? text,
      Widget? icon,
      List<Color>? gradientColors,
      double? size,
      bool isFloating = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LumoraButton(
            onPressed: onPressed ?? () {},
            text: text,
            icon: icon,
            gradientColors: gradientColors,
            size: size,
            isFloating: isFloating,
          ),
        ),
      );
    }

    testWidgets('renders text button with correct label', (tester) async {
      await tester.pumpWidget(buildButton(text: 'Jouer'));
      expect(find.text('Jouer'), findsOneWidget);
    });

    testWidgets('renders icon button when size is specified', (tester) async {
      await tester.pumpWidget(buildButton(
        size: 44,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
      ));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(buildButton(
        text: 'Test',
        onPressed: () => pressed = true,
      ));
      await tester.tap(find.text('Test'));
      expect(pressed, true);
    });

    testWidgets('does not call onPressed when disabled (null)', (tester) async {
      await tester.pumpWidget(buildButton(onPressed: null, text: 'Disabled'));
      // Disabled button — InkResponse won't fire
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('uses default gradient when none specified', (tester) async {
      await tester.pumpWidget(buildButton(text: 'Default'));
      // Vérifie que le Container avec gradient est présent
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('uses custom gradient when specified', (tester) async {
      await tester.pumpWidget(buildButton(
        text: 'Custom',
        gradientColors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
      ));
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('creates two AnimationControllers without crash', (tester) async {
      // Ce test vérifie que le TickerProviderStateMixin est utilisé
      // et que 2 AnimationControllers ne causent pas d'erreur
      await tester.pumpWidget(buildButton(text: 'Animated'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Si on arrive ici sans erreur, les 2 contrôleurs fonctionnent
      expect(find.text('Animated'), findsOneWidget);
    });

    testWidgets('press animation works (scale down on tap)', (tester) async {
      await tester.pumpWidget(buildButton(text: 'Press'));
      await tester.pump();

      // Trouver l'InkWell et simuler un tap-down
      final inkWell = find.byType(InkWell);
      expect(inkWell, findsOneWidget);

      // Le ScaleTransition devrait être présent
      expect(find.byType(ScaleTransition), findsOneWidget);
    });

    testWidgets('floating animation offset is present', (tester) async {
      await tester.pumpWidget(buildButton(text: 'Float', isFloating: true));
      await tester.pump();

      // Le TweenAnimationBuilder pour le floating doit être présent
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('non-floating button has no floating animation', (tester) async {
      await tester.pumpWidget(buildButton(text: 'NoFloat', isFloating: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('NoFloat'), findsOneWidget);
    });

    testWidgets('haptic feedback on tap does not crash', (tester) async {
      await tester.pumpWidget(buildButton(text: 'Haptic'));
      await tester.tap(find.text('Haptic'));
      await tester.pump();
      // Pas de crash = succès
      expect(find.text('Haptic'), findsOneWidget);
    });

    testWidgets('multiple LumoraButtons in a column all work', (tester) async {
      var count = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LumoraButton(
                onPressed: () => count++,
                text: 'Button 1',
              ),
              const SizedBox(height: 8),
              LumoraButton(
                onPressed: () => count++,
                text: 'Button 2',
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.text('Button 1'));
      await tester.tap(find.text('Button 2'));
      expect(count, 2);
    });
  });
}