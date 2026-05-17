# Guide de Déploiement Complet — Lumora

Ce document couvre l'ensemble du pipeline CI/CD, la soumission aux stores, la configuration Firebase post-deploy et le plan de rollback pour le projet Lumora.

---

## 1. Prérequis

### Comptes et accès

| Service | Compte requis | Usage |
|---------|---------------|-------|
| Google Play Console | Compte développeur (25 $) | Publication Android, IAP, PEGI |
| Apple Developer | Compte développeur (99 $/an) | Publication iOS, TestFlight, sign match |
| Firebase | Projet Firebase (blaze plan recommandé) | Auth, Firestore, Functions, Analytics, FCM |
| RevenueCat | Compte RevenueCat | IAP cross-platform, webhooks |
| AdMob | Compte AdMob lié à Google Play | Pubs interstitielles + récompensées |
| GitHub | Repository privé | CI/CD Actions, secrets, releases |
| Slack / Discord | Webhook URL | Notifications pipeline |

### Secrets GitHub à configurer

- `ANDROID_KEYSTORE_BASE64` — Keystore encodé base64
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `GOOGLE_PLAY_JSON_KEY` — Clé de service Google Play Console (JSON)
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT` — Clé .p8 App Store Connect
- `MATCH_PASSWORD` — Mot de passe du repo match (certificats iOS)
- `FIREBASE_CI_TOKEN` — Token Firebase CLI pour déploiement functions
- `FIREBASE_PROJECT_ID`
- `FIREBASE_API_KEY`
- `ADMOB_ANDROID_APP_ID`
- `ADMOB_IOS_APP_ID`
- `REVENUECAT_ANDROID_KEY`
- `REVENUECAT_IOS_KEY`
- `SLACK_WEBHOOK_URL` (optionnel)
- `DISCORD_WEBHOOK_URL` (optionnel)

---

## 2. Configuration initiale

### 2.1 Fastlane

```bash
cd lumora-mobile
bundle install
```

**Android** :
1. Générer le keystore et l'encoder en base64 (`base64 -i keystore.jks`).
2. Stocker dans `GOOGLE_PLAY_JSON_KEY` la clé de service Play Console.
3. Placer le keystore décodé via CI dans `android/app/keystore.jks`.

**iOS** :
1. Créer un repo Git privé pour les certificats (`lumora-certificates`).
2. `cd ios && fastlane match init`
3. `fastlane match appstore` (génère certificat + provisioning profile)
4. Configurer `MATCH_PASSWORD` dans les secrets.

### 2.2 API keys via `--dart-define`

Aucune clé API ne doit être écrite en dur dans le code. Les clés suivantes sont injectées au build :

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_ANDROID_APP_ID=ca-app-pub-xxx \
  --dart-define=REVENUECAT_ANDROID_KEY=xxx \
  --dart-define=FIREBASE_API_KEY=xxx
```

Ces `--dart-define` sont utilisés dans :
- `android/app/build.gradle` (récupération via `project.property(...)`)
- `ios/Runner/Info.plist` (variables d'environnement injectées par Fastlane)

### 2.3 Firebase init (mobile)

```bash
cd lumora-mobile
flutterfire configure --project=lumora-prod --out=lib/core/firebase_options.dart
```

Fichiers natifs générés :
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## 3. Pipeline CI/CD étape par étape

### 3.1 CI (`github/workflows/ci.yml`)

Déclencheurs : push sur `main`, `develop`, `feat/**` + pull requests.

| Étape | Temps estimé | Description |
|-------|--------------|-------------|
| Checkout | < 10s | Clone du repo |
| Flutter setup | < 30s | Installation Flutter 3.24.x |
| `pub get` | 30–60s | Résolution des dépendances |
| `build_runner` | 1–2 min | Génération `*.g.dart`, `*.freezed.dart` |
| `flutter analyze` | 30–60s | Analyse statique (`very_good_analysis`) |
| `flutter test --coverage` | 3–6 min | Tests unitaires + widget + upload Codecov |
| Build APK debug | 4–6 min | Vérification build Android |
| Build iOS no-codesign | 5–8 min | Vérification build iOS (macOS runner) |

**Temps total CI** : ~12–18 minutes.

### 3.2 CD (`github/workflows/cd.yml`)

Déclencheurs : tag `v*` sur `main` ou `workflow_dispatch` manuel.

| Étape | Temps estimé | Description |
|-------|--------------|-------------|
| Checkout + Flutter setup | 1 min | — |
| Decode keystore + match | 30s | Certificats et signing |
| `flutter build appbundle --release` | 6–8 min | AAB Android signé |
| Fastlane `internal` / `beta` / `production` | 3–5 min | Upload Google Play |
| `flutter build ios --release` | 8–12 min | Archive iOS signée |
| Fastlane `beta` / `release` | 5–8 min | Upload TestFlight / App Store Connect |
| Notification Slack/Discord | < 5s | Résumé statut |

**Temps total CD** : ~25–35 minutes (Android + iOS en parallèle).

### 3.3 Backend Deploy (`github/workflows/backend-deploy.yml`)

Déclencheurs : push sur `main` modifiant `backend/functions/**`.

| Étape | Temps estimé | Description |
|-------|--------------|-------------|
| `npm ci` | 30s | — |
| `eslint` | 15s | Lint TypeScript |
| `tsc` | 20s | Compilation |
| `firebase deploy --only functions` | 2–4 min | Déploiement Cloud Functions v2 |

---

## 4. Procédure de soumission App Store

### 4.1 Conformité Review Guidelines

- **Guideline 2.1 — Performance** : L'app ne doit pas crasher. Vérifier via Crashlytics beta interne.
- **Guideline 3.1.1 — IAP** : Tous les achats doivent passer par RevenueCat / StoreKit. Pas de redirect vers site externe pour payer.
- **Guideline 4.2 — Design** : L'UI organique de Lumora (bulles, glassmorphism) est un atout différenciant ; s'assurer que les screenshots et la video promo reflètent cette identité visuelle.
- **Guideline 5.1.1 — Data** : Politique de confidentialité hébergée sur `https://lumora.game/privacy`.
- **Guideline 5.1.2 — Account** : Authentification Apple obligatoire si d'autres SSO sont proposés.

### 4.2 Assets requis

| Asset | Format | Contraintes transversales |
|-------|--------|---------------------------|
| Screenshots (6.7", 6.5", 5.5", iPad) | PNG/JPEG | Doivent montrer l'UI organique (bulles, glassmorphism, pas de carrés gris) |
| Video promo (optionnel) | MP4, 15–30s | Montrer la parallaxe 3D, les particules, le partage social |
| Texte App Store | Localisé FR/EN/ES/DE | Mentionner gratuit+IAP, événements, sauvegarde cross-device, partage |
| Notes de version | FR/EN/ES/DE | Claires et concises |

### 4.3 Checklist soumission

- [ ] Build iOS signé uploadé via Fastlane `release`
- [ ] IAP configurés dans App Store Connect (prix par région)
- [ ] Associated Domains pour Dynamic Links (partage social)
- [ ] Push notifications entitlement (FCM)
- [ ] Politique confidentialité + conditions d'utilisation en ligne
- [ ] Testé sur iPhone 12/13/14/15 + iPad (pas de déformation UI)
- [ ] Bouton "Restaurer les Achats" visible dans les paramètres

---

## 5. Procédure de soumission Google Play

### 5.1 Build et signing

- Format : AAB (Android App Bundle), obligatoire pour les nouvelles apps.
- API level minimum : 26 (Android 8.0).
- Target SDK : 34+.

### 5.2 Fiche produit

| Champ | Exigence | Contraintes transversales |
|-------|----------|---------------------------|
| Titre | 30 car | Lumora — Puzzle Cosmique |
| Description courte | 80 car | Mentionner univers organique, effets 3D, gratuit+IAP |
| Description longue | 4000 car | Décrire UI organique, parallaxe, indices décroissants, événements, partage, cross-device |
| Screenshots (téléphone + tablette) | 2–8 par format | Bulles, glassmorphism, parallaxe, pas de carrés gris |
| Video | MP4, 30s max | Gameplay fluide 60 FPS avec effets 3D |

### 5.3 Classification PEGI

- Âge : 3+
- Achats intégrés : Oui
- Publicités : Oui (interstitielles + récompensées)
- Partage social : Optionnel

### 5.4 Release graduelle

1. **Internal Testing** : 20 testeurs internes (immédiat).
2. **Closed Testing** : 100 testeurs externes (validation store non requise).
3. **Production** : Rollout graduel via Fastlane :
   - Jour 1 : 10 %
   - Jour 3 (si crash < 1 %) : 50 %
   - Jour 5 (si rating > 4.0) : 100 %

---

## 6. Configuration Firebase post-deploy

### 6.1 Analytics

- Importer les événements custom (`level_start`, `level_complete`, `iap_purchase`, `ad_show`, `share`, `notification_open`) dans Firebase Console > Custom definitions.
- Créer les audiences : payers, churners_7d, churners_30d, high_engagement, near_perfect.
- Activer DebugView pour la validation initiale.

### 6.2 Crashlytics

- Vérifier le reporting automatique sur les builds internal testing.
- Uploader les symbols dSYM iOS via Fastlane après chaque release.
- Configurer les alertes email + Slack (crash rate > 1 %).

### 6.3 Remote Config

1. Uploader les valeurs par défaut depuis `devops/firebase/remote_config_defaults.json`.
2. Activer les paramètres pour les tests A/B :
   - `ad_interstitial_every_n_levels`
   - `iap_prices_tier_a/b/c`
   - `difficulty_curve_multiplier`
   - `hintSystem`
   - `streak_break_policy`
3. Vérifier le fetch côté client (15 min minimum fetch interval en production).

### 6.4 A/B Testing

- Lancer le Test 1 (fréquence pubs) dès 1000 installations actives.
- Suivre les objectifs Analytics liés (revenus, rétention).
- Documenter les résultats dans `docs/AB_TEST_RESULTS.md`.

---

## 7. Monitoring post-launch (M2–M6)

### Itérations mensuelles

| Mois | Focus | Actions clés |
|------|-------|--------------|
| M2 | Ajustement baseline | Analyser D1/D7, ARPDAU, lancer Test 1 et Test 2 |
| M3 | Événement saisonnier été | Préparer assets, activer `eventScheduler.ts`, nouveaux thèmes IAP |
| M4 | Tournoi + leaderboard | Activer `leaderboardUpdate.ts`, lancer Test 3 (difficulté) |
| M5 | Nouveaux niveaux (batch 50) | Mise à jour Firestore `levels/`, A/B testing placement pubs |
| M6 | Passe Saisonnier 2 | Bundles IAP optimisés LTV, lancer Test 5 (streak) |

### Dashboards quotidiens

- **Firebase Analytics** : rétention, funnels, événements custom.
- **Crashlytics** : stabilité, top crashs par niveau.
- **RevenueCat** : revenus IAP, churn, renouvellements.
- **AdMob** : eCPM, fill rate, revenus publicitaires.

---

## 8. Plan de rollback

### 8.1 Rollback Store (Android)

Si un crash critique (> 2 %) ou un bug majeur est détecté post-release :

1. **Halter le rollout** : Google Play Console > Production > Halt rollout → 0 %.
2. **Build précédent** : Promouvoir la version précédente (M-1) vers production à 100 % via `fastlane android production` avec le tag précédent.
3. **Hotfix** : Créer une branche `hotfix/`, corriger, tag `vX.Y.Z+1`, relancer CD.

### 8.2 Rollback Store (iOS)

Apple ne permet pas de "downgrader" un build. Solutions :
1. Soumettre un hotfix accéléré (expedited review) avec le tag `vX.Y.Z+1`.
2. Si le bug est lié à une fonctionnalité isolée, la désactiver via Remote Config (`feature_flag_X = false`).

### 8.3 Rollback Firestore Rules

Les règles sont versionnées dans `devops/firebase/firestore.rules`.

```bash
# Restaurer la version précédente du fichier
# Puis déployer :
firebase deploy --only firestore:rules --project=lumora-prod
```

**Précaution** : les règles rétrogradées ne révoquent pas les accès déjà accordés ; elles s'appliquent uniquement aux nouvelles requêtes.

### 8.4 Rollback Cloud Functions

```bash
# Lister les versions
firebase functions:log --project=lumora-prod

# Redéployer la version précédente (via tag git)
git checkout vX.Y.Z-1 -- backend/functions/src/
cd backend/functions
npm run build
firebase deploy --only functions --project=lumora-prod
```

Alternative : utiliser Firebase Console > Functions > Version history > Rollback (interface graphique).

---

## 9. Checklist go-live finale

- [ ] CI verte sur `main` (analyze + test + build APK/iOS)
- [ ] CD exécutée avec succès sur Internal / TestFlight
- [ ] Beta fermée (50+ testeurs) sans crash critique
- [ ] Firestore rules déployées et testées
- [ ] Cloud Functions déployées et idempotentes
- [ ] IAP validés côté RevenueCat + stores
- [ ] AdMob IDs injectés via `--dart-define`
- [ ] Remote Config fetch < 5s avec fallback local
- [ ] Notifications FCM + locales testées
- [ ] Analytics events visibles en DebugView
- [ ] Screenshots stores conformes charte organique (pas de carrés gris)
- [ ] Politique confidentialité + PEGI/App Store review guidelines OK
- [ ] Plan de rollback documenté et accessible à l'on-call

---

## 10. Contraintes transversales — Validation DevOps

| # | Contrainte | Intégration DevOps / Stores |
|---|------------|----------------------------|
| 1 | **UI organique** | Screenshots stores et video promo doivent refléter 100 % de l'UI organique (bulles, glassmorphism, dégradés). Aucun asset carré gris dans les metadata. |
| 2 | **2D avec effets 3D** | Descriptions stores mentionnent parallaxe, lumières dynamiques, particules. Video promo met en avant les effets 3D. |
| 3 | **Indices décroissants** | Metadata App Store / Play Store mentionnent "indices visuels intelligents qui s'adaptent". Remote Config `hintSystem` documenté. |
| 4 | **Compte utilisateur** | Metadata mentionnent sauvegarde cross-device via Google/Apple/Email. Onboarding review guidelines couvert (Apple Sign-In obligatoire). |
| 5 | **Partage social** | Metadata mentionnent capture d'écran stylisée et partage natif. Associated Domains configuré pour Dynamic Links. |
| 6 | **Gratuit + pubs + IAP abordables** | Metadata mentionnent "Gratuit avec achats intégrés optionnels" et Passe Saisonnier. PEGI mentionne publicités et achats. IAP <= 4.99 $. |
| 7 | **Événements automatiques** | Metadata mentionnent événements saisonniers, défis quotidiens, tournois. `eventScheduler.ts` déployé automatiquement. |
| 8 | **Notifications de retour** | Metadata mentionnent notifications de retour. FCM + fallback local configurés. Entitlement push iOS activé. |
| 9 | **Sessions courtes, accessible, addictif** | Metadata mentionnent boucles de 30–90s, offline-first, accessibilité. Review guidelines Apple/Google respectées (contrastes, tailles tap >= 48dp). |
