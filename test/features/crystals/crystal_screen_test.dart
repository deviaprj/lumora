import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/crystals/data/crystal_progression_service.dart';
import 'package:lumora_mobile/features/crystals/domain/crystal_board.dart';
import 'package:lumora_mobile/features/crystals/domain/crystal_models.dart';
import 'package:lumora_mobile/features/crystals/presentation/crystal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  required int level,
  required CrystalBoard board,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: CrystalScreen(level: level, boardBuilder: (_) => board),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CrystalProgressionService.instance.resetForTest();
  });

  testWidgets('affiche le HUD, le plateau et la consigne', (tester) async {
    final board = CrystalBoard.fromGrid(
      [
        [CrystalColor.rose, CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.gold, CrystalColor.mint],
        [CrystalColor.gold, CrystalColor.gold, CrystalColor.gold],
      ],
      random: Random(1),
    );

    await _pumpScreen(tester, level: 1, board: board);

    expect(find.text('Cristaux de couleur'), findsOneWidget);
    expect(find.textContaining('Niv. 1'), findsOneWidget);
    expect(
      find.text('Touche un cristal, puis un voisin de la même couleur.'),
      findsOneWidget,
    );
    expect(find.text('Éclats'), findsOneWidget);
    expect(find.text('Gestes'), findsOneWidget);
    expect(find.text('Objectif'), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('crystal-gem-0-0')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('crystal-gem-2-2')), findsOneWidget);
  });

  testWidgets('sélectionne un cristal et adapte la consigne', (tester) async {
    final board = CrystalBoard.fromGrid(
      [
        [CrystalColor.rose, CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.gold, CrystalColor.mint],
        [CrystalColor.gold, CrystalColor.gold, CrystalColor.gold],
      ],
      random: Random(2),
    );

    await _pumpScreen(tester, level: 1, board: board);

    await tester.tap(find.byKey(const ValueKey<String>('crystal-gem-2-0')));
    await tester.pump();

    expect(
      find.text('Choisis un voisin or pour libérer sa lumière.'),
      findsOneWidget,
    );
  });

  testWidgets('libère un groupe et met à jour le score', (tester) async {
    final board = CrystalBoard.fromGrid(
      [
        [CrystalColor.rose, CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.gold, CrystalColor.mint],
        [CrystalColor.gold, CrystalColor.gold, CrystalColor.gold],
      ],
      random: Random(3),
    );

    await _pumpScreen(tester, level: 1, board: board);

    await tester.tap(find.byKey(const ValueKey<String>('crystal-gem-2-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('crystal-gem-2-1')));
    await tester.pump();

    // Quatre cristaux d'or reliés : 160 éclats.
    expect(find.text('160'), findsOneWidget);
    expect(find.text('13'), findsOneWidget); // gestes restants
    expect(find.text('Série lancée, continue'), findsOneWidget);
    expect(find.text('x1.1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();

    expect(find.text('160'), findsNothing);
    expect(find.text('14'), findsOneWidget);
  });

  testWidgets('une paire invalide ne consomme pas de geste', (tester) async {
    final board = CrystalBoard.fromGrid(
      [
        [CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.gold],
      ],
      random: Random(4),
    );

    await _pumpScreen(tester, level: 1, board: board);

    await tester.tap(find.byKey(const ValueKey<String>('crystal-gem-0-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('crystal-gem-1-0')));
    await tester.pump();

    expect(find.text('14'), findsOneWidget);
    expect(find.text('Relie deux voisins identiques'), findsOneWidget);
  });

  testWidgets('affiche l’overlay de victoire quand l’objectif est atteint',
      (tester) async {
    final board = CrystalBoard.fromGrid(
      List<List<CrystalColor>>.generate(
        4,
        (_) => List<CrystalColor>.filled(4, CrystalColor.rose),
      ),
      random: Random(5),
    );

    await _pumpScreen(tester, level: 1, board: board);

    await tester.tap(find.byKey(const ValueKey<String>('crystal-gem-0-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('crystal-gem-0-1')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      find.byKey(const ValueKey<String>('crystal-victory-overlay')),
      findsOneWidget,
    );
    expect(find.text('Le prisme s\'illumine'), findsOneWidget);
    expect(find.text('Palier suivant'), findsOneWidget);

    await tester.tap(find.text('Palier suivant'));
    await tester.pump();

    expect(find.textContaining('Niv. 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('crystal-victory-overlay')),
      findsNothing,
    );
  });
}
