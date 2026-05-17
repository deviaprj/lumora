import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flame/flame.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/firebase_options_fallback.dart';
import 'features/game/data/player_progression_service.dart';

/// Entry point Lumora — initialise Firebase, Flame, AdMob, RevenueCat puis runApp.
///
/// Les SDKs Firebase/AdMob/RevenueCat ne sont initialisés que lorsque les
/// clés sont fournies via `--dart-define`. Sur Linux desktop (développement)
/// ou si les clés manquent, l'application continue sans eux.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement (mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialisation Flame (assets, device, fullscreen)
  await Flame.device.fullScreen();
  await Flame.device.setOrientation(DeviceOrientation.portraitUp);

  // Initialisation conditionnelle des SDK tiers
  await _initializeThirdPartySDKs();
  await PlayerProgressionService.instance.load();

  runApp(
    const ProviderScope(
      child: LumoraApp(),
    ),
  );
}

Future<void> _initializeThirdPartySDKs() async {
  try {
    // Firebase — tentative native d'abord, fallback via dart-define si les fichiers
    // natifs ne sont pas embarqués dans le repo courant.
    if ((Platform.isAndroid || Platform.isIOS || Platform.isMacOS) && Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (nativeError) {
        final fallbackOptions = FirebaseOptionsFallback.currentPlatform;
        if (fallbackOptions == null) {
          rethrow;
        }

        debugPrint('Firebase native init unavailable, fallback to dart-define options: $nativeError');
        await Firebase.initializeApp(options: fallbackOptions);
      }
    }

    // AdMob — initialisé uniquement sur mobile et si la clé est présente
    const admobAppId = String.fromEnvironment('ADMOB_ANDROID_APP_ID');
    if (admobAppId.isNotEmpty && (Platform.isAndroid || Platform.isIOS)) {
      // TODO: await MobileAds.instance.initialize();
    }

    // RevenueCat — initialisé uniquement sur mobile et si la clé est présente
    const revenueCatKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
    if (revenueCatKey.isNotEmpty && (Platform.isAndroid || Platform.isIOS)) {
      // TODO: await Purchases.configure(PurchasesConfiguration(revenueCatKey));
    }
  } catch (e) {
    // En développement, les SDK peuvent ne pas être disponibles
    debugPrint('Third-party SDK initialization skipped or failed: $e');
  }
}

class LumoraApp extends StatelessWidget {
  const LumoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lumora',
      debugShowCheckedModeBanner: false,
      theme: LumoraTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
