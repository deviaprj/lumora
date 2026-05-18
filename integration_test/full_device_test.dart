import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lumora_mobile/main.dart';
import 'package:lumora_mobile/app/router.dart';
import 'package:lumora_mobile/features/game/presentation/game_screen.dart';
import 'package:lumora_mobile/features/game/presentation/world_map_screen.dart';
import 'package:lumora_mobile/features/settings/presentation/settings_screen.dart';
import 'package:lumora_mobile/features/monetization/presentation/shop_screen.dart';
import 'package:lumora_mobile/features/events/presentation/events_screen.dart';
import 'package:lumora_mobile/features/game/engine/game_state.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper : charge l'app, attend que le routeur soit prêt, navigue vers [route].
  Future<void> _navigateToRoute(WidgetTester tester, String route) async {
    isAuthenticated = route == '/auth' ? false : true;
    await tester.pumpWidget(const ProviderScope(child: LumoraApp()));
    // Laisser le routeur s'initialiser
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig as GoRouter;
    router.go(route);
    // Laisser la transition se jouer
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('Lumora — Navigation device', () {
    testWidgets('01 Auth : boutons organiques', (tester) async {
      await _navigateToRoute(tester, '/auth');

      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Continuer avec Apple'), findsOneWidget);
      expect(find.text('Continuer avec Email'), findsOneWidget);
      expect(find.text('Jouer anonymement'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('02 Home : écran d\'accueil', (tester) async {
      await _navigateToRoute(tester, '/home');

      expect(find.text('Jouer'), findsOneWidget);
      expect(find.text('Carte des Mondes'), findsOneWidget);
      expect(find.text('Événements'), findsOneWidget);
      expect(find.text('Boutique'), findsOneWidget);
    });

    testWidgets('03 World Map : navigation', (tester) async {
      await _navigateToRoute(tester, '/world-map');

      expect(find.byType(WorldMapScreen), findsOneWidget);
    });

    testWidgets('04 Settings : cartes organiques', (tester) async {
      await _navigateToRoute(tester, '/settings');

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('05 Shop : PageView', (tester) async {
      await _navigateToRoute(tester, '/shop');

      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('06 Events : cartes', (tester) async {
      await _navigateToRoute(tester, '/events');

      expect(find.byType(EventsScreen), findsOneWidget);
    });

    testWidgets('07 Absence de boutons Material bruts', (tester) async {
      await _navigateToRoute(tester, '/home');
      for (final route in ['/home', '/settings', '/shop', '/events']) {
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        final router = app.routerConfig as GoRouter;
        router.go(route);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(ElevatedButton), findsNothing, reason: 'Aucun ElevatedButton sur $route');
        expect(find.byType(TextButton), findsNothing, reason: 'Aucun TextButton sur $route');
        expect(find.byType(OutlinedButton), findsNothing, reason: 'Aucun OutlinedButton sur $route');
      }
    });

    testWidgets('08 Transitions fluides (pas d\'erreur)', (tester) async {
      await _navigateToRoute(tester, '/home');
      for (final route in ['/home', '/world-map', '/settings', '/shop', '/events']) {
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        final router = app.routerConfig as GoRouter;
        router.go(route);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(ErrorWidget), findsNothing, reason: 'Aucune erreur sur $route');
      }
    });
  });

  group('Lumora — GameState (logique pure)', () {
    testWidgets('09 GameState : démarrage', (tester) async {
      final gameState = GameState(level: World1Levels.levels.first);
      expect(gameState.status, GameStatus.idle);
      expect(gameState.lives, 3);
      gameState.start();
      expect(gameState.status, GameStatus.playing);
    });

    testWidgets('10 GameState : connexions', (tester) async {
      final gameState = GameState(level: World1Levels.levels.first);
      gameState.start();
      expect(gameState.addConnection(0, 1), true);
      expect(gameState.addConnection(0, 99), false);
    });

    testWidgets('11 GameState : victoire', (tester) async {
      final gameState = GameState(level: World1Levels.levels.first);
      gameState.start();
      gameState.addConnection(0, 1);
      gameState.addConnection(1, 2);
      expect(gameState.status, GameStatus.victory);
      expect(gameState.stars, greaterThanOrEqualTo(1));
    });

    testWidgets('12 GameState : défaite timer', (tester) async {
      final gameState = GameState(level: World1Levels.levels.first);
      gameState.start();
      gameState.tickTimer(200.0);
      expect(gameState.status, GameStatus.defeat);
    });

    testWidgets('13 GameState : timer progression', (tester) async {
      final gameState = GameState(level: World1Levels.levels.first);
      gameState.start();
      expect(gameState.timeRemaining, 120.0);
      gameState.tickTimer(90.0);
      expect(gameState.timeRemaining, 30.0);
    });

    testWidgets('14 GameState : indices et reset', (tester) async {
      final gameState = GameState(level: World1Levels.levels.first);
      gameState.start();
      gameState.addConnection(0, 1);
      expect(gameState.score, 100);
      gameState.useHint();
      expect(gameState.score, 50);
      gameState.reset();
      expect(gameState.status, GameStatus.idle);
    });

    testWidgets('15 LevelData : niveaux valides', (tester) async {
      final levels = World1Levels.levels;
      expect(levels.length, 10);
      for (final level in levels) {
        expect(level.nodes.isNotEmpty, true);
        for (final conn in level.requiredConnections) {
          expect(conn.from, lessThan(level.nodes.length));
          expect(conn.to, lessThan(level.nodes.length));
        }
      }
    });
  });
}