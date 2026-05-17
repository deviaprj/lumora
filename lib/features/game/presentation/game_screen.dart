import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';
import '../domain/level_data.dart';
import '../engine/game_state.dart';
import '../engine/lumora_game.dart';
import 'victory_overlay.dart';

/// Écran de jeu — Stack avec GameWidget(LumoraGame) + overlay UI organique.
///
/// UI : niveau (bulle), vies (cœurs flottants), timer (cercle organique),
/// pause (bulle), indice (ampoule organique), score.
/// Gameplay : tap nœuds, swipe filaments, drag lumie, pinch zoom.
class GameScreen extends StatefulWidget {
  final LevelData? level;

  const GameScreen({super.key, this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final LumoraGame _game;
  late final GameState _gameState;
  bool _showVictory = false;
  bool _showDefeat = false;

  @override
  void initState() {
    super.initState();
    final level = widget.level ?? World1Levels.levels.first;
    _gameState = GameState(level: level);
    _game = LumoraGame(levelData: level, gameState: _gameState);

    // Connecter les callbacks
    _game.onVictory = _onVictory;
    _game.onDefeat = _onDefeat;
    _game.onStateChanged = _onStateChanged;
  }

  void _onVictory() {
    if (!mounted) return;
    setState(() => _showVictory = true);
  }

  void _onDefeat() {
    if (!mounted) return;
    setState(() => _showDefeat = true);
  }

  void _onStateChanged(GameState state) {
    if (!mounted) return;
    setState(() {});
  }

  void _onPause() {
    _game.pauseGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseOverlay(
        onResume: () {
          _game.resumeGame();
          Navigator.of(context).pop();
        },
        onSettings: () {
          Navigator.of(context).pop();
          context.go('/settings');
        },
        onQuit: () {
          Navigator.of(context).pop();
          context.go('/world-map');
        },
      ),
    );
  }

  void _onHint() {
    if (_gameState.lives > 0) {
      _game.useHint();
    }
  }

  void _onStartGame() {
    _game.startLevel();
  }

  void _onRestart() {
    setState(() {
      _showDefeat = false;
      _showVictory = false;
    });
    _game.restartLevel();
    _game.startLevel();
  }

  void _onNextLevel() {
    setState(() => _showVictory = false);
    _game.loadNextLevel();
    _game.startLevel();
  }

  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Couche jeu Flame
          GameWidget(game: _game),

          // Overlay UI organique
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Niveau
                      _LevelBubble(level: _gameState.level.id),
                      const SizedBox(width: 8),
                      // Score
                      _ScoreBadge(score: _gameState.score),
                      const Spacer(),
                      // Vies + Coups
                      _LivesAndAttempts(
                        lives: _gameState.lives,
                        maxLives: _gameState.maxLives,
                        attemptsRemaining: _gameState.attemptsRemaining,
                        attemptsPerLife: _gameState.attemptsPerLife,
                      ),
                      const SizedBox(width: 8),
                      // Timer
                      _OrganicTimer(
                        remaining: _gameState.timeRemaining,
                        max: _gameState.maxTime,
                      ),
                      const SizedBox(width: 8),
                      // Pause
                      LumoraButton(
                        onPressed: _onPause,
                        icon: const Icon(Icons.pause_rounded, color: Colors.white, size: 20),
                        gradientColors: [LumoraColors.midnight, LumoraColors.twilight],
                        size: 40,
                        elevation: 4,
                      ),
                      const SizedBox(width: 8),
                      // Indice
                      LumoraButton(
                        onPressed: _gameState.status == GameStatus.playing ? _onHint : null,
                        icon: Icon(
                          Icons.lightbulb_rounded,
                          color: _gameState.status == GameStatus.playing
                              ? Colors.white
                              : LumoraColors.disabledMist,
                          size: 20,
                        ),
                        gradientColors: _gameState.status == GameStatus.playing
                            ? [LumoraColors.energyAmber, LumoraColors.auroraGold]
                            : [LumoraColors.midnight, LumoraColors.dawn],
                        size: 40,
                        elevation: 4,
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Bouton démarrer (affiché au début du niveau)
          if (_gameState.status == GameStatus.idle)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LumoraColors.auroraBlue.withAlpha(40),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: LumoraButton(
                  onPressed: _onStartGame,
                  text: 'Commencer',
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  gradientColors: [LumoraColors.twilight, LumoraColors.auroraBlue],
                  elevation: 10,
                ),
              ),
            ),

          // Debug victoire (kDebugMode seulement)
          if (kDebugMode && !_showVictory && !_showDefeat)
            Positioned(
              bottom: 16,
              left: 16,
              child: LumoraButton(
                onPressed: _onVictory,
                text: 'Debug Victoire',
                gradientColors: [LumoraColors.midnight, LumoraColors.deepSpace],
                elevation: 2,
              ),
            ),

          // Overlay victoire
          if (_showVictory)
            VictoryOverlay(
              stars: _gameState.stars,
              score: _gameState.score,
              onNextLevel: _onNextLevel,
              onShare: () {
                // TODO: capture + share overlay
              },
              onMenu: () => context.go('/world-map'),
            ),

          // Overlay défaite
          if (_showDefeat)
            Container(
              color: const Color(0xCC000000),
              child: Center(
                child: LumoraCard(
                  padding: const EdgeInsets.all(32),
                  borderRadius: LumoraRadii.modal,
                  shadows: [LumoraShadows.glow(color: LumoraColors.errorRose)],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Monde assombri...', style: LumoraTextStyles.displayMedium()),
                      const SizedBox(height: 8),
                      Text(
                        'Score : ${_gameState.score}',
                        style: LumoraTextStyles.bodyLarge(),
                      ),
                      const SizedBox(height: 24),
                      LumoraButton(
                        onPressed: _onRestart,
                        text: 'Réessayer',
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
                        elevation: 8,
                      ),
                      const SizedBox(height: 14),
                      LumoraButton(
                        onPressed: () => context.go('/world-map'),
                        text: 'Carte des mondes',
                        icon: const Icon(Icons.map_rounded, color: Colors.white70),
                        gradientColors: [LumoraColors.midnight, LumoraColors.deepSpace],
                        elevation: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bulle organique affichant le numéro de niveau.
class _LevelBubble extends StatelessWidget {
  final int level;
  const _LevelBubble({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        gradient: LumoraGradients.primaryBubble,
        boxShadow: [LumoraShadows.soft()],
      ),
      child: Text(
        'Niv. $level',
        style: LumoraTextStyles.label(color: LumoraColors.pearl),
      ),
    );
  }
}

/// Badge de score.
class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.chip),
        gradient: LumoraGradients.secondaryBubble,
        boxShadow: [LumoraShadows.innerGlow()],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: LumoraColors.auroraGold, size: 16),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: LumoraTextStyles.label(color: LumoraColors.pearl),
          ),
        ],
      ),
    );
  }
}

/// Vies (cœurs) + coups restants pour la vie en cours.
class _LivesAndAttempts extends StatelessWidget {
  final int lives;
  final int maxLives;
  final int attemptsRemaining;
  final int attemptsPerLife;
  const _LivesAndAttempts({
    required this.lives,
    required this.maxLives,
    required this.attemptsRemaining,
    required this.attemptsPerLife,
  });

  @override
  Widget build(BuildContext context) {
    final attemptColor = attemptsRemaining > 2
        ? LumoraColors.auroraGreen
        : (attemptsRemaining > 1
            ? LumoraColors.waitOrange
            : LumoraColors.errorRose);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cœurs pour les vies
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxLives, (index) {
            final active = index < lives;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                transform: Matrix4.identity()..scale(active ? 1.0 : 0.7),
                child: Icon(
                  active
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      active ? LumoraColors.lifeCoral : LumoraColors.disabledMist,
                  size: 18,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        // Compteur de coups restants
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LumoraRadii.chip),
            color: attemptColor.withAlpha(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, color: attemptColor, size: 12),
              const SizedBox(width: 3),
              Text(
                '$attemptsRemaining/$attemptsPerLife',
                style: LumoraTextStyles.label(color: attemptColor).copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Timer organique — cercle avec remplissage progressif.
class _OrganicTimer extends StatelessWidget {
  final double remaining;
  final double max;
  const _OrganicTimer({required this.remaining, required this.max});

  @override
  Widget build(BuildContext context) {
    final progress = (remaining / max).clamp(0.0, 1.0);
    final color = progress > 0.5
        ? LumoraColors.auroraGreen
        : (progress > 0.25 ? LumoraColors.waitOrange : LumoraColors.errorRose);

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 4,
            backgroundColor: LumoraColors.disabledMist,
            valueColor: AlwaysStoppedAnimation<Color>(LumoraColors.disabledMist),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Center(
            child: Text(
              '${remaining.ceil()}',
              style: LumoraTextStyles.label(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay de pause — modale glassmorphism avec cercles flottants.
class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onSettings;
  final VoidCallback onQuit;

  const _PauseOverlay({
    required this.onResume,
    required this.onSettings,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LumoraCard(
        backgroundColor: const Color(0x88000000),
        borderColor: const Color(0x44FFFFFF),
        borderRadius: LumoraRadii.modal,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pause', style: LumoraTextStyles.titleLarge()),
            const SizedBox(height: 20),
            LumoraButton(
              onPressed: onResume,
              text: 'Reprendre',
              gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
            ),
            const SizedBox(height: 12),
            LumoraButton(
              onPressed: onSettings,
              text: 'Paramètres',
              gradientColors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
            ),
            const SizedBox(height: 12),
            LumoraButton(
              onPressed: onQuit,
              text: 'Quitter',
              gradientColors: [LumoraColors.midnight, LumoraColors.deepSpace],
              elevation: 2,
            ),
          ],
        ),
      ),
    );
  }
}