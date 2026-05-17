# Fastlane — Lumora

Ce dossier contient les configurations Fastlane pour le déploiement continu d'Android et iOS.

## Prérequis

- Ruby 3.2+
- Bundler
- Flutter 3.24+
- Compte Google Play Console (Android)
- Compte Apple Developer + App Store Connect (iOS)
- Firebase project configuré

## Installation

```bash
cd lumora-mobile
bundle install
```

### Android — Configuration initiale

1. Générer un keystore de production :
```bash
keytool -genkey -v -keystore android/app/keystore.jks -alias lumora -keyalg RSA -keysize 2048 -validity 10000
```

2. Encoder le keystore en base64 pour GitHub Secrets :
```bash
base64 -i android/app/keystore.jks | pbcopy
```

3. Créer une clé de service Google Play (JSON) dans Google Play Console > API Access, puis l'ajouter à `GOOGLE_PLAY_JSON_KEY`.

4. Configurer les secrets GitHub :
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `GOOGLE_PLAY_JSON_KEY`
- `ADMOB_ANDROID_APP_ID`
- `REVENUECAT_ANDROID_KEY`

### iOS — Configuration initiale (match)

1. Créer un repository Git privé pour les certificats (ex. `lumora-certificates`).

2. Initialiser match :
```bash
cd ios
fastlane match init
```

3. Générer les certificats App Store :
```bash
fastlane match appstore
```

4. Configurer les secrets GitHub :
- `MATCH_PASSWORD` (mot de passe du repo match)
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT` (clé API App Store Connect, format .p8)
- `ADMOB_IOS_APP_ID`
- `REVENUECAT_IOS_KEY`

## Utilisation

### Android

```bash
cd android
bundle exec fastlane internal    # Internal Testing (APK debug)
bundle exec fastlane beta        # Closed Testing (AAB release)
bundle exec fastlane production  # Production graduelle 10 %
bundle exec fastlane promote_to_50
bundle exec fastlane promote_to_100
```

### iOS

```bash
cd ios
bundle exec fastlane beta        # TestFlight Internal
bundle exec fastlane release     # App Store Connect + soumission review
bundle exec fastlane build_release  # Build local uniquement
```

## Rollout graduel Android

La lane `production` déploie automatiquement à 10 %. Après 24–48h de monitoring (Crashlytics, reviews), promouvoir à 50 % puis 100 % via les lanes dédiées.

## Contraintes transversales

- **UI organique / 2D+3D** : Aucun impact Fastlane ; les assets stores (screenshots, video promo) doivent refléter le rendu organique (bulles, glassmorphism, dégradés).
- **Gratuit+pubs+IAP** : Les SKUs IAP doivent être créés dans Play Console / App Store Connect avant le build release.
- **Événements et notifications** : Les notifications FCM nécessitent l'entitlement push activé dans le provisioning profile (match le gère).
- **Compte utilisateur / partage** : L'Associated Domain pour Dynamic Links doit être configuré dans Xcode et le provisioning profile.
