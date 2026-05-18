# Notice API Keys — Lumora

Ce document regroupe les clés, IDs et secrets nécessaires pour passer Lumora en version finale.

Important : certaines valeurs sont de vraies clés secrètes, d'autres sont des IDs de configuration. Dans le projet, les deux types sont indispensables, mais ils ne doivent pas être traités de la même manière.

## 0. Liens officiels utiles (création de comptes et consoles)

### Comptes et consoles

- Firebase Console : https://console.firebase.google.com/
- Google Cloud Console : https://console.cloud.google.com/
- Compte Google (création) : https://accounts.google.com/signup
- Compte Apple Developer : https://developer.apple.com/account/
- Programme Apple Developer (abonnement) : https://developer.apple.com/programs/
- Meta for Developers (Facebook Login) : https://developers.facebook.com/
- AdMob Console : https://admob.google.com/
- RevenueCat Dashboard : https://app.revenuecat.com/
- Resend (email API) : https://resend.com/

### Compte unique ou un compte par projet ?

Règle générale : **un compte plateforme peut servir à plusieurs projets**. Vous n'avez pas besoin de créer un nouveau compte utilisateur pour chaque app.

Ce qui est réutilisable (niveau compte):
- Compte Google
- Compte Apple Developer
- Compte Meta Developer
- Compte AdMob
- Compte RevenueCat
- Compte Resend

Ce qui doit être créé par projet/app (niveau ressource):
- Projet Firebase (souvent 1 par environnement: staging/prod)
- Apps Firebase Android/iOS dans le projet
- App IDs et Ad Unit IDs AdMob par application
- App Facebook (ou au minimum une configuration app distincte par environnement)
- Projet RevenueCat + entitlements + webhooks
- Domaines/expéditeurs Resend selon politique de l'organisation

Bonnes pratiques multi-projets:
1. Garder un seul compte propriétaire (organisation) avec membres d'équipe.
2. Créer des ressources séparées par environnement (`staging`, `prod`).
3. Ne jamais partager les secrets prod avec les environnements de test.
4. Utiliser des préfixes de nommage cohérents (`lumora-staging`, `lumora-prod`).

### Documentation officielle (référence)

- Firebase setup Flutter : https://firebase.google.com/docs/flutter/setup
- Firebase Auth (providers) : https://firebase.google.com/docs/auth
- Google Sign-In Firebase : https://firebase.google.com/docs/auth/flutter/google-signin
- Apple Sign-In Firebase : https://firebase.google.com/docs/auth/flutter/apple
- Facebook Login Firebase : https://firebase.google.com/docs/auth/flutter/facebook-login
- AdMob Flutter : https://developers.google.com/admob/flutter/quick-start

## 0.b Obtenir un compte validé (checklist rapide)

### Compte Google validé

1. Créer le compte via https://accounts.google.com/signup.
2. Vérifier l'email et le numéro de téléphone si demandé.
3. Activer la double authentification (recommandé prod).
4. Vérifier que vous accédez bien à Firebase Console et Google Cloud Console.

### Compte Apple Developer validé

1. Se connecter à https://developer.apple.com/account/ avec un Apple ID.
2. S'inscrire au programme via https://developer.apple.com/programs/.
3. Finaliser la validation légale/paiement (individuel ou organisation).
4. Vérifier l'accès aux certificats, identifiers et Sign In with Apple.

### Compte Meta Developer validé

1. Créer/ouvrir un compte sur https://developers.facebook.com/.
2. Passer les vérifications demandées (email, téléphone, entreprise si nécessaire).
3. Créer une app Meta et activer Facebook Login.
4. Sortir du mode dev pour la prod (App Review si permissions sensibles).

### Compte AdMob validé

1. Ouvrir https://admob.google.com/.
2. Créer le compte et associer un mode de paiement.
3. Valider l'application et les réglages de conformité.
4. Créer les App IDs et Ad Unit IDs finaux.

### Compte RevenueCat validé

1. Ouvrir https://app.revenuecat.com/.
2. Créer le projet et lier les apps stores.
3. Vérifier les products/entitlements.
4. Générer les clés SDK et webhook.

## 1. Résumé rapide des intégrations

Les intégrations actuellement présentes dans le projet sont :
- Firebase mobile
- Firebase Analytics
- AdMob publicités récompensées
- RevenueCat pour les achats / abonnements futurs
- Firebase Functions backend
- Notifications push via Firebase Admin / FCM
- Authentification Firebase réelle (Google, Apple, Facebook, Email + code)

## 2. Liste des clés et secrets à prévoir

| Élément | Type | Utilité | Statut dans le code actuel |
|---|---|---|---|
| FIREBASE_API_KEY | Clé de configuration Firebase | Initialisation Firebase par fallback Dart | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_PROJECT_ID | ID de projet | Projet Firebase de référence | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_MESSAGING_SENDER_ID | ID de projet | Push / FCM / Firebase | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_STORAGE_BUCKET | ID de bucket | Stockage Firebase si activé | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_ANDROID_APP_ID | ID d'application | Firebase Android | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_IOS_APP_ID | ID d'application | Firebase iOS | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_IOS_BUNDLE_ID | ID de bundle | iOS / Firebase | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_MACOS_APP_ID | ID d'application | Firebase macOS | Utilisé par lib/core/firebase_options_fallback.dart |
| FIREBASE_MACOS_BUNDLE_ID | ID de bundle | macOS / Firebase | Utilisé par lib/core/firebase_options_fallback.dart |
| ADMOB_ANDROID_APP_ID | ID d'application AdMob | Initialisation AdMob Android | Utilisé par lib/main.dart et AndroidManifest.xml |
| ADMOB_REWARDED_UNIT_ID | ID d'unité pub | Vidéos récompensées | Utilisé par lib/features/monetization/data/rewarded_ad_service.dart |
| GADApplicationIdentifier | ID d'application AdMob iOS | Initialisation AdMob iOS | Présent dans ios/Runner/Info.plist |
| REVENUECAT_ANDROID_KEY | Clé publique RevenueCat | Configuration future des achats côté mobile | Utilisé par lib/main.dart |
| REVENUECAT_WEBHOOK_SECRET | Secret webhook | Vérification des webhooks RevenueCat côté backend | Utilisé par backend/functions/src/purchaseValidation.ts |
| RESEND_API_KEY | Secret API email | Envoi du code de validation email | Utilisé par backend/functions/src/emailVerification.ts |
| RESEND_FROM_EMAIL | Configuration email | Adresse expéditrice du code de validation | Utilisé par backend/functions/src/emailVerification.ts |
| EMAIL_VERIFICATION_PEPPER | Secret backend | Renforcement du hash des codes/tokens email | Utilisé par backend/functions/src/emailVerification.ts |
| FACEBOOK_APP_ID | ID OAuth | Configuration native Facebook Login | Requis pour flutter_facebook_auth |
| GoogleService-Info.plist | Fichier de config | Configuration Firebase iOS | Requis pour iOS |
| google-services.json | Fichier de config | Configuration Firebase Android | Requis pour Android |

### Fonctions backend email-code ajoutées

- sendEmailVerificationCode
- verifyEmailVerificationCode
- finalizeEmailSignup

Ces 3 fonctions pilotent le flux de création de compte email avec vérification par code avant création du compte Firebase Auth.

### Clés à considérer plus tard si l'authentification devient réelle

Ces éléments sont évoqués dans la documentation produit, mais ils ne sont pas encore câblés dans le code courant :
- Google OAuth client ID
- Apple Sign-In key / Services ID
- Web client ID Google si vous activez un flux web ou multi-plateforme
- FCM server credentials supplémentaires si vous ajoutez un service externe de notifications

## 3. Démarche détaillée par intégration

### 3.1 Firebase mobile

#### Ce qu'il faut obtenir
- Un projet Firebase actif
- Les deux fichiers natifs :
  - Android : google-services.json
  - iOS : GoogleService-Info.plist
- Les valeurs de fallback Dart si vous souhaitez continuer à utiliser l'initialisation sans fichiers natifs sur certaines plateformes :
  - FIREBASE_API_KEY
  - FIREBASE_PROJECT_ID
  - FIREBASE_MESSAGING_SENDER_ID
  - FIREBASE_STORAGE_BUCKET
  - FIREBASE_ANDROID_APP_ID
  - FIREBASE_IOS_APP_ID
  - FIREBASE_IOS_BUNDLE_ID
  - FIREBASE_MACOS_APP_ID
  - FIREBASE_MACOS_BUNDLE_ID

#### Comment les obtenir
1. Ouvrir la console Firebase.
2. Créer ou sélectionner le projet Lumora.
3. Ajouter une application Android.
4. Renseigner le nom de package exact de l'app Flutter native.
5. Télécharger google-services.json.
6. Ajouter une application iOS.
7. Renseigner le bundle identifier iOS.
8. Télécharger GoogleService-Info.plist.
9. Si vous utilisez le fallback Dart, récupérer aussi les valeurs d'application et de projet depuis la configuration SDK Firebase.

#### URLs directes Firebase Console

- Console principale : https://console.firebase.google.com/
- Paramètres du projet (Project Settings) : https://console.firebase.google.com/project/_/settings/general/
- Ajout app Android : https://console.firebase.google.com/project/_/settings/general/android
- Ajout app iOS : https://console.firebase.google.com/project/_/settings/general/ios
- Auth providers : https://console.firebase.google.com/project/_/authentication/providers
- Cloud Functions : https://console.firebase.google.com/project/_/functions
- Firestore : https://console.firebase.google.com/project/_/firestore

Remplacez `_` par l'ID réel de votre projet Firebase dans les URLs ci-dessus.

#### Procédure détaillée Console Firebase (de zéro à utilisable)

1. Aller sur https://console.firebase.google.com/ puis Créer un projet.
2. Nommer le projet (ex: lumora-prod) et activer Google Analytics si nécessaire.
3. Dans Paramètres du projet, section Général, ajouter Android puis iOS.
4. Télécharger `google-services.json` (Android) et `GoogleService-Info.plist` (iOS).
5. Placer ces fichiers dans les dossiers du projet mobile.
6. Ouvrir Authentication > Sign-in method et activer Google, Apple, Facebook, Email/Password.
7. Configurer chaque provider avec ses client IDs/secrets requis.
8. Ouvrir Firestore et créer la base (mode production recommandé + règles adaptées).
9. Ouvrir Cloud Functions et vérifier que le projet est relié pour les déploiements backend.
10. Tester une connexion réelle depuis l'app et vérifier l'apparition de l'utilisateur dans Authentication > Users.

#### Comment les installer dans le projet
- Android : placer google-services.json dans android/app/.
- iOS : placer GoogleService-Info.plist dans ios/Runner/.
- Si vous utilisez les valeurs Dart fallback : passer les valeurs via --dart-define au lancement ou à la compilation.

#### Comment les configurer pour l'utilisation
- Le point d'entrée est lib/main.dart.
- Le fallback est géré dans lib/core/firebase_options_fallback.dart.
- En production, privilégier les fichiers natifs Firebase. Le fallback est utile pour le développement local ou les environnements partiels.

#### Attention
- Ne versionnez jamais les vrais fichiers de production dans un dépôt public.
- Si vous avez plusieurs environnements, prévoyez au minimum : dev, staging et prod.

### 3.2 AdMob / publicités récompensées

#### Ce qu'il faut obtenir
- Un compte AdMob validé
- Un AdMob App ID Android
- Un AdMob App ID iOS si l'application iOS est distribuée
- Un Rewarded Ad Unit ID pour les vidéos récompensées

#### Ce qui existe déjà dans le projet
- AndroidManifest.xml contient actuellement un ID de test AdMob.
- ios/Runner/Info.plist contient actuellement un ID de test AdMob.
- Le service de vidéo récompensée lit ADMOB_REWARDED_UNIT_ID dans lib/features/monetization/data/rewarded_ad_service.dart.
- lib/main.dart initialise AdMob uniquement si la clé est fournie.

#### Comment les obtenir
1. Créer le compte AdMob.
2. Ajouter l'application Android et, si nécessaire, iOS.
3. Créer une unité de pub récompensée.
4. Copier l'App ID Android dans le manifeste Android.
5. Copier le GADApplicationIdentifier iOS dans le Info.plist.
6. Copier le Rewarded Ad Unit ID dans la configuration Flutter.

#### Comment les installer dans le projet
- Android : remplacer la valeur de com.google.android.gms.ads.APPLICATION_ID dans android/app/src/main/AndroidManifest.xml.
- iOS : remplacer la valeur de GADApplicationIdentifier dans ios/Runner/Info.plist.
- Flutter : fournir ADMOB_REWARDED_UNIT_ID via --dart-define ou via l'environnement d'exécution.

#### Comment les configurer pour l'utilisation
- lib/main.dart appelle MobileAds.instance.initialize() quand ADMOB_ANDROID_APP_ID est présent.
- AdMobRewardedAdService utilise le Rewarded Ad Unit ID pour charger et afficher les vidéos.
- Garder les IDs de test tant que l’application n’est pas prête pour la production.

#### Bonnes pratiques avant mise en production
- Remplacer tous les IDs de test par les IDs réels.
- Vérifier que la politique de consentement publicitaire est en place si nécessaire selon la région.
- Tester sur un appareil de validation avant publication.

### 3.3 RevenueCat

#### Ce qu'il faut obtenir
- Une clé publique RevenueCat Android
- Une clé publique RevenueCat iOS si la plateforme est activée
- Les identifiants de produits configurés dans RevenueCat
- Un secret de webhook RevenueCat si vous utilisez la validation serveur

#### Ce qui existe déjà dans le projet
- lib/main.dart lit REVENUECAT_ANDROID_KEY.
- backend/functions/src/purchaseValidation.ts lit REVENUECAT_WEBHOOK_SECRET.
- La logique de validation d'achat est déjà préparée côté backend.

#### Comment les obtenir
1. Créer le projet RevenueCat.
2. Ajouter l'application Android et/ou iOS.
3. Lier les produits du store.
4. Copier la clé publique du SDK RevenueCat.
5. Créer le webhook RevenueCat si vous voulez synchroniser les achats côté backend.
6. Définir un secret webhook fort pour protéger l'endpoint.

#### Comment les installer dans le projet
- Flutter : passer REVENUECAT_ANDROID_KEY via --dart-define.
- Backend : fournir REVENUECAT_WEBHOOK_SECRET comme variable d'environnement au moment du déploiement Firebase Functions.

#### Comment les configurer pour l'utilisation
- Le SDK RevenueCat est encore en mode préparatoire dans lib/main.dart.
- Le backend purchaseValidation est prêt à recevoir un webhook et à enregistrer les transactions.
- Assurez-vous que les produits du store et les produits RevenueCat portent exactement les mêmes identifiants.

### 3.4 Firebase Functions / backend

#### Ce qu'il faut obtenir
- Aucun secret supplémentaire obligatoire pour Firebase Admin dans le flux standard Firebase
- Un secret webhook RevenueCat si vous activez la validation d'achat
- Les identifiants de push / FCM sont gérés par Firebase Admin et le projet Firebase

#### Comment ça fonctionne dans ce projet
- backend/functions/src/index.ts initialise Firebase Admin avec initializeApp().
- Les fonctions utilisent Firestore, Auth et Messaging via le projet Firebase associé.
- Le backend envoie des notifications via FCM sans clé client supplémentaire dans le code applicatif Flutter.

#### Comment l'installer correctement
1. Associer le backend functions au même projet Firebase que l'app mobile.
2. Déployer les fonctions avec le bon compte Firebase.
3. Définir REVENUECAT_WEBHOOK_SECRET si vous utilisez la validation d'achat.
4. Vérifier que les accès Firestore/Auth/Cloud Messaging sont autorisés pour le service account du projet.

### 3.5 Notifications push

#### Ce qu'il faut obtenir
- Pas de clé client Flutter supplémentaire si vous restez dans Firebase/FCM
- Un projet Firebase correctement configuré avec FCM
- Un token appareil côté client pour recevoir les notifications

#### Comment les utiliser
- Les notifications sont envoyées par le backend via Firebase Admin / Messaging.
- Le document ne demande pas de clé dédiée côté mobile pour cette partie.
- Si vous ajoutez un service tiers plus tard, il faudra documenter ses clés séparément.

### 3.6 Authentification Google / Apple / Email

#### Statut actuel
- L’authentification est mentionnée dans la notice produit, mais elle n’est pas encore entièrement branchée côté natif dans ce repo.

#### Clés à prévoir pour la version finale si vous activez l'auth réelle
- Google OAuth client ID
- Apple Services ID
- Apple Sign In key
- Eventuellement un web client ID Google

#### Démarche générale
1. Créer les identifiants dans Google Cloud Console et Apple Developer.
2. Les relier au projet Firebase Authentication.
3. Les injecter dans le projet Flutter ou dans la configuration native selon le provider.
4. Tester la connexion anonyme puis la migration vers un compte lié.

## 4. Comment installer les clés dans le projet sans les exposer

### Méthode recommandée
- Mettre les fichiers natifs Firebase dans android/app/ et ios/Runner/.
- Injecter les secrets sensibles via l'environnement ou via --dart-define.
- Ne pas committer les clés de production dans Git.
- Garder un fichier d'exemple avec des valeurs fictives si vous voulez documenter le format.

### Exemple de logique de déploiement
- Développement local : variables d’environnement temporaires ou --dart-define.
- CI/CD : variables secrètes dans le pipeline.
- Production mobile : fichiers natifs Firebase + clés de pub / SDK en dur uniquement si elles sont publiques ou non sensibles.

## 5. Comment savoir si les clés sont bien en place

Vous pouvez vérifier les points suivants :
- Firebase démarre sans fallback d’erreur dans les logs.
- Les publicités récompensées se chargent sans message “unavailable”.
- Les vidéos récompensées apparaissent sur l’écran de défaite.
- Les webhooks RevenueCat arrivent bien dans les logs backend.
- Les achats de test ou de prod sont bien écrits dans Firestore.
- Les notifications FCM partent depuis le backend sans exception.

## 6. Comment me notifier que les clés réelles sont installées

Le plus simple est de m’envoyer un message court de ce type :

Clés de production prêtes.
- Firebase Android : OK
- Firebase iOS : OK
- AdMob Android App ID : OK
- AdMob iOS App ID : OK
- Rewarded Ad Unit ID : OK
- RevenueCat Android Key : OK
- RevenueCat webhook secret : OK
- Fichiers natifs Firebase : OK

Si vous voulez être plus précis, ajoutez aussi :
- Ce qui est en prod
- Ce qui reste en test
- Les plateformes concernées
- Si vous souhaitez que je mette à jour le code, les manifests ou la documentation

Important : ne collez pas les secrets en clair dans le chat. Dites simplement qu’ils sont en place, puis indiquez si vous voulez que je remplace les valeurs de test par les valeurs de production dans le projet.

## 7. Règle pratique pour Lumora

- Tant que les clés réelles ne sont pas fournies, le projet peut continuer à fonctionner avec ses fallbacks et ses IDs de test.
- Dès que les clés réelles sont prêtes, il faut remplacer les valeurs de test dans Android, iOS, Flutter et le backend concerné.
- Si vous me le demandez ensuite, je peux faire la migration fichier par fichier sans toucher aux autres parties du projet.

## 8. Configuration native Facebook (Android + iOS)

### Android

Le projet est prêt avec placeholders natifs Facebook dans:
- android/app/src/main/AndroidManifest.xml
- android/app/build.gradle
- android/app/src/main/res/values/strings.xml

Valeurs à fournir:
- FACEBOOK_APP_ID
- FACEBOOK_CLIENT_TOKEN

Injection possible:
1. Variable shell avant build
2. Ou propriété Gradle

Exemple (shell):

FACEBOOK_APP_ID=123456789012345
FACEBOOK_CLIENT_TOKEN=your_facebook_client_token
flutter run

### iOS

Le projet charge une config optionnelle via:
- ios/Flutter/Debug.xcconfig
- ios/Flutter/Release.xcconfig

Créez le fichier local:
- ios/Flutter/FacebookConfig.xcconfig

En partant de:
- ios/Flutter/FacebookConfig.xcconfig.example

Variables à renseigner dans ce fichier:
- FACEBOOK_APP_ID
- FACEBOOK_CLIENT_TOKEN
- FACEBOOK_DISPLAY_NAME
- FACEBOOK_URL_SCHEME (en général `fb`)

Info.plist est déjà branché pour lire ces variables:
- FacebookAppID
- FacebookClientToken
- FacebookDisplayName
- URL scheme Facebook

## 9. Déploiement Firebase secrets + functions (commandes exactes)

### Prérequis

1. Installer Firebase CLI: https://firebase.google.com/docs/cli
2. Se connecter: `firebase login`
3. Vérifier le projet cible: `firebase projects:list`

### Commandes exactes sans script

Définir le projet:

`export FIREBASE_PROJECT_ID=lumora-staging`  (ou `lumora-prod`)

Pousser les secrets:

`printf '%s' "$REVENUECAT_WEBHOOK_SECRET" | firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET --project "$FIREBASE_PROJECT_ID" --force`

`printf '%s' "$RESEND_API_KEY" | firebase functions:secrets:set RESEND_API_KEY --project "$FIREBASE_PROJECT_ID" --force`

`printf '%s' "$RESEND_FROM_EMAIL" | firebase functions:secrets:set RESEND_FROM_EMAIL --project "$FIREBASE_PROJECT_ID" --force`

`printf '%s' "$EMAIL_VERIFICATION_PEPPER" | firebase functions:secrets:set EMAIL_VERIFICATION_PEPPER --project "$FIREBASE_PROJECT_ID" --force`

Déployer les functions:

`firebase deploy --only functions --project "$FIREBASE_PROJECT_ID"`

### Déploiement en une commande (script)

Script ajouté:
- scripts/deploy_firebase_env.sh

Usage:

1. Créer `.env.staging` et/ou `.env.prod` à la racine
2. Renseigner au minimum:
  - FIREBASE_PROJECT_ID
  - REVENUECAT_WEBHOOK_SECRET
  - RESEND_API_KEY
  - RESEND_FROM_EMAIL
  - EMAIL_VERIFICATION_PEPPER
3. Lancer:

`./scripts/deploy_firebase_env.sh staging`

ou

`./scripts/deploy_firebase_env.sh prod`

## 9.b Script jumelé mobile (build defines + préflight natif)

Script ajouté:
- scripts/deploy_mobile_env.sh

Objectif:
1. Charger `.env.staging` ou `.env.prod`
2. Vérifier les variables mobile obligatoires
3. Vérifier les fichiers natifs (`google-services.json`, `GoogleService-Info.plist`)
4. Générer `ios/Flutter/FacebookConfig.xcconfig`
5. Générer un fichier dart-define prêt build (`build/dart_defines.<env>.env`)
6. Optionnel: lancer un build smoke Android

Usage:

`./scripts/deploy_mobile_env.sh staging`

`./scripts/deploy_mobile_env.sh prod`

`./scripts/deploy_mobile_env.sh staging --build`

Commande build équivalente:

`flutter build apk --debug --dart-define-from-file=build/dart_defines.staging.env`

## 9.c Commande jumelée backend + mobile

Pour préparer staging rapidement:

1. `./scripts/deploy_mobile_env.sh staging`
2. `./scripts/deploy_firebase_env.sh staging`

Pour préparer prod:

1. `./scripts/deploy_mobile_env.sh prod`
2. `./scripts/deploy_firebase_env.sh prod`

## 9.d Smoke test auto au démarrage (staging)

Un smoke test auth est exécuté automatiquement au démarrage si `STAGING_SMOKE_AUTH=true`:
- Vérifie Firebase initialisé
- Vérifie accessibilité Firebase Auth email
- Vérifie disponibilité Apple (iOS/macOS)
- Vérifie présence config Facebook injectée
- Vérifie accessibilité de la function `sendEmailVerificationCode`

Implémentation:
- lib/features/auth/data/auth_startup_smoke.dart
- Hook au démarrage dans lib/main.dart

Activation:
- Le script mobile met automatiquement `STAGING_SMOKE_AUTH=true` pour `staging` dans le fichier dart-define généré.

## 10. Checklist de validation finale (Go / No-Go release)

### Comptes & accès

- [ ] Firebase projet prod validé
- [ ] Apple Developer actif
- [ ] Meta Developer + Facebook Login validé
- [ ] AdMob compte validé
- [ ] RevenueCat projet et produits validés

### Clés & secrets

- [ ] `google-services.json` prod installé
- [ ] `GoogleService-Info.plist` prod installé
- [ ] `ADMOB_*` prod configurés (Android + iOS + rewarded unit)
- [ ] `REVENUECAT_*` prod configurés
- [ ] `RESEND_API_KEY` configuré
- [ ] `RESEND_FROM_EMAIL` configuré
- [ ] `EMAIL_VERIFICATION_PEPPER` configuré
- [ ] `FACEBOOK_APP_ID` configuré Android et iOS
- [ ] `FACEBOOK_CLIENT_TOKEN` configuré Android et iOS

### Auth & backend

- [ ] Google login OK sur device réel
- [ ] Apple login OK sur device réel
- [ ] Facebook login OK sur device réel
- [ ] Email signup: code reçu + code validé + compte créé
- [ ] Firebase Functions déployées sans erreur
- [ ] Logs functions sans erreur critique

### Monétisation & QA

- [ ] Vidéo récompensée chargée et récompense appliquée
- [ ] Webhook RevenueCat reçu et persisté en base
- [ ] Règles Firestore validées pour prod

### GO / NO-GO

- [ ] GO release: toutes les cases ci-dessus validées
- [ ] NO-GO release: au moins une case critique non validée
