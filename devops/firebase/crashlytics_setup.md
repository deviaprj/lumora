# Firebase Crashlytics — Setup Guide

## Objectif
Capturer les crashs, ANR et exceptions non gérées avec un contexte de gameplay riche pour un debug rapide.

## 1. Configuration SDK Flutter

```dart
// main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Capture erreurs Flutter
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Capture erreurs isolées (async)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const LumoraApp());
}
```

## 2. Custom Keys (contexte gameplay)

| Clé | Type | Description |
|-----|------|-------------|
| `current_level` | int | Niveau en cours au moment du crash |
| `current_world` | int | Monde courant |
| `device_tier` | string | low/mid/high (selon RAM / GPU) |
| `screen_dpi` | int | Densité d'écran |
| `audio_enabled` | bool | Musique/SFX activés |
| `hints_auto` | bool | Indices automatiques activés |
| `session_duration_sec` | int | Durée de la session en secondes |
| `iap_active` | bool | Passe saisonnier actif |

```dart
await FirebaseCrashlytics.instance.setCustomKey('current_level', gameNotifier.currentLevel);
await FirebaseCrashlytics.instance.setCustomKey('session_duration_sec', sessionTracker.duration.inSeconds);
```

## 3. Reporting Automatique

- **Crashs natifs Android/iOS** : automatique via Firebase Crashlytics plugin.
- **ANR** : activés dans Firebase Console > Crashlytics > Settings > ANR reporting.
- **Nightly digest** : activer l'email récapitulatif dans les préférences de la console.

## 4. Symbols et dSYM

### Android
Aucune action requise pour les builds Flutter standard (obfuscation désactivée en debug, mapping ProGuard uploadé en release si `minifyEnabled true`).

### iOS
Uploader automatiquement les dSYM via une run script dans Xcode :
```bash
# Build Phases > New Run Script Phase
"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp ${SRCROOT}/Runner/GoogleService-Info.plist -p ios ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
```
Ou via Fastlane après build :
```ruby
upload_symbols_to_crashlytics(gsp_path: "./Runner/GoogleService-Info.plist")
```

## 5. Seuils d'alerte

Voir `monitoring/alerting_rules.md` pour les règles :
- Crash rate > 1 % sur 1h
- ANR rate > 0.5 % sur 1h

## 6. Intégration avec CI/CD

Le build release Android et iOS doit activer le flag `--obfuscate` uniquement en production avec un mapping uploadé :
```bash
flutter build appbundle --release --obfuscate --split-debug-info=symbols/
```
