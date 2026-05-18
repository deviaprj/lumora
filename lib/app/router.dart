import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/game/data/player_progression_service.dart';
import '../features/game/domain/level_data.dart';
import '../features/game/presentation/game_screen.dart';
import '../features/game/presentation/world_map_screen.dart';
import '../features/monetization/presentation/shop_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../shared/widgets/lumora_button.dart';
import '../shared/widgets/lumora_card.dart';
import 'theme.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

Stream<dynamic> _authStateChangesSafely() {
  if (Firebase.apps.isEmpty) {
    return const Stream<dynamic>.empty();
  }
  return FirebaseAuth.instance.authStateChanges();
}

late final _authRefresh = _GoRouterRefreshStream(_authStateChangesSafely());

/// Transition organique — fade + scale élastique (depuis la droite).
CustomTransitionPage<void> _buildPage({
  required GoRouterState state,
  required Widget child,
  Offset slideOffset = const Offset(0.15, 0),
  bool scaleOnEntry = false,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = Curves.easeOutCubic;
      final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

      Widget result = SlideTransition(
        position: Tween<Offset>(
          begin: slideOffset,
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

      if (scaleOnEntry) {
        result = ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: result,
        );
      }

      return FadeTransition(
        opacity: curvedAnimation,
        child: result,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

/// Transition fade pour le splash.
CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 600),
  );
}

/// Transition organique pour la carte des mondes — scale élastique + fade.
CustomTransitionPage<void> _worldMapTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      final scaleAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(scaleAnimation),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 350),
  );
}

/// Transition organique pour le gameplay — slide vertical léger + scale.
CustomTransitionPage<void> _gameTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      final slideAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      final scaleAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(slideAnimation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(scaleAnimation),
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

late final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  refreshListenable: _authRefresh,
  redirect: (BuildContext context, GoRouterState state) {
    final hasFirebase = Firebase.apps.isNotEmpty;
    final location = state.uri.path;

    if (!hasFirebase) {
      return null;
    }

    final isAuth = FirebaseAuth.instance.currentUser != null;

    final publicRoutes = ['/splash', '/auth'];
    if (publicRoutes.contains(location)) return null;

    if (!isAuth) return '/auth';

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadeTransition(
        state: state,
        child: const _SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const AuthScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) {
        final level = state.extra as LevelData?;
        return _gameTransition(
          state: state,
          child: GameScreen(level: level),
        );
      },
    ),
    GoRoute(
      path: '/world-map',
      pageBuilder: (context, state) {
        final completedId = state.uri.queryParameters['completed'];
        final persistedCompletedId = PlayerProgressionService.instance.completedLevelId;
        final routeCompletedId = completedId != null ? int.tryParse(completedId) ?? 0 : 0;
        return _worldMapTransition(
          state: state,
          child: WorldMapScreen(
            completedLevelId: routeCompletedId > persistedCompletedId
                ? routeCompletedId
                : persistedCompletedId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/shop',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const ShopScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/events',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const EventsScreen(),
      ),
    ),
  ],
);

/// Splash screen organique — fond dégradé, logo animé, init asynchrone.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/auth');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LumoraGradients.authBg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _logoController,
                  curve: Curves.elasticOut,
                ),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _logoController,
                    curve: Curves.easeOutCubic,
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LumoraGradients.primaryBubble,
                      boxShadow: [
                        LumoraShadows.glow(),
                        BoxShadow(
                          color: LumoraColors.auroraGreen.withAlpha(30),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bubble_chart_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _logoController,
                  curve: Curves.easeOutCubic,
                ),
                child: Text(
                  'Lumora',
                  style: LumoraTextStyles.displayLarge(),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _logoController,
                  curve: Curves.easeOutCubic,
                ),
                child: Text(
                  'Réveille les mondes assoupis',
                  style: LumoraTextStyles.bodyMedium(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran d'accueil — navigation organique vers les fonctionnalités du jeu.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LumoraGradients.homeBg),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Text('Lumora', style: LumoraTextStyles.displayMedium()),
                    const Spacer(),
                    LumoraButton(
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
                      gradientColors: [LumoraColors.midnight, LumoraColors.twilight],
                      size: 44,
                      elevation: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Réveille les mondes assoupis',
                  style: LumoraTextStyles.bodyMedium(color: LumoraColors.softMist),
                ),
                const Spacer(),

                // Jouer — bouton principal avec glow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: LumoraColors.auroraBlue.withAlpha(40),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: LumoraButton(
                    onPressed: () => context.go('/world-map'),
                    text: 'Jouer',
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    gradientColors: [LumoraColors.twilight, LumoraColors.auroraBlue],
                    elevation: 10,
                  ),
                ),
                const SizedBox(height: 24),

                // Carte des mondes
                _HomeCard(
                  icon: Icons.map_rounded,
                  title: 'Carte des Mondes',
                  subtitle: 'Explore les niveaux',
                  gradientColors: [LumoraColors.auroraBlue, LumoraColors.auroraPurple],
                  onTap: () => context.go('/world-map'),
                ),
                const SizedBox(height: 12),

                // Événements
                _HomeCard(
                  icon: Icons.celebration_rounded,
                  title: 'Événements',
                  subtitle: 'Défis et récompenses',
                  gradientColors: [LumoraColors.auroraOrange, LumoraColors.auroraGold],
                  onTap: () => context.go('/events'),
                ),
                const SizedBox(height: 12),

                // Boutique
                _HomeCard(
                  icon: Icons.store_rounded,
                  title: 'Boutique',
                  subtitle: 'Thèmes et power-ups',
                  gradientColors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
                  onTap: () => context.go('/shop'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte de navigation sur l'écran d'accueil.
class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LumoraCard(
        borderRadius: LumoraRadii.card,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shadows: [LumoraShadows.floating(color: gradientColors.last)],
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LumoraTextStyles.bodyLarge()),
                  const SizedBox(height: 2),
                  Text(subtitle, style: LumoraTextStyles.label(color: LumoraColors.softMist)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: LumoraColors.softMist, size: 24),
          ],
        ),
      ),
    );
  }
}