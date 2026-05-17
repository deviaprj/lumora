# SPEC_FONCTIONNELLES_DevOps.md — Lumora

## Livrables source
- `devops/github/workflows/ci.yml` — Pipeline CI (analyze + test + coverage)
- `devops/github/workflows/cd.yml` — Pipeline CD (build release + Fastlane deploy stores)
- `devops/github/workflows/backend-deploy.yml` — Déploiement Cloud Functions
- `devops/fastlane/android/Fastfile` — Lanes internal / beta / production (graduelle)
- `devops/fastlane/ios/Fastfile` — Lanes beta (TestFlight) / release (App Store)
- `devops/fastlane/README.md` — Procédure Fastlane
- `devops/firebase/analytics_setup.md` — Configuration Analytics + events custom
- `devops/firebase/crashlytics_setup.md` — Configuration Crashlytics
- `devops/firebase/remote_config_setup.md` — Configuration Remote Config + A/B testing
- `devops/firebase/ab_testing_plan.md` — Plan 5 tests A/B détaillé
- `devops/stores/play_store_metadata.md` — Fiche Google Play (FR/EN/ES/DE)
- `devops/stores/app_store_metadata.md` — Fiche App Store (FR/EN/ES/DE)
- `devops/monitoring/kpi_dashboard.md` — Dashboard KPIs (retention, revenus, performance)
- `devops/monitoring/alerting_rules.md` — Règles d'alerte et seuils
- `devops/DEPLOYMENT_GUIDE.md` — Guide de déploiement complet

---

## Résumé DevOps
**CI** : GitHub Actions 12–18 min (push/PR) — pub get, build_runner, analyze, test --coverage, Codecov
**CD** : GitHub Actions + Fastlane 25–35 min (tag v*) — build AAB/iOS signé, upload Google Play (internal/beta/production graduelle 10/50/100%), upload TestFlight/App Store Connect
**Backend** : GitHub Actions 4–6 min (push backend/functions) — npm ci, eslint, tsc, firebase deploy --only functions

## Cas d'usage consolidés

| ID | Cas d'usage | Acteur | Description |
|----|-------------|--------|-------------|
| UC-DO-01 | Exécuter la CI | Développeur | À chaque push/PR, lancer analyze + tests + coverage |
| UC-DO-02 | Déployer sur les stores | DevOps | Build signé, upload Google Play / App Store Connect, release graduelle |
| UC-DO-03 | Configurer Firebase Analytics | Product Owner | Events custom, audiences, funnels conversion |
| UC-DO-04 | Configurer A/B Testing | Product Owner | 5 tests A/B via Remote Config (pubs, prix, difficulté, indices, streak) |
| UC-DO-05 | Monitorer les KPIs | Product Owner / Lead | Dashboard D1/D7/D30, ARPDAU, LTV, crash rate, eCPM |
| UC-DO-06 | Recevoir des alertes | Équipe technique | Crash rate > 1%, retention < 40%, ARPDAU < 0.03$, erreurs Functions > 5/min |
| UC-DO-07 | Soumettre aux stores | Product Owner | Fiches produit, screenshots narratifs, descriptions localisées |
| UC-DO-08 | Rollback en urgence | DevOps | Revenir à la version précédente, rollback rules/functions |

## User stories consolidées

| ID | User Story | Critères d'acceptation |
|----|------------|------------------------|
| US-DO-01 | En tant que développeur, je veux une CI automatisée, afin de garantir la qualité à chaque push. | ci.yml : flutter analyze --no-fatal-infos, flutter test --coverage, upload Codecov. |
| US-DO-02 | En tant que DevOps, je veux un déploiement graduel automatisé, afin de limiter les risques en production. | cd.yml + Fastlane : release graduelle 10% → 50% → 100% Google Play ; TestFlight → App Store. |
| US-DO-03 | En tant que product owner, je veux des tests A/B configurables, afin d'optimiser les revenus sans mise à jour app. | ab_testing_plan.md : 5 tests, variants, audiences, durées 7+j, significance 1000+ joueurs/variante. |
| US-DO-04 | En tant que product owner, je veux un monitoring des KPIs, afin de prendre des décisions data-driven. | kpi_dashboard.md : retention, ARPDAU, LTV, conversion IAP, crash rate, eCPM, temps session. |
| US-DO-05 | En tant que product owner, je veux des fiches stores optimisées, afin de maximiser les conversions d'install. | Metadata localisées FR/EN/ES/DE, 5 screenshots narratifs décrivant le rendu organique, keywords optimisés. |
| US-DO-06 | En tant que DevOps, je veux un plan de rollback, afin de réagir rapidement en cas de problème critique. | DEPLOYMENT_GUIDE.md : rollback stores, rollback Firestore rules, rollback Cloud Functions, hotfix branch. |

## Règles fonctionnelles livrées (sélection)

### CI/CD
- **RB-CI-01** : ci.yml déclenché sur push/PR main/develop/feat/**. Durée 12–18 min.
- **RB-CI-02** : cd.yml déclenché sur tag v* ou workflow_dispatch. Build AAB release signé + iOS signé. Upload Fastlane. Durée 25–35 min.
- **RB-CI-03** : backend-deploy.yml déclenché sur push modifiant backend/functions/**. npm ci, eslint, tsc, firebase deploy --only functions.
- **RB-CI-04** : Secrets GitHub : ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, IOS_MATCH_PASSWORD, FIREBASE_TOKEN, SLACK_WEBHOOK.
- **RB-CI-05** : Dart defines pour API keys (AdMob, DeepSeek/OpenRouter) injectées au build, jamais en dur dans le repo.

### Fastlane
- **RB-FL-01** : Android lanes : internal (APK debug → Internal Testing), beta (AAB → Closed Testing), production (AAB → Production graduelle).
- **RB-FL-02** : iOS lanes : beta (build → TestFlight internal), release (build → App Store Connect + submit).
- **RB-FL-03** : Match pour provisioning profiles et certificats iOS.

### Firebase Configuration
- **RB-FB-01** : Analytics : events custom level_start, level_complete, iap_purchase, ad_show, share, notification_open. Audiences payers/churners/high_engagement.
- **RB-FB-02** : Crashlytics : reporting automatique, custom keys (niveau en cours, device info).
- **RB-FB-03** : Remote Config : hintSystem, ad_interstitial_every_n_levels, iap_prices_tier_a/b/c, difficulty_curve_multiplier, event_schedule. Mise à jour temps réel 15 min max.
- **RB-FB-04** : A/B Testing plan : 5 tests avec variants, audiences, durées min 7j, significance 1000+ joueurs/variante.

### Stores Metadata
- **RB-ST-01** : Play Store : titre 30 car, description courte 80 car, description longue, 5 screenshots narratifs, keywords, PEGI.
- **RB-ST-02** : App Store : titre 30 car, sous-titre 30 car, description, 5 screenshots narratifs, keywords 100 car.
- **RB-ST-03** : Localisation FR / EN / ES / DE. Mentions "Gratuit avec achats intégrés optionnels", Passe Saisonnier, événements saisonniers.

### Monitoring
- **RB-MO-01** : KPIs : D1/D7/D30 retention, ARPDAU, LTV, conversion IAP, crash rate, ANR, eCPM, fill rate, temps session, niveaux complétés.
- **RB-MO-02** : Alertes : crash rate > 1% → P1, D1 retention < 40% → P1, ARPDAU < 0.03$ → P2, Functions erreurs > 5/min → P2, Firestore reads > 100k/jour → P3.

### Déploiement
- **RB-DP-01** : Prérequis : comptes Apple Developer, Google Play Console, Firebase project, GitHub Secrets configurés.
- **RB-DP-02** : Post-launch M2–M6 : ajustement courbe difficulté, événement saisonnier, tournoi hebdo, nouveaux niveaux, Passe Saisonnier 2, optimisation LTV.
- **RB-DP-03** : Rollback : reversion version store, rollback Firestore rules via git, rollback Functions via firebase deploy --only functions:previous.

---

*Document consolidé par l'Agent Principal — Projet Lumora — 2026-05-07*
