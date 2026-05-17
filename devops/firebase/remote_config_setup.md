# Firebase Remote Config — Setup Guide

## Objectif
Modifier les paramètres de gameplay, de monétisation et de difficulté à la volée sans mise à jour de l'app, et supporter les tests A/B.

## 1. Paramètres configurés

| Paramètre | Type | Valeur par défaut | Description | Contrainte couverte |
|-----------|------|-------------------|-------------|---------------------|
| `hintSystem` | JSON | `{ "delay": 15, "opacity": 0.9, "frequency": 1 }` | Configuration globale du HintSystem | Indices décroissants |
| `ad_interstitial_every_n_levels` | int | 5 | Fréquence des interstitielles (1 pub tous les N niveaux) | Monétisation (pubs) |
| `iap_prices_tier_a` | string | "0.99" | Prix pack 5 vies | Monétisation (IAP) |
| `iap_prices_tier_b` | string | "2.99" | Prix pack 20 vies | Monétisation (IAP) |
| `iap_prices_tier_c` | string | "4.99" | Prix pack 50 vies + Passe Saisonnier | Monétisation (IAP) |
| `difficulty_curve_multiplier` | double | 1.0 | Multiplicateur temps/obstacles (1.0 = design nominal) | Difficulté graduelle |
| `event_schedule` | JSON | `{ "daily": "00:00", "weekend": "Fri 20:00", "tournament": "Mon 00:00" }` | Horaires événements UTC | Événements automatiques |
| `ui_theme_variant` | string | "organic" | Variante UI (organic / seasonal_halloween / seasonal_xmas) | UI organique |
| `streak_break_policy` | string | "reset" | Politique streak : reset / minus_one / freeze | Rétention |

## 2. Fallback local

Si Remote Config est indisponible (offline ou timeout > 5s), l'app utilise `assets/remote_config_defaults.json` embarqué dans le build.

```json
{
  "hintSystem": {"delay":15,"opacity":0.9,"frequency":1},
  "ad_interstitial_every_n_levels": 5,
  "iap_prices_tier_a": "0.99",
  "iap_prices_tier_b": "2.99",
  "iap_prices_tier_c": "4.99",
  "difficulty_curve_multiplier": 1.0,
  "event_schedule": {"daily":"00:00","weekend":"Fri 20:00","tournament":"Mon 00:00"},
  "ui_theme_variant": "organic",
  "streak_break_policy": "reset"
}
```

## 3. Configuration SDK Flutter

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

final remoteConfig = FirebaseRemoteConfig.instance;

await remoteConfig.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 5),
  minimumFetchInterval: const Duration(minutes: 15),
));

await remoteConfig.setDefaults(<String, dynamic>{
  'ad_interstitial_every_n_levels': 5,
  'difficulty_curve_multiplier': 1.0,
});

await remoteConfig.fetchAndActivate();

final adFrequency = remoteConfig.getInt('ad_interstitial_every_n_levels');
```

## 4. Procédure A/B Testing via Remote Config

1. **Créer une expérience** dans Firebase Console > Remote Config > A/B Testing.
2. **Choisir l'objectif** : revenu (AdMob + IAP), rétention D1/D7, ou taux de conversion IAP.
3. **Définir les variants** : modifier le paramètre cible (ex. `ad_interstitial_every_n_levels` à 3, 5, 7).
4. **Sélectionner l'audience** : 100 % nouveaux utilisateurs ou segment spécifique (payers, churners…).
5. **Durée minimum** : 7 jours, 1000 utilisateurs par variante.
6. **Rollout progressif** : 10 % > 50 % > 100 % de l'audience cible.

## 5. Contraintes transversales

- **UI organique** : le paramètre `ui_theme_variant` permet des variations saisonnières tout en maintenant les principes d'arrondi et glassmorphism.
- **2D+3D** : `difficulty_curve_multiplier` ajuste la vitesse parallaxe et le nombre d'obstacles dynamiques.
- **Indices décroissants** : `hintSystem` permet de régler globalement le délai, l'opacité et la fréquence sans rebuild.
- **Monétisation** : les prix IAP peuvent être ajustés par région et par cohorte en temps réel.
