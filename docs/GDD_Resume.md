# GDD Résumé — Lumora

## 1. Concept Unique

**Pitch (1 phrase)** : Dans *Lumora*, vous guidez une petite créature de lumière à travers des mondes organiques en connectant des nœuds d’énergie colorée d’un simple glissement, pour réveiller des galaxies assoupies une étincelle à la fois.

**Description détaillée** : Lumora est un jeu de puzzle-reflexion tactile en 2D+3D où le joueur incarne une « Lumie », une orbe lumineuse naive et curieuse. Son but : restaurer la lumière dans des mondes flottants en connectant des nœuds d’énergie dispersés par des filaments colorés. Chaque niveau est un tableau de nœuds (3 à 25 selon la difficulté) de différentes couleurs. Le joueur tape un nœud, puis glisse vers un autre pour tracer un filament. Quand tous les nœuds sont reliés dans un ordre logique (couleurs adjacentes, symétries, motifs cachés), le niveau s’illumine et le joueur passe au suivant.

Au fil des niveaux, des mécaniques enrichissent le core loop :
- **Nœuds prismatiques** : changent de couleur quand on passe dessus.
- **Miroirs de lumière** : réfléchissent le filament à 90°.
- **Obstacles mouvants** : nuages sombres qui effacent les filaments si on reste trop longtemps.
- **Nœuds chronométrés** : doivent être connectés dans un temps imparti.
- **Bonus combos** : connecter 3 nœuds de suite sans lever le doigt déclenche un « Super Filament » (particules dorées + score x2).

**Pourquoi c’est addictif** :
1. **Feedback sensoriel immédiat** : chaque connexion déclenche un son cristallin, un ripple lumineux et des particules. Le cerveau associe instantanément l’action à une récompense dopaminergique.
2. **Progression claire** : les mondes se débloquent visuellement, les étoiles brillent, la carte est un spectacle vivant.
3. **Sessions courtes, rejouabilité infinie** : un niveau rapide = 30–90s. Le joueur pense « encore un petit niveau » et enchaine 5 à 10 sans s’en rendre compte.
4. **Maitrise visible** : les combos et les niveaux 3 étoiles offrent un sentiment de contrôle croissant.
5. **Univers apaisant mais stimulant** : pas de violence, pas de stress brutal. La difficulté monte en douceur comme une vague.

---

## 2. Univers et Lore

### L’univers imaginé
Lumora se déroule dans les « Royaumes du Crépuscule », un espace céleste composé de mondes flottants suspendus dans un néant scintillant. Autrefois, chaque monde brillait de mille feux. Mais une étrange « Grande Ombre » a éteint les filaments énergétiques qui reliaient les cœurs des mondes. Sans ces connexions, les mondes se sont endormis, leurs couleurs fanées, leurs habitants — les Lumies — réduits à de petites lueurs errantes.

Le joueur incarne **Lumie**, la dernière orbe qui a conservé sa mémoire. Guidée par les murmures des étoiles, elle voyage de monde en monde pour retisser les filaments, réveiller les cœurs endormis et, peut-être, comprendre d’où vient l’Ombre.

### Les personnages
- **Lumie** : petite orbe lumineuse douce, avec deux yeux minimalistes qui clignent quand elle est contente. Elle ne parle pas ; elle émet des notes musicales. Son corps réagit à la couleur du monde qu’elle traverse (dorée à l’aube, violette au crépuscule).
- **Les Gardiens** (bosses narratifs tous les 20 niveaux) : des entités géométriques organiques (tore, mébius, spirale) qui matérialisent la Grande Ombre. Battre un Gardien = résoudre un puzzle complexe sous pression. Le Gardien ne meurt pas ; il sourit et s’illumine à son tour.
- **Les Échos** : traces lumineuses laissées par les anciens joueurs (fantômes en mode « ghost » dans les tournois).

### Ambiance visuelle et sonore
- **Visuel** : Fonds en dégradés fluides (jamais de couleur plate), parallaxe 3D avec couches de brume lumineuse, particules flottantes (poussières d’étoiles), glassmorphism sur les panneaux UI. Les nœuds sont des gemmes organiques arrondies avec des reflets dynamiques. Les filaments sont des traits de lumière avec un effet « néon doux » (glow subtil).
- **Sonore** : Musique ambiante générée procéduralement (scales pentatoniques, binaural beats apaisants). Chaque couleur de nœud a sa note (Do = rouge, Ré = orange, Mi = jaune…). Connecter une séquence correcte joue un accord harmonique. Les erreurs produisent un son sourd mais jamais désagréable (comme une cloche sous l’eau).
- **Haptique** : micro-vibration à chaque connexion, vibration continue douce pendant les combos, vibration « cœur » quand un monde s’illumine.

### Musique
- **Menu/Monde 1 (Aube Dorée)** : Piano + synth pads, tempo 80 BPM, tonalité majeure.
- **Monde 2 (Crépuscule Violet)** : Harpe électrique + basse douce, tempo 90 BPM, mode mineur doux.
- **Monde 3 (Nuit Étoilée)** : Ambiant spatial, nappes de synthèse, bruits de vagues cosmiques.
- **Monde 4 (Aurore Boréale)** : Cordes éthérées + percussion légère, tempo 100 BPM.
- **Monde 5 (Soleil de Midi)** : Guitare acoustique virtuelle + clochettes, tempo 110 BPM, ton joyeux.
- **Victoire** : Accords de harpe ascendants + carillon (3–4s max, pas intrusif).
- **Défaite** : Nappe qui descend en intensité, pas de musique triste — plutôt un "soupir" sonore.

---

## 3. Core Loop

**Session type : 3–8 minutes**

**Étape 1 — Lancer (5s)**
Le joueur ouvre l’app. L’écran d’accueil montre Lumie flottant sur un fond parallaxe. Le joueur tape la bulle « Jouer » (organique, flottante, dégradée). Transition glassmorphism vers la carte des mondes.

**Étape 2 — Choisir & Résoudre (1–3 min)**
- Le joueur choisit un niveau sur la carte (bulles organiques reliées par des filaments de Bezier).
- Le niveau se charge en < 2s. Fond 2D+3D avec nœuds flottants légèrement en suspension.
- Le joueur tape un nœud → glisse vers un autre → filament lumineux apparaît.
- Répéter jusqu’à ce que tous les nœuds soient connectés selon la règle du niveau.
- Validation : animation d’illumination du monde, apparition des étoiles (1–3 selon performance).

**Étape 3 — Récompense & Décision (5–10s)**
- Écran de victoire avec particules 3D, étoiles qui apparaissent une par une.
- Le joueur choisit : « Niveau Suivant », « Partager », ou « Menu ».
- Si le joueur a complété 5 niveaux, une pub interstitielle s’affiche (après l’écran de victoire, jamais pendant).
- Retour à la carte ou passage au niveau suivant — boucle.

**Ce qui pousse à rejouer**
- **Objectif immédiat** : « Encore un niveau pour débloquer le monde suivant » (seuil d’étoiles).
- **Maitrise** : rejouer un ancien niveau pour obtenir la 3e étoile (sans indice, dans le temps).
- **Streak** : le compteur de jours consécutifs brûle sur l’écran d’accueil.
- **Événement actif** : une bulle saisonnière flottante pulse en haut de l’écran.
- **Vies limitées** : le joueur a 5 vies max. Échec = -1 vie. Régénération 1 vie / 20 min. Cette friction douce crée un rythme naturel pause/reprise sans frustrer.

---

## 4. Mécaniques de Jeu

### Actions du joueur
| Action | Input | Effet |
|--------|-------|-------|
| Sélectionner nœud | Tap | Nœud grossit légèrement (bounce 150ms), halo pulsant, son de note |
| Connecter nœuds | Swipe / Drag | Trace un filament lumineux entre les deux nœuds. Si valide : filament reste + combo +1. Si invalide : filament s’efface avec son doux d’erreur |
| Pause | Tap bulle pause | Modale glassmorphism avec cercles flottants : Reprendre, Recommencer, Paramètres, Quitter |
| Indice manuel | Tap ampoule organique | Consomme 1 indice gratuit ou propose vidéo récompensée. Affiche un filament fantôme subtil vers la prochaine bonne connexion |

### Règles fondamentales
- **Règle de couleur (Monde 1–2)** : on ne peut connecter que des nœuds de couleurs adjacentes sur le spectre (rouge↔orange, orange↔jaune, etc.).
- **Règle de symétrie (Monde 2–3)** : le motif connecté doit être symétrique par rapport à un axe central.
- **Règle de complétude (Monde 3+)** : certains nœuds doivent être traversés exactement 2 fois (entrée/sortie).
- **Règle d’obstacle (Monde 4+)** : les filaments ne doivent pas croiser les zones d’ombre mouvantes.
- **Règle de temps (Monde 5+)** : niveau chronométré. Le timer est un cercle organique qui se rétrécit doucement.

### Scoring
| Action | Points |
|--------|--------|
| Connexion valide | 10 pts × multiplicateur de combo |
| Combo x2 (2 connexions d’affilée) | 20 pts |
| Combo x3 | 40 pts |
| Combo x4+ | 80 pts (max) |
| Nœud bonus (doré) | +50 pts |
| Niveau terminé | +100 pts × nombre d’étoiles |
| Niveau terminé sans indice | +50 pts bonus |
| Niveau terminé dans le temps | +50 pts bonus |
| Étoile 3/3 | Score final × 1.5 |

### Power-ups (gratuits, gagnés en jeu)
| Power-up | Effet | Comment l’obtenir |
|----------|-------|-------------------|
| **Éclair de lumière** | Révèle la prochaine connexion correcte pendant 3s | Daily reward, combo x5 |
| **Temps suspendu** | Arrête le chronomètre pendant 10s | Niveau avec 3 étoiles |
| **Super Filament** | Le prochain filament est indestructible (traverse les ombres) | Événement week-end |
| **Double Score** | Multiplicateur ×2 pendant 1 niveau | Vidéo récompensée |

### Vies
- Max 5 vies. Échec sur un niveau = -1 vie.
- Régénération : 1 vie toutes les 20 minutes.
- Remplissage immédiat : Pack IAP ou vidéo récompensée (1 vie).

---

## 5. Système de Difficulté Graduelle

### Courbe d’apprentissage (Sigmoïde modérée)
La difficulté est introduite **une mécanique à la fois**, jamais deux nouveautés simultanées.

| Tranche | Niveaux | Ce qui change | Taux de réussite cible |
|---------|---------|-------------|------------------------|
| Tutoriel implicite | 1–10 | Connexion simple, 3–5 nœuds, 1 couleur, temps illimité, indices automatiques très fréquents | ≥ 95 % |
| Découverte | 11–30 | 2 couleurs, 5–8 nœuds, timer 120s, 1 obstacle statique | ≥ 80 % |
| Combinaison | 31–60 | 3 couleurs, symétrie, 8–12 nœuds, timer 90s, obstacles dynamiques | ≥ 65 % |
| Maîtrise | 61–90 | 4 couleurs, nœuds prismatiques, miroirs, 12–18 nœuds, timer 60s | ≥ 50 % |
| Expert | 91–100 | Toutes les mécaniques combinées, 18–25 nœuds, timer 45s | ≥ 45 % |
| Légendaire | 101+ (post-launch) | Défis de précision, combos obligatoires, timer 30s | ≥ 40 % |

### Paramètres par palier de 20 niveaux
| Paramètre | Niv 1–20 | 21–40 | 41–60 | 61–80 | 81–100 |
|-----------|----------|-------|-------|-------|--------|
| Temps alloué | Illimité → 120s | 120s → 90s | 90s → 75s | 75s → 60s | 60s → 45s |
| Nombre de nœuds | 3–5 | 5–8 | 8–12 | 12–18 | 18–25 |
| Nombre de couleurs | 1 | 2 | 3 | 4 | 4+ prismatiques |
| Obstacles | 0 | 0 statiques | 1–2 dynamiques | 2–3 dynamiques + ombres | 3–5 + ombres mouvantes |
| Nombre d’étapes logiques | 2 | 3–4 | 5–6 | 6–8 | 8–12 |
| Indices automatiques | Très fréquents | Fréquents | Modérés | Rares | Désactivés par défaut |

### Anti-frustration
- Si un joueur échoue 3 fois de suite sur un niveau, le système propose :
  1. Un indice gratuit automatique (sans pénalité d’étoile).
  2. Une vidéo récompensée pour passer le niveau (1 fois / 24h).
  3. Un message d’encouragement : « Tu y es presque ! Les Gardiens eux-mêmes ont eu du mal au début. »

---

## 6. Système d’Indices Visuels Décroissants

### Tableau détaillé par palier

| Palier (Niveaux) | Délai avant indice (s) | Opacité de l’indice | Fréquence d’apparition | Type d’indice |
|------------------|------------------------|---------------------|------------------------|---------------|
| 1 – 10 | 8 | 95 % | Dès la 1re hésitation (> 3s sans action) | Filament fantôme animé + halo brillant sur le nœud cible |
| 11 – 20 | 15 | 85 % | Toutes les 2 hésitations | Filament fantôme + halo pulsant |
| 21 – 30 | 25 | 75 % | Toutes les 3 hésitations | Halo pulsant seul sur le nœud cible |
| 31 – 40 | 40 | 60 % | Toutes les 4 hésitations | Contour subtil autour du nœud + micro-son de cloche |
| 41 – 50 | 55 | 50 % | Toutes les 6 hésitations | Éclaircissement passif de la zone cible (lumière ambiante +20 %) |
| 51 – 60 | 70 | 40 % | Toutes les 8 hésitations | Ombre légère projetée vers le nœud cible (directionnelle) |
| 61 – 70 | 90 | 30 % | Toutes les 10 hésitations | Micro-ripple autour du nœud cible (discret, 2s) |
| 71 – 80 | 120 | 25 % | Toutes les 12 hésitations | Changement subtil de teinte du nœud cible (saturation +15 %) |
| 81 – 90 | 150 | 20 % | Toutes les 15 hésitations | Son de note légèrement plus aiguë émis par le nœud cible |
| 91 – 100 | Désactivé par défaut | 15 % | Sur demande manuelle uniquement | Ombre microscopique (indice tactile visuel quasi invisible) |
| 101+ | Désactivé | 10 % | Sur demande manuelle | Lueur imperceptible (pour les joueurs qui veulent un défi pur) |

### Définitions
- **Hésitation** : le joueur ne touche aucun nœud interactif pendant X secondes (X = 3s au début, augmente avec la difficulté).
- **Indice automatique** : déclenché après le délai du palier, uniquement si le joueur est en hésitation et qu’aucun indice n’a été donné lors de la dernière hésitation comptabilisée.
- **Indice manuel** : bouton ampoule organique dans la barre de pause. Consomme 1 jeton d’indice (régénère 1 jeton / 24h, max 3). Si stock = 0, proposition de vidéo récompensée pour 1 jeton.

### Règles de scoring liées aux indices
- Indice automatique : **aucune pénalité** d’étoile.
- Indice manuel utilisé **avant** la victoire : la 3e étoile ("sans indice") est perdue pour ce run, mais rejouer sans indice permet de la récupérer.
- Indice manuel utilisé **après** avoir déjà perdu la 3e étoile (ex: timeout) : pas de pénalité supplémentaire.

### Personnalisation
- Le joueur peut désactiver les indices automatiques dans les paramètres (toggle organique arrondi).
- Désactiver les indices automatiques débloque un **badge "Puriste"** sur le profil.

---

## 7. Monétisation

### Modèle économique
**Gratuit** avec publicités non intrusives et IAP abordables (jamais plus de 5 $).

### Publicités interstitielles
| Paramètre | Valeur |
|-----------|--------|
| Fréquence | 1 interstitielle tous les **5 niveaux complétés** (paramétrable Remote Config : 3, 5, ou 7) |
| Placement | Après l’écran de victoire, avant la carte de sélection de niveau |
| Restrictions | Jamais pendant un niveau. Jamais après une défaite. Cooldown minimum 60s entre deux interstitielles. |
| Exemption | Joueurs avec le **Passe Saisonnier actif** : 0 interstitielle. |

### Publicités récompensées (volontaires)
| Placement | Récompense | Limitation |
|-----------|------------|------------|
| Bouton "Bonus" bulle flottante (écran d’accueil) | 1 vie supplémentaire (si vies < 5) | Max 3 vidéos / jour |
| Écran de défaite (si vies = 0) | 1 vie pour réessayer immédiatement | Max 1 / niveau |
| Boutique (overlay) | Doubler la récompense daily reward du jour | 1x / jour |
| Écran de niveau bloqué | Débloquer le niveau sans passer les précédents | 1x / 24h |
| Boutique thèmes | Essai gratuit d’un thème Premium pendant 24h | 1x / thème |

### Achats intégrés (IAP) — Tous ≤ 5 $
| Produit | Prix USD | Description | Placement |
|---------|----------|-------------|-----------|
| **Pack 5 Vies** | 0.99 $ | Recharge instantanée | Boutique, écran défaite |
| **Pack 20 Vies** | 2.99 $ | Meilleur rapport qualité/prix | Boutique (badge "Populaire") |
| **Pack 50 Vies** | 4.99 $ | Max 5 $ | Boutique |
| **Pack Vies Infinies 24h** | 1.99 $ | Vies illimitées pendant 24h | Événement happy hour, boutique |
| **Thème Premium "Nébula"** | 1.99 $ | Fond cosmétique + effets 3D exclusifs | Boutique (aperçu 3D rotatif) |
| **Pack 3 Thèmes** | 3.99 $ | Bundle saisonnier | Boutique |
| **Passe Saisonnier** | 4.99 $ | Niveaux événementiels débloqués, récompenses x2, pubs interstitielles désactivées | Accueil (bulle mise en avant) |
| **Protection Streak** | 0.99 $ | Sauvegarde la streak si le joueur manque 1 jour | Écran daily reward, boutique |
| **Pack Indices x10** | 1.99 $ | 10 jetons d’indice manuel | Boutique |

### Déclencheurs de monétisation "doux"
- **Écran de défaite + vies = 0** : proposition contextuelle de vidéo récompensée ou pack de vies (bouton organique, jamais popup agressive).
- **Après 3 étoiles sur 10 niveaux consécutifs** : suggestion de thème cosmétique ("Tu brilles ! Personnalise ta lumière avec le thème Nébula").
- **Happy Hour** : notification push + badge "-50 %" sur les IAP dans la boutique.
- **Premier achat** : bonus de 3 vies gratuites offertes (incitation à convertir).

### Respect du joueur
- Aucune pub sonore sans consentement (GDPR/COPPA).
- Bouton "Acheter le Passe" visible mais jamais en plein milieu du gameplay.
- Après un achat IAP, un message de remerciement organique s’affiche : "Merci de soutenir Lumora !" avec des particules dorées (pas de popup intrusive).

---

## 8. Système de Rétention

### Daily Rewards (Calendrier croissant)
Présenté sous forme de **bulles organiques en grille circulaire** (jamais de calendrier carré). Chaque jour = une bulle qui s’ouvre avec une animation 3D (éclatement de particules).

| Jour | Récompense | Effet visuel |
|------|------------|--------------|
| J1 | 1 vie | Bulle rouge douce |
| J2 | 2 vies | Bulle rouge brillante |
| J3 | 1 indice | Bulle jaune avec icône ampoule |
| J4 | 2 indices | Bulle jaune dorée |
| J5 | Thème essai 24h | Bulle arc-en-ciel tournante |
| J6 | 3 vies | Bulle rouge avec couronne |
| J7 | 5 vies + 1 thème permanent aléatoire | Bulle légendaire (particules dorées, son de carillon) |

- **Streak (série)** : si le joueur revient 7 jours consécutifs, un bonus de streak s’active : trophée "Étoile Filante" + avatar exclusif "Aurora".
- **Protection de streak** : si le joueur manque 1 jour, la streak tombe à 0. Il peut la racheter :
  - Via vidéo récompensée (1x / mois).
  - Via IAP "Protection Streak" (0.99 $) qui fige la streak pendant 48h.

### Notifications de retour (Push + Locales)
Déclenchées par FCM (Firebase Cloud Messaging) + fallback notifications locales si FCM refusé.

| Délai | Titre | Corps | Ton | Son | CTA |
|-------|-------|-------|-----|-----|-----|
| **24h** | "Ton Lumie a faim de lumière !" | "Reviens réveiller un monde assoupi. Ta récompense quotidienne t’attend." | Doux, affectueux | Carillon léger | Ouvrir le calendrier daily reward |
| **72h** | "Un Gardien s’éveille…" | "Un nouveau défi week-end vient d’apparaître. Viens tester ta mémoire lumineuse et gagne 3 vies !" | Entraînant, aventure | Harpe rapide | Ouvrir l’écran événements |
| **7j** | "Ta flamme s’éteint…" | "Tu as 7 jours de suite — une Étoile Filante ! Ne laisse pas la Grande Ombre gagner." | Urgent mais chaleureux | Son de feu doux | Ouvrir l’accueil + afficher streak |
| **14j** | "Les mondes deviennent gris…" | "Lumie pleure des larmes de lumière. Reviens, elle a besoin de toi." | Émotionnel, mignon | Son cristallin triste | Ouvrir + offrir 1 vie gratuite |
| **30j** | "Lumora a changé !" | "Nouveaux niveaux, nouveaux thèmes, nouveaux Gardiens. L’Aurore est de retour." | Magique, découverte | Nappe éthérée | Ouvrir + popup nouveautés |

### Notifications personnalisées (segmentées)
| Segment | Déclencheur | Message |
|---------|-------------|---------|
| Joueur proche 3 étoiles | N’a pas rejoué un niveau à 2 étoiles depuis 24h | "Niveau 12 : il ne te manque qu’une étincelle pour le perfect. Reviens !" |
| Joueur avec Passe Saisonnier | Passe sur le point d’expirer (< 3j) | "Ton Passe expire bientôt. Profite encore des niveaux Éclipse !" |
| Joueur sans achat | A regardé 5 vidéos récompensées | "Tu aimes les bonus ? Le Pack 20 Vies est à -30 % aujourd’hui." |
| Joueur social | A partagé 3x | "Tes amis parlent de toi ! 2 nouveaux joueurs ont installé Lumora grâce à toi." |

### Système de promotion "Lumière Perdue"
Si un joueur n’a pas ouvert l’app depuis :
- **3 jours** : envoi d’une **"Lumière Perdue"** — un petit niveau spécial (1 nœud, 1 connexion) jouable directement depuis la notification sans ouvrir l’app (Android rich notification / iOS interactive). Le compléter donne 1 vie.
- **7 jours** : offre d’un **"Cadeau de Retour"** — pack de 3 vies + 1 indice + 1 thème essai 24h, affiché dans une bulle organique flottante à l’ouverture.
- **14 jours** : niveau spécial "Retrouvailles" avec Lumie qui court vers le joueur. Récompense : avatar exclusif "Phénix" (non obtenable autrement).
- **30 jours** : message narratif : "La Grande Ombre a failli gagner. Mais tu es là. Bienvenue à la maison, Lumie t’attendait." + récompense massive (5 vies + thème permanent + passe saisonnier essai 3j).

---

## 9. Événements Automatiques

### Calendrier type sur 4 semaines

| Semaine | Lundi | Mardi | Mercredi | Jeudi | Vendredi | Samedi | Dimanche |
|---------|-------|-------|----------|-------|----------|--------|----------|
| **S1** | Tournoi Ouvert (00:00 UTC) | Tournoi J2 | Tournoi J3 | Tournoi J4 | Tournoi Clôture (23:59 UTC) | **Défi Week-End** : "Filaments Fous" (vitesse x1.5) | Défi Week-End J2 |
| **S2** | Défi Quotidien : Couleur | Défi Quotidien : Symétrie | Défi Quotidien : Vitesse | Défi Quotidien : Combo | **Happy Hour** (18h–22h UTC) : pubs récompensées x2 | **Défi Week-End** : "Ombres Dansantes" | Défi Week-End J2 |
| **S3** | Défi Quotidien : Miroir | Défi Quotidien : Prismes | Défi Quotidien : Temps | Défi Quotidien : Libre | **Happy Hour** (18h–22h UTC) : IAP -30 % | **Défi Week-End** : "Méga Nœuds" (25 nœuds) | Défi Week-End J2 |
| **S4** | Tournoi Ouvert (00:00 UTC) | Tournoi J2 | Tournoi J3 | Tournoi J4 | Tournoi Clôture + **Happy Hour** | **Défi Week-End** : "Gardien Réveillé" (boss spécial) | Défi Week-End J2 + **Événement Saisonnier** lancement |

### Types d’événements détaillés

**1. Défi Quotidien**
- **Fréquence** : tous les jours à 00:00 UTC.
- **Mécanique** : 1 niveau spécial (difficulté adaptée au joueur) avec une contrainte thématique (ex: "Sans indice", "En moins de 30s", "Seulement couleurs chaudes").
- **Récompense** : 1 vie + 1 étoile bonus (comptabilisée pour le déblocage des mondes).
- **Notification** : rappel à 20h heure locale si non complété.

**2. Défi Week-End**
- **Fréquence** : vendredi 20:00 UTC → dimanche 23:59 UTC.
- **Mécanique** : série de 5 niveaux spéciaux avec mécanique altérée (vitesse x1.5, ombres actives, nœuds géants, etc.).
- **Récompense** :
  - Compléter 3 niveaux : 3 vies + avatar week-end exclusif.
  - Compléter 5 niveaux : 5 vies + avatar + thème "Week-End".
- **Notification** : vendredi 18h UTC ("Le week-end Lumora commence !").

**3. Tournoi Automatique (Bi-mensuel)**
- **Fréquence** : semaines 1 et 4, lundi 00:00 UTC → vendredi 23:59 UTC.
- **Mécanique** : leaderboard mondial basé sur le score cumulé sur 10 niveaux aléatoires (mêmes niveaux pour tous). Les joueurs ont 5 essais par niveau pour optimiser leur score.
- **Récompense** :
  - Top 100 : thème "Champion" exclusif.
  - Top 10 : Passe Saisonnier gratuit pour la saison en cours.
  - Top 1 : avatar légendaire "Soleil" + titre "Maître des Filaments".
- **Notification** : lundi 10h UTC ("Le tournoi est ouvert ! Montre ta lumière.").

**4. Happy Hour**
- **Fréquence** : 2 fois par semaine, vendredi soir (horaire local adapté par timezone).
- **Mécanique** : période de 4h avec bonus actifs.
- **Variantes** :
  - Happy Hour "Bonus" : pubs récompensées x2 (2 vies au lieu de 1).
  - Happy Hour "Soldes" : tous les IAP à -30 %.
  - Happy Hour "Lumière" : indices automatiques réactivés temporairement même pour les pros.
- **Notification** : 1h avant début.

**5. Événement Saisonnier (Mensuel)**
- **Fréquence** : 1 saison = 1 mois. Thèmes : Printemps (Floraison), Été (Solstice), Automne (Équinoxe), Hiver (Étoile Polaire), Halloween (Éclipse), Noël (Aurore).
- **Mécanique** : 10 niveaux spéciaux avec thème visuel unique, nouveau Gardien, musique exclusive.
- **Récompense** :
  - Compléter 5 niveaux : thème saisonnier exclusif.
  - Compléter 10 niveaux : avatar saisonnier + titre.
  - Passe Saisonnier : débloque automatiquement les 10 niveaux + récompenses x2 + désactive les pubs.
- **Notification** : 48h avant, 24h avant, à l’ouverture, rappel si non commencé à J+7.

### Programmation technique
- Tous les événements sont planifiés via **Google Cloud Scheduler** + **Firebase Cloud Functions** (`eventScheduler`).
- Aucune intervention manuelle requise.
- Les joueurs sont notifiés automatiquement par FCM selon leur fuseau horaire (Remote Config `timezone_offset`).

---

## 10. Partage Social

### Capture automatique
- À la fin de chaque niveau (victoire ou défaite), une capture d’écran est générée automatiquement en arrière-plan.
- **Overlay organique** ajouté (jamais de rectangle, jamais de bords droits) :
  - Avatar du joueur (rond, bordure dégradée dynamique).
  - Score et étoiles obtenues (bulles flottantes avec micro-animations).
  - Texte personnalisé selon la performance :
    - 3 étoiles : "J’ai illuminé le niveau {N} de Lumora avec un perfect ! Peux-tu faire aussi bien ?"
    - 1–2 étoiles : "J’ai réveillé le niveau {N} de Lumora ! Rejoins-moi dans les Royaumes du Crépuscule."
    - Défaite : "Le niveau {N} de Lumora m’a résisté… Viens m’aider !"
  - Background glassmorphism avec le logo Lumora en filigrane (transparence 20 %).
  - Filament décoratif en bordure (courbe de Bézier colorée).

### Partage réseaux sociaux
- Bouton de partage présent sur l’écran de victoire sous forme de **bulle organique flottante** avec icône de partage (jamais de bouton carré).
- Canaux supportés : Instagram, Facebook, Twitter/X, WhatsApp, Snapchat, TikTok, et partage natif (share_sheet).
- Le partage inclut : image PNG (1080×1920, format story) + texte + lien dynamique Firebase (redirection fiche store).

### Système de parrainage
- Si un destinataire installe Lumora via le lien dynamique, le joueur original reçoit :
  - 1 vie + 1 indice (parrainage 1).
  - À 3 parrainages : thème "Ami de la Lumière".
  - À 5 parrainages : 5 vies + avatar "Éclaireur".
  - À 10 parrainages : Passe Saisonnier gratuit.
- Le lien expire après 30 jours. Le parrainage est crédité une seule fois par nouvel install (device ID).
- **Notification** : "Quelqu’un a rejoint Lumora grâce à toi ! Voici ta récompense."

### Paramètres
- Le joueur peut désactiver la capture automatique dans les paramètres (toggle organique).
- Option "Masquer le score" pour les joueurs modestes.

---

## 11. Progression et Collection

### Mondes thématiques
| Monde | Nom | Thème visuel | Seuil d’étoiles pour débloquer | Niveaux |
|-------|-----|--------------|-------------------------------|---------|
| 1 | Aube Dorée | Ciel rose/or, brume légère, nœuds chauds | 0 (débloqué) | 20 |
| 2 | Crépuscule Violet | Ciel violet/indigo, ombres douces, nœuds froids | 30 étoiles | 20 |
| 3 | Nuit Étoilée | Fond noir profond, constellations, nœuds argentés | 65 étoiles | 20 |
| 4 | Aurore Boréale | Vert/bleu fluo, particules dansantes, nœuds prismatiques | 105 étoiles | 20 |
| 5 | Soleil de Midi | Blanc/doré intense, lumière crue, nœuds radieux | 150 étoiles | 20 |

### Système d’étoiles (1–3)
- **1 étoile** : Niveau terminé (même avec indices, même en dépassant le temps).
- **2 étoiles** : Niveau terminé dans le temps alloué.
- **3 étoiles** : Niveau terminé dans le temps + sans utiliser d’indice manuel.
- Les étoiles sont **cumulables et rétroactives** : rejouer un niveau améliore le score max.

### Collection et Unlocks
| Élément | Comment l’obtenir | Description |
|---------|-------------------|-------------|
| **Avatars Lumie** | Progression (tous les 10 niveaux), streaks, événements, parrainage | Change l’apparence de Lumie (couleur, forme, yeux) |
| **Titres de profil** | Tous les 10 niveaux complétés | S’affiche sous le pseudo (ex: "Éclaireur", "Gardien des Filaments") |
| **Thèmes cosmétiques** | IAP, événements, daily reward J7 | Change le fond, les nœuds, les filaments, la musique |
| **Badges** | Défis secrets (ex: "Puriste" = 50 niveaux sans indice) | Collection visuelle sur le profil |
| **Gardiens débloqués** | Battre le boss tous les 20 niveaux | Apparaissent dans la galerie, peuvent être utilisés comme "compagnon" cosmétique |

### Écran de sélection de niveau (World Map)
- **Fond** : parallaxe 2D+3D avec couches de profondeur (nuages lumineux, étoiles lointaines).
- **Niveaux** : bulles flottantes reliées par des filaments organiques (courbes de Bézier). Les bulles complétées brillent avec 1–3 mini-étoiles flottantes au-dessus.
- **Bulles verrouillées** : grises translucides avec cadenas animé. Tap = vibration légère + message bulle : "Rassemble plus d’étoiles pour réveiller ce monde !"
- **Aucune grille carrée** : tout est flottant, organique, avec micro-mouvement sinusoïdal.

---

## 12. Carte des Émotions

| Émotion | Quand / Comment elle est provoquée | Durée | Intensité |
|---------|-----------------------------------|-------|-----------|
| **Curiosité** | Dès l’ouverture : Lumie flotte, le monde respire, les bulles d’accueil bougent doucement. Le joueur veut toucher. | 5–10s | Douce |
| **Joie** | Connexion valide : son cristallin, ripple lumineux, particules. Chaque petite victoire est célébrée. | 200–500ms | Vive mais brève |
| **Surprise** | Premier combo x3 : le Super Filament déclenche une pluie de particules dorées inattendue. | 1–2s | Modérée |
| **Satisfaction** | Niveau terminé : le monde s’illumine, les étoiles apparaissent une par une avec un crescendo sonore. Le joueur voit son effort récompensé visuellement. | 3–5s | Forte |
| **Fierté** | 3 étoiles obtenues pour la première fois sur un niveau difficile : message "Parfait !" avec zoom élastique, carillon, trophée miniature. | 3–5s | Très forte |
| **Frustration contrôlée** | Échec : le fond s’assombrit, une pluie de particules tombantes douces, un message d’encouragement chaleureux. Jamais de "GAME OVER" agressif. Le joueur peut réessayer immédiatement ou utiliser une vie. | 2–3s | Légère, rapidement convertie en motivation |
| **Anticipation** | Avant un événement : compte à rebours circulaire sur l’accueil, bulle saisonnière qui pulse. Le joueur attend avec impatience. | Variable | Modérée |
| **Connexion émotionnelle** | Narration douce entre les mondes : Lumie regarde le joueur avec ses yeux minimalistes, émet une note de gratitude. Pas de texte lourd, juste un regard. | 2–3s | Douce, accumulative |
| **Compétition amicale** | Tournoi : voir son nom monter dans le leaderboard. Pas de stress, juste un "Et si j’essayais encore une fois ?" | Variable | Modérée |

**Principe directeur** : Lumora évite la frustration aigue grâce à l’anti-frustration system (3 échecs = proposition d’aide) et à l’absence de punition brutale. La joie est répétée à chaque connexion, la satisfaction est amplifiée à chaque victoire.

---

## 13. Différenciation Concurrentielle

### Pourquoi Lumora se démarque

| Concurrents (type) | Leur force | Ce que Lumora fait différemment |
|--------------------|-----------|---------------------------------|
| **Candy Crush** (match-3) | Mécanique addictive, marque forte | Lumora propose un gameplay créatif (dessiner des filaments) plutôt que du matching passif. L’univers est apaisant, pas sucré/agressif. |
| **Monument Valley** (puzzle artistique) | Beauté visuelle, narration silencieuse | Lumora ajoute la compétition (tournois, leaderboard), les événements automatiques, et la progression infinie (100+ niveaux). |
| **Two Dots** (puzzle connect) | Simplicité, courbe douce | Lumora introduit la 3D (parallaxe, lumières, particules) dans un moteur 2D, une narration émotionnelle avec Lumie, et une monétisation respectueuse (jamais plus de 5 $). |
| **Wordscapes** (casual réflexion) | Sessions courtes, rentable | Lumora est plus sensoriel (musique procédurale, haptique) et social (partage natif, parrainage). |
| **Genshin Impact** (gacha) | Univers riche, monetisation massive | Lumora est accessible à tous (pas de barrière technique), 100 % gratuit viable, et l’univers est chaleureux pas dark/fantasy lourd. |

### Différenciation unique
1. **UI 100 % organique** : aucun concurrent casual ne pousse aussi loin l’absence de bords droits. Lumora est une expérience tactile et visuelle cohérente de bout en bout.
2. **Musique procédurale liée au gameplay** : connecter des nœuds joue des notes. Le joueur compose involontairement une mélodie. Aucun puzzle casual ne fait cela.
3. **Système d’indices décroissants intelligent** : l’accessibilité est intégrée dès la conception, pas ajoutée en patch. Les débutants sont guidés, les pros ne sont jamais gênés.
4. **Événements automatiques riches** : pas juste un daily reward, mais un calendrier complet (tournois, happy hours, saisons) qui tourne sans intervention humaine.
5. **Monétisation éthique** : plafond de 5 $, pubs non intrusives, Passe Saisonnier qui retire les pubs (respect du joueur payant).

---

## 14. Contraintes Transversales — Vérification Finale

Checklist obligatoire. Chaque contrainte est intégrée et vérifiée dans les sections ci-dessus.

| # | Contrainte | Où / Comment elle est intégrée | Statut |
|---|------------|------------------------------|--------|
| 1 | **UI organique** | Tous les écrans utilisent des bulles flottantes, des cartes arrondies (min 16dp), du glassmorphism, des dégradés, des ombres portées. Aucun bouton carré gris, aucun bord droit. Voir sections 2, 4, 7, 8, 10, 11. | ✅ Vérifié |
| 2 | **2D avec effets 3D** | Parallaxe de fond, lumières dynamiques sur les nœuds, particules à chaque interaction, ombres portées animées, glassmorphism. Voir sections 2 (ambiance visuelle), 3 (core loop), 11 (world map). | ✅ Vérifié |
| 3 | **Indices visuels décroissants** | Tableau complet section 6 : opacité, délai, fréquence, type d’indice définis par palier de 10 niveaux. Paramétrables via Remote Config. | ✅ Vérifié |
| 4 | **Compte utilisateur (Google/Apple/Email) + sauvegarde cross-device** | Sections 3 et 4 des Specs Fonctionnelles. Firestore user-scoped, sync < 5s, offline-first, liaison anonyme → authentifié sans perte. | ✅ Vérifié |
| 5 | **Partage social** | Section 10 : capture auto + overlay organique + partage natif + lien dynamique + parrainage avec récompenses. | ✅ Vérifié |
| 6 | **Gratuit + pubs + IAP abordables ≤ 5 $** | Section 7 : interstitielles 1/5 niveaux, récompensées volontaires, IAP max 4.99 $ (Pack 50 Vies, Passe Saisonnier). Respect strict du plafond. | ✅ Vérifié |
| 7 | **Événements automatiques** | Section 9 : défi quotidien, week-end, tournoi bi-mensuel, happy hour, saisonnier — tous programmés via Cloud Scheduler + Cloud Functions sans intervention manuelle. | ✅ Vérifié |
| 8 | **Notifications de retour** | Section 8 : notifications 24h/72h/7j/14j/30j avec contenu personnalisé, ton adapté, son doux. Fallback FCM + locales. | ✅ Vérifié |
| 9 | **Sessions courtes, accessible, addictif** | Section 3 (core loop 3–8 min), section 5 (courbe sigmoïde modérée), section 12 (carte des émotions), section 1 (pourquoi c’est addictif). | ✅ Vérifié |

---

*Document généré le 2026-05-07. Sous-agent Game Designer — Projet Lumora.*
