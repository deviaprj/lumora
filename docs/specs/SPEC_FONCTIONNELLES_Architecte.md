# SPEC_FONCTIONNELLES_Architecte.md — Lumora

## Livrable source
- `docs/Architecture.md` — Architecture technique complète (605 lignes)

---

## Résumé de l'architecture
**Stack** : Flutter 3.24+ + Flame 1.18+ (game engine 2D intégré natif) + Firebase (Auth, Firestore, Functions, Storage, FCM) + Riverpod + GoRouter + RevenueCat + Google Mobile Ads.
**Justification** : Single-codebase Android/iOS, rendu Skia natif 60 FPS, hot reload rapide, intégration directe widgets custom organiques et shaders GLSL. Unity écarté (trop lourd), Godot (pas de binding Flutter), React Native (pont JS trop lent pour particules/shaders).

## Cas d'usage consolidés

| ID | Cas d'usage | Acteur | Description |
|----|-------------|--------|-------------|
| UC-AR-01 | Développer le client Flutter | Développeur frontend | Implémenter écrans, gameplay, UI organique, effets 3D |
| UC-AR-02 | Déployer le backend Firebase | Développeur backend | Configurer Auth, Firestore, Functions, FCM, Storage |
| UC-AR-03 | Sécuriser les achats IAP | Backend | Valider receipts côté serveur, empêcher falsification client-side |
| UC-AR-04 | Orchestrer les événements automatiques | Backend | Planifier et déclencher défis quotidiens, week-end, tournois, happy hours |
| UC-AR-05 | Envoyer des notifications segmentées | Backend | FCM topics + fallback locales selon comportement (churn, engagement) |
| UC-AR-06 | Assurer la conformité GDPR/COPPA | Équipe juridique/QA | Consentement explicite, droit à l'effacement, anonymisation |
| UC-AR-07 | Optimiser les revenus | Product Owner | A/B testing prix, fréquence pubs, segmentation joueurs, LTV |
| UC-AR-08 | Garantir la performance | QA/Développeur | Chargement niveau <2s, 60 FPS, jank <5%, gestion mémoire |
| UC-AR-09 | Maintenir la qualité via CI/CD | DevOps | GitHub Actions + Fastlane + tests automatisés + déploiement graduel |

## User stories consolidées

| ID | User Story | Critères d'acceptation |
|----|------------|------------------------|
| US-AR-01 | En tant que développeur frontend, je veux une arborescence claire et des composants partagés, afin de développer l'UI organique sans duplication. | Arborescence lib/ avec shared/widgets (LumoraButton, LumoraCard), features/, generated/. |
| US-AR-02 | En tant que développeur backend, je veux des Cloud Functions idempotentes et sécurisées, afin de gérer les événements et les achats sans risque. | Functions TypeScript v2 avec vérification d'idempotence, règles Firestore strictes. |
| US-AR-03 | En tant que product owner, je veux une segmentation des joueurs et des tests A/B, afin de maximiser les revenus sans frustrer les utilisateurs. | Remote Config pilote fréquence pubs, prix IAP, courbe difficulté, indices. Segments : non-payers, payeurs occasionnels, whales, churnés. |
| US-AR-04 | En tant que joueur, je veux que mes données soient synchronisées entre mes appareils, afin de reprendre ma progression n'importe où. | Firestore offline-first + Hive cache + sync automatique <5s + indicateur visuel. |
| US-AR-05 | En tant que joueur inactif, je veux recevoir des notifications engageantes, afin d'être incité à revenir. | FCM topics segmentés + fallback locales. Rate limit 3 push/jour. Timezone-aware. |
| US-AR-06 | En tant qu'utilisateur, je veux que mes achats soient sécurisés et restaurables, afin d'avoir confiance dans l'application. | Validation IAP côté serveur uniquement (Cloud Function), webhook RevenueCat, restauration via bouton dédié. |
| US-AR-07 | En tant qu'utilisateur européen/parent, je veux que mes données personnelles soient protégées, afin d'utiliser l'app en conformité. | Écran consentement onboarding, droit à l'effacement (Cloud Function), COPPA (<13 ans = pas de pubs/analytics). |
| US-AR-08 | En tant que développeur, je veux un pipeline CI/CD automatisé, afin de livrer rapidement et sans erreur. | GitHub Actions (analyze + test + coverage), Fastlane (internal/beta/production), déploiement Firebase. |

## Règles fonctionnelles livrées (sélection)

### Firestore — Schéma et sécurité
- **RB-DB-01** : 8 collections principales : users, progress, inventory, purchases, events, levels, eventDefinitions, leaderboards, referrals.
- **RB-DB-02** : Collections user-scoped : seul le propriétaire (ou compte lié) peut lire/écrire users/{uid}, progress/{uid}, inventory/{uid}, events/{uid}.
- **RB-DB-03** : purchases/{uid} : lecture autorisée propriétaire, écriture interdite client-side (`allow write: if false`). Seule la Cloud Function purchaseValidation peut écrire.
- **RB-DB-04** : levels/ et eventDefinitions/ : lecture publique, écriture interdite client-side.
- **RB-DB-05** : leaderboards/{tournamentId}/entries/{uid} : lecture publique, écriture via Cloud Function uniquement.
- **RB-DB-06** : Index composites pour leaderboard (score DESC, updatedAt DESC) et events (eventType ASC, expiresAt ASC).

### API — Cloud Functions
- **RB-API-01** : checkQuota (HTTPS callable) : clé unique par niveau+session, anti-triche.
- **RB-API-02** : dailyRewardReset (scheduled) : 00:00 UTC, batch Firestore avec lastResetDate.
- **RB-API-03** : eventScheduler (scheduled) : vérifie eventDefinition.startAt avant création, idempotent.
- **RB-API-04** : leaderboardUpdate (Firestore trigger) : agrégation scores, écriture avec admin SDK.
- **RB-API-05** : purchaseValidation (HTTPS) : webhook RevenueCat, vérification signature + unicité transactionId, double-check Google Play/Apple API si suspect.
- **RB-API-06** : referralCredit (HTTPS callable) : crédite parrain si nouvel install validé par device ID.
- **RB-API-07** : mergeAnonymousData (interne) : fusionne progression anonyme vers authentifié (max étoiles, max niveau).
- **RB-API-08** : deleteUserData (HTTPS callable) : suppression GDPR complète + anonymisation leaderboard.
- **RB-API-09** : scheduleNotifications (scheduled) : toutes les heures, segments dynamiques churn/near_perfect, rate limit 3 push/jour/utilisateur.

### Offline-first
- **RB-OF-01** : Cache local Hive pour progress, inventory, settings. Écriture locale <10ms.
- **RB-OF-02** : Queue de sync FIFO dans Hive avec timestamp, operationType, checksum.
- **RB-OF-03** : Sync automatique dès retour online, batchs de 50 opérations max.
- **RB-OF-04** : Résolution conflits : timestamp gagnant ; progression = max étoiles/niveau ; inventaire = somme consommables ; conflit irréductible = modale utilisateur.
- **RB-OF-05** : Indicateur visuel SyncIndicator (vert = sync, orange = attente, rouge = erreur + retry).

### Monétisation et LTV
- **RB-MN-01** : Interstitielles tous les X niveaux (Remote Config 3/5/7), jamais après défaite, cooldown 60s, exemption Passe Saisonnier.
- **RB-MN-02** : Récompensées volontaires : vie, indice, doubler daily reward, débloquer niveau, essai thème.
- **RB-MN-03** : IAP ≤ 4.99$ : packs vies, thèmes, Passe Saisonnier, Protection Streak, Pack Indices.
- **RB-MN-04** : Segmentation : non-payers (prix -20%), payeurs occasionnels (bundle 3.99$), whales (pas de pubs, accès anticipé).
- **RB-MN-05** : LTV cible ≥ 2.50$ sur 180 jours (pubs + IAP cumulés).

### Notifications
- **RB-NT-01** : Topics FCM : all_players, active_payers, churn_24h/7d/30d, near_perfect, social_sharers.
- **RB-NT-02** : Fallback locales via flutter_local_notifications si FCM refusé.
- **RB-NT-03** : Timezone-aware (users/{uid}/settings/timezone), envoi à 20h locale.
- **RB-NT-04** : Rate limit max 3 push/jour/utilisateur (hors événements majeurs).
- **RB-NT-05** : Recalcul des notifications locales à chaque ouverture pour éviter doublons FCM+locale.

### Sécurité et conformité
- **RB-SC-01** : Consentement explicite onboarding (Analytics, Ads, Crashlytics) stocké dans users/{uid}/settings/consents.
- **RB-SC-02** : Droit à l'effacement : deleteUserData supprime users/, progress/, inventory/, anonymise leaderboard.
- **RB-SC-03** : Portabilité : export JSON chiffré via Firebase Storage (URL temporaire 24h).
- **RB-SC-04** : COPPA : si <13 ans, pubs désactivées, Analytics anonymisées (pas de device ID).
- **RB-SC-05** : Anonymisation leaderboard : pseudo uniquement, uid hashé, jamais d'email/nom réel.

### Performance
- **RB-PF-01** : Chargement niveau < 2s (préchargement assets monde courant+N+1, Hive local, shaders précompilés).
- **RB-PF-02** : 60 FPS garanti (FixedResolutionViewport, object pooling, disposal explicite).
- **RB-PF-03** : Jank monitoring < 5% de frames > 16.6ms.
- **RB-PF-04** : Cache images TTL 7j (cached_network_image), assets dynamiques TTL 30j (Firebase Storage CDN).
- **RB-PF-05** : Scalabilité Firestore : documents < 1Mo, tableaux purchases limités à 100 entrées puis archivage.

### CI/CD
- **RB-CI-01** : GitHub Actions : flutter analyze --no-fatal-infos, flutter test --coverage, Codecov upload.
- **RB-CI-02** : Fastlane Android : internal (APK debug), beta (AAB release), production (graduel 10%/50%/100%).
- **RB-CI-03** : Fastlane iOS : beta (TestFlight internal), release (App Store Connect + soumission auto).
- **RB-CI-04** : Dart defines pour API keys (AdMob, etc.) via --dart-define, jamais en dur dans le repo.
- **RB-CI-05** : Déploiement Firebase rules/functions via pipeline après merge sur main.

---

*Document consolidé par l'Agent Principal — Projet Lumora — 2026-05-07*
