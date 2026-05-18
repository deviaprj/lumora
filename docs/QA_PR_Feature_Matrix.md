# QA / PR Feature Matrix - Lumora (Beta)

Version: 2026-05-18
Usage: reference unique pour QA manuelle, QA auto et PR review

Colonnes:
- Feature: capacite produit verifiee
- Fichiers: fichiers runtime principaux
- Statut: IMPLEMENTE / PARTIEL / NON IMPLEMENTE
- Tests existants: tests actuellement presents
- Tests manquants: couverture a ajouter

| Feature | Fichiers | Statut | Tests existants | Tests manquants |
|---|---|---|---|---|
| Gameplay core (vies/coups/score/victoire/defaite) | lib/features/game/engine/game_state.dart; lib/features/game/engine/lumora_game.dart; lib/features/game/presentation/game_screen.dart | IMPLEMENTE | test/game_state_test.dart; test/features/game/engine/game_interaction_test.dart; integration_test/full_device_test.dart (cases 09-14) | Tests integration device reels sur gestures Flame complexes (drag multi-touch + combo visuel) |
| Niveaux artisanaux + progression procedurale | lib/features/game/domain/level_data.dart | IMPLEMENTE | test/game_state_test.dart (LevelCatalog) | Test golden/perf sur generation procedurale longue (100+ niveaux) |
| Indice manuel en jeu | lib/features/game/engine/game_state.dart; lib/features/game/engine/lumora_game.dart; lib/features/game/presentation/game_screen.dart | IMPLEMENTE | test/game_state_test.dart (useHint); integration_test/full_device_test.dart (case 14) | Test widget sur bouton indice + feedback UI in-game |
| HintSystem automatique decroissant (palier) | lib/features/settings/presentation/settings_screen.dart (toggle seulement) | PARTIEL | Aucun test metier auto-hint actif | Tests unitaires + widget sur delai/opacite/frequence par palier apres implementation |
| Objectifs secondaires et maitrise | lib/features/game/domain/level_data.dart; lib/features/game/engine/game_state.dart; lib/features/monetization/data/reward_inventory.dart; lib/features/game/presentation/victory_overlay.dart | IMPLEMENTE | test/features/monetization/reward_inventory_test.dart; test/features/game/presentation/world_map_screen_test.dart; test/game_state_test.dart (rising flow) | Test integration complet run -> victoire -> recompenses -> map badge |
| Inventaire persistant rewards (cooldowns/charges) | lib/features/monetization/data/reward_inventory.dart | IMPLEMENTE | test/features/monetization/reward_inventory_test.dart | Test migration de schema prefs (backward compatibility) |
| Rewarded ads (service central) | lib/features/monetization/data/rewarded_ad_service.dart; lib/features/game/presentation/game_screen.dart; lib/features/monetization/presentation/shop_screen.dart; lib/features/events/presentation/events_screen.dart | IMPLEMENTE | Tests de logique inventaire/cooldown indirects | Tests integration avec AdMob fake/stub pour valider callbacks onRewardEarned |
| Defaite -> video 1 +1 vie, video 2 +2 vies | lib/features/game/presentation/game_screen.dart; lib/features/game/engine/game_state.dart | IMPLEMENTE | test/features/game/engine/game_interaction_test.dart (grantLives/retry), test/game_state_test.dart | Test widget scenario complet overlay defaite + double video |
| World map filtres maitrise + jump | lib/features/game/presentation/world_map_screen.dart | IMPLEMENTE | test/features/game/presentation/world_map_screen_test.dart | Test UX navigation sur device reel (latence + transitions) |
| Progression locale joueur | lib/features/game/data/player_progression_service.dart | IMPLEMENTE | test/features/game/data/player_progression_service_test.dart | Test concurrence ecriture multi-ecrans |
| Auth providers Google/Apple/Facebook/Anonyme | lib/features/auth/data/auth_service.dart; lib/features/auth/presentation/auth_screen.dart; lib/app/router.dart | IMPLEMENTE | integration_test/full_game_test.dart (UI auth); integration_test/full_device_test.dart (case 01) | Tests mocks pour chaque provider + erreurs provider par code |
| Auth email par code (send/verify/finalize) | lib/features/auth/data/auth_service.dart; backend/functions/src/emailVerification.ts; backend/functions/src/index.ts | IMPLEMENTE | Couverture backend compile OK (build), smoke startup callable | Tests unitaires backend sur TTL/attempts/token consume + tests client mock callable |
| Guard routeur FirebaseAuth | lib/app/router.dart | IMPLEMENTE | integration_test/full_device_test.dart (navigations), couverture indirecte | Test widget explicite redirect matrix (auth/non-auth) |
| Smoke startup auth staging | lib/features/auth/data/auth_startup_smoke.dart; lib/main.dart | IMPLEMENTE | Verification manuelle logs + activation dart-define | Test integration dedie STAGING_SMOKE_AUTH=true avec assertions de checks |
| Evenements ecran mobile | lib/features/events/presentation/events_screen.dart | IMPLEMENTE | integration_test/full_device_test.dart (case 06) | Test widget complet sur cooldown display + CTA etat pending |
| Scheduler/events backend | backend/functions/src/eventScheduler.ts; backend/functions/src/dailyRewardReset.ts; backend/functions/src/index.ts | PARTIEL | Build backend functions (TypeScript) | Tests unitaires backend pour idempotence et priorites evenement |
| Notifications retention end-to-end | backend/functions/src/scheduleNotifications.ts; lib/features/settings/presentation/settings_screen.dart | PARTIEL | Couverture backend partielle via build | Tests bout-en-bout FCM + preferences utilisateur + opt-in |
| Partage social fin de niveau | lib/features/game/presentation/victory_overlay.dart (CTA present) | NON IMPLEMENTE (E2E) | Aucun test E2E partage | Tests integration capture + share sheet + attribution |
| Analytics metier | lib/core/utils/analytics.dart | PARTIEL | Couverture indirecte via gameplay reward flow | Tests unitaires payloads analytics + tests de non-regression event names |
| Securite secrets / env scripts | scripts/deploy_firebase_env.sh; scripts/deploy_mobile_env.sh; .env.*.example | IMPLEMENTE (ops) | Verification manuelle scripts + preflight | Tests shell automatises (lint shellcheck + dry-run CI) |
| Build Android naming binaire | android/app/build.gradle; android/app/src/main/AndroidManifest.xml | IMPLEMENTE | Verification build manuelle des artefacts | Test CI qui valide noms APK et output-metadata.json |

## Checklist PR reviewer (obligatoire)

1. La feature modifiee existe dans la matrice.
2. Le statut a ete mis a jour (IMPLEMENTE/PARTIEL/NON IMPLEMENTE).
3. Les tests existants ont ete executes et notes.
4. Les tests manquants ont un ticket de suivi (si non couverts dans la PR).
5. Si feature BLOQUANT BETA: preuve d'execution des gates A-D dans la PR.

## Format de mise a jour recommande dans une PR

- Feature:
- Statut avant:
- Statut apres:
- Fichiers touches:
- Tests executes:
- Tests manquants crees en ticket:
