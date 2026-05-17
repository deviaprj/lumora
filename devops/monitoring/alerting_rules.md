# Alerting Rules — Lumora

Ce document définit les règles d'alerte pour le post-launch, les canaux de notification et les procédures d'escalade.

## 1. Crash rate (Crashlytics)

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| > 1 % | 1 heure | Slack #alerts-lumora + email tech-lead | Vérifier version concernée, prioriser hotfix |
| > 2 % | 1 heure | Slack #alerts-lumora + SMS on-call | Pause rollout graduel, préparer rollback store |
| Nouveau crash > 50 occurrences | 1 heure | Slack #alerts-lumora | Créer ticket P0, assigner développeur |

## 2. Rétention D1 (Firebase Analytics)

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| < 40 % | Jour J+1 | Slack #kpi-lumora + email product | Analyser funnel onboarding, vérifier fréquence pubs, activer Remote Config difficulté douce |
| < 30 % | Jour J+1 | Slack #alerts-lumora + meeting urgence | Audit complet onboarding + pubs + crashs, rollback si release récente |

## 3. ARPDAU (RevenueCat + AdMob)

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| < 0.03 $ | 3 jours consécutifs | Slack #kpi-lumora | Activer Test 2 (prix IAP), augmenter eCPM (nouveau réseau médiation) |
| < 0.02 $ | 3 jours consécutifs | Slack #alerts-lumora | Vérifier AdMob fill rate, lancer offre "Happy Hour" |

## 4. Cloud Functions erreurs

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| > 5 erreurs / minute | 5 minutes | Slack #alerts-lumora | Consulter logs Firebase, vérifier idempotence, corriger function |
| > 20 erreurs / minute | 5 minutes | Slack #alerts-lumora + pager on-call | Rollback function vers version précédente (voir DEPLOYMENT_GUIDE) |
| Latence callable P95 > 800 ms | 15 minutes | Slack #alerts-lumora | Optimiser requêtes Firestore, augmenter mémoire function |

## 5. Firestore reads

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| > 100 000 reads / jour | 1 jour | Slack #alerts-lumora + email backend | Vérifier indexation, ajouter cache client Hive, profiler requêtes lentes |
| > 500 000 reads / jour | 1 jour | Slack #alerts-lumora + pager on-call | Audit complet accès client, vérifier boucle infinie, activer rate limit |

## 6. ANR rate (Android)

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| > 0.5 % | 1 heure | Slack #alerts-lumora | Profiler thread principal, réduire calculs frame, vérifier shaders |
| > 1 % | 1 heure | Slack #alerts-lumora + email tech-lead | Hotfix urgent, rollback si corrélée à release |

## 7. IAP validation failures

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| > 5 % de webhooks rejetés | 1 heure | Slack #alerts-lumora + email finance | Vérifier `purchaseValidation.ts`, vérifier clé HMAC/ECDSA RevenueCat |
| Fraude flag > 10 / jour | 1 jour | Slack #alerts-lumora | Analyser transactions suspectes, contacter RevenueCat support |

## 8. Notification delivery failures

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| > 10 % tokens invalides | 1 jour | Slack #alerts-lumora | Nettoyer tokens FCM obsolètes, vérifier fallback local notifications |
| Rate limit atteint > 100x | 1 jour | Slack #alerts-lumora | Vérifier logique `scheduleNotifications.ts`, ajuster batch size |

## 9. Rollout graduel Android (Store)

| Seuil | Fenêtre | Canal | Action |
|-------|---------|-------|--------|
| Crash rate > 1.5 % sur version en rollout | 4 heures | Slack #alerts-lumora | Halter rollout (passer à 0 %), investiguer, reprendre ou annuler |
| Rating moyen < 3.5 étoiles sur 50+ reviews | 24 heures | Slack #kpi-lumora | Analyser reviews, prioriser correctifs UX / difficulté |

## 10. Canaux et intégrations

| Canal | Usage | Configuration |
|-------|-------|---------------|
| Slack #alerts-lumora | Alertes temps réel | Webhook via GitHub Secrets `SLACK_WEBHOOK_URL` |
| Slack #kpi-lumora | Récapitulatifs quotidiens | Message programmé via GitHub Actions ou bot interne |
| Email tech-lead | Escalade secondaire | Configuré dans Firebase Alerts > Email notifications |
| Pager / SMS on-call | P0 critique (crash > 2 %, Firestore > 500k reads) | Service PagerDuty ou Opsgenie lié à Firebase Alerts |

## 11. Checklist d'activation des alertes

- [ ] Activer Firebase Crashlytics Alerts dans la console (email + Slack).
- [ ] Activer Firebase Performance Alerts pour les callable latences.
- [ ] Configurer Cloud Monitoring pour Firestore reads/writes.
- [ ] Activer les alertes RevenueCat (webhook failures, fraud flags).
- [ ] Connecter AdMob Alerts (fill rate drop, eCPM drop).
- [ ] Tester les webhooks Slack/Discord avec un faux crash.
- [ ] Documenter l'on-call rotation (1 semaine, rotatif équipe).
