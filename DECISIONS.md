# Décisions de design — Lumora Mobile

## Session 2026-05-17

### D6 : Progression hybride artisanale + procedurale
**Décision** : Conserver une ouverture en niveaux faits main (1–10), puis basculer sur une generation procedurale infinie.

**Pourquoi** : Les premiers niveaux servent de tutoriel invisible et de reference qualitative. La generation infinie prend ensuite le relais pour offrir de la rejouabilite sans attendre du contenu artisanal massif.

### D7 : Regles speciales lisibles plutot qu'une complexite cachée
**Décision** : Les paliers proceduraux introduisent des regles nommees (`Flux stable`, `Surcharge`, `Resonance`, `Blackout`) affichees directement dans l'UI.

**Pourquoi** : La difficulte devient compréhensible. Le joueur sait pourquoi un niveau est plus exigeant sans avoir l'impression d'une punition arbitraire.

### D8 : Une seule logique de video recompensee
**Décision** : Centraliser la video recompensee pour le gameplay, la boutique et les evenements via le meme service AdMob.

**Pourquoi** : Un pipeline unique simplifie la maintenance, la mesure analytique et garantit une UX coherente. Les pubs restent opt-in et contextuelles.

### D9 : Reprise apres defaite graduelle
**Décision** : Sur un echec, la premiere video rend 1 vie, la seconde 2 vies, puis l'offre disparait.

**Pourquoi** : Cela aide a repartir sans transformer la defaite en ressource infinie. Le joueur garde une sensation de rattrapage, pas d'exploitation.

### D10 : Amplification visuelle guidee par la lisibilite
**Décision** : Renforcer les nœuds, filaments et overlays avec plus d'eclat, d'orbites et de pulses, sans ajouter de bruit fonctionnel.

**Pourquoi** : L'objectif n'est pas seulement de faire plus beau, mais de rendre les points d'accroche visuels plus memorables et plus lisibles pendant l'action.

### D11 : La maitrise doit etre suivie comme une boucle produit a part entiere
**Décision** : Emmettre un evenement analytique dedie `mastery_reward_granted` au moment de la victoire, avec fallback local si Firebase n'est pas initialise.

**Pourquoi** : La meta-boucle de maitrise influence directement retention, reutilisation des charges et rejouabilite. Il faut pouvoir la mesurer des maintenant sans bloquer le developpement local ni casser la build tant que la configuration Firebase mobile n'est pas dans le repo.

### D12 : La world map doit montrer non seulement l'acces, mais l'etat de maitrise
**Décision** : Ajouter sur la carte des mondes un filtre visuel de maitrise (`A gagner`, `En cours`, `Complete`) et des marqueurs differencies sur chaque bulle.

**Pourquoi** : Une simple numerotation ne suffit pas a guider la rejouabilite. Le joueur doit voir instantanement quels niveaux peuvent encore enrichir son inventaire, lesquels sont partiellement maitrises, et lesquels sont totalement exploites.

## Session 2026-05-11

### D1 : Système vies/coups séparé
**Décision** : Séparer les vies (cœurs) des coups (tentatives par vie). Chaque vie donne droit à N coups. Seules les connexions ratées ou dupliquées consomment des coups. Quand les coups sont épuisés, on perd une vie et on récupère les coups.

**Pourquoi** : L'utilisateur trouvait injuste qu'une connexion réussie coûte une vie. Le système précédent confondait vies et tentatives. La nouvelle mécanique est plus intuitive : on essaie, on se trompe = ça coûte, on réussit = ça ne coûte rien.

**Valeurs** : Niv 1-3 → 3 vies × 5 coups, Niv 4 → 3 vies × 7 coups, Niv 5 → 3 vies × 10 coups.

### D2 : Positions de nœuds aléatoires
**Décision** : Les positions des nœuds sont aléatoires à chaque partie, avec contrainte de distance minimale (80px) et de marge (60px du bord).

**Pourquoi** : Les positions fixes rendaient le jeu répétitif et prévisible. L'algorithme de placement aléatoire avec `maxAttempts = 150` garantit des positions bien espacées.

**Trade-off** : Certaines configurations aléatoires pourraient être plus faciles que d'autres. Considérer à l'avenir un système de validation de configuration (pas de croisements involontaires trop faciles, etc.).

### D3 : Anchor.center + translate pour le rendu Flame
**Décision** : Pour les composants avec `Anchor.center`, ajouter `canvas.translate(size.x/2, size.y/2)` au début de `render()`.

**Pourquoi** : Avec `Anchor.center`, Flame positionne le composant de sorte que le coin top-left de la bounding box = `position - size/2`. Mais `Offset.zero` dans `render()` correspond au coin top-left, pas au centre. Sans le translate, tous les éléments visuels sont décalés de `size/2` par rapport à leur position logique. C'est un piège classique Flame.

### D4 : Single-pointer drag
**Décision** : Un seul pointeur actif pour le drag à la fois. Si un nouveau drag commence, l'ancien est annulé (`_cancelCurrentDrag`).

**Pourquoi** : Sur mobile, les multi-touch non gérés créent des états incohérents (filaments fantômes, drag bloqué). Le gameplay de Lumora est un swipe à la fois entre deux nœuds.

### D5 : Couleur bleu apaisant pour boutons principaux
**Décision** : Les boutons "Jouer" et "Commencer" utilisent le gradient `[LumoraColors.twilight, LumoraColors.auroraBlue]` avec un glow `auroraBlue`.

**Pourquoi** : Le vert (auroraGreen) initial paraissait trop agressif/tech pour un bouton d'action principal. Le bleu apaisant correspond mieux à l'univers lumineux/cosmique de Lumora.