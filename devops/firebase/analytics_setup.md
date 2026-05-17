# Firebase Analytics — Setup Guide

## Objectif
Tracker le parcours joueur, la rétention, la monétisation et l'engagement via des événements custom et des audiences segmentées.

## 1. Événements Custom (obligatoires)

| Événement | Paramètres | Déclenchement | Contrainte transversale couverte |
|-----------|------------|---------------|----------------------------------|
| `level_start` | `level_id` (int), `world_id` (int), `difficulty_tier` (int) | Début niveau | Gameplay, 2D+3D |
| `level_complete` | `level_id`, `stars` (1–3), `time_spent` (s), `hints_used` (int), `retry_count` (int) | Victoire | Progression, indices décroissants |
| `level_fail` | `level_id`, `time_spent`, `fail_reason` (timeout/mistake/quit) | Défaite | Anti-frustration |
| `hint_auto_shown` | `level_id`, `delay_s`, `opacity` (%), `tier` (1–5) | Indice auto affiché | Indices décroissants |
| `hint_manual_used` | `level_id`, `source` (free/ad/rewarded) | Indice manuel utilisé | Accessibilité |
| `ad_interstitial_show` | `level_id_after`, `frequency_config` (int) | Interstitielle affichée | Monétisation (pubs) |
| `ad_rewarded_show` | `reward_type`, `placement` (home/defeat/shop) | Récompensée visionnée | Monétisation (pubs) |
| `iap_purchase` | `product_id`, `price_usd` (double), `revenuecat_transaction_id` | Achat validé | Monétisation (IAP abordables) |
| `share_screenshot` | `network` (instagram/facebook/whatsapp/etc.), `level_id`, `stars` | Partage effectué | Partage social |
| `daily_reward_claim` | `day_number` (1–7), `streak_count` (int), `reward_type` | Récompense quotidienne récupérée | Rétention |
| `notification_open` | `notification_id` (string), `delay_since_last_open` (h) | Notification cliquée | Notifications de retour |
| `event_participate` | `event_type` (daily/weekend/seasonal/tournament), `event_id` | Inscription événement | Événements automatiques |
| `auth_link` | `source` (anonymous_to_google/apple/email) | Liaison compte | Compte utilisateur |
| `cross_device_restore` | `device_type_new` (android/ios), `sync_duration_ms` (int) | Restauration cross-device | Sauvegarde cross-device |

## 2. Configuration SDK Flutter

```dart
// main.dart
import 'package:firebase_analytics/firebase_analytics.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

await analytics.logEvent(
  name: 'level_complete',
  parameters: {
    'level_id': 42,
    'stars': 3,
    'time_spent': 45,
    'hints_used': 0,
    'retry_count': 1,
  },
);
```

## 3. Audiences Segments

| Audience | Critère | Usage |
|----------|---------|-------|
| **Payers** | `iap_purchase` > 0 | Offres premium, pas de pubs, accès anticipé |
| **Churners 7j** | Dernière session > 7j | Notification retour "Ta flamme s'éteint…" |
| **Churners 30j** | Dernière session > 30j | "Lumora a changé !" + nouveautés |
| **High Engagement** | >= 3 sessions/jour, >= 10 niveaux/semaine | Cohorte A/B testing avancé |
| **Non-Payers** | 0 achat, > 20 vidéos récompensées | Prix IAP réduits via Remote Config |
| **Near Perfect** | 2 étoiles sur niveau difficile depuis 24h | "Il ne te manque qu'une étincelle !" |

## 4. Configuration Console Firebase

1. Activer **Google Analytics** dans le projet Firebase.
2. Lier la propriété GA4 (data stream Android + iOS).
3. Importer les événements custom ci-dessus dans **Custom definitions**.
4. Créer les audiences dans **Audiences** > **New audience**.
5. Activer **DebugView** en développement (`adb shell setprop debug.firebase.analytics.app com.lumora.game`).

## 5. Conformité GDPR / COPPA

- Demander le consentement explicite avant d'activer Analytics (écran onboarding organique).
- Si l'utilisateur déclare < 13 ans (COPPA), désactiver la collection d'ID publicitaire et anonymiser les données.
- Documenter le consentement dans `users/{uid}/settings/consents`.
