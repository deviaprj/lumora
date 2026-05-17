# Lumora — Phase 4 : DevOps & Déploiement

## Récapitulatif Phase 4

Livrables DevOps complétés pour le projet **Lumora** (Flutter + Flame + Firebase).

---

### 1. CI/CD GitHub Actions

#### `ci.yml` — Intégration Continue
- **Analyse statique** : `flutter analyze --no-fatal-infos`
- **Tests** : `flutter test --coverage --tags "unit,widget"` + upload Codecov
- **Build Android** : APK debug avec `--dart-define` pour les clés API
- **Build iOS** : `--no-codesign --simulator` sur macOS runner

#### `cd.yml` — Déploiement Continu
- **Android** : Fastlane → Play Store (internal / beta / production)
- **iOS** : Fastlane → TestFlight / App Store
- **Secrets** : Keystore, JSON Play Store, Match password, API keys
- **Notifications** : Slack/Discord webhook après déploiement

#### `backend-deploy.yml` — Cloud Functions
- Lint + Type-check + tests Node.js
- Déploiement Firebase Functions avec token CI
- Notification Slack/Discord

---

### 2. Fastlane

#### Android (`android/fastlane/`)
- `Appfile` : `package_name("com.lumora.game")`
- `Fastfile` : lanes `test`, `build_debug`, `internal`, `beta`, `production`
- `Gemfile` : Fastlane ~> 2.220

#### iOS (`ios/fastlane/`)
- `Appfile` : bundle ID + équipe
- `Fastfile` : lanes `test`, `build`, `beta`, `release`
- `Gemfile` : Fastlane ~> 2.220

---

### 3. Backend Firebase

#### Sécurité
- `firestore.rules` : 13 collections avec règles user-scoped
  - `users`, `profiles`, `progress`, `levels`, `leaderboards`, `purchases`, `events`, `notifications`, `dailyRewards`, `referrals`, `settings`
  - Écriture `purchases` interdite côté client (`allow write: if false`)
  - Admin checks via collection `admins`

#### Indexation
- `firestore.indexes.json` : 3 index composites
  - Leaderboards : `worldId` ASC + `score` DESC
  - Events : `status` ASC + `startAt` ASC
  - Events : `status` ASC + `priority` DESC + `startAt` ASC

#### Configuration
- `firebase.json` : Firestore + Functions + Hosting
- `.firebaserc` : projet par défaut `lumora-game`

---

### 4. Initialisation SDK (main.dart)

Les SDKs tiers sont initialisés **conditionnellement** :

```dart
// Firebase — uniquement si FIREBASE_API_KEY présente et non-Linux
// AdMob — uniquement sur mobile (Android/iOS) + ADMOB_ANDROID_APP_ID
// RevenueCat — uniquement sur mobile + REVENUECAT_ANDROID_KEY
```

**Fallback** : en développement Linux ou clés manquantes, l'app continue sans crash.

---

### 5. Secrets Requis (GitHub + --dart-define)

| Secret | Description | Utilisé dans |
|--------|-------------|-------------|
| `FIREBASE_API_KEY` | Clé API Firebase | CI build, main.dart |
| `ADMOB_ANDROID_APP_ID` | ID app AdMob | CI build, main.dart |
| `REVENUECAT_ANDROID_KEY` | Clé publique RevenueCat | CI build, main.dart |
| `ANDROID_KEYSTORE_BASE64` | Keystore signé (base64) | CD Android |
| `ANDROID_KEYSTORE_PASSWORD` | Mot de passe keystore | CD Android |
| `ANDROID_KEY_ALIAS` | Alias clé | CD Android |
| `ANDROID_KEY_PASSWORD` | Mot de passe clé | CD Android |
| `GOOGLE_PLAY_JSON_KEY` | Clé service Play Store | CD Android Fastlane |
| `MATCH_PASSWORD` | Mot de passe Match | CD iOS |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID App Store Connect | CD iOS |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID App Store Connect | CD iOS |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Contenu clé API (base64) | CD iOS |
| `REVENUECAT_IOS_KEY` | Clé publique iOS RevenueCat | CD iOS |
| `ADMOB_IOS_APP_ID` | ID app iOS AdMob | CD iOS |
| `FIREBASE_CI_TOKEN` | Token Firebase CLI | Backend deploy |
| `SLACK_WEBHOOK_URL` | Webhook Slack (optionnel) | Notifications |
| `DISCORD_WEBHOOK_URL` | Webhook Discord (optionnel) | Notifications |

---

### 6. Commandes de Déploiement

#### Développement local
```bash
flutter pub get
flutter run -d android  # ou -d ios
```

#### Build release (local)
```bash
flutter build apk --release \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=ADMOB_ANDROID_APP_ID=... \
  --dart-define=REVENUECAT_ANDROID_KEY=...
```

#### Déploiement backend
```bash
cd backend/functions
npm ci
npm run build
firebase deploy --only functions --project lumora-game
```

#### Déploiement stores (via CI/CD)
1. Merger `feat/phase-3-profils-details` → `main`
2. Taguer `v1.0.0`
3. Le workflow `cd.yml` se déclenche automatiquement

---

### 7. Blockers Résolus Phase 3 → Phase 4

| Issue | Statut | Fix |
|-------|--------|-----|
| `_PauseOverlay` Container brut | ✅ | Utilise `LumoraCard` avec glassmorphism |
| Bouton "Debug Victoire" en prod | ✅ | Caché derrière `kDebugMode` |
| `main.dart` TODO SDK | ✅ | Initialisation conditionnelle + fallback |
| Projet non versionné | ✅ | Ajouté au repo Git avec `.gitignore` mis à jour |

---

### 8. Prochaines Étapes (Post Phase 4)

1. **Configurer Firebase** : `flutterfire configure` pour générer `firebase_options.dart`
2. **Intégrer RevenueCat** : `purchases_flutter` + adapter
3. **Intégrer AdMob** : `google_mobile_ads` + adapter
4. **Notifications locales** : `flutter_local_notifications` dans `main.dart`
5. **Tests E2E** : Exécuter `integration_test/` sur émulateur physique
6. **Beta fermée** : Déployer via Fastlane `internal` → recueillir feedback

---

*Document généré le 2026-05-07 — Phase 4 DevOps complète.*
