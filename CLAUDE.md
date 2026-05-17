# CLAUDE.md — Lumora Mobile

## Contexte
Jeu mobile Flutter 3.24+ avec Flame (game engine 2D) + Firebase. Style visuel ultra-moderne : 2D avec effets 3D (parallaxe, lumières dynamiques, particules). UI 100% organique (pas de boutons carrés gris, pas de bords droits, tout arrondi, dégradés, glassmorphism, ombres portées, micro-animations fluides).

## Build
```bash
export PATH="/home/geekai/flutter/bin:$PATH"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64  # Requis pour audioplayers
flutter pub get
flutter build apk --debug          # APK debug (nécessite JDK 17)
flutter analyze --no-fatal-infos   # Analyse statique
flutter test test/                 # Tests unitaires
flutter test integration_test/ --device-id 6db039ac   # Tests device Xiaomi 12
adb install -r -t -d build/app/outputs/flutter-apk/app-debug.apk  # Install APK
adb shell settings put global stay_on_while_plugged_in 3   # Garder écran allumé
```

## Architecture
- `lib/app/` — router (GoRouter transitions organiques), theme (dark organique)
- `lib/core/` — utils (haptics), audio (SoundManager)
- `lib/features/game/` — moteur Flame + écrans (gameplay, world-map, victory)
  - `engine/` — LumoraGame, EnergyNode, FilamentComponent, LumieComponent, GameState, ProceduralBackground, ParticleSystemComponent
  - `domain/` — LevelData, Connection, NodePosition
  - `presentation/` — GameScreen, WorldMapScreen, VictoryOverlay
- `lib/features/auth/` — écran d'authentification (Google/Apple/Email/Anonyme)
- `lib/features/settings/` — paramètres avec toggles iOS-style
- `lib/features/monetization/` — shop avec PageView horizontal
- `lib/features/events/` — événements avec compte à rebours
- `lib/shared/widgets/` — LumoraButton (press animation + haptics), LumoraCard (glassmorphism blur)

## Dépendances
- flame: 1.18.0 (moteur 2D)
- go_router: ^14.0.0 (navigation organique)
- flutter_riverpod: ^2.6.0 (state management)
- audioplayers: ^6.1.0 (SFX + musique ambiante)
- Android compileSdk = 35 (requis par audioplayers_android)

## Contraintes critiques
- **Jamais** de boutons Material bruts (ElevatedButton, TextButton, OutlinedButton)
- **Jamais** de bords droits sur les containers (toujours borderRadius ou shape: circle)
- `kDebugMode` obligatoire pour tout bouton/overlay de debug
- Flame `loadParallaxComponent` préfixe automatiquement `assets/images/` — ne pas doubler le chemin
- **GameState est partagé** entre GameScreen (UI) et LumoraGame (moteur). Ne jamais créer deux instances séparées.
- **ParticleSystemComponent** est notre classe custom — `import 'particle_system.dart'` sans le `hide ParticleSystemComponent` de Flame.
- **JDK 17** requis pour le build (audioplayers Android SDK 35).

## Effets visuels implémentés
- **EnergyNode** : glow pulsant multi-couche, ripple ring à l'activation, bounce d'activation, flash de connexion, specular highlight dynamique, idle oscillation
- **FilamentComponent** : Bézier cubique (courbes organiques), reveal progressif, 4 couches de glow, épaisseur variable (effet électrique), trail de particules lumineuses, break animation avec fragments Bézier
- **LumieComponent** : glow pulsant 4 couches, trail gradient amélioré, spring physics pour snap-to, specular highlight, breathing effect
- **ProceduralBackground** : 5 couches (nébuleuse lointaine, nuages, 300 étoiles, nuages proches, brume), shooting stars aléatoires, couleurs thématiques par monde
- **ParticleSystemComponent** : pool recyclé (max 300), connectionBurst, victoryCascade, comboSpiral, nodeRipple, errorScatter, étoiles ambiantes
- **LumoraButton** : press animation (scale 0.95), floating animation, haptic feedback
- **LumoraCard** : BackdropFilter blur (glassmorphism réel)
- **VictoryOverlay** : particules dorées, étoiles avec glow halos, score animé
- **WorldMapScreen** : chemins Bézier avec glow néon multi-couche, bulles flottantes animées
- **Router** : transitions organiques (scale+fade pour jeu, elastic pour world-map)
- **Haptics** : LumoraHaptics (light/medium/heavy impact, selection click) sur toutes les interactions
- **Audio** : SoundManager avec gammes pentatoniques par monde, SFX cristallins pour connexions

## Points de vigilance
- `pumpAndSettle()` bloque à l'infini avec Flame (Ticker actifs). Utiliser `pump(Duration)` à la place.
- Le auth guard GoRouter redirige vers `/auth` si `isAuthenticated == false`.
- Xiaomi 12 (MIUI) : ADB nécessite "Installer via USB" + "USB Debugging (Security Settings)".
- Les tests device doivent naviguer directement vers les routes plutôt que de compter sur le splash screen.

## Système de vies et coups (implémenté session 2026-05-11)
- **Vies** = cœurs (3 par niveau). Chaque vie donne droit à N coups (`attemptsPerLife`).
- **Coups** (`attemptsRemaining`) : consommés uniquement par les connexions ratées ou dupliquées.
- Quand tous les coups d'une vie sont épuisés → perd 1 vie + récupère `attemptsPerLife` coups.
- Quand toutes les vies sont épuisées → défaite.
- Connexions réussies ne coûtent rien (0 coup, 0 vie).
- UI : `_LivesAndAttempts` widget (cœurs + compteur `X/Y` avec code couleur vert/orange/rouge).
- `LevelData.attemptsPerLife` : Niv 1-3 = 5, Niv 4 = 7, Niv 5 = 10.

## Bugs corrigés (session 2026-05-11)
- **Anchor/Offset.zero** : `EnergyNode` et `LumieComponent` utilisaient `Anchor.center` mais dessinaient à `Offset.zero`. Fix : `canvas.translate(size.x/2, size.y/2)` avant le rendu.
- **LevelData final** : `levelData` était `final` et jamais mis à jour au chargement du niveau suivant. Fix : champ mutable + `levelData = nextLevel` dans `loadNextLevel()`.
- **Nettoyage incomplet** : `_loadLevel()` nettoyait seulement `_nodes`/`_filaments` listes, pas les composants auto-retirés (filaments cassés). Fix : `children.whereType<T>().toList().forEach(remove)`.
- **Drag bloqué** : Pas de suivi du pointeur actif → conflits multi-touch. Fix : `_activePointerId` tracking + `_cancelCurrentDrag()`.
- **Positions fixes** : Nœuds toujours aux mêmes positions. Fix : `_generateRandomPositions()` avec minDistance 80px.
- **Bouton Commencer** : Trop grand + vert au lieu de bleu. Fix : Container circle + glow + gradient `[twilight, auroraBlue]`.
- **eventPosition.game** : N'existe pas dans Flame 1.18.0. Utiliser `eventPosition.widget` uniquement.

## Prochaine session (prioritaire)
1. **Assets parallax PNG** : Remplacer ProceduralBackground par de vrais assets image.
2. **Firebase Auth** : Brancher Google/Apple/Email/Anonymous.
3. **Progression persistante** : SharedPreferences pour completedLevelId.
4. **Stabiliser tests device** : Valider les 15 scénarios + nouveaux tests lives/attempts.
5. **Fonts** : Bundler Nunito (référencé dans theme mais pas dans pubspec).
6. **Overlay défaite enrichi** : Afficher tentatives restantes dans l'overlay de défaite.
7. **World 2+ niveaux** : Ajouter des niveaux pour les mondes suivants avec difficulté croissante.