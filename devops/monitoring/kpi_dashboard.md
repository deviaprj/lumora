# KPI Dashboard — Lumora

Ce tableau de bord centralise les métriques critiques du post-launch et les outils de suivi associés.

## 1. Rétention (Firebase Analytics)

| Métrique | Outil | Fréquence | Seuil d'alerte | Action si seuil franchi |
|----------|-------|-----------|----------------|-------------------------|
| D1 Retention | Firebase Analytics > Retention | Quotidien | < 40 % | Vérifier onboarding, courbe difficulté niveaux 1–5, fréquence pubs |
| D7 Retention | Firebase Analytics > Retention | Quotidien | < 20 % | Activer Test 3 (courbe difficulté), ajuster notifications 72h |
| D30 Retention | Firebase Analytics > Retention | Hebdomadaire | < 10 % | Activer Test 5 (streak), lancer événement saisonnier |

## 2. Monétisation (RevenueCat + AdMob)

| Métrique | Outil | Fréquence | Seuil d'alerte | Action si seuil franchi |
|----------|-------|-----------|----------------|-------------------------|
| ARPDAU | RevenueCat Dashboard + AdMob | Quotidien | < 0.03 $ | Activer Test 2 (prix IAP), augmenter fréquence pubs (Test 1) |
| LTV (180j) | RevenueCat Cohorts + BigQuery | Hebdomadaire | < 2.50 $ | Optimiser bundles IAP, lancer Passe Saisonnier promotion |
| Taux conversion IAP | RevenueCat > Conversion | Quotidien | < 3 % | A/B testing prix, offres contextuelles (défaite + vies=0) |
| Revenu pubs (AdMob) | AdMob > Reporting | Quotidien | < 50 % baseline | Vérifier fill rate, tester nouveaux réseaux (MAX fallback) |

## 3. Stabilité (Crashlytics)

| Métrique | Outil | Fréquence | Seuil d'alerte | Action si seuil franchi |
|----------|-------|-----------|----------------|-------------------------|
| Crash rate | Crashlytics > Stability | Quotidien | > 1 % | Hotfix urgent, rollback store si > 2 % |
| ANR rate | Crashlytics > ANRs | Quotidien | > 0.5 % | Profiler thread principal, réduire calculs frame |
| Crashs par niveau | Crashlytics > Custom keys | Quotidien | > 5 crashs/niveau | Corriger niveau ou asset manquant |

## 4. Publicités (AdMob)

| Métrique | Outil | Fréquence | Seuil d'alerte | Action si seuil franchi |
|----------|-------|-----------|----------------|-------------------------|
| eCPM interstitiel | AdMob > Reporting | Hebdomadaire | < 1.50 $ | Tester segmentation géo, ajouter réseau médiation |
| Fill rate global | AdMob > Reporting | Quotidien | < 85 % | Activer réseaux de secours, vérifier consentement GDPR |
| Taux de clic récompensée | AdMob > Reporting | Quotidien | < 15 % | Ajuster placement (défaite, boutique, accueil) |

## 5. Engagement (Firebase Analytics)

| Métrique | Outil | Fréquence | Seuil d'alerte | Action si seuil franchi |
|----------|-------|-----------|----------------|-------------------------|
| Temps de session moyen | Analytics > Engagement | Quotidien | < 6 min | Ajouter mini-jeux, réduire temps chargement, vérifier 60 FPS |
| Niveaux complétés / session | Analytics > Events | Quotidien | < 3 | Ajuster difficulté (Remote Config), activer indices auto |
| Sessions / utilisateur / jour | Analytics > Engagement | Quotidien | < 2.5 | Activer notifications push, daily rewards, événements |

## 6. Backend (Firebase Console + Cloud Monitoring)

| Métrique | Outil | Fréquence | Seuil d'alerte | Action si seuil franchi |
|----------|-------|-----------|----------------|-------------------------|
| Firestore reads/jour | Firebase Console > Usage | Quotidien | > 100 000 | Vérifier indexation, ajouter cache client, profiler requêtes |
| Firestore writes/jour | Firebase Console > Usage | Quotidien | > 50 000 | Batch writes, rate limiting Cloud Function |
| Cloud Functions erreurs | Cloud Monitoring > Logs | Quotidien | > 5 erreurs/min | Corriger function, vérifier idempotence, rollback si critique |
| Latence callable | Cloud Monitoring > Latency | Quotidien | P95 > 800 ms | Optimiser requêtes Firestore, augmenter mémoire function |

## 7. Tableau récapitulatif hebdomadaire (M2–M6)

Chaque lundi à 9h, le lead product owner publie un récap dans #kpi-lumora (Slack/Discord) avec :
1. D1 / D7 / D30 de la semaine passée + évolution WoW.
2. ARPDAU et LTV cumulé.
3. Top 3 crashs (niveau + stack trace).
4. Statut des tests A/B en cours (étape, taille cohorte, tendance).
5. Décision go/no-go pour les rollouts graduels en cours.

## 8. Outils recommandés

| Outil | Usage | Lien |
|-------|-------|------|
| Firebase Analytics | Rétention, engagement, funnels | console.firebase.google.com |
| RevenueCat Dashboard | Revenus IAP, cohortes LTV | app.revenuecat.com |
| AdMob | Revenus pubs, eCPM, fill rate | admob.google.com |
| Crashlytics | Crashs, ANR, custom keys | console.firebase.google.com |
| BigQuery (Firebase) | Requêtes SQL avancées, LTV | cloud.google.com/bigquery |
| Grafana (optionnel) | Dashboard unifié auto-refresh | grafana.com |
