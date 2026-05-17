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

- **MIUI USB déconnexion** : Le Xiaomi 12 se déconnecte pendant les tests device après ~30s. Solution : `adb shell settings put global stay_on_while_plugged_in 3` + activer "Stay awake" dans les options développeur.
- **Integration tests device** : 6/8 tests UI passent (01-06), mais le device se déconnecte avant la fin du test 07. Les 7 tests GameState (09-15) sont en logique pure et ne nécessitent pas le device.

## Prochaine session (prioritaire)

1. **Persistance des bonus pubs** : relier les bonus boutique/evenements a un inventaire joueur persistant.
2. **Assets parallax PNG** : remplacer le fond procédural par de vrais assets PNG quand disponibles.
3. **Firebase Auth** : brancher l'authentification (Google/Apple/Email/Anonymous).
4. **Progression persistante** : sauvegarder le completedLevelId et les themes/règles vues en SharedPreferences.
5. **Stabiliser tests device** : relancer les 15 tests integration et couvrir les flows video recompensee.
6. **Fonts** : bundler Nunito (référencé dans theme mais pas dans pubspec).
7. **Economy tuning** : calibrer les paliers `Surcharge/Resonance/Blackout` via analytics et Remote Config.

## Backlog

- Brancher RevenueCat (IAP packs vies, thèmes, passe saisonnier)
- Notifications de retour (24h/72h/7j/30j)
- Événements automatiques (daily, week-end, saisonnier, tournois)
- Leaderboard + système de parrainage
- Mode journalier (niveau aléatoire quotidien)
- Achievements / badges