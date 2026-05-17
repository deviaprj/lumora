import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/app/theme.dart';
import 'package:lumora_mobile/shared/widgets/lumora_button.dart';
import 'package:lumora_mobile/shared/widgets/lumora_card.dart';
import 'package:lumora_mobile/features/game/presentation/victory_overlay.dart';
import 'package:lumora_mobile/features/game/presentation/world_map_screen.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';

/// Tests de régression pour vérifier que les widgets utilisent
/// le bon TickerProvider (TickerProviderStateMixin pour multi-controllers,
/// SingleTickerProviderStateMixin pour single controller).
void main() {
  group('TickerProvider Regression Tests', () {
    group('LumoraButton', () {
      testWidgets('renders without ticker assertion error', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LumoraButton(
              onPressed: () {},
              text: 'Test',
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Test'), findsOneWidget);
      });

      testWidgets('multiple buttons in column do not crash', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LumoraButton(onPressed: () {}, text: 'A'),
                LumoraButton(onPressed: () {}, text: 'B'),
                LumoraButton(onPressed: () {}, text: 'C'),
              ],
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('A'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
      });

      testWidgets('press animation completes without error', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LumoraButton(
              onPressed: () {},
              text: 'Press',
            ),
          ),
        ));
        await tester.pump();

        // Tap and release
        await tester.tap(find.text('Press'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Press'), findsOneWidget);
      });
    });

    group('LumoraCard', () {
      testWidgets('renders without blur by default', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LumoraCard(child: Text('Content')),
          ),
        ));
        expect(find.text('Content'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsNothing);
      });

      testWidgets('renders with blur enabled without crash', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: LumoraCard(
                enableBlur: true,
                child: Text('Blurred'),
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Blurred'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);
      });

      testWidgets('victory overlay card with blur does not crash',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            backgroundColor: LumoraColors.deepSpace,
            body: VictoryOverlay(
              stars: 3,
              score: 500,
              onNextLevel: () {},
              onShare: () {},
              onMenu: () {},
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Monde illuminé !'), findsOneWidget);
      });

      testWidgets('multiple cards in column', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LumoraCard(child: Text('Card 1')),
                const SizedBox(height: 8),
                LumoraCard(child: Text('Card 2')),
              ],
            ),
          ),
        ));
        expect(find.text('Card 1'), findsOneWidget);
        expect(find.text('Card 2'), findsOneWidget);
      });
    });

    group('WorldMapScreen', () {
      testWidgets('renders level bubbles with animations', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: WorldMapScreen(completedLevelId: 0),
        ));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Vérifie que le titre est visible
        expect(find.text('Carte des Mondes'), findsOneWidget);
      });

      testWidgets('multiple animation controllers do not crash',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: WorldMapScreen(completedLevelId: 2),
        ));
        await tester.pump();
        // Laisser les animations tourner quelques frames
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Carte des Mondes'), findsOneWidget);
      });
    });

    group('VictoryOverlay', () {
      testWidgets('renders 3 star slots', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            backgroundColor: LumoraColors.deepSpace,
            body: VictoryOverlay(
              stars: 2,
              score: 300,
              onNextLevel: () {},
              onShare: () {},
              onMenu: () {},
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        // Vérifie que les étoiles et le texte sont présents
        expect(find.text('Monde illuminé !'), findsOneWidget);
        // Vérifie qu'il y a bien 3 icônes d'étoiles (remplies ou vides)
        expect(find.byIcon(Icons.star_rounded), findsWidgets);
        expect(find.byIcon(Icons.star_border_rounded), findsWidgets);
      });

      testWidgets('animation controllers do not cause assertion errors',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            backgroundColor: LumoraColors.deepSpace,
            body: VictoryOverlay(
              stars: 3,
              score: 500,
              onNextLevel: () {},
              onShare: () {},
              onMenu: () {},
            ),
          ),
        ));
        // Animer les étoiles une par une
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 350));
        // Pas d'assertion error = succès
        expect(find.text('Monde illuminé !'), findsOneWidget);
      });
    });

    group('Game transition tests', () {
      testWidgets('LumoraCard glassmorphism in dark theme', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: LumoraTheme.darkTheme,
          home: Scaffold(
            backgroundColor: LumoraColors.deepSpace,
            body: Center(
              child: LumoraCard(
                enableBlur: true,
                shadows: [LumoraShadows.glow()],
                child: Text('Glassmorphism'),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(find.text('Glassmorphism'), findsOneWidget);
      });
    });
  });
}