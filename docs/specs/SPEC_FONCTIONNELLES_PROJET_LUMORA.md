# SPECIFICATIONS FONCTIONNELLES DU PROJET — LUMORA

## Vue d'ensemble

**Projet** : Lumora — Jeu mobile 2D/3D cross-platform (Android/iOS)
**Pitch** : Dans *Lumora*, vous guidez une petite créature de lumière à travers des mondes organiques en connectant des nœuds d’énergie colorée d’un simple glissement, pour réveiller des galaxies assoupies une étincelle à la fois.
**Stack** : Flutter 3.24+ + Flame 1.18+ + Firebase (Auth, Firestore, Functions, Storage, FCM) + Riverpod + GoRouter + RevenueCat + Google Mobile Ads
**Style** : UI 100% organique (pas de boutons carrés gris, pas de bords droits, glassmorphism, dégradés, ombres portées, micro-animations fluides). 2D avec effets 3D (parallaxe, lumières dynamiques, particules, shaders GLSL).
**Public cible** : Large (casual et core gamers, 18–45 ans, accessible à tous, sessions courtes 3–8 min)
**Modèle économique** : Gratuit avec publicités non intrusives (interstitielles + récompensées) + IAP abordables (≤ 4.99 $)

---

## Contraintes Transversales — Couverture Complète

| # | Contrainte | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Statut Global |
|---|------------|---------|---------|---------|---------|---------------|
| 1 | **UI organique** (pas de carrés gris, pas de bords droits) | Plan + Specs + GDD : charte UI/UX, LumoraButton/LumoraCard | Frontend : tous les écrans utilisent LumoraButton (borderRadius 9999, dégradé, ombre) et LumoraCard (glassmorphism, blur, min 16dp) | QA : tests widget vérifient absence ElevatedButton/textButton brut, borderRadius pill | DevOps : screenshots narratifs stores décrivent rendu organique | ✅ COUVERT |
| 2 | **2D avec effets 3D** (parallaxe, lumières, particules, shaders) | GDD : ambiance visuelle, Flame ParallaxComponent, CustomPainter | Frontend : LumoraGame avec parallaxe 3 couches, shaders placeholder, glow via MaskFilter.blur | QA : tests widget vérifient présence Flame GameWidget, CustomPainter | DevOps : metadata stores mentionnent effets 3D | ✅ COUVERT |
| 3 | **Indices visuels décroissants** (délai, opacité, fréquence par palier) | Specs : tableau complet par palier de 10 niveaux (8s/95% → 150s/20%) | Frontend : bouton ampoule organique, HintSystem placeholder | QA : hint_system_test.dart valide courbe décroissante | DevOps : Remote Config hintSystem, A/B testing indices | ✅ COUVERT |
| 4 | **Compte utilisateur + sauvegarde cross-device** (Google/Apple/Email/Anonyme) | Specs : sections 3 et 4, règles RB-AC, RB-SA, fusion progression | Frontend : AuthScreen avec 4 bulles, sync_indicator vert/orange/rouge | QA : offline_sync_test.dart valide résolution conflits | DevOps : metadata mentionne sauvegarde cross-device, DEPLOYMENT_GUIDE config Apple Sign-In | ✅ COUVERT |
| 5 | **Partage social** (capture auto + overlay organique + parrainage) | Specs : section 8, RB-SO, liens dynamiques Firebase | Frontend : VictoryOverlay avec bouton partage bulle bleue | QA : intégration test onboarding → partage | DevOps : metadata mentionne partage natif, DEPLOYMENT_GUIDE config Associated Domains | ✅ COUVERT |
| 6 | **Gratuit + pubs + IAP abordables** (≤ 5 $) | Specs : section 9, RB-MO, prix 0.99–4.99 $ | Frontend : ShopScreen avec cartes organiques, prix visibles | QA : monetization_logic_test.dart valide fréquence pubs, exemption Passe Saisonnier | DevOps : metadata mentionne "Gratuit avec achats intégrés", PEGI/App Store classification | ✅ COUVERT |
| 7 | **Événements automatiques** (défis, tournois, happy hours, saisonniers) | Specs : section 11, RB-EV, calendrier 4 semaines | Backend : eventScheduler.ts + dailyRewardReset.ts idempotentes | QA : tests valident idempotence eventScheduler | DevOps : metadata mentionne événements saisonniers, backend-deploy.yml pour functions | ✅ COUVERT |
| 8 | **Notifications de retour** (24h/72h/7j/14j/30j, segmentées) | Specs : section 10, RB-RE, messages créatifs et ton adapté | Backend : scheduleNotifications.ts avec segments FCM, rate limit 3/jour | QA : tests valident rate limit notifications | DevOps : metadata mentionne notifications, DEPLOYMENT_GUIDE config FCM + fallback locales | ✅ COUVERT |
| 9 | **Sessions courtes, accessible, addictif** | GDD : core loop 3–8 min, carte des émotions, anti-frustration | Frontend : niveaux rapides 30–90s, timer circulaire, victory elastic scale | QA : intégration test parcours complet fluide | DevOps : metadata met en avant sessions courtes, offline-first | ✅ COUVERT |

---

## Livrables par Phase

### Phase 1 — Conception & Spécifications

| Sous-Agent | Fichier livré | Description |
|------------|---------------|-------------|
| **Planificateur** | `docs/Plan_Action.md` | Plan d'action 16 semaines, KPIs cibles, jalons, matrice risques |
| **Planificateur** | `docs/Specifications_Fonctionnelles_Generales.md` | Specs générales 423 lignes : compte, sauvegarde, progression, difficulté, indices, partage, monétisation, rétention, événements, analytics |
| **Game Designer** | `docs/GDD_Resume.md` | GDD 476 lignes : concept unique (Lumie + nœuds d'énergie), univers, core loop, mécaniques, difficulté graduelle, indices décroissants, monétisation, rétention, événements, partage, collection, carte des émotions, différenciation |
| **Architecte** | `docs/Architecture.md` | Architecture 605 lignes : stack justifié, arborescence, schéma Firestore (8 collections), API Cloud Functions (9 endpoints), offline-first, plan revenus, FCM/APNs, sécurité, performance, CI/CD |
| **Agent Principal** | `docs/specs/SPEC_FONCTIONNELLES_Planificateur.md` | Consolidation cas d'usage, user stories, règles métier du Planificateur |
| **Agent Principal** | `docs/specs/SPEC_FONCTIONNELLES_GameDesigner.md` | Consolidation cas d'usage, user stories, règles métier du Game Designer |
| **Agent Principal** | `docs/specs/SPEC_FONCTIONNELLES_Architecte.md` | Consolidation cas d'usage, user stories, règles métier de l'Architecte |

### Phase 2 — Développement

| Sous-Agent | Fichier livré | Description |
|------------|---------------|-------------|
| **Développeur Frontend** | `lib/main.dart` | Entry point Firebase/Flame/AdMob/RevenueCat init |
| **Développeur Frontend** | `lib/app/theme.dart` | Design system Lumora (colors, gradients, shadows, text styles, radii) |
| **Développeur Frontend** | `lib/app/router.dart` | GoRouter avec routes et auth guards |
| **Développeur Frontend** | `lib/shared/widgets/lumora_button.dart` | Bouton organique bulle/dégradé/ombre, jamais bord droit |
| **Développeur Frontend** | `lib/shared/widgets/lumora_card.dart` | Card glassmorphism blur/bordure/coins arrondis |
| **Développeur Frontend** | `lib/shared/widgets/sync_indicator.dart` | Indicateur sync vert/orange/rouge + retry |
| **Développeur Frontend** | `lib/features/auth/presentation/auth_screen.dart` | Écran auth 4 bulles flottantes (Google, Apple, Email, Anonyme) |
| **Développeur Frontend** | `lib/features/game/engine/lumora_game.dart` | Flame Game de base avec parallaxe 3 couches |
| **Développeur Frontend** | `lib/features/game/presentation/game_screen.dart` | Écran jeu overlay organique (vies, timer, pause, indice) |
| **Développeur Frontend** | `lib/features/game/presentation/victory_overlay.dart` | Overlay victoire étoiles elastic scale, boutons organiques |
| **Développeur Frontend** | `lib/features/game/presentation/world_map_screen.dart` | Carte mondes bulles flottantes + Bézier |
| **Développeur Frontend** | `lib/features/monetization/presentation/shop_screen.dart` | Boutique scroll horizontal organique |
| **Développeur Frontend** | `lib/features/settings/presentation/settings_screen.dart` | Paramètres cartes organiques empilées, toggles iOS-style |
| **Développeur Frontend** | `lib/features/events/presentation/events_screen.dart` | Événements cartes organiques, compte à rebours |
| **Développeur Frontend** | `lib/STYLE_GUIDE.md` | Guide UI organique (règles, tokens, composants, anti-patterns) |
| **Développeur Backend** | `backend/functions/src/index.ts` | Point d'entrée Functions v2 |
| **Développeur Backend** | `backend/functions/src/checkQuota.ts` | Anti-triche quota |
| **Développeur Backend** | `backend/functions/src/dailyRewardReset.ts` | Reset récompenses 00:00 UTC |
| **Développeur Backend** | `backend/functions/src/eventScheduler.ts` | Ordonnancement événements automatiques |
| **Développeur Backend** | `backend/functions/src/leaderboardUpdate.ts` | Agrégation scores tournoi |
| **Développeur Backend** | `backend/functions/src/purchaseValidation.ts` | Validation webhook RevenueCat + double-check |
| **Développeur Backend** | `backend/functions/src/referralCredit.ts` | Crédit parrainage |
| **Développeur Backend** | `backend/functions/src/mergeAnonymousData.ts` | Fusion compte anonyme → authentifié |
| **Développeur Backend** | `backend/functions/src/scheduleNotifications.ts` | Notifications FCM segmentées |
| **Développeur Backend** | `backend/functions/src/deleteUserData.ts` | Suppression GDPR |
| **Développeur Backend** | `backend/functions/package.json` / `tsconfig.json` | Dépendances et config TypeScript |
| **Développeur Backend** | `devops/firebase/firestore.rules` | Règles user-scoped strictes |
| **Développeur Backend** | `devops/firebase/firestore.indexes.json` | Index composites leaderboard + events |
| **Développeur Backend** | `devops/firebase/remote_config_defaults.json` | Valeurs par défaut config dynamique |
| **Agent Principal** | `docs/specs/SPEC_FONCTIONNELLES_DeveloppeurFrontend.md` | Consolidation Frontend |
| **Agent Principal** | `docs/specs/SPEC_FONCTIONNELLES_DeveloppeurBackend.md` | Consolidation Backend |

### Phase 3 — Test & Validation Visuelle

| Sous-Agent | Fichier livré | Description |
|------------|---------------|-------------|
| **QA Visuel** | `tests/unit/hint_system_test.dart` | Logique indices décroissants par palier |
| **QA Visuel** | `tests/unit/monetization_logic_test.dart` | Fréquence pubs, exemption Passe, cooldown |
| **QA Visuel** | `tests/unit/offline_sync_test.dart` | Résolution conflits max étoiles/somme consommables |
| **QA Visuel** | `tests/widget/lumora_button_test.dart` | Absence bords droits, couleur non grise |
| **QA Visuel** | `tests/widget/lumora_card_test.dart` | Glassmorphism blur, borderRadius >= 16, ombre |
| **QA Visuel** | `tests/widget/auth_screen_test.dart` | 4 bulles organiques, absence ElevatedButton brut |
| **QA Visuel** | `tests/widget/game_screen_test.dart` | Timer circulaire, pause bulle, indice ampoule |
| **QA Visuel** | `tests/widget/shop_screen_test.dart` | Cartes organiques, scroll horizontal, pas de grille carrée |
| **QA Visuel** | `tests/integration/onboarding_to_level_test.dart` | Parcours complet splash → auth → niveau → victoire → partage |
| **QA Visuel** | `tests/test_helpers.dart` | Mocks AdMob, RevenueCat, Firebase, Flame |
| **QA Visuel** | `tests/QA_REPORT.md` | Rapport qualité complet, 61 scénarios, verdict **GO** |
| **Agent Principal** | `docs/specs/SPEC_FONCTIONNELLES_QAVisuel.md` | Consolidation QA |

### Phase 4 — Déploiement & Suivi

| Sous-Agent | Fichier livré | Description |
|------------|---------------|-------------|
| **DevOps** | `devops/github/workflows/ci.yml` | Pipeline CI (analyze + test + coverage + Codecov) |
| **DevOps** | `devops/github/workflows/cd.yml` | Pipeline CD (build release + Fastlane deploy stores) |
| **DevOps** | `devops/github/workflows/backend-deploy.yml` | Déploiement Cloud Functions |
| **DevOps** | `devops/fastlane/android/Fastfile` | Lanes internal / beta / production graduelle |
| **DevOps** | `devops/fastlane/ios/Fastfile` | Lanes beta TestFlight / release App Store |
| **DevOps** | `devops/fastlane/README.md` | Procédure Fastlane |
| **DevOps** | `devops/firebase/analytics_setup.md` | Configuration Analytics + events custom |
| **DevOps** | `devops/firebase/crashlytics_setup.md` | Configuration Crashlytics |
| **DevOps** | `devops/firebase/remote_config_setup.md` | Configuration Remote Config + A/B testing |
| **DevOps** | `devops/firebase/ab_testing_plan.md` | Plan 5 tests A/B détaillé |
| **DevOps** | `devops/stores/play_store_metadata.md` | Fiche Google Play localisée FR/EN/ES/DE |
| **DevOps** | `devops/stores/app_store_metadata.md` | Fiche App Store localisée FR/EN/ES/DE |
| **DevOps** | `devops/monitoring/kpi_dashboard.md` | Dashboard KPIs (retention, revenus, performance) |
| **DevOps** | `devops/monitoring/alerting_rules.md` | Règles d'alerte et seuils |
| **DevOps** | `devops/DEPLOYMENT_GUIDE.md` | Guide de déploiement complet + plan rollback |
| **Agent Principal** | `docs/specs/SPEC_FONCTIONNELLES_DevOps.md` | Consolidation DevOps |

---

## KPIs Cibles

| KPI | Cible | Outil de mesure |
|-----|-------|-----------------|
| D1 Retention | ≥ 45% | Firebase Analytics |
| D7 Retention | ≥ 20% | Firebase Analytics |
| D30 Retention | ≥ 10% | Firebase Analytics |
| ARPDAU | ≥ 0.05$ | RevenueCat + AdMob |
| LTV | ≥ 2.50$ | RevenueCat + Analytics |
| Conversion IAP | ≥ 3% | RevenueCat |
| Temps session moyen | ≥ 8 min | Firebase Analytics |
| Niveaux complétés / session | ≥ 3 | Firebase Analytics |
| Crash rate | < 1% | Crashlytics |
| Jank | < 5% | Flutter Performance |

---

## Planning Macro

| Semaine | Phase | Activités |
|---------|-------|-----------|
| S1–S4 | Phase 1 | Conception : GDD, Specs, Architecture, Charte UI |
| S5–S12 | Phase 2 | Développement : Frontend Flutter + Backend Firebase |
| S13–S14 | Phase 3 | QA : Tests unitaires/widget/intégration, bêta fermée |
| S15–S16 | Phase 4 | Déploiement : CI/CD, soumission stores, release graduelle |
| M2–M6 | Post-Launch | Itérations : A/B testing, événements, nouveaux niveaux, optimisation LTV |

---

## Glossaire

| Terme | Définition |
|-------|------------|
| **UI organique** | Design sans bords droits, formes arrondies, dégradés, glassmorphism, ombres portées |
| **2D+3D** | Rendu 2D avec effets de profondeur (parallaxe, lumières, particules, shaders) |
| **Indices décroissants** | Système d'aide visuelle dont l'intensité (opacité, délai, fréquence) diminue avec la progression |
| **IAP abordables** | Achats intégrés à moins de 5 $ pour maximiser la conversion |
| **Événements automatiques** | Événements programmés déclenchés par Cloud Functions sans action manuelle |
| **ARPDAU** | Average Revenue Per Daily Active User |
| **LTV** | Lifetime Value — valeur totale générée par un utilisateur |

---

*Document de synthèse final — Projet Lumora — Généré le 2026-05-07*
*Architecte principal : Agent Principal Claude Code*
*Sous-agents contributifs : Planificateur, Game Designer, Architecte, Développeur Frontend, Développeur Backend, QA Visuel, DevOps*
