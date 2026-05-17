# SPEC_FONCTIONNELLES_DeveloppeurBackend.md — Lumora

## Livrables source
- `backend/functions/src/index.ts` — Point d'entrée Functions v2
- `backend/functions/src/checkQuota.ts` — Anti-triche quota
- `backend/functions/src/dailyRewardReset.ts` — Reset récompenses quotidiennes 00:00 UTC
- `backend/functions/src/eventScheduler.ts` — Ordonnancement événements automatiques
- `backend/functions/src/leaderboardUpdate.ts` — Agrégation scores tournoi
- `backend/functions/src/purchaseValidation.ts` — Validation webhook RevenueCat + double-check
- `backend/functions/src/referralCredit.ts` — Crédit parrainage
- `backend/functions/src/mergeAnonymousData.ts` — Fusion compte anonyme → authentifié
- `backend/functions/src/scheduleNotifications.ts` — Notifications FCM segmentées
- `backend/functions/src/deleteUserData.ts` — Suppression GDPR
- `backend/functions/package.json` / `tsconfig.json`
- `devops/firebase/firestore.rules` — Règles user-scoped strictes
- `devops/firebase/firestore.indexes.json` — Index composites
- `devops/firebase/remote_config_defaults.json` — Valeurs par défaut config

---

## Résumé du backend
**Plateforme** : Firebase Cloud Functions v2 (Node.js 20, TypeScript strict)
**Base de données** : Firestore (8 collections, modèle plat, user-scoped)
**Sécurité** : Règles Firestore strictes + validation IAP côté serveur uniquement + GDPR deleteUserData
**Notifications** : FCM topics segmentés + fallback locales
**Événements** : Cloud Scheduler + Functions idempotentes

## Cas d'usage consolidés

| ID | Cas d'usage | Acteur | Description |
|----|-------------|--------|-------------|
| UC-BE-01 | Vérifier le quota anti-triche | Client (jeu) | Avant chaque niveau, vérifier que le joueur n'a pas dépassé les limites |
| UC-BE-02 | Réinitialiser les récompenses quotidiennes | Système | Tous les jours à 00:00 UTC, reset le calendrier daily reward pour les joueurs actifs |
| UC-BE-03 | Planifier les événements | Système | Créer/ouvrir automatiquement défis quotidiens, week-end, tournois, happy hours, saisonniers |
| UC-BE-04 | Mettre à jour le leaderboard | Système | Agréger les scores d'un tournoi en cours et classer les joueurs |
| UC-BE-05 | Valider un achat IAP | RevenueCat webhook | Recevoir webhook, vérifier receipt, écrire historique sécurisé |
| UC-BE-06 | Créditer un parrainage | Client | Après install via lien dynamique, créditer le parrain si device ID unique |
| UC-BE-07 | Fusionner compte anonyme | Client | Lier anonyme → Google/Apple/Email sans perte de progression |
| UC-BE-08 | Envoyer notifications segmentées | Système | Toutes les heures, envoyer FCM aux segments churn/near_perfect/payers |
| UC-BE-09 | Supprimer les données utilisateur | Client/Admin | Exercer le droit à l'effacement GDPR |

## User stories consolidées

| ID | User Story | Critères d'acceptation |
|----|------------|------------------------|
| US-BE-01 | En tant que backend, je veux valider les achats côté serveur, afin d'empêcher toute falsification client-side. | purchaseValidation.ts : webhook RevenueCat, vérification signature, unicité transactionId, double-check Google Play/Apple API. Écriture admin SDK uniquement. purchases/{uid} : allow write: if false. |
| US-BE-02 | En tant que backend, je veux orchestrer les événements sans intervention humaine, afin d'avoir du contenu frais en continu. | eventScheduler.ts : idempotent, vérifie startAt avant création. dailyRewardReset.ts : 00:00 UTC, batch Firestore avec lastResetDate. |
| US-BE-03 | En tant que backend, je veux envoyer des notifications personnalisées, afin de réactiver les joueurs inactifs. | scheduleNotifications.ts : segments churn_24h/7d/30d, near_perfect, active_payers. Rate limit 3 push/jour. Timezone-aware. |
| US-BE-04 | En tant que backend, je veux protéger les données utilisateur, afin de respecter la vie privée. | Firestore rules user-scoped (isOwner). deleteUserData.ts suppression complète + anonymisation leaderboard. Consentement onboarding stocké. |
| US-BE-05 | En tant que backend, je veux fusionner les comptes anonymes, afin que les joueurs ne perdent pas leur progression. | mergeAnonymousData.ts : résolution max étoiles, max niveau, somme consommables. |
| US-BE-06 | En tant que backend, je veux tracker le parrainage, afin de récompenser les joueurs qui invitent des amis. | referralCredit.ts : device ID unique, maxUses, crédite inventory/{referrerUid}. |

## Règles fonctionnelles livrées (sélection)

### Cloud Functions
- **RB-FN-01** : checkQuota : HTTPS callable, clé unique niveau+session, anti-triche.
- **RB-FN-02** : dailyRewardReset : scheduled 00:00 UTC, batch Firestore, idempotent via lastResetDate.
- **RB-FN-03** : eventScheduler : scheduled, vérifie eventDefinition.startAt, idempotent.
- **RB-FN-04** : leaderboardUpdate : Firestore trigger, agrégation scores, écriture admin SDK.
- **RB-FN-05** : purchaseValidation : HTTPS webhook RevenueCat, vérification signature, unicité transactionId, double-check API store si suspect, flag fraude.
- **RB-FN-06** : referralCredit : HTTPS callable, device ID unique, maxUses, crédite parrain.
- **RB-FN-07** : mergeAnonymousData : HTTPS callable, fusion progress/inventory/events, résolution max/somme.
- **RB-FN-08** : scheduleNotifications : scheduled toutes les heures, segments FCM, rate limit 3/jour, timezone-aware.
- **RB-FN-09** : deleteUserData : HTTPS callable, suppression GDPR complète, anonymisation leaderboard.

### Firestore — Sécurité
- **RB-RL-01** : users/{uid}, progress/{uid}, inventory/{uid}, events/{uid} : read/write si isOwner(uid) || isAnonymousLinked(uid).
- **RB-RL-02** : purchases/{uid} : read si owner, write interdit client-side (allow write: if false).
- **RB-RL-03** : levels/, eventDefinitions/ : read publique, write interdit.
- **RB-RL-04** : leaderboards/{tournamentId}/entries/{uid} : read publique, write interdit client-side.
- **RB-RL-05** : referrals/{code} : read publique, write via Functions.

### Configuration
- **RB-RC-01** : remote_config_defaults.json : hintSystem (delay/opacity par palier), ad_interstitial_every_n_levels=5, iap_prices_tier_a=0.99, iap_prices_tier_b=2.99, iap_prices_tier_c=4.99, difficulty_curve_multiplier=1.0.
- **RB-RC-02** : firestore.indexes.json : leaderboard (score DESC, updatedAt DESC), events (eventType ASC, expiresAt ASC).

---

*Document consolidé par l'Agent Principal — Projet Lumora — 2026-05-07*
