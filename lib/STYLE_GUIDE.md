# STYLE_GUIDE.md — Lumora Mobile

## Règle #1 : Jamais de boutons carrés gris, jamais de bords droits

Tout widget interactif, tout conteneur, toute surface visuelle DOIT respecter
la forme organique : coins arrondis (minimum 12dp, idéalement 16dp+), formes
bulles (9999dp), ou contours fluides (courbes de Bézier). Aucune exception.

---

## Tokens

### Couleurs
- **Pas de gris brut** (#808080 est INTERDIT).
- Fonds : `deepSpace`, `twilight`, `dawn`, `midnight` — des bleus/violets profonds.
- Surfaces : `softMist`, `pearl` — blancs très légèrement teintés.
- Accents : `auroraGreen`, `auroraBlue`, `auroraPurple`, `auroraPink`, `auroraGold`, `auroraOrange`.
- États : `lifeCoral` (vies), `energyAmber` (indices), `syncGreen`, `waitOrange`, `errorRose`.
- Verrous / inactifs : `lockOverlay`, `disabledMist` — translucides, jamais opaques gris.

### Dégradés
- `homeBg` : deepSpace → twilight → dawn
- `authBg` : midnight → deepSpace → twilight
- `victory` : auroraGold → auroraOrange
- `primaryBubble` : auroraGreen → auroraBlue
- `secondaryBubble` : auroraPurple → auroraPink
- `dangerBubble` : lifeCoral → auroraPink
- `glassOverlay` : blanc 13% → blanc 7%

### Ombres
- `soft` : blur 16, offset (0, 6), alpha faible
- `glow` : blur 24, offset (0, 0), alpha moyenne — pour les éléments actifs
- `floating` : blur 20, offset (0, 10) — pour les bulles flottantes
- `innerGlow` : blur 12, offset (0, -4) — pour les effets de profondeur

### Border Radius
- `card` : 16dp (minimum pour toute carte)
- `modal` : 24dp (bottom sheets, dialogues)
- `screen` : 32dp (grandes surfaces, plein écran)
- `bubble` : 9999dp (pills, boutons)
- `small` : 12dp (chips, badges)

---

## Animations

### Courbes
- `ease-in-out-cubic` : transitions de navigation, apparitions de cartes.
- `elasticOut` : apparitions d'étoiles, badges, récompenses (dopamine).
- `easeInOutCubic` : floating des bulles, transitions de page.

### Patterns
- **Fade + slide** : les écrans entrants glissent depuis la droite/bas avec fade.
- **Elastic scale** : les éléments de récompense grossissent avec rebond.
- **Pulse glow** : les éléments interactifs pulsant doucement (AnimationController loop).

---

## Composants approuvés

### LumoraButton
- **Usage** : Toute action utilisateur (tap, navigation, achat, partage).
- **Forme** : bulle pleinement arrondie (borderRadius 9999).
- **Surface** : dégradé linéaire (jamais couleur unie grise).
- **Effet** : ombre colorée douce (elevation 4–8), inkWell circulaire.
- **Interdit** : pas de `ElevatedButton`, `TextButton`, `OutlinedButton` natifs.

### LumoraCard
- **Usage** : Tout panneau, conteneur d'information, modale.
- **Forme** : coins arrondis min 16dp.
- **Surface** : glassmorphism (backdrop blur simulé via couleur alpha + bordure blanche légère 0.5dp).
- **Effet** : ombre portée douce.
- **Interdit** : pas de `Card` Material brut, pas de `Container` sans borderRadius.

### LumoraModal (à venir)
- **Usage** : modales bottom-sheet, confirmations.
- **Forme** : bords supérieurs arrondis 24dp, corps fluide.
- **Animation** : hero transition + fade-slide.

---

## Anti-patterns INTERDITS

| Anti-pattern | Remplacement |
|--------------|--------------|
| `ElevatedButton` | `LumoraButton` |
| `TextButton` brut | `LumoraButton` avec fond transparent |
| `Container` sans `borderRadius` | `Container` + `BorderRadius.circular(...)` ou `LumoraCard` |
| Couleurs unies grises (`Colors.grey`, `#808080`) | Dégradés ou couleurs teintées (`softMist`, `disabledMist`) |
| Bords droits (0dp) | Minimum 12dp, idéalement 16dp+ ou bulle |
| `MaterialButton` | `LumoraButton` |
| `AlertDialog` carré | `LumoraCard` centrée avec fond glassmorphism |
| `Switch` Material rectangulaire | `CupertinoSwitch` (arrondi natif) ou toggle organique custom |

---

## Lint implicite

Avant chaque commit, vérifier visuellement que :
1. Aucun widget ne présente un angle droit visible.
2. Aucun bouton n'est gris plat sans dégradé.
3. Toutes les ombres sont colorées (pas de `Colors.black` pur).
4. Tous les textes utilisent la police Nunito/Quicksand.
5. Les icones sont toutes `Icons.*_rounded` (pas `_outlined` anguleux).
