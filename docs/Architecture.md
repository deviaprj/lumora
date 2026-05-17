# Architecture Technique — Lumora

## 1. Stack Justifié

### 1.1 Pourquoi Flutter + Flame + Firebase

| Couche | Technologie | Justification |
|--------|-------------|---------------|
| **Framework** | Flutter 3.24+ (Dart 3.5+) | Single-codebase Android/iOS ; rendu Skia performant ; hot reload pour itération rapide ; accès natif via platform channels pour haptique, captures d'écran et partage. React Native est écarté car le rendu jeu (60 FPS, shaders, particules) y est trop lent via le pont JS. |
| **Game Engine** | Flame 1.18+ | Moteur 2D léger intégré nativement dans Flutter (même couche de rendu). Supporte les `CustomPainter`, les shaders GLSL via `FragmentProgram`, et la parallaxe via `ParallaxComponent`. Unity est écarté car l'overhead (> 50 Mo) et la complexité d'intégration Flutter (flutter_unity_widget) cassent la cohérence UI organique et allongent les temps de chargement. Godot n'a pas de binding Flutter mature. |
| **Backend BaaS** | Firebase (Auth, Firestore, Functions, Storage, FCM) | Serverless, scaling automatique, coût prévisible à faible volume (démarrage), intégration SDK native Flutter. Évite la maintenance d'un backend Node/Django dédié pour un MVP de 16 semaines. |
| **State Management** | Riverpod + build_runner | Génération de providers typés (`*.g.dart`), gestion fine des états `AsyncValue`, invalidation automatique des streams Firestore. Évite les boilerplates de Bloc pour un projet où la rapidité d'itération prime. |
| **Routing** | GoRouter | Déclaratif, deep linking natif, guards d'authentification intégrés, compatible avec les overlays de partage social. |
| **Monétisation** | RevenueCat (IAP) + Google Mobile Ads | RevenueCat normalise les achats cross-platform (Play/App Store) et fournit des webhooks sécurisés. AdMob est le standard d'exposition publicitaire mobile. Les deux SDKs sont wrappés dans des adapters pour permettre le mockage en tests et le remplacement futur (ex. MAX d'AppLovin). |

### 1.2 Pourquoi pas Unity / Godot / React Native

- **Unity** : Trop lourd pour un puzzle casual (< 100 Mo). L'intégration UI organique dans Flutter + overlay Unity est fragile et non-60-FPS sur mid-range. La monétisation IAP/pubs reste identique, donc l'overhead n'est pas justifié.
- **Godot** : Excellent pour le jeu pur, mais aucun binding Flutter stable. Il faudrait exporter en bibliothèque native, ce qui complexifie le pipeline CI/CD et le partage de contexte utilisateur (auth, analytics).
- **React Native** : Le pont JavaScript est un goulot d'étranglement pour le rendu de particules et de shaders temps réel. Flame n'existe pas dans l'écosystème RN.

---

## 2. Arborescence Projet détaillée

```
lumora-mobile/
├── android/                        # Android native (API 26+, Kotlin)
│   └── app/build.gradle            # dart-define AdMob IDs, Firebase config
├── ios/                            # iOS native (14+, Swift)
│   └── Runner/GoogleService-Info.plist
├── lib/
│   ├── main.dart                   # Entry point : init Firebase, AdMob, RevenueCat, Flame
│   ├── app/
│   │   ├── router.dart             # GoRouter : routes + auth guards + deep links
│   │   └── theme.dart              # Design system Lumora : LumoraColors, LumoraGradients, LumoraShadows
│   ├── core/
│   │   ├── constants.dart          # API URLs, Remote Config keys, AdMob IDs (const conditional)
│   │   ├── secure_storage.dart     # FlutterSecureStorage : tokens, UID anonyme, sauvegarde chiffrée
│   │   ├── firebase_options.dart   # Configuration multi-environnement (dev, staging, prod)
│   │   ├── platform/
│   │   │   └── platform_service.dart # isMobile, isExtension, isDesktop (Linux dev sans Firebase)
│   │   └── providers/
│   │       ├── firebase_providers.g.dart   # Auth, Firestore, Analytics, Crashlytics, Remote Config
│   │       └── app_providers.dart          # Connectivity, app lifecycle, gyroscope
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── auth_repository.dart    # FirebaseAuth + GoogleSignIn + SignInWithApple
│   │   │   │   └── anonymous_linker.dart   # Fusion anonyme -> authentifié
│   │   │   ├── domain/
│   │   │   │   └── app_user.dart           # Modèle Freezed : uid, displayName, avatar, authProvider
│   │   │   └── presentation/
│   │   │       ├── auth_screen.dart        # Bulles organiques Google/Apple/Email/Anonyme
│   │   │       └── auth_notifier.dart      # Riverpod : signIn, linkAccount, signOut
│   │   ├── game/
│   │   │   ├── data/
│   │   │   │   ├── level_repository.dart   # Firestore levels/{id} + cache local Hive
│   │   │   │   └── hint_config_repository.dart # Remote Config hint params + fallback local JSON
│   │   │   ├── domain/
│   │   │   │   ├── level.dart              # Modèle : id, worldId, nodes, rules, timeLimit
│   │   │   │   └── hint_params.dart        # delay, opacity, frequency, tier
│   │   │   ├── engine/
│   │   │   │   ├── lumora_game.dart        # Flame Game : caméra, composants monde, nœuds
│   │   │   │   ├── node_component.dart     # Sprite + hitbox + glow shader
│   │   │   │   ├── filament_component.dart # CustomPainter : trait lumineux avec glow
│   │   │   │   ├── parallax_background.dart# ParallaxComponent multi-couches
│   │   │   │   └── particle_system.dart    # Effets particules (victoire, combo, erreur)
│   │   │   └── presentation/
│   │   │       ├── game_screen.dart        # Overlay UI (vies, timer, pause, indice)
│   │   │       ├── world_map_screen.dart   # Bulles flottantes reliées par Bézier
│   │   │       ├── victory_overlay.dart    # Particules, étoiles, partage
│   │   │       └── game_notifier.dart      # État gameplay : niveau courant, combo, timer
│   │   ├── monetization/
│   │   │   ├── data/
│   │   │   │   ├── ad_mob_adapter.dart     # Wrapper GoogleMobileAds (interstitiel, récompensée)
│   │   │   │   ├── revenue_cat_adapter.dart# Wrapper purchases_flutter
│   │   │   │   └── purchase_validator.dart # Cloud Function receipt validation
│   │   │   ├── domain/
│   │   │   │   ├── product.dart            # SKU, prix local, type (consommable, non-consommable, abonnement)
│   │   │   │   └── ad_config.dart          # fréquence interstitiel, cooldown, exemption passe
│   │   │   └── presentation/
│   │   │       ├── shop_screen.dart        # Cartes organiques avec aperçu 3D
│   │   │       └── monetization_notifier.dart # État IAP + pub (loaded, rewarded, etc.)
│   │   ├── social/
│   │   │   ├── data/
│   │   │   │   ├── screenshot_service.dart # RepaintBoundary -> PNG + overlay organique
│   │   │   │   └── dynamic_link_service.dart # Firebase Dynamic Links : invites + parrainage
│   │   │   ├── domain/
│   │   │   │   └── share_payload.dart      # imagePath, text, deepLink, network
│   │   │   └── presentation/
│   │   │       └── share_overlay.dart      # Bulle flottante Instagram/Facebook/WhatsApp…
│   │   ├── events/
│   │   │   ├── data/
│   │   │   │   ├── event_repository.dart   # Firestore events/ + cache Hive
│   │   │   │   └── leaderboard_repository.dart # Cloud Function leaderboardUpdate
│   │   │   ├── domain/
│   │   │   │   ├── game_event.dart         # Type, dates, rewards, constraints
│   │   │   │   └── leaderboard_entry.dart  # uid, score, rank, timestamp
│   │   │   └── presentation/
│   │   │       ├── events_screen.dart      # Carte événement avec compte à rebours circulaire
│   │   │       └── events_notifier.dart    # État événements actifs, participations
│   │   └── settings/
│   │       ├── data/
│   │       │   └── settings_repository.dart # Firestore users/{uid}/settings + local
│   │       ├── domain/
│   │       │   └── user_settings.dart      # son, musique, vibrations, notifications, indicesAuto
│   │       └── presentation/
│   │           └── settings_screen.dart    # Cartes organiques empilées, toggles iOS-style
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── lumora_button.dart          # Widget organique : forme bulle, dégradé, ombre, inkWell arrondi
│   │   │   ├── lumora_card.dart            # Conteneur glassmorphism : blur + bordure blanche + coins arrondis
│   │   │   ├── lumora_modal.dart           # Modal bottom-sheet organique avec hero animation
│   │   │   └── sync_indicator.dart         # Nuage + flèche : vert/orange/rouge (état sync)
│   │   ├── animations/
│   │   │   ├── elastic_scale.dart          # Animation bounce elastic pour étoiles
│   │   │   └── fade_slide_transition.dart  # Courbe ease-in-out-cubic pour navigation
│   │   └── extensions/
│   │       └── color_extensions.dart       # Dégradés, luminosité, glassmorphism helpers
│   └── generated/                        # *.g.dart, *.freezed.dart (exclus de l'analyse)
├── backend/
│   └── functions/
│       ├── src/
│       │   ├── checkQuota.ts               # Vérification quota anti-triche (appelé par client)
│       │   ├── dailyRewardReset.ts         # Reset récompenses quotidiennes à 00:00 UTC
│       │   ├── eventScheduler.ts         # Déclenchement événements via Cloud Scheduler
│       │   ├── leaderboardUpdate.ts      # Agrégation scores tournoi
│       │   ├── purchaseValidation.ts       # Validation receipt IAP côté serveur
│       │   └── referralCredit.ts           # Crédit parrainage après install via Dynamic Link
│       └── package.json
├── tests/
│   ├── unit/                               # Core, repositories, notifiers (tags: unit)
│   ├── widget/                             # UI organique : LumoraButton, LumoraCard, écrans (tags: widget)
│   ├── integration/                        # Parcours complet : auth -> niveau -> pub -> IAP (tags: integration)
│   └── test_helpers.dart                   # Mocks AdMob, RevenueCat, Firebase, mocks Flame Game
├── devops/
│   ├── github/
│   │   └── workflows/
│   │       ├── ci.yml                      # flutter analyze + test + coverage
│   │       └── cd.yml                      # fastlane deploy Firebase / stores
│   ├── fastlane/
│   │   ├── android/Fastfile                # build + deploy Google Play (internal, alpha, production)
│   │   └── ios/Fastfile                    # build + deploy TestFlight / App Store
│   └── firebase/
│       ├── firestore.rules                 # Règles user-scoped + indexation
│       ├── firestore.indexes.json          # Index composites pour requêtes leaderboard
│       ├── storage.rules                    # Accès public images de partage
│       └── remote_config_defaults.json      # Valeurs par défaut hint system, pub frequency, prix IAP
├── assets/
│   ├── images/                             # Sprites 2D, fonds parallaxe, bulles UI
│   ├── shaders/                            # GLSL fragment shaders (glow, glassmorphism, ripple)
│   ├── audio/                              # Musiques procédurales, SFX cristallins
│   └── fonts/                              # Police organique arrondie (ex. Nunito, Quicksand)
├── scripts/
│   ├── run_tests.sh                        # ./run_tests.sh [unit|widget|integration|coverage]
│   └── build_runner.sh                     # flutter pub run build_runner --delete-conflicting-outputs
├── android/app/build.gradle
├── ios/Runner.xcworkspace
├── pubspec.yaml                            # Dépendances : flame, riverpod, firebase, share_plus, etc.
└── dart_test.yaml                          # Timeouts par tag : unit 30s, widget 60s, integration 5m
```

---

## 3. Schéma Base de Données Firestore

### 3.1 Collections et Documents

```
users/{uid}                          # Document utilisateur principal
  ├── profile
  │     displayName: string
  │     avatarUrl: string
  │     createdAt: timestamp
  │     lastLoginAt: timestamp
  │     authProvider: "google" | "apple" | "email" | "anonymous"
  ├── settings
  │     music: bool
  │     sound: bool
  │     vibrations: bool
  │     notifications: bool
  │     hintsAuto: bool
  │     language: string
  │     timezone: string
  └── anonymousLinkedTo: string      # UID authentifié après liaison

progress/{uid}                       # Progression unique par utilisateur
  ├── currentLevel: number
  ├── currentWorld: number
  ├── starsByLevel: map<number, number>   # {levelId: 1|2|3}
  ├── unlockedLevels: array<number>
  ├── totalStars: number
  ├── lastSyncAt: timestamp
  └── localDeviceId: string          # Pour résolution conflit

inventory/{uid}                      # Inventaire temps réel
  ├── lives: number                  # 0–5 (max 5 par défaut)
  ├── livesLastRegenAt: timestamp    # Pour calcul régénération côté client
  ├── hintTokens: number             # 0–3 max
  ├── hintTokensLastRegenAt: timestamp
  ├── unlockedThemes: array<string>
  ├── activeSeasonPass: object       # {active: bool, expiresAt: timestamp, seasonId: string}
  ├── consumables: map<string, number>
  └── cosmetics: array<string>       # Avatars, titres, badges

purchases/{uid}                      # Historique achats (audit + restauration)
  ├── transactions: array<{
  │     transactionId: string
  │     productId: string
  │     revenueCatId: string
  │     priceUsd: number
  │     purchasedAt: timestamp
  │     platform: "android" | "ios"
  │     restored: bool
  │   }>
  └── firstPurchaseAt: timestamp

events/{uid}                         # Participation événements
  ├── activeParticipations: array<{
  │     eventId: string
  │     eventType: "daily" | "weekend" | "seasonal" | "tournament"
  │     score: number
  │     completedLevels: number
  │     rewardsClaimed: array<string>
  │     startedAt: timestamp
  │     expiresAt: timestamp
  │   }>
  └── history: subcollection

levels/{levelId}                     # Données statiques niveaux (lecture publique)
  ├── worldId: number
  ├── difficultyTier: number
  ├── nodes: array<{x, y, color, type}>
  ├── rules: array<string>
  ├── timeLimit: number              # null = illimité
  └── obstacles: array<{x, y, pattern}>

eventDefinitions/{eventId}           # Définitions événements (lecture publique)
  ├── type: string
  ├── startAt: timestamp
  ├── endAt: timestamp
  ├── rules: object
  ├── rewards: array<object>
  └── requiresSeasonPass: bool

leaderboards/{tournamentId}/entries/{uid}
  ├── score: number
  ├── bestLevelTime: number
  ├── updatedAt: timestamp
  └── nickname: string               # dénormalisé pour affichage rapide

referrals/{referralCode}             # Codes de parrainage
  ├── referrerUid: string
  ├── createdAt: timestamp
  ├── uses: number
  └── maxUses: number
```

### 3.2 Règles de Sécurité Firestore

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Fonctions utilitaires
    function isAuthenticated() {
      return request.auth != null;
    }
    function isOwner(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }
    function isAnonymousLinked(uid) {
      return isAuthenticated() &&
             get(/databases/$(database)/documents/users/$(uid)).data.anonymousLinkedTo == request.auth.uid;
    }

    // Collections user-scoped : seul le propriétaire (ou compte lié) peut lire/écrire
    match /users/{uid} {
      allow read, write: if isOwner(uid) || isAnonymousLinked(uid);
    }
    match /progress/{uid} {
      allow read, write: if isOwner(uid) || isAnonymousLinked(uid);
    }
    match /inventory/{uid} {
      allow read, write: if isOwner(uid) || isAnonymousLinked(uid);
    }
    match /purchases/{uid} {
      allow read: if isOwner(uid) || isAnonymousLinked(uid);
      allow write: if false; // Écriture uniquement via Cloud Function (sécurité IAP)
    }
    match /events/{uid} {
      allow read, write: if isOwner(uid) || isAnonymousLinked(uid);
    }

    // Données statiques : lecture publique
    match /levels/{levelId} {
      allow read: if true;
      allow write: if false; // Seulement via Admin SDK ou CI
    }
    match /eventDefinitions/{eventId} {
      allow read: if true;
      allow write: if false;
    }

    // Leaderboard : écriture via Cloud Function uniquement (validation anti-triche)
    match /leaderboards/{tournamentId}/entries/{uid} {
      allow read: if true;
      allow write: if false; // Écriture via leaderboardUpdate.ts
    }

    // Referrals : lecture publique (vérification existence), écriture via Functions
    match /referrals/{code} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### 3.3 Indexations

```json
{
  "indexes": [
    {
      "collectionGroup": "entries",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "score", "order": "DESCENDING" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "eventType", "order": "ASCENDING" },
        { "fieldPath": "expiresAt", "order": "ASCENDING" }
      ]
    }
  ]
}
```

**Principal challenge de sécurité** : La vérification côté serveur des achats IAP. Les règles Firestore interdisent l'écriture directe dans `purchases/{uid}` ; seule la Cloud Function `purchaseValidation.ts` (déclenchée par RevenueCat webhook) peut écrire l'historique, empêchant la falsification client-side des transactions.

---

## 4. API et Services

### 4.1 Cloud Functions Endpoints (Node.js 20, Firebase Functions v2)

| Endpoint | Méthode | Déclencheur | Description | Idempotence |
|----------|---------|-------------|-------------|-------------|
| `checkQuota` | HTTPS callable | Client (avant niveau) | Vérifie quota anti-triche (pas de bypass client) | Clé unique par niveau+session |
| `dailyRewardReset` | Scheduled | Cloud Scheduler 00:00 UTC | Réinitialise les récompenses quotidiennes pour tous les utilisateurs actifs | Opération sur batch Firestore avec `lastResetDate` |
| `eventScheduler` | Scheduled | Cloud Scheduler (fréquence variable) | Crée/ouvre les événements (week-end, saison, tournoi, happy hour) | Vérifie `eventDefinition.startAt` avant création |
| `leaderboardUpdate` | Firestore trigger | Écriture `events/{uid}` | Agrège les scores du tournoi en cours et met à jour le classement | Clé composite `tournamentId+uid` |
| `purchaseValidation` | HTTPS | RevenueCat webhook | Reçoit le webhook `INITIAL_PURCHASE`, écrit dans `purchases/{uid}` | Vérification `transactionId` déjà existant |
| `referralCredit` | HTTPS callable | Client (après install) | Crédite le parrain si nouvel install validé via device ID | Device ID stocké dans `referrals/{code}/devices` |

### 4.2 Firebase Auth Flows

1. **Anonyme** : `FirebaseAuth.instance.signInAnonymously()` → UID généré → progression stockée dans Firestore sous cet UID.
2. **Liaison** : `linkWithCredential(GoogleAuthProvider.credential(...))` → Cloud Function `mergeAnonymousData` fusionne `progress/{oldUid}` vers `progress/{newUid}` si conflit (max étoiles, max niveau). Si conflit non résoluble automatiquement, la modale côté client propose la version locale vs cloud.
3. **Restauration cross-device** : Connexion sur nouvel appareil → `onAuthStateChanged` → lecture `progress/{uid}` → écriture SecureStorage locale → indicateur sync vert.

### 4.3 RevenueCat Webhooks

- **URL cible** : `https://<region>-<project>.cloudfunctions.net/purchaseValidation`
- **Événements écoutés** : `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `BILLING_ISSUE`
- **Traitement** : Validation du receipt côté serveur (Google Play RTDN / Apple App Store Server API) → écriture Firestore → invalidation cache client via FCM silent push.

### 4.4 AdMob Events

- **Événements trackés** : `ad_interstitial_show`, `ad_rewarded_show`, `ad_impression`, `ad_click`, `ad_failed_to_load`
- **Flux** : AdMob SDK -> Firebase Analytics (lien automatique) -> BigQuery (optionnel pour analyse LTV).
- **Configuration** : IDs AdMob passés via `--dart-define` ; fréquence interstitielle récupérée via Remote Config (`ad_interstitial_every_n_levels`).

---

## 5. Stratégie Offline-First

### 5.1 Architecture Cache

| Source de Vérité | Cache Local | Sync Direction | Technologie |
|------------------|-------------|----------------|-------------|
| Firestore | Hive boxes (`progress`, `inventory`, `settings`) | Bidirectionnel (Firestore -> Hive dès connexion ; Hive -> Firestore à chaque mutation) | `cloud_firestore` offline persistence + Hive pour structures complexes |
| Niveaux statiques | Hive `levels` box + préchargement au premier lancement | Unidirectionnel (cloud vers local, rarement modifiés) | Téléchargement batch au onboarding |
| Images/assets | `cached_network_image` + `flutter_cache_manager` | Unidirectionnel | Cache fichier local |

### 5.2 Mécanisme de Sync

1. **Écriture locale immédiate** : Toute mutation (fin de niveau, achat, changement paramètre) est écrite dans Hive en < 10ms.
2. **Queue de sync** : Une queue ordonnée (type FIFO) persiste dans Hive avec les opérations en attente. Chaque entrée contient un `timestamp`, un `operationType` et un `checksum`.
3. **Sync automatique** : `ConnectivityProvider` (Riverpod) écoute `connectivity_plus`. Dès retour online, la queue est consommée par batchs de 50 opérations maximum pour éviter les timeouts Firestore.
4. **Résolution de conflits** :
   - **Règle principale** : timestamp le plus récent gagne.
   - **Progression** : si conflit sur `starsByLevel`, on conserve le max d'étoiles par niveau ; si conflit sur `currentLevel`, on conserve le niveau le plus avancé.
   - **Inventaire** : somme des consommables si les deux côtés ont consommé entre-temps (ex. +1 vie sur device A, -1 vie sur device B = net 0).
   - **Conflit irréductible** : modale utilisateur organique (`LumoraModal`) pour choisir la version à garder (rare, < 0.1 % des cas).

### 5.3 Indicateur Visuel de Sync

Widget `SyncIndicator` affiché en haut à droite de l'écran d'accueil :
- **Vert** (`Icons.cloud_done`) : Toutes les données sont synchronisées avec Firestore.
- **Orange** (`Icons.cloud_upload`) : Des modifications locales sont en attente de sync.
- **Rouge** (`Icons.cloud_off`) : Erreur de sync (Firestore indisponible ou règle rejetée). Tap = retry manuel + log Crashlytics.

---

## 6. Plan Maximisation Revenus

### 6.1 Emplacements Publicitaires Optimaux

| Type | Placement | Déclencheur | Contrainte |
|------|-----------|-------------|------------|
| **Interstitielles** | Après l'écran de victoire, avant la carte | Tous les X niveaux (Remote Config : 3, 5 ou 7) | Jamais après défaite ; cooldown 60s ; jamais si `activeSeasonPass == true` |
| **Récompensées** | Bouton "Bonus" bulle flottante (accueil), écran défaite (vies=0), boutique | Action volontaire du joueur | Max 3/jour pour les vies ; 1x/niveau pour le déblocage |
| **Bannières** | Aucune | — | Lumora n'utilise pas de bannières pour préserver l'immersion organique |

### 6.2 Déclencheurs IAP (Conversion douce)

1. **Défaite + vies = 0** : proposition contextuelle de pack de vies (0.99 $) ou vidéo récompensée. Bouton organique `LumoraButton` en bulle rouge douce.
2. **3 étoiles sur 10 niveaux consécutifs** : suggestion thème cosmétique Nébula (1.99 $) avec aperçu 3D rotatif dans la boutique.
3. **Happy Hour** : notification push "-50 % sur les IAP" + badge doré dans la boutique.
4. **Premier achat** : bonus de 3 vies gratuites pour inciter la conversion (affiché dans une bulle de remerciement organique).

### 6.3 Segmentation et A/B Testing

| Segment | Caractéristique | Stratégie |
|---------|-----------------|-----------|
| **Non-payers** | 0 achat, > 20 vidéos récompensées | Cohorte B : prix IAP réduits de 20 % (Remote Config) |
| **Payers occasionnels** | 1–2 achats < 5 $ | Offre bundle "Pack Vies + Thème" à 3.99 $ |
| **Whales** | > 3 achats ou Passe Saisonnier actif | Pas de pubs, accès anticipé aux événements, avatar exclusif |
| **Churné** | Pas de session depuis 7j | Offre de retour "Cadeau de Retour" + Passe essai 3j |

### 6.4 LTV Optimization

- **Cohorte Day-0** : tracker ARPDAU par cohorte via Firebase Analytics.
- **Prédictions Firebase** : utiliser l'audience "predicted_churners" pour proposer une vidéo récompensée doublée avant le départ.
- **Passe Saisonnier** : récurrent par nature (mensuel), LTV > 4.99 $ si renouvellement. Revenu garanti vs pubs variables.
- **Cap LTV** : objectif >= 2.50 $ par utilisateur sur 180 jours (via revenus pubs + IAP cumulés).

---

## 7. Intégration FCM / APNs pour Notifications et Événements

### 7.1 Topics et Segments

| Topic | Audience | Messages types |
|-------|----------|----------------|
| `all_players` | 100 % utilisateurs | Lancement événement saisonnier, MAJ majeure |
| `active_payers` | Possède un achat IAP | Happy Hour "Soldes", expiration Passe |
| `churn_24h` | Dernière session > 24h | "Ta récompense quotidienne t'attend" |
| `churn_7d` | Dernière session > 7j | "Ta flamme s'éteint…" + offre retour |
| `churn_30d` | Dernière session > 30j | "Lumora a changé !" + nouveautés |
| `near_perfect` | 2 étoiles sur un niveau difficile depuis 24h | "Il ne te manque qu'une étincelle pour le perfect !" |
| `social_sharers` | > 3 partages | "Tes amis parlent de toi !" + récompense parrainage |

### 7.2 Scheduling et Automatisation

- **Cloud Functions** : `scheduleNotifications.ts` s'exécute toutes les heures via Cloud Scheduler. Elle requête Firestore pour les segments dynamiques (churn, near_perfect) et envoie des messages FCM par topics.
- **Timezone-aware** : le champ `users/{uid}/settings/timezone` est utilisé pour planifier l'envoi à 20h locale (événement quotidien) et 10h locale (tournoi).
- **Rate limiting** : maximum 3 notifications push par utilisateur et par jour (hors événements majeurs).

### 7.3 Fallback Notifications Locales

Si l'utilisateur refuse FCM ou si le token est invalide :
- **Scheduling local** : `flutter_local_notifications` programme les notifications de retour (24h, 72h, 7j, 30j) au moment de la fermeture de l'app (`didChangeAppLifecycleState` -> `inactive`).
- **Contenu** : identique aux notifications FCM, mais sans personnalisation dynamique (pas de "niveau 12" spécifique, message générique).
- **Synchronisation** : à chaque ouverture, les notifications locales programmées sont recalculées et annulées/remplacées pour éviter les doublons FCM + locale.

---

## 8. Sécurité et Conformité

### 8.1 Règles Firestore (Résumé des contraintes)

- **User-scoped strict** : `request.auth.uid == uid` obligatoire pour toute collection privée (`users`, `progress`, `inventory`, `purchases`, `events`).
- **Écriture purchases interdite client-side** : `allow write: if false` sur `purchases/{uid}`. Seule la Cloud Function `purchaseValidation` (déclenchée par webhook RevenueCat) peut écrire, garantissant l'intégrité financière.
- **Leaderboard protégé** : écriture impossible depuis le client ; `leaderboardUpdate.ts` agrège les scores valides et écrit avec `admin` SDK.

### 8.2 Validation IAP côté Serveur

1. **RevenueCat** gère la validation primaire (receipt Play Store / App Store).
2. **Webhook** vers `purchaseValidation.ts` vérifie la signature du payload et l'unicité du `transactionId`.
3. **Double-check** (optionnel mais recommandé) : la function appelle l'API Google Play Developer / Apple App Store Server API pour valider le receipt si le webhook est suspect (prix anormal, produit inconnu).
4. **Rollback** : si un achat est signalé comme frauduleux, la function crédite un champ `fraudFlag` et notifie l'utilisateur via FCM silent push pour invalidation client-side.

### 8.3 GDPR / COPPA

| Exigence | Implémentation |
|----------|----------------|
| **Consentement explicite** | Écran onboarding (obligatoire) : toggle organique pour Analytics, Ads, Crashlytics. Stocké dans `users/{uid}/settings/consents`. |
| **Droit à l'effacement** | Endpoint Cloud Function `deleteUserData(uid)` : supprime `users/{uid}`, `progress/{uid}`, `inventory/{uid}`, anonymise `leaderboards/*` (remplace pseudo par "Joueur supprimé"). Appelable depuis Paramètres. |
| **Portabilité** | Bouton "Télécharger mes données" exporte JSON chiffré via Firebase Storage (URL temporaire 24h). |
| **COPPA** | Si l'utilisateur déclare < 13 ans (écran onboarding), les publicités AdMob sont désactivées et les données Analytics sont anonymisées (pas de device ID, pas de segment publicitaire). |
| **Anonymisation** | Les documents `leaderboards` et `eventDefinitions` n'exposent jamais d'email ou de nom réel ; seul le `nickname` dénormalisé et un `uid` hashé sont visibles. |

---

## 9. Performance et Scalabilité

### 9.1 Chargement Niveau < 2 secondes

- **Préchargement** : lors du splash screen, les assets du monde courant + monde suivant sont chargés en mémoire (`ImageCache` + `AudioCache`).
- **Hive** : les données de niveau sont stockées localement ; aucun appel réseau n'est nécessaire pour jouer un niveau déjà téléchargé.
- **Lazy loading monde** : les mondes > N+2 ne sont chargés que lors du scroll approchant sur la carte.
- **Shaders compilés** : les shaders GLSL sont précompilés au build (`flutter build` avec `--bundle-sksl-path` sur les devices cibles testés) pour éviter le jank de compilation shader au premier rendu.

### 9.2 60 FPS et Gestion Mémoire

- **Flame game loop** : `FixedResolutionViewport` (1080×1920 logique) pour cohérence visuelle ; scaling matériel natif.
- **Object pooling** : les nœuds, particules et filaments sont réutilisés via `PoolObject<T>` pour éviter les allocations GC pendant le gameplay.
- **Disposal explicite** : `dispose()` sur `Image`, `AudioPlayer`, `Shader` lors de la fermeture d'un niveau.
- **Jank monitoring** : `FlutterPerformance` en mode debug ; objectif < 5 % de frames au-dessus de 16.6ms.

### 9.3 Cache Images et Assets

- **`cached_network_image`** : images profil, avatars, thèmes cosmétiques (TTL 7 jours).
- **`flutter_cache_manager`** : assets dynamiques téléchargés (thèmes saisonniers, musiques événements).
- **Firebase Storage CDN** : images de partage social générées par `screenshot_service` uploadées avec metadata `cache-control: public, max-age=2592000`.

### 9.4 Scalabilité Backend

- **Firestore** : modèle plat (pas de sous-collections profondes), documents < 1 Mo. Les tableaux `transactions` dans `purchases/{uid}` sont limités à 100 entrées ; au-delà, archivage vers `purchases/{uid}/history`.
- **Cloud Functions** : scaling automatique, mémoire allouée 256 Mo pour les functions légères, 1 Go pour `leaderboardUpdate` (batch d'écriture).
- **Rate limiting** : `checkQuota` utilise un compteur Firestore (`FieldValue.increment`) avec une règle de sécurité côté client pour éviter le spam.

---

## 10. CI/CD et DevOps

### 10.1 GitHub Actions (`ci.yml`)

```yaml
name: CI Lumora
on: [push, pull_request]
jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - run: flutter analyze --no-fatal-infos
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4
```

### 10.2 Fastlane

| Plateforme | Lane | Description |
|------------|------|-------------|
| Android | `internal` | Build APK debug -> Google Play Internal Testing Track |
| Android | `beta` | Build AAB release -> Closed Testing |
| Android | `production` | Build AAB release -> Production graduelle (10 %, 50 %, 100 %) |
| iOS | `beta` | Build iOS -> TestFlight Internal |
| iOS | `release` | Build iOS -> App Store Connect + soumission automatique |

- **Signing** : keystores et provisioning profiles stockés dans GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `IOS_MATCH_PASSWORD`).
- **Dart defines** : API keys (AdMob, DeepSeek/OpenRouter si IA intégrée) injectées via `--dart-define` au build, jamais en dur dans le repo.

### 10.3 Déploiement Firebase

- **Firestore rules** : déployées via `firebase deploy --only firestore:rules` dans le pipeline CI après merge sur `main`.
- **Cloud Functions** : déployées via `firebase deploy --only functions` avec option `--force` uniquement en staging ; production nécessite review manuelle.
- **Remote Config** : valeurs par défaut versionnées dans `devops/firebase/remote_config_defaults.json` et uploadées via script Python dans le pipeline.

### 10.4 Tests Automatisés

| Type | Commande | Seuil |
|------|----------|-------|
| Unit | `flutter test --tags unit` | Couverture >= 70 % |
| Widget | `flutter test --tags widget` | Pass 100 %, pas de régression LumoraButton/LumoraCard |
| Integration | `flutter test integration_test/` | Parcours complet : auth -> niveau 1 -> pub -> IAP |
| Performance | `flutter test --tags performance` | Chargement niveau < 2s, jank < 5 % |

---

## 11. Contraintes Transversales — Vérification Technique

Cette section atteste que chacune des 9 contraintes du projet est supportée par l'architecture décrite ci-dessus.

| # | Contrainte | Support Architectural | Statut |
|---|------------|----------------------|--------|
| 1 | **UI organique** | `lib/shared/widgets/lumora_button.dart` et `lumora_card.dart` sont les seuls widgets interactifs approuvés. `theme.dart` définit `LumoraColors` et `LumoraGradients` sans dépendance à `MaterialButton` ou `ElevatedButton`. Les écrans `auth_screen`, `shop_screen`, `settings_screen` utilisent ces composants exclusifs. Règle lint personnalisée dans `analysis_options.yaml` interdit l'import de `material/buttons` brut. | ✅ Couvert |
| 2 | **2D avec effets 3D** | Flame `ParallaxComponent` dans `parallax_background.dart`, shaders GLSL dans `assets/shaders/` (glow, ripple, glassmorphism), `CustomPainter` pour les filaments lumineux. Le rendu est Skia/Impeller natif Flutter, donc 60 FPS garanti sans bridge. | ✅ Couvert |
| 3 | **Indices visuels décroissants** | `hint_config_repository.dart` récupère les paramètres via Firebase Remote Config avec fallback sur `assets/hints_fallback.json`. Le `HintSystem` applique `delay`, `opacity`, `frequency` par palier de niveau via une table de mapping injectée par Riverpod. | ✅ Couvert |
| 4 | **Compte utilisateur + sauvegarde cross-device** | Firebase Auth (Google, Apple, Email, Anonyme) avec `anonymous_linker.dart`. Firestore `users/{uid}`, `progress/{uid}`, `inventory/{uid}` sont user-scoped et synchronisés offline-first via Hive + queue de sync. Restauration automatique en < 5s après `onAuthStateChanged`. | ✅ Couvert |
| 5 | **Partage social** | `screenshot_service.dart` utilise `RepaintBoundary` + `share_plus` pour capturer le niveau et générer un overlay organique (avatar rond, texte bulle, fond glassmorphism). `dynamic_link_service.dart` génère des liens Firebase avec tracking parrainage. | ✅ Couvert |
| 6 | **Gratuit + pubs + IAP abordables** | `monetization/data/ad_mob_adapter.dart` et `revenue_cat_adapter.dart` fournissent une abstraction (pattern Adapter) permettant de swapper AdMob/RevenueCat sans toucher la couche domaine. Tous les IAP sont <= 4.99 $ configurés côté store. Remote Config pilote la fréquence des interstitielles. | ✅ Couvert |
| 7 | **Événements automatiques** | `eventScheduler.ts` (Cloud Function) déclenchée par Cloud Scheduler ouvre/ferme les événements. Aucune action manuelle requise. Fonctions idempotentes via vérification `eventDefinition.startAt`. Monitoring via Firebase Console ; rollback documenté (script `rollback_event.sh`). | ✅ Couvert |
| 8 | **Notifications de retour** | FCM topics (`churn_24h`, `churn_7d`, `churn_30d`) + fallback `flutter_local_notifications` si FCM refusé. Segmentation par comportement (engagement, monétisation, churn) via `scheduleNotifications.ts`. | ✅ Couvert |
| 9 | **Sessions courtes, accessible, addictif** | Core loop optimisé pour 30–90s par niveau. Offline-first évite le blocage réseau. Anti-frustration intégrée dans `game_notifier.dart` (3 échecs -> proposition aide). Haptique + SFX + particules à chaque action pour feedback dopaminergique immédiat. | ✅ Couvert |

---

*Document généré le 2026-05-07. Sous-agent Architecte — Projet Lumora.*
