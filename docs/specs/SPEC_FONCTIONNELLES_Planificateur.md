# SPEC_FONCTIONNELLES_Planificateur.md — Lumora

## Livrables source
- `docs/Plan_Action.md` — Plan d'action complet (242 lignes)
- `docs/Specifications_Fonctionnelles_Generales.md` — Spécifications fonctionnelles générales (423 lignes)

---

## Cas d'usage consolidés

| ID | Cas d'usage | Acteur | Description |
|----|-------------|--------|-------------|
| UC-PL-01 | Planifier le développement en 16 semaines | Équipe projet | Découpage en 4 phases avec jalons, livrables et responsables |
| UC-PL-02 | Suivre les KPIs de rétention et monétisation | Product Owner | D1/D7/D30 retention, ARPDAU, LTV, conversion IAP |
| UC-PL-03 | Gérer les risques projet | Lead projet | Matrice des risques avec probabilité, impact et mitigation |
| UC-PL-04 | Valider les contraintes transversales | QA / Lead | Checklist des 9 contraintes à chaque phase |

## User stories consolidées

| ID | User Story | Critères d'acceptation |
|----|------------|------------------------|
| US-PL-01 | En tant que lead projet, je veux un planning de 16 semaines avec des jalons clairs, afin de suivre la progression et anticiper les blocages. | Plan_Action.md livré avec phases, jalons, timeline macro et matrice des risques. |
| US-PL-02 | En tant que product owner, je veux des KPIs cibles définis (retention, revenus), afin de mesurer le succès post-launch. | KPIs D1≥45%, D7≥20%, D30≥10%, ARPDAU≥0.05$, LTV≥2.50$, conversion IAP≥3%. |
| US-PL-03 | En tant que développeur, je veux des spécifications fonctionnelles détaillées couvrant tous les modules, afin de développer sans ambiguïté. | Specs générales livrées avec règles métier (RB-*) par fonctionnalité. |
| US-PL-04 | En tant que QA, je veux une checklist des contraintes transversales, afin de valider chaque livrable avant passage en prod. | 9 contraintes listées et vérifiables dans Plan_Action.md Phase 3 et Specs Section 14. |

## Règles fonctionnelles livrées (sélection)

### Plan d'action
- **RB-PL-01** : Livraison MVP en 16 semaines (S1–S16) + itérations mensuelles M2–M6.
- **RB-PL-02** : Scope freeze au jalon J12 (fin S12), plus aucune nouvelle feature avant la release.
- **RB-PL-03** : Déploiement graduel en production : 10 % → 50 % → 100 %.
- **RB-PL-04** : A/B testing préliminaire sur la fréquence des pubs pendant la bêta fermée (S14).

### Spécifications fonctionnelles générales
- **RB-AC-01 à RB-AC-04** : Authentification (Google, Apple, Email, Anonyme) + fusion progression.
- **RB-SA-01 à RB-SA-04** : Sauvegarde cross-device (Firestore source de vérité, offline-first, résolution conflits, indicateur visuel de sync).
- **RB-PR-01 à RB-PR-03** : Progression (mondes de 20 niveaux, étoiles 1–3, unlocks thématiques, bulles organiques flottantes).
- **RB-DI-01 à RB-DI-02** : Difficulté graduelle (courbe sigmoïde, taux de réussite cible par tranche, ajustement dynamique Remote Config).
- **RB-IN-01 à RB-IN-05** : Indices visuels décroissants (délai, opacité, fréquence par palier ; indice manuel = pénalité 3e étoile).
- **RB-SO-01 à RB-SO-04** : Partage social (capture auto + overlay organique + liens dynamiques + parrainage).
- **RB-MO-01 à RB-MO-05** : Monétisation (interstitielles 1/5 niveaux, récompensées volontaires, IAP ≤ 5$, Passe Saisonnier sans pubs).
- **RB-RE-01 à RB-RE-04** : Rétention (notifications 24h/72h/7j/30j, daily rewards croissants, streak avec protection IAP/vidéo).
- **RB-EV-01 à RB-EV-04** : Événements automatiques (quotidiens, week-end, saisonniers, tournois ; Cloud Scheduler ; priorité si chevauchement).
- **RB-AN-01 à RB-AN-04** : Analytics (events trackés, A/B testing 5 tests, Remote Config temps réel, conformité GDPR/COPPA).
- **RB-HO-01 à RB-PA-04** : Règles métier détaillées par écran (Accueil, Carte des mondes, Gameplay, Victoire, Défaite, Boutique, Paramètres).

## Vérification des contraintes transversales

| Contrainte | Statut | Références |
|------------|--------|------------|
| UI organique (pas de carrés gris, pas de bords droits) | ✅ Intégrée | Plan_Action.md Phase 1/2/3 ; Specs §2.3, §13 (RB-HO à RB-PA) |
| 2D avec effets 3D | ✅ Intégrée | Specs §1.1 vision, §13.3 RB-GP-01, §13.2 RB-WM-01 |
| Indices visuels décroissants | ✅ Intégrée | Specs §7 tableau complet par palier, RB-IN-01 à RB-IN-05 |
| Compte utilisateur + sauvegarde cross-device | ✅ Intégrée | Specs §3, §4, RB-AC, RB-SA |
| Partage social | ✅ Intégrée | Specs §8, RB-SO |
| Gratuit + pubs + IAP abordables | ✅ Intégrée | Specs §9, RB-MO, prix ≤ 5$ |
| Événements automatiques | ✅ Intégrée | Specs §11, RB-EV, Cloud Scheduler |
| Notifications de retour | ✅ Intégrée | Specs §10, RB-RE, planning 24h/72h/7j/30j |

---

*Document consolidé par l'Agent Principal — Projet Lumora — 2026-05-07*
