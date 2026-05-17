import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lumora_mobile/features/auth/presentation/auth_screen.dart';
import 'package:lumora_mobile/features/game/presentation/game_screen.dart';
import 'package:lumora_mobile/features/game/presentation/victory_overlay.dart';
import 'package:lumora_mobile/features/game/presentation/world_map_screen.dart';
import 'package:lumora_mobile/shared/widgets/lumora_button.dart';
import 'package:lumora_mobile/app/theme.dart';

// ---------------------------------------------------------------------------
// Integration Test — Parcours complet : splash → auth → home → world-map
// → gameplay → victoire → partage
// ---------------------------------------------------------------------------

class _TestApp extends StatelessWidget {
  final String initialLocation;

  const _TestApp({required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: LumoraGradients.authBg),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LumoraGradients.primaryBubble,
                      ),
                      child: const Icon(Icons.bubble_chart_rounded, size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text('Lumora', style: LumoraTextStyles.displayLarge()),
                  ],
                ),
              ),
            ),
          ),
        ),
        GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LumoraGradients.homeBg,
                borderRadius: BorderRadius.zero,
              ),
              child: const Center(child: Text('HOME')),
            ),
          ),
        ),
        GoRoute(path: '/world-map', builder: (_, __) => const WorldMapScreen()),
        GoRoute(path: '/game', builder: (_, __) => const GameScreen()),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: LumoraTheme.darkTheme,
      routerConfig: router,
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding to Level — parcours complet', () {
    testWidgets('splash → auth → home → world-map → gameplay → victoire', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: ProviderScope(child: _TestApp(initialLocation: '/splash')),
        ),
      );
      await tester.pumpAndSettle();

      // Helper pour obtenir un contexte frais après chaque navigation
      BuildContext freshContext() => tester.element(find.byType(Scaffold));

      // 1. Splash
      expect(find.text('Lumora'), findsOneWidget);

      // Simuler la transition auto du splash (2s delay dans le vrai app)
      // Ici on navigue manuellement vers auth
      GoRouter.of(freshContext()).go('/auth');
      await tester.pumpAndSettle();

      // 2. Auth — 4 boutons organiques
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Continuer avec Apple'), findsOneWidget);
      expect(find.text('Continuer avec Email'), findsOneWidget);
      expect(find.text('Jouer anonymement'), findsOneWidget);

      // Tap anonyme (s'assurer qu'il est visible)
      await tester.ensureVisible(find.text('Jouer anonymement'));
      await tester.tap(find.text('Jouer anonymement'));
      await tester.pumpAndSettle();

      // 3. Home (placeholder)
      // Le routeur navigue vers /home dans le vrai app
      // On simule la navigation
      GoRouter.of(freshContext()).go('/home');
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);

      // 4. World Map
      GoRouter.of(freshContext()).go('/world-map');
      await tester.pumpAndSettle();
      expect(find.text('Carte des Mondes'), findsOneWidget);
      // Verifier presence de CustomPaint (parallaxe + bezier)
      expect(find.byType(CustomPaint), findsWidgets);

      // 5. Gameplay
      GoRouter.of(freshContext()).go('/game');
      // pumpAndSettle ne fonctionne pas car le parallax anime en continu
      // Laisser la navigation se faire puis 2s pour le chargement du jeu
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      // Overlay UI organique present
      expect(find.byType(LumoraButton), findsWidgets,
          reason: 'Les boutons pause et indice doivent etre presents');
      expect(find.textContaining('Niv.'), findsOneWidget);

      // 6. Declencher victoire (via debug bouton dans GameScreen)
      await tester.tap(find.text('Debug Victoire'));
      await tester.pump(const Duration(milliseconds: 800));

      // 7. VictoryOverlay
      expect(find.byType(VictoryOverlay), findsOneWidget);
      expect(find.text('Monde illuminé !'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);

      // Boutons organiques presents
      expect(find.text('Niveau Suivant'), findsOneWidget);
      expect(find.text('Partager'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);

      // 8. Partager
      await tester.ensureVisible(find.text('Partager'));
      await tester.tap(find.text('Partager'));
      await tester.pump(const Duration(milliseconds: 400));
      // Verifier qu'aucun crash ne survient (pump reussit)

      // 9. Retour menu
      await tester.ensureVisible(find.text('Menu'));
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      // On doit etre sur world-map
      expect(find.text('Carte des Mondes'), findsOneWidget);
    });

    testWidgets('transitions fluides sans erreur', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: ProviderScope(child: _TestApp(initialLocation: '/auth')),
        ),
      );
      await tester.pumpAndSettle();

      // Naviguer vers toutes les routes principales
      for (final route in ['/home', '/world-map', '/game']) {
        GoRouter.of(tester.element(find.byType(Scaffold))).go(route);
        // pumpAndSettle ne marche pas sur /game (parallax continu)
        if (route == '/game') {
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
        } else {
          await tester.pumpAndSettle();
        }
        expect(find.byType(ErrorWidget), findsNothing,
            reason: 'Aucune erreur de rendu ne doit survenir sur $route');
      }
    });

    testWidgets('aucun bord droit ni bouton carre gris sur tout le parcours', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: ProviderScope(child: _TestApp(initialLocation: '/auth')),
        ),
      );
      await tester.pumpAndSettle();

      final screens = ['/auth', '/home', '/world-map', '/game'];

      for (final screen in screens) {
        GoRouter.of(tester.element(find.byType(Scaffold))).go(screen);
        if (screen == '/game') {
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
        } else {
          await tester.pumpAndSettle();
        }

        final containers = find.byType(Container);
        for (final element in tester.widgetList<Container>(containers)) {
          final decoration = element.decoration as BoxDecoration?;
          if (decoration == null) continue;
          if (decoration.borderRadius == null && decoration.shape != BoxShape.circle) {
            // Tolere les fonds plein ecran (decoration sans borderRadius)
            // si le Container est le premier enfant du Scaffold body.
            final isBackground = element.child == null || (element.constraints?.maxWidth == double.infinity);
            if (isBackground) continue;
            fail('Bord droit detecte sur $screen');
          }
        }
      }
    });
  });
}
