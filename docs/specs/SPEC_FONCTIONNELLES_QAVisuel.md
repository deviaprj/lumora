# SPEC_FONCTIONNELLES_QAVisuel.md — Lumora

## Livrables source
- `tests/unit/hint_system_test.dart` — Logique indices décroissants par palier
- `tests/unit/monetization_logic_test.dart` — Fréquence pubs, exemption Passe Saisonnier, cooldown
- `tests/unit/offline_sync_test.dart` — Résolution conflits (max étoiles, somme consommables)
- `tests/widget/lumora_button_test.dart` — Absence bords droits, borderRadius pill, couleur non grise
- `tests/widget/lumora_card_test.dart` — Glassmorphism blur, borderRadius >= 16, ombre
- `tests/widget/auth_screen_test.dart` — 4 bulles organiques, absence ElevatedButton brut
- `tests/widget/game_screen_test.dart` — Timer circulaire, pause bulle, indice ampoule, pas de bords droits
- `tests/widget/shop_screen_test.dart` — Cartes organiques, scroll horizontal, pas de grille carrée
- `tests/integration/onboarding_to_level_test.dart` — Parcours complet splash → auth → home → niveau → victoire → partage
- `tests/test_helpers.dart` — Mocks AdMob, RevenueCat, Firebase, Flame
- `tests/QA_REPORT.md` — Rapport qualité complet avec verdict GO/NO-GO

---

## Résumé QA
**Verdict** : **GO** pour passage en Phase 4
**Tests écrits** : 61 scénarios (15 unitaires + 31 widget + 3 intégration + 12 helpers)
**Couverture cible** : ≥ 70% (unitaires), 100% pass widget, 100% pass intégration

## Cas d'usage consolidés

| ID | Cas d'usage | Acteur | Description |
|----|-------------|--------|-------------|
| UC-QA-01 | Valider l'UI organique | QA / Développeur | Vérifier absence de boutons carrés gris et de bords droits dans tous les écrans |
| UC-QA-02 | Tester les indices décroissants | QA | Vérifier que le délai augmente et l'opacité diminue par palier |
| UC-QA-03 | Tester la monétisation | QA | Vérifier fréquence pubs, exemption Passe Saisonnier, cooldown, validation IAP serveur |
| UC-QA-04 | Tester la sync offline | QA | Vérifier résolution conflits max étoiles, max niveau, somme consommables |
| UC-QA-05 | Tester le parcours utilisateur | QA | Parcours complet onboarding → niveau → victoire → partage |
| UC-QA-06 | Produire le rapport qualité | QA | QA_REPORT.md avec checklist 9 contraintes, captures narratives, bugs, verdict |

## User stories consolidées

| ID | User Story | Critères d'acceptation |
|----|------------|------------------------|
| US-QA-01 | En tant que QA, je veux des tests automatisés pour l'UI organique, afin de garantir qu'aucun bouton carré gris n'apparaisse. | Tests widget LumoraButton (borderRadius pill), LumoraCard (blur >= 16), AuthScreen (absence ElevatedButton). |
| US-QA-02 | En tant que QA, je veux tester la logique d'indices décroissants, afin de valider l'accessibilité graduelle. | hint_system_test.dart : délai 8s→150s, opacité 95%→10%, fréquence 1re hésitation→manuel uniquement. |
| US-QA-03 | En tant que QA, je veux tester la monétisation, afin de vérifier qu'elle est respectueuse et sécurisée. | monetization_logic_test.dart : interstitielle tous les N niveaux, exemption Passe Saisonnier, cooldown 60s, write interdit purchases/. |
| US-QA-04 | En tant que QA, je veux tester la synchronisation offline, afin de garantir la cohérence cross-device. | offline_sync_test.dart : conflit max étoiles, max niveau, somme consommables. |
| US-QA-05 | En tant que QA, je veux un rapport qualité exhaustif, afin de décider du GO/NO-GO. | QA_REPORT.md : 9 contraintes pass, descriptions narratives captures, bugs, verdict GO. |

## Règles fonctionnelles livrées (sélection)

### Tests unitaires
- **RB-TU-01** : hint_system_test : délai augmente par palier (8→15→25→40→55→70→90→120→150→désactivé).
- **RB-TU-02** : hint_system_test : opacité diminue par palier (95%→85%→75%→60%→50%→40%→30%→25%→20%→15%→10%).
- **RB-TU-03** : monetization_logic_test : interstitielle affichée tous les N niveaux (Remote Config 3/5/7).
- **RB-TU-04** : monetization_logic_test : exemption interstitielles si activeSeasonPass == true.
- **RB-TU-05** : monetization_logic_test : cooldown 60s entre deux interstitielles.
- **RB-TU-06** : offline_sync_test : conflit étoiles = max par niveau.
- **RB-TU-07** : offline_sync_test : conflit niveau = max atteint.
- **RB-TU-08** : offline_sync_test : conflit consommables = somme des deux côtés.

### Tests widget
- **RB-TW-01** : lumora_button_test : borderRadius >= 16dp ou pill (9999dp). Jamais de shape rectangulaire.
- **RB-TW-02** : lumora_button_test : couleur non grise brute (#808080 interdit).
- **RB-TW-03** : lumora_card_test : BackdropFilter.blur présent (glassmorphism).
- **RB-TW-04** : lumora_card_test : borderRadius >= 16dp.
- **RB-TW-05** : lumora_card_test : boxShadow non vide.
- **RB-TW-06** : auth_screen_test : 4 boutons organiques présents (Google, Apple, Email, Anonyme).
- **RB-TW-07** : auth_screen_test : zero ElevatedButton ou TextButton brut.
- **RB-TW-08** : game_screen_test : timer circulaire organique (CircularProgressIndicator avec strokeCap round).
- **RB-TW-09** : game_screen_test : bouton pause en bulle (LumoraButton), bouton indice ampoule (LumoraButton).
- **RB-TW-10** : shop_screen_test : scroll horizontal, cartes organiques, absence de grille carrée.

### Tests intégration
- **RB-TI-01** : onboarding_to_level_test : splash → auth → home → sélection niveau → gameplay → victoire → partage.
- **RB-TI-02** : onboarding_to_level_test : transitions fluides entre écrans.
- **RB-TI-03** : onboarding_to_level_test : overlay victoire avec étoiles et boutons organiques.

### QA Report
- **RB-QR-01** : 9 contraintes transversales validées avec statut PASS et preuves.
- **RB-QR-02** : Descriptions narratives des 8 écrans clés (accueil, auth, gameplay, victoire, world map, boutique, paramètres, événements).
- **RB-QR-03** : Bugs identifiés (non bloquants) : PauseOverlay Container brut (corrigé), Debug Victoire (corrigé), TODO Firebase init.
- **RB-QR-04** : Verdict GO pour Phase 4.

---

*Document consolidé par l'Agent Principal — Projet Lumora — 2026-05-07*
