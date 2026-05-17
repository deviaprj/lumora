# Décisions de design — Lumora Mobile

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