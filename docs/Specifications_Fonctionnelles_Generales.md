# Specifications Fonctionnelles Generales - Lumora (Version contractuelle release beta)

Version document: 2026-05-18
Statut document: contractuel beta
Portee: application mobile Flutter + moteur Flame + backend Firebase Functions

## Table des matieres

1. Objet et portee contractuelle
2. Definitions contractuelles
3. Exigences contractuelles par domaine
4. Criteres d'acceptation testables (beta gate)
5. Conditions Go / No-Go beta
6. Exclusions explicites beta
7. Gouvernance QA et PR review
8. Annexes

---

## 1. Objet et portee contractuelle

Ce document definit les engagements minimaux de release beta.

Il remplace toute formulation ambigue de type vision/intentions par:
- obligations fonctionnelles verifiables,
- criteres de recette testables,
- statut de conformite au code actuel.

Reference de suivi QA/PR:
- Annexe A: docs/QA_PR_Feature_Matrix.md

---

## 2. Definitions contractuelles

- IMPLEMENTE: fonctionnalite active dans le runtime principal et verifiable.
- PARTIEL: fonctionnalite visible mais incomplete, mockee ou non branchee bout-en-bout.
- NON IMPLEMENTE: fonctionnalite absente du runtime de la beta.

Niveaux de criticite:
- BLOQUANT BETA: doit etre conforme avant diffusion beta.
- NON BLOQUANT BETA: peut etre reporte post-beta avec risque documente.

Definition of done contractuelle:
1. Code merge sur branche cible beta.
2. Criteres d'acceptation associes executes avec resultat conforme.
3. Statut dans la matrice QA/PR mis a jour.
4. Aucun blocker securite connu non mitige.

---

## 3. Exigences contractuelles par domaine

### 3.1 Gameplay coeur

Statut actuel: IMPLEMENTE
Criticite: BLOQUANT BETA

Exigences:
1. Le gameplay doit utiliser un GameState partage entre moteur et UI.
2. Le systeme vies/coups doit appliquer:
   - erreur/doublon -> perte de coups,
   - coups a zero -> perte d'une vie + refill coups,
   - vies a zero -> defaite.
3. Les regles speciales Stable, Surcharge, Resonance, Blackout doivent etre actives.
4. Les objectifs secondaires doivent etre evalues pendant la partie et a la victoire.

### 3.2 Systeme d'indices

Statut actuel: PARTIEL
Criticite: BLOQUANT BETA (scope reduit explicitement)

Exigences beta retenues:
1. L'indice manuel doit fonctionner en jeu et appliquer son cout attendu.
2. Le cout d'indice doit respecter la regle Blackout (cout augmente).
3. Les charges d'indices persistantes doivent etre consommables.

Exigences reportees (hors gate beta):
1. HintSystem automatique decroissant par palier (delai/opacite/frequence).

### 3.3 Progression et persistance locale

Statut actuel: IMPLEMENTE (local)
Criticite: BLOQUANT BETA

Exigences:
1. La progression locale doit persister le niveau complete max.
2. Les metadonnees monde/regle vue doivent persister localement.
3. La carte des mondes doit afficher niveaux verrouilles/disponibles/completes.
4. Les filtres de maitrise doivent fonctionner.

### 3.4 Monetisation rewarded + inventaire

Statut actuel: IMPLEMENTE (rewarded), PARTIEL (stack complete)
Criticite: BLOQUANT BETA pour rewarded, NON BLOQUANT pour IAP complete

Exigences beta:
1. Rewarded ads utilisables sur jeu, boutique, evenements.
2. Defaite: 1ere video = +1 vie, 2eme video = +2 vies.
3. Inventaire rewards persistant local avec cooldowns par placement.
4. Charges Double Score / Super Filament consommables en partie.

Exigences reportees:
1. IAP production full stack (paiement, restore complet, entitlement final).
2. Interstitielles cadencees en production.

### 3.5 Authentification

Statut actuel: IMPLEMENTE (mobile + functions email)
Criticite: BLOQUANT BETA

Exigences:
1. Connexion Google, Apple, Facebook, Anonyme disponibles.
2. Flux email par code (send/verify/finalize) operationnel.
3. Auth guard routeur actif via FirebaseAuth.
4. Smoke startup auth staging activable via STAGING_SMOKE_AUTH.

### 3.6 Evenements et backend scheduling

Statut actuel: PARTIEL
Criticite: NON BLOQUANT BETA

Exigences beta:
1. Ecran evenements accessible avec rewards et cooldowns.
2. Functions planifiees deployables sans erreur de build TypeScript.

Report beta+:
1. Pipeline live-ops complet (contenu/ops/moderation).
2. Priorisation multi-evenements validee full prod.

### 3.7 Sauvegarde cross-device cloud

Statut actuel: PARTIEL/NON IMPLEMENTE cote client
Criticite: NON BLOQUANT BETA (BLOQUANT release publique)

Exigences beta:
1. Le mode local persistant doit etre stable.
2. Le document de limites doit expliciter l'absence de sync cloud complete.

### 3.8 Notifications de retention

Statut actuel: PARTIEL
Criticite: NON BLOQUANT BETA

Exigences beta:
1. La brique backend de scheduling doit compiler et se deployer.
2. Les preferences UI peuvent rester partielles si documentees.

### 3.9 Partage social

Statut actuel: NON IMPLEMENTE bout-en-bout
Criticite: NON BLOQUANT BETA

Exigences beta:
1. Le manque de partage social final doit etre explicitement documente.

### 3.10 Securite, secrets et conformite

Statut actuel: PARTIEL
Criticite: BLOQUANT BETA pour fondamentaux

Exigences:
1. Les secrets ne doivent pas etre hardcodes dans le code source.
2. Les scripts de preflight/deploiement doivent permettre staging/prod separes.
3. Le flux email code doit appliquer hash + TTL + max attempts.
4. Les endpoints sensibles doivent avoir un plan de hardening documente.

### 3.11 Build et binaires Android

Statut actuel: IMPLEMENTE
Criticite: BLOQUANT BETA

Exigences:
1. APK debug doit sortir en lumora-debug.apk.
2. APK release doit sortir en lumora.apk.
3. applicationId Android doit etre com.lumora.lumora.

---

## 4. Criteres d'acceptation testables (beta gate)

### 4.1 Gate A - gameplay et progression (BLOQUANT)

1. Executer test/game_state_test.dart et obtenir PASS.
2. Executer test/features/game/engine/game_interaction_test.dart et obtenir PASS.
3. Executer test/features/game/data/player_progression_service_test.dart et obtenir PASS.
4. Executer test/features/game/presentation/world_map_screen_test.dart et obtenir PASS.

Resultat attendu:
- aucune regression sur vies/coups/defaite/victoire,
- progression locale et map conformes.

### 4.2 Gate B - rewards et inventaire (BLOQUANT)

1. Executer test/features/monetization/reward_inventory_test.dart et obtenir PASS.
2. Verifier en scenario manuel:
   - defaite -> video 1 -> +1 vie,
   - defaite -> video 2 -> +2 vies.

Resultat attendu:
- persistance rewards stable,
- cooldowns appliques,
- reprise apres defaite conforme.

### 4.3 Gate C - auth et routes (BLOQUANT)

1. Verifier l'ecran auth: Google, Apple, Facebook, Email, Anonyme visibles.
2. Verifier que le guard routeur redirige vers /auth si session absente.
3. Verifier le smoke auth staging (si STAGING_SMOKE_AUTH=true): aucun check critique en echec.

Resultat attendu:
- parcours auth principal non bloquant.

### 4.4 Gate D - build artefacts Android (BLOQUANT)

1. Build debug reussi.
2. Build release reussi.
3. Verifier presence de:
   - build/app/outputs/apk/debug/lumora-debug.apk
   - build/app/outputs/apk/release/lumora.apk
4. Verifier metadata:
   - applicationId = com.lumora.lumora.

Resultat attendu:
- livrables binaires conformes au naming contractuel.

### 4.5 Gate E - non bloquant beta (a suivre)

1. Notifications retention full UX.
2. Partage social final.
3. Sync cloud cross-device complet.
4. IAP full production flow.

Resultat attendu:
- backlog clair, priorise et trace dans la matrice QA/PR.

---

## 5. Conditions Go / No-Go beta

Go beta si et seulement si:
1. Gates A, B, C, D sont verts.
2. Aucun incident critique securite non mitige.
3. Les ecarts NON BLOQUANT sont explicitement acceptes.

No-Go beta si au moins un point:
1. Echec gate A/B/C/D.
2. Build release non reproductible.
3. Regression auth ou gameplay bloquante.

---

## 6. Exclusions explicites beta

Les elements suivants ne sont pas des pre-requis go beta:
1. HintSystem auto-decroissant complet.
2. Partage social complet avec attribution.
3. Sync cloud cross-device complet cote client.
4. Stack IAP production exhaustive.

Ils deviennent prioritaires pour release publique.

---

## 7. Gouvernance QA et PR review

Regles:
1. Toute PR fonctionnelle doit mettre a jour la matrice QA/PR.
2. Toute fonctionnalite marquee IMPLEMENTE doit avoir:
   - test existant, ou
   - test manquant explicitement justifie avec ticket de dette.
3. Toute evolution bloquante beta doit mettre a jour les gates A-D.

Document de reference PR/QA:
- docs/QA_PR_Feature_Matrix.md

---

## 8. Annexes

- Annexe A: matrice Feature -> Fichiers -> Statut -> Tests existants/manquants
  - docs/QA_PR_Feature_Matrix.md
