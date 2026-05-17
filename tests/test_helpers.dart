import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Test Helpers — Lumora QA
// Fournit mocks et utilities pour tous les niveaux de tests.
// ---------------------------------------------------------------------------

// =============================================================================
// 1. PUMP UTILITIES
// =============================================================================

/// Pumpe un widget Lumora dans un environnement de test complet :
/// - MediaQuery 390×844 (iPhone 14)
/// - MaterialApp avec router factice si besoin
/// - Directionalité texte (LTR)
Future<void> pumpLumoraApp(
  WidgetTester tester,
  Widget widget, {
  bool useRouter = false,
  List<NavigatorObserver>? observers,
  bool settle = true,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => widget),
      GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/world-map', builder: (_, __) => const SizedBox()),
    ],
  );
  final wrapped = MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: useRouter
          ? MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
            )
          : MaterialApp(
              debugShowCheckedModeBanner: false,
              home: widget,
              navigatorObservers: observers ?? [],
            ),
    ),
  );
  await tester.pumpWidget(wrapped);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumpe un widget simple sans navigation.
Future<void> pumpLumoraWidget(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: widget),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// =============================================================================
// 2. MOCK FIREBASE
// =============================================================================

class MockFirebaseAuth {
  String? _uid;
  bool get isSignedIn => _uid != null;
  String? get uid => _uid;

  void signInAnonymously() => _uid = 'mock_anon_uid';
  void signInWithGoogle() => _uid = 'mock_google_uid';
  void signOut() => _uid = null;
}

class MockFirestore {
  final Map<String, Map<String, dynamic>> _data = {};

  void setDoc(String path, Map<String, dynamic> data) => _data[path] = data;

  Map<String, dynamic>? getDoc(String path) => _data[path];

  void clear() => _data.clear();
}

class MockFirebaseMessaging {
  final List<Map<String, dynamic>> _messages = [];

  Future<void> sendMessage(Map<String, dynamic> msg) async {
    _messages.add(msg);
  }

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
}

void mockFirebase({
  MockFirebaseAuth? auth,
  MockFirestore? firestore,
  MockFirebaseMessaging? messaging,
}) {
  // Enregistre les instances dans un registre global si besoin
  // Dans les tests unitaires, on injecte directement ces mocks.
}

// =============================================================================
// 3. MOCK ADMOB
// =============================================================================

class MockAdMob {
  int interstitialLoadCount = 0;
  int interstitialShowCount = 0;
  int rewardedLoadCount = 0;
  int rewardedShowCount = 0;
  DateTime? lastInterstitialShownAt;

  bool shouldShowInterstitial({
    required int levelsCompletedSinceLastAd,
    required int frequency,
    required bool hasSeasonPass,
    required DateTime now,
    required Duration cooldown,
  }) {
    if (hasSeasonPass) return false;
    if (levelsCompletedSinceLastAd < frequency) return false;
    if (lastInterstitialShownAt != null &&
        now.difference(lastInterstitialShownAt!) < cooldown) {
      return false;
    }
    return true;
  }

  void showInterstitial() {
    interstitialShowCount++;
    lastInterstitialShownAt = DateTime.now();
  }

  void showRewarded() {
    rewardedShowCount++;
  }
}

// =============================================================================
// 4. MOCK REVENUECAT
// =============================================================================

class MockRevenueCat {
  final List<Map<String, dynamic>> _purchases = [];
  bool _seasonPassActive = false;

  void setSeasonPass(bool active) => _seasonPassActive = active;
  bool get seasonPassActive => _seasonPassActive;

  void recordPurchase(Map<String, dynamic> purchase) => _purchases.add(purchase);
  List<Map<String, dynamic>> get purchases => List.unmodifiable(_purchases);

  Future<void> restorePurchases() async {
    // No-op mock
  }
}

// =============================================================================
// 5. MOCK FLAME GAME
// =============================================================================

class MockFlameGame {
  bool paused = false;
  void pause() => paused = true;
  void resume() => paused = false;
}

// =============================================================================
// 6. WIDGET TEST UTILITIES
// =============================================================================

/// Trouve la valeur de borderRadius sur un Container décoré.
double? findBorderRadius(WidgetTester tester, Finder finder) {
  final container = tester.widget<Container>(finder);
  final decoration = container.decoration as BoxDecoration?;
  final radius = decoration?.borderRadius as BorderRadius?;
  return radius?.topLeft.x;
}

/// Vérifie qu'aucun descendant de [finder] n'est un ElevatedButton, TextButton,
/// OutlinedButton ou MaterialButton brut.
void expectNoMaterialButtons(WidgetTester tester, {Finder? ancestor}) {
  final elevated = ancestor != null
      ? find.descendant(of: ancestor, matching: find.byType(ElevatedButton))
      : find.byType(ElevatedButton);
  final textBtn = ancestor != null
      ? find.descendant(of: ancestor, matching: find.byType(TextButton))
      : find.byType(TextButton);
  final outlined = ancestor != null
      ? find.descendant(of: ancestor, matching: find.byType(OutlinedButton))
      : find.byType(OutlinedButton);
  final material = ancestor != null
      ? find.descendant(of: ancestor, matching: find.byType(MaterialButton))
      : find.byType(MaterialButton);

  expect(elevated, findsNothing, reason: 'Aucun ElevatedButton brut ne doit etre present');
  expect(textBtn, findsNothing, reason: 'Aucun TextButton brut ne doit etre present');
  expect(outlined, findsNothing, reason: 'Aucun OutlinedButton brut ne doit etre present');
  expect(material, findsNothing, reason: 'Aucun MaterialButton brut ne doit etre present');
}

/// Vérifie qu'un widget donné ne contient pas de couleur grise brute (#808080)
/// ou Colors.grey.
void expectNoBrutalGrey(WidgetTester tester, {Finder? ancestor}) {
  final scope = ancestor ?? find.byType(Widget);
  final containers = find.descendant(of: scope, matching: find.byType(Container));
  for (final element in tester.widgetList(containers)) {
    final container = element as Container;
    final decoration = container.decoration as BoxDecoration?;
    final color = decoration?.color;
    if (color != null) {
      const brutalGrey = Color(0xFF808080);
      expect(
        color != brutalGrey && color != Colors.grey,
        isTrue,
        reason: 'Couleur grise brute interdite detectee',
      );
    }
  }
}
