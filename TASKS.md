# Tâches — Lumora Mobile

## Complété (session 2026-05-11 — gameplay fixes)

## Complété (session 2026-05-17 — progression, pubs, rendu)

| # | Tâche | Statut |
|---|-------|--------|
| 30 | Videos recompensees AdMob branchees sur la defaite | ✅ Terminé |
| 31 | Logique pub partagee entre jeu, boutique et evenements | ✅ Terminé |
| 32 | 10 niveaux artisanaux + progression procedurale infinie | ✅ Terminé |
| 33 | Themes de mondes et regles speciales procedurales | ✅ Terminé |
| 34 | Indice manuel couteux avec vrai apercu de connexion | ✅ Terminé |
| 35 | Passe visuelle gameplay (nœuds, filaments, victoire) | ✅ Terminé |
| 36 | Tests unitaires gameplay et progression mis a jour | ✅ Terminé |
| 37 | Documentation produit et notice synchronisees | ✅ Terminé |

## Complété (session 2026-05-17 — meta-boucle, analytics, world map)

| # | Tâche | Statut |
|---|-------|--------|
| 38 | Inventaire joueur persistant pour vies, indices et charges bonus | ✅ Terminé |
| 39 | Activation réelle des charges Double Score et Super Filament | ✅ Terminé |
| 40 | Objectifs secondaires proceduraux + recompenses de maitrise | ✅ Terminé |
| 41 | Analytics `mastery_reward_granted` avec fallback local | ✅ Terminé |
| 42 | World map enrichie (filtres, badges, compteur, saut pertinent) | ✅ Terminé |
| 43 | Test widget cible pour la navigation de maitrise | ✅ Terminé |

| # | Tâche | Statut |
|---|-------|--------|
| 1 | Fix anchor/Offset.zero (EnergyNode + LumieComponent) | ✅ Terminé |
| 2 | Fix levelData final → mutable + loadNextLevel() | ✅ Terminé |
| 3 | Fix nettoyage incomplet (_loadLevel → whereType) | ✅ Terminé |
| 4 | Fix drag bloqué multi-touch (_activePointerId) | ✅ Terminé |
| 5 | Positions nœuds aléatoires (_generateRandomPositions) | ✅ Terminé |
| 6 | Bouton Commencer : taille normale + bleu apaisant | ✅ Terminé |
| 7 | Système vies/coups séparé (GameState + LevelData) | ✅ Terminé |
| 8 | UI _LivesAndAttempts (cœurs + compteur coups) | ✅ Terminé |
| 9 | eventPosition.widget (pas .game) | ✅ Terminé |
| 10 | Auto-activation nœuds dormants au drag start | ✅ Terminé |
| 11 | Build APK + install device | ✅ Terminé |

## Complété (session 2026-05-08 — suite 2)

| # | Tâche | Statut |
|---|-------|--------|
| 12 | ProceduralBackground (fallback parallax) | ✅ Terminé |
| 13 | World Map dynamique (bulles connectées, états levels) | ✅ Terminé |
| 14 | Router mis à jour (LevelData extra, completedLevelId) | ✅ Terminé |
| 15 | Animated transitions (fade + slide, CustomTransitionPage) | ✅ Terminé |
| 16 | HomeScreen réel (Jouer, Carte, Événements, Boutique, Paramètres) | ✅ Terminé |
| 17 | Tests unitaires GameState (24/24 passent) | ✅ Terminé |
| 18 | Build APK debug OK | ✅ Terminé |
| 19 | 0 erreurs flutter analyze | ✅ Terminé |
| 20 | Bug fix : GameState partagé entre GameScreen et LumoraGame | ✅ Terminé |
| 21 | Tests integration device simplifiés (15 scénarios) | ✅ Terminé |

## Complété (session 2026-05-08 — début)

| # | Tâche | Statut |
|---|-------|--------|
| 22 | EnergyNode, FilamentComponent, LumieComponent, GameState | ✅ Terminé |
| 23 | LumoraGame complet (tap, swipe, pinch) | ✅ Terminé |
| 24 | 5 niveaux World1 (Éveil→Nébuleuse) | ✅ Terminé |
| 25 | GameScreen connecté au GameState réel | ✅ Terminé |
| 26 | ProceduralBackground (étoiles/nébuleuse/poussière) | ✅ Terminé |

## Complété (session 2026-05-07)

| # | Tâche | Commit |
|---|-------|--------|
| 27 | Compilation APK debug + installation Xiaomi 12 | 9129414 |
| 28 | Corrections bugs visuels (LumoraButton, parallax, kDebugMode) | 9129414 |
| 29 | Fix auth guard pour tests device + pumpAndSettle timeout Flame | 3d5c5d9 |

## Problèmes connus

- **Build Android des tests device cassé par le toolchain Kotlin** : la suite `flutter test integration_test/ --device-id 6db039ac` ne démarre plus sur device car `firebase_analytics` tire des dépendances Play Services compilées avec une metadata Kotlin 2.1.0, alors que le plugin Kotlin Android du projet attend encore 1.8.0. Le blocage arrive pendant `:firebase_analytics:compileDebugKotlin`, avant l'exécution des scénarios UI.
- **Configuration Firebase mobile absente du repo** : `android/app/google-services.json` et `ios/Runner/GoogleService-Info.plist` ne sont pas présents. L'app garde donc un fallback local pour l'analytics et l'auth Firebase ne peut pas être finalisée tant que la config native n'est pas fournie.
- **MIUI / écran allumé** : le Xiaomi 12 est bien visible en ADB et `stay_on_while_plugged_in = 15` est déjà actif. La déconnexion USB n'est plus le blocage principal observé le 2026-05-17, mais le réglage "Stay awake" doit rester activé pour les longues suites device.

## Prochaine session (prioritaire vers beta)

1. **Débloquer le build Android device** : mettre à niveau le plugin Kotlin/Gradle Android pour redevenir compatible avec `firebase_analytics` et rétablir `assembleDebug`.
2. **Persistance de progression joueur** : stocker `completedLevelId`, derniers mondes vus, règles vues et statut de maîtrise global dans un service local dédié.
3. **Firebase mobile complet** : embarquer la config native, brancher Firebase Auth (Google, Apple, Email, anonyme) et conserver le parcours invité comme fallback.
4. **Stabiliser les tests device** : relancer les 15 scénarios sur Xiaomi 12 une fois le build réparé, puis ajouter les flows vidéo récompensée, inventaire persistant et world map de maîtrise.
5. **Fonts produit** : bundler Nunito dans `pubspec.yaml`, vérifier les fallback typography et homogénéiser les styles titres/corps/badges.
6. **Progression et monde 2+** : ajouter un vrai pont entre le tutoriel artisanal et les mondes suivants avec plus de niveaux signature, paliers de difficulté plus lisses et meilleure montée en charge.
7. **Assets visuels bêta** : étendre les PNG de parallax et les fonds illustrés au-delà du gameplay principal (events, world map, variations par monde) en gardant le procédural en fallback.
8. **UX défaite / reprise** : enrichir l'overlay de défaite avec tentatives restantes, meilleure lisibilité des vies de réserve et hiérarchie claire entre retry, pub et abandon.
9. **Economy tuning** : calibrer `Surcharge`, `Resonance`, `Blackout`, les cooldowns boutique/événements et les récompenses de maîtrise via analytics + Remote Config.
10. **Boucle de rétention bêta** : ajouter un défi quotidien, une rotation simple d'événements et un premier objectif de retour joueur sans complexifier encore le commerce.
11. **Accessibilité et confort** : mode daltonien léger, vibrations configurables plus fines, vitesse FX réduite et meilleure lisibilité des états de combo/erreur.
12. **Checklist release beta** : versioning, crash-free startup, instrumentation minimale, smoke tests Android, vérification offline et revue UX complète du premier quart d'heure.

## Backlog

- Brancher RevenueCat (IAP packs vies, thèmes, passe saisonnier)
- Notifications de retour (24h/72h/7j/30j)
- Événements automatiques (daily, week-end, saisonnier, tournois)
- Leaderboard + système de parrainage
- Mode journalier (niveau aléatoire quotidien)
- Achievements / badges
- Sauvegarde cloud / reprise multi-device liée au compte
- Replays légers ou ghost runs pour comparer ses meilleures parties
- Partage social de score, niveau et série de maîtrise
- Personnalisation cosmétique des mondes, filaments et halos
- A/B tests de tuning economy / UX via Remote Config
- Pipeline LiveOps (saisons, bundles, calendrier d'événements)
- Localisation EN pour la bêta fermée élargie
- Accessibilité avancée (contrastes renforcés, tailles de texte, réduction des animations)