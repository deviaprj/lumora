# Plan A/B Testing — Lumora

Ce document détaille les 5 tests A/B prioritaires pour optimiser la rétention, la monétisation et l'expérience utilisateur.

## Méthodologie générale

- **Significativité** : minimum 1000 joueurs par variante.
- **Durée** : 7 jours minimum (14 jours recommandés pour les KPIs de rétention D7/D30).
- **Rollout** : 10 % > 50 % > 100 % de l'audience cible.
- **Outil** : Firebase Remote Config + Firebase A/B Testing (objectifs liés à Analytics).

---

## Test 1 — Fréquence des publicités interstitielles

| | |
|---|---|
| **Objectif** | Maximiser ARPDAU sans baisser D1 retention |
| **Paramètre** | `ad_interstitial_every_n_levels` |
| **Contrôle (A)** | 5 niveaux |
| **Variante B** | 3 niveaux |
| **Variante C** | 7 niveaux |
| **Audience** | 100 % nouveaux utilisateurs (Day-0) |
| **KPIs primaires** | D1 retention, ARPDAU |
| **KPIs secondaires** | Temps de session, niveaux complétés/session |
| **Durée** | 14 jours |
| **Hypothèse** | 3 niveaux = revenus pubs + mais churn ; 7 niveaux = revenus — mais retention + |

---

## Test 2 — Prix des achats intégrés (IAP vies)

| | |
|---|---|
| **Objectif** | Maximiser le taux de conversion IAP et le revenu moyen par payeur |
| **Paramètres** | `iap_prices_tier_a`, `iap_prices_tier_b`, `iap_prices_tier_c` |
| **Contrôle (A)** | 0.99 $ / 2.99 $ / 4.99 $ |
| **Variante B** | 0.79 $ / 1.99 $ / 3.99 $ |
| **Variante C** | 0.99 $ / 1.99 $ / 4.99 $ (tier B réduit uniquement) |
| **Audience** | Joueurs ayant visionné >= 2 vidéos récompensées (intention d'achat modérée) |
| **KPIs primaires** | Taux conversion IAP, LTV |
| **KPIs secondaires** | Nombre d'achats par utilisateur, panier moyen |
| **Durée** | 14 jours |
| **Hypothèse** | Les prix plus bas augmentent la conversion sans diminuer significativement le revenu total. |

---

## Test 3 — Courbe de difficulté

| | |
|---|---|
| **Objectif** | Maximiser D7 retention en réduisant la frustration des paliers 11–30 |
| **Paramètre** | `difficulty_curve_multiplier` + override niveau |
| **Contrôle (A)** | Courbe actuelle (temps –10s tous les 10 niveaux, +1 obstacle tous les 15) |
| **Variante B** | +10s par niveau (courbe plus douce) |
| **Variante C** | –1 obstacle sur les niveaux 11–30 |
| **Audience** | Joueurs ayant atteint le niveau 10 (cohorte à risque de churn) |
| **KPIs primaires** | D7 retention, taux de réussite niveaux 11–30 |
| **KPIs secondaires** | Temps de session, nombre d'indices utilisés |
| **Durée** | 14 jours |
| **Hypothèse** | Une courbe plus douce augmente la rétention D7 sans rendre le jeu trop facile. |

---

## Test 4 — Système d'indices (automatique vs manuel)

| | |
|---|---|
| **Objectif** | Mesurer l'impact des indices automatiques sur la progression et la frustration |
| **Paramètre** | `hintSystem` (JSON complet) |
| **Contrôle (A)** | Courbe décroissante actuelle (auto puis manuel) |
| **Variante B** | Toujours actifs (indices automatiques à tous les paliers) |
| **Variante C** | Toujours désactivés (uniquement manuel) |
| **Audience** | Joueurs niveaux 1–30 (période d'apprentissage) |
| **KPIs primaires** | Taux de réussite niveau 1-essai, D1 retention |
| **KPIs secondaires** | Étoiles moyennes par niveau, temps de session |
| **Durée** | 7 jours |
| **Hypothèse** | Les indices toujours actifs réduisent la frustration débutant ; toujours désactivés augmentent le sentiment de réussite pour les core gamers. |

---

## Test 5 — Politique de streak (Daily Reward)

| | |
|---|---|
| **Objectif** | Maximiser D30 retention en optimisant la gestion de la rupture de streak |
| **Paramètre** | `streak_break_policy` |
| **Contrôle (A)** | Reset à zéro (perte totale du streak) |
| **Variante B** | –1 jour (streak diminué de 1) |
| **Variante C** | Freeze gratuit 1x (1 chance de rattrapage sans action, puis reset) |
| **Audience** | Joueurs avec un streak >= 3 jours (engagement établi) |
| **KPIs primaires** | D30 retention, taux de retour après rupture |
| **KPIs secondaires** | Sessions/semaine, vidéos récompensées visionnées pour streak |
| **Durée** | 21 jours (nécessite observation sur plusieurs cycles) |
| **Hypothèse** | Le freeze gratuit 1x augmente le sentiment d'équité et la rétention long terme sans cannibaliser les IAP de protection streak. |

---

## Calendrier des tests (M2–M6)

| Mois | Test actif | Objectif |
|------|-----------|----------|
| M2 | Test 1 (fréquence pubs) | ARPDAU baseline |
| M2–M3 | Test 2 (prix IAP) | Conversion |
| M3 | Test 3 (difficulté) | D7 retention |
| M4 | Test 4 (indices) | Accessibilité vs challenge |
| M5–M6 | Test 5 (streak) | D30 retention |

## Notes sur les contraintes transversales

- **UI organique** : les overlays A/B (ex. variante C du streak avec freeze) doivent utiliser `LumoraCard` et `LumoraButton` pour afficher le résultat du test.
- **2D+3D** : les variations de difficulté (Test 3) impactent la vitesse de parallaxe et le nombre de particules ; vérifier les FPS.
- **Monétisation** : les tests de prix (Test 2) ne doivent jamais dépasser 4.99 $ pour respecter la contrainte "IAP abordables".
- **Événements automatiques** : les résultats des tests sont intégrés dans `eventDefinitions` pour ajuster automatiquement les paramètres des saisons suivantes.
