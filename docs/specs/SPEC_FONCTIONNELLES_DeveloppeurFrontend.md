# SPEC_FONCTIONNELLES_DeveloppeurFrontend.md — Lumora

## Livrables source
- `lib/main.dart` — Entry point Firebase/Flame/AdMob/RevenueCat init
- `lib/app/theme.dart` — Design system Lumora (colors, gradients, shadows, text styles, radii)
- `lib/app/router.dart` — GoRouter avec routes /splash, /auth, /home, /game, /world-map, /shop, /settings, /events + auth guards
- `lib/shared/widgets/lumora_button.dart` — Bouton organique bulle/dégradé/ombre, jamais bord droit
- `lib/shared/widgets/lumora_card.dart` — Card glassmorphism blur/bordure/coins arrondis
- `lib/shared/widgets/sync_indicator.dart` — Indicateur sync vert/orange/rouge + retry
- `lib/features/auth/presentation/auth_screen.dart` — Écran auth avec 4 bulles flottantes (Google, Apple, Email, Anonyme)
- `lib/features/game/engine/lumora_game.dart` — Flame Game de base avec parallaxe 3 couches
- `lib/features/game/presentation/game_screen.dart` — Écran jeu avec overlay organique (vies, timer circulaire, pause, indice ampoule)
- `lib/features/game/presentation/victory_overlay.dart` — Overlay victoire avec étoiles elastic scale, boutons organiques
- `lib/features/game/presentation/world_map_screen.dart` — Carte mondes bulles flottantes + Bézier placeholder
- `lib/features/monetization/presentation/shop_screen.dart` — Boutique scroll horizontal organique avec cartes produits
- `lib/features/settings/presentation/settings_screen.dart` — Paramètres cartes organiques empilées, toggles iOS-style
- `lib/features/events/presentation/events_screen.dart` — Écran événements avec cartes organiques et compte à rebours
- `lib/STYLE_GUIDE.md` — Guide de style UI organique (règles, tokens, composants, anti-patterns)

---

## Cas d'usage consolidés

| ID | Cas d'usage | Acteur | Description |
|----|-------------|--------|-------------|
| UC-FE-01 | Lancer l'application | Joueur | Splash screen, init Firebase, transition vers auth ou home |
| UC-FE-02 | S'authentifier | Joueur | Choisir Google, Apple, Email ou Anonyme via bulles organiques |
| UC-FE-03 | Naviguer dans l'app | Joueur | Router GoRouter avec transitions fluides et deep linking |
| UC-FE-04 | Jouer un niveau | Joueur | Écran de jeu Flame avec tap/swipe sur nœuds, timer, pause, indice |
| UC-FE-05 | Consulter la carte des mondes | Joueur | World map avec bulles flottantes, niveaux complétés/verrouillés |
| UC-FE-06 | Partager une victoire | Joueur | Overlay victoire avec bouton partage bulle bleue organique |
| UC-FE-07 | Acheter dans la boutique | Joueur | Shop avec cartes organiques, prix visibles, aperçu placeholder |
| UC-FE-08 | Régler les paramètres | Joueur | Settings avec toggles arrondis, restaurer achats, lier compte |
| UC-FE-09 | Voir les événements | Joueur | Events screen avec cartes actives, compte à rebours circulaire |
| UC-FE-10 | Vérifier la synchronisation | Joueur | SyncIndicator en haut à droite, vert/orange/rouge |

## User stories consolidées

| ID | User Story | Critères d'acceptation |
|----|------------|------------------------|
| US-FE-01 | En tant que joueur, je veux une UI entièrement organique et moderne, afin d'avoir une expérience premium et immersive. | LumoraButton (borderRadius 9999, dégradé, ombre), LumoraCard (glassmorphism, blur, bordure), jamais ElevatedButton/textButton brut. STYLE_GUIDE.md documente les règles. |
| US-FE-02 | En tant que joueur, je veux jouer avec une seule main, afin de pouvoir jouer n'importe où. | Game screen : tap + swipe, boutons en bas ou sur les côtés accessibles au pouce. Timer circulaire en haut. |
| US-FE-03 | En tant que joueur, je veux des animations fluides et satisfaisantes, afin de ressentir du plaisir à chaque action. | Victory overlay : étoiles elastic scale (150–300ms), particules placeholder. Transitions : fade-slide ease-in-out-cubic. |
| US-FE-04 | En tant que joueur, je veux voir ma progression sur une carte vivante, afin d'être motivé à continuer. | World map : bulles flottantes reliées par Bézier, niveaux complétés brillants avec mini-étoiles, verrouillés gris translucides. |
| US-FE-05 | En tant que joueur, je veux pouvoir acheter des vies ou des thèmes facilement, afin de personnaliser mon expérience. | Shop screen : scroll horizontal organique avec snap elastic, cartes produits avec prix (0.99$–4.99$), badge Populaire. |
| US-FE-06 | En tant que joueur, je veux recevoir des indices visuels quand je bloque, afin de ne pas abandonner. | Bouton ampoule organique dans la barre de jeu. Prêt pour injection HintConfigRepository (Remote Config). |
| US-FE-07 | En tant que joueur, je veux partager mes victoires, afin de défier mes amis. | Victory overlay : bouton Partager bulle bleue. Prêt pour screenshot_service + share_plus. |
| US-FE-08 | En tant que joueur, je veux que mes données soient synchronisées, afin de ne pas perdre ma progression. | SyncIndicator visible sur l'accueil. Vert = sync, orange = attente, rouge = erreur + retry. |

## Règles fonctionnelles livrées (sélection)

### Design system
- **RB-DS-01** : LumoraColors : jamais de gris brut (#808080). Utiliser des teintes chaudes/froides avec luminosité adaptée.
- **RB-DS-02** : BorderRadius minimum : 16dp cartes, 24dp modales, 32dp écrans complets, 9999dp boutons bulle.
- **RB-DS-03** : Glassmorphism : blur 10–20, opacité 0.6–0.8, bordure blanche 0.5dp.
- **RB-DS-04** : Ombres : elevation 4–8dp, couleur assortie au thème, diffuse (pas de noir pur).
- **RB-DS-05** : Animations UI : ease-in-out-cubic pour transitions, elastic scale pour étoiles/victoires.

### Composants partagés
- **RB-CO-01** : LumoraButton : shape bulle (borderRadius 9999), gradient linéaire/radial, shadow colorée, inkWell circulaire. Paramètres : onPressed, text, icon, gradientColors, size.
- **RB-CO-02** : LumoraCard : glassmorphism (BackdropFilter.blur), borderRadius 16dp+, border blanc léger, shadow. Paramètres : child, padding, borderRadius.
- **RB-CO-03** : SyncIndicator : icon nuage+flèche, couleur selon état (vert/orange/rouge), tap = retry sync.

### Écrans
- **RB-AU-01** : AuthScreen : fond dégradé, logo Lumora, 4 bulles flottantes (Google, Apple, Email, Anonyme). LumoraButton uniquement.
- **RB-GS-01** : GameScreen : Stack GameWidget + overlay UI. Barre supérieure : niveau (bulle), vies (cœurs), timer (cercle organique remplissable), pause (bulle), indice (ampoule).
- **RB-GS-02** : VictoryOverlay : glassmorphism, étoiles apparaissent une par une (elastic scale), boutons organiques (Niveau Suivant vert, Partager bleu, Menu gris translucide).
- **RB-WM-01** : WorldMapScreen : fond parallaxe, bulles flottantes reliées par CustomPainter Bézier, complétés brillants, verrouillés gris+cadenas.
- **RB-SH-01** : ShopScreen : fond dégradé, scroll horizontal avec snap elastic, cartes organiques par produit, aperçu placeholder.
- **RB-SE-01** : SettingsScreen : cartes organiques empilées, toggles iOS-style arrondis, bouton Restaurer Achats.
- **RB-EV-01** : EventsScreen : cartes organiques par événement actif, compte à rebours circulaire, fond parallaxe placeholder.

---

*Document consolidé par l'Agent Principal — Projet Lumora — 2026-05-07*
