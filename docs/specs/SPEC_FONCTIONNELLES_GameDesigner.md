# SPEC_FONCTIONNELLES_GameDesigner.md — Lumora

## Livrable source
- `docs/GDD_Resume.md` — Game Design Document résumé (476 lignes)

---

## Résumé du concept
**Pitch** : Dans *Lumora*, vous guidez une petite créature de lumière (Lumie) à travers des mondes organiques en connectant des nœuds d’énergie colorée d’un simple glissement, pour réveiller des galaxies assoupies une étincelle à la fois.

**Genre** : Puzzle-réflexion tactile 2D+3D avec progression et collection.
**Session type** : 3–8 minutes, une seule main (tap + swipe).
**Core loop** : Lancer → Choisir niveau (bulle flottante) → Connecter nœuds par filaments lumineux → Victoire avec particules 3D → Récompense & décider de continuer.

## Cas d'usage consolidés

| ID | Cas d'usage | Acteur | Description |
|----|-------------|--------|-------------|
| UC-GD-01 | Jouer une session de puzzle | Joueur | Sélectionner un niveau, connecter des nœuds par tap/swipe, valider la solution |
| UC-GD-02 | Utiliser un indice visuel | Joueur | Recevoir un indice automatique (décroissant) ou activer un indice manuel (ampoule) |
| UC-GD-03 | Gérer ses vies | Joueur | Perdre une vie en cas d'échec, régénérer au fil du temps, acheter ou regarder une vidéo |
| UC-GD-04 | Partager sa progression | Joueur | Capturer l'écran de victoire avec overlay organique et partager sur réseaux sociaux |
| UC-GD-05 | Participer à un événement | Joueur | Défi quotidien, week-end, tournoi ou saisonnier avec récompenses exclusives |
| UC-GD-06 | Collectionner des cosmétiques | Joueur | Débloquer avatars, thèmes, titres, badges via progression, événements ou IAP |
| UC-GD-07 | Consulter le leaderboard | Joueur | Voir son classement dans les tournois automatiques |
| UC-GD-08 | Recevoir une notification de retour | Joueur inactif | Être notifié par FCM/local avec message personnalisé après 24h/72h/7j/14j/30j |

## User stories consolidées

| ID | User Story | Critères d'acceptation |
|----|------------|------------------------|
| US-GD-01 | En tant que joueur, je veux connecter des nœuds colorés par un simple glissement, afin de résoudre un puzzle intuitif et satisfaisant. | Tap sur nœud → swipe vers un autre → filament lumineux apparaît. Validation quand tous les nœuds sont reliés selon la règle du niveau. |
| US-GD-02 | En tant que débutant, je veux recevoir des indices visuels automatiques, afin de ne jamais rester bloqué sans savoir quoi faire. | Indice déclenché après délai du palier (8s → 150s) si hésitation détectée. Opacité et type d'indice adaptés au niveau du joueur. |
| US-GD-03 | En tant que joueur avancé, je veux pouvoir désactiver les indices automatiques, afin de ne pas être gêné par des aides inutiles. | Toggle dans les paramètres. Débloque badge "Puriste". Indices manuels toujours disponibles. |
| US-GD-04 | En tant que joueur, je veux obtenir 3 étoiles sur chaque niveau, afin de ressentir un sentiment de maîtrise et de perfection. | 1 étoile = terminé ; 2 étoiles = dans le temps ; 3 étoiles = dans le temps + sans indice manuel. Rejouable pour améliorer. |
| US-GD-05 | En tant que joueur, je veux participer à des événements automatiques variés, afin d'avoir du contenu frais sans mise à jour manuelle. | Défis quotidiens (00:00 UTC), week-end (ven-dim), tournois bi-mensuels, happy hours 2x/semaine, saisonniers mensuels. |
| US-GD-06 | En tant que joueur social, je veux partager mes victoires avec mes amis, afin de les défier et de recevoir des récompenses de parrainage. | Capture auto + overlay organique + share_sheet + lien dynamique. Parrainage crédité une fois par install. |
| US-GD-07 | En tant que joueur, je veux recevoir des notifications engageantes quand je n'ai pas joué, afin d'être incité à revenir sans sentiment d'intrusion. | Messages créatifs et segmentés (24h/72h/7j/14j/30j) avec ton adapté (doux, aventure, émotionnel, magique). |
| US-GD-08 | En tant que joueur, je veux collectionner des cosmétiques et des badges, afin de personnaliser mon expérience et montrer ma progression. | Avatars, thèmes, titres, badges débloquables via progression, streaks, événements, parrainage, IAP. |
| US-GD-09 | En tant que joueur occasionnel, je veux que les sessions soient courtes et sans frustration, afin de jouer dans les transports ou en attendant. | Niveaux rapides (30–90s), courbe sigmoïde, anti-frustration (3 échecs = proposition d'aide), pas de GAME OVER agressif. |
| US-GD-10 | En tant que joueur engagé, je veux des défis de précision et des combos, afin de ressentir une compétition amicale. | Combos x2/x3/x4+, leaderboard tournoi, niveaux chronométrés, expert 91+. |

## Règles fonctionnelles livrées (sélection)

### Mécaniques de jeu
- **RB-GP-01** : Action principale = tap un nœud puis swipe vers un autre pour tracer un filament lumineux.
- **RB-GP-02** : Règle de couleur (Mondes 1–2) : connexion uniquement entre couleurs adjacentes sur le spectre.
- **RB-GP-03** : Règle de symétrie (Mondes 2–3) : motif connecté doit être symétrique par rapport à un axe.
- **RB-GP-04** : Règle de complétude (Mondes 3+) : certains nœuds doivent être traversés exactement 2 fois.
- **RB-GP-05** : Règle d'obstacle (Mondes 4+) : filaments ne doivent pas croiser les zones d'ombre mouvantes.
- **RB-GP-06** : Règle de temps (Mondes 5+) : timer cercle organique qui se rétrécit.
- **RB-GP-07** : Combo x2 (2 connexions d'affilée) = 20 pts ; x3 = 40 pts ; x4+ = 80 pts max.
- **RB-GP-08** : Échec = -1 vie. Si 3 échecs consécutifs sur un niveau = proposition indice gratuit, vidéo récompensée ou message d'encouragement.
- **RB-GP-09** : Nœuds bonus dorés = +50 pts. Super Filament (combo x5 ou événement) = traverse les ombres.
- **RB-GP-10** : Vies max = 5. Régénération 1 vie / 20 min.

### Difficulté graduelle
- **RB-DI-01** : Courbe sigmoïde par tranches de 20 niveaux (tutoriel → découverte → combinaison → maîtrise → expert).
- **RB-DI-02** : Taux de réussite cible : 1–10 ≥95%, 11–30 ≥80%, 31–60 ≥65%, 61–90 ≥50%, 91–100 ≥45%, 101+ ≥40%.
- **RB-DI-03** : Si taux réel < cible de >10 points, ajustement automatique (temps +10s, obstacle retiré, indice plus précoce).

### Indices visuels décroissants (tableau complet)
| Palier | Délai (s) | Opacité | Fréquence | Type d'indice |
|--------|-----------|---------|-----------|---------------|
| 1–10 | 8 | 95% | 1re hésitation (>3s) | Filament fantôme + halo |
| 11–20 | 15 | 85% | Toutes les 2 hésitations | Filament fantôme + halo pulsant |
| 21–30 | 25 | 75% | Toutes les 3 hésitations | Halo pulsant seul |
| 31–40 | 40 | 60% | Toutes les 4 hésitations | Contour subtil + micro-son |
| 41–50 | 55 | 50% | Toutes les 6 hésitations | Éclaircissement passif zone cible |
| 51–60 | 70 | 40% | Toutes les 8 hésitations | Ombre légère directionnelle |
| 61–70 | 90 | 30% | Toutes les 10 hésitations | Micro-ripple discret (2s) |
| 71–80 | 120 | 25% | Toutes les 12 hésitations | Changement subtil de teinte nœud |
| 81–90 | 150 | 20% | Toutes les 15 hésitations | Son de note plus aiguë |
| 91–100 | Désactivé | 15% | Sur demande manuelle | Ombre microscopique |
| 101+ | Désactivé | 10% | Sur demande manuelle | Lueur imperceptible |

### Monétisation
- **RB-MO-01** : Interstitielles 1/5 niveaux, placement après victoire, jamais pendant niveau ni après défaite.
- **RB-MO-02** : Récompensées volontaires : vie supplémentaire, doubler daily reward, débloquer niveau, essai thème 24h.
- **RB-MO-03** : IAP ≤ 5$ (Pack 5/20/50 vies, Vies infinies 24h, Thème Nébula, Pack 3 thèmes, Passe Saisonnier, Protection Streak, Pack Indices x10).
- **RB-MO-04** : Passe Saisonnier actif = 0 interstitielle + niveaux événementiels + récompenses x2.
- **RB-MO-05** : Déclencheurs doux : écran défaite + vies=0, après 10 niveaux 3 étoiles, happy hour, premier achat bonus 3 vies.

### Rétention
- **RB-RE-01** : Daily rewards croissants J1–J7 (bulles organiques), streak avec bonus et protection IAP/vidéo.
- **RB-RE-02** : Notifications 24h/72h/7j/14j/30j avec contenu personnalisé et ton adapté.
- **RB-RE-03** : Promotions "Lumière Perdue" : niveau spécial depuis notification (3j), Cadeau Retour (7j), Niveau Retrouvailles (14j), Message narratif + récompense massive (30j).
- **RB-RE-04** : Notifications segmentées (proche 3 étoiles, Passe expire, 5 vidéos regardées, partage fréquent).

### Événements automatiques
- **RB-EV-01** : Défi quotidien (00:00 UTC) : 1 niveau spécial avec contrainte thématique.
- **RB-EV-02** : Défi week-end (ven 20h → dim 23:59 UTC) : série de 5 niveaux spéciaux.
- **RB-EV-03** : Tournoi bi-mensuel (lun 00h → ven 23:59 UTC) : leaderboard mondial sur 10 niveaux aléatoires.
- **RB-EV-04** : Happy hour (2x/semaine, vendredi 18h–22h UTC) : pubs récompensées x2 ou IAP -30%.
- **RB-EV-05** : Événement saisonnier mensuel (Printemps, Été, Automne, Hiver, Halloween, Noël) : 10 niveaux spéciaux + Gardien + musique exclusive.

### Partage social
- **RB-SO-01** : Capture auto à chaque fin de niveau + overlay organique (avatar rond, étoiles flottantes, texte personnalisé, glassmorphism).
- **RB-SO-02** : Parrainage : 1 vie+1 indice par install, bonus à 3/5/10 parrainages (thème, avatar, Passe Saisonnier gratuit).

### Progression
- **RB-PR-01** : 5 mondes × 20 niveaux = 100 niveaux au lancement. Seuil d'étoiles pour débloquer les mondes suivants.
- **RB-PR-02** : Étoiles 1–3 : terminé / dans le temps / dans le temps + sans indice manuel.
- **RB-PR-03** : Collection : avatars Lumie (tous les 10 niveaux), titres, thèmes cosmétiques, badges secrets, Gardiens débloqués.

---

*Document consolidé par l'Agent Principal — Projet Lumora — 2026-05-07*
