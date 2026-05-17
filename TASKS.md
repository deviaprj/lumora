# Tâches — Lumora Mobile

## Complété (session 2026-05-11 — gameplay fixes)

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

1. **Mettre à jour les tests unitaires** : game_state_test.dart et game_interaction_test.dart doivent refléter le nouveau système lives/attempts (attemptsPerLife, attemptsRemaining).
2. **Overlay défaite enrichi** : Afficher les tentatives restantes et info coups dans l'overlay de défaite GameScreen.
3. **Assets parallax PNG** : Remplacer le fond procédural par de vrais assets PNG quand disponibles.
4. **Firebase Auth** : Brancher l'authentification (Google/Apple/Email/Anonymous).
5. **Progression persistante** : Sauvegarder le completedLevelId en SharedPreferences pour que la World Map reflète la progression.
6. **Stabiliser tests device** : Relancer les 15 tests integration + ajouter tests lives/attempts.
7. **Fonts** : Bundler Nunito (référencé dans theme mais pas dans pubspec).
8. **World 2+ niveaux** : Ajouter des niveaux pour les mondes suivants avec difficulté croissante.

## Backlog

- Brancher RevenueCat (IAP packs vies, thèmes, passe saisonnier)
- Notifications de retour (24h/72h/7j/30j)
- Événements automatiques (daily, week-end, saisonnier, tournois)
- Leaderboard + système de parrainage
- Mode journalier (niveau aléatoire quotidien)
- Achievements / badges