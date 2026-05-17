import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/analytics.dart';
import '../../monetization/data/reward_inventory.dart';
import '../../monetization/data/rewarded_ad_service.dart';
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
  final RewardedAdService? rewardedAdService;

  const GameScreen({super.key, this.level, this.rewardedAdService});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final LumoraGame _game;
  late final GameState _gameState;
  late final RewardedAdService _rewardedAdService;
  late final RewardInventory _rewardInventory;
  late final LumoraAnalyticsService _analyticsService;
  bool _showVictory = false;
  bool _showDefeat = false;
  int _rewardedVideosUsed = 0;
  bool _isRewardedAdPending = false;
  ObjectiveRewardSummary _victoryRewardSummary = const ObjectiveRewardSummary();

  @override
  void initState() {
    super.initState();
    final level = widget.level ?? LevelCatalog.firstLevel;
    _gameState = GameState(level: level);
    _game = LumoraGame(levelData: level, gameState: _gameState);
    _rewardedAdService = widget.rewardedAdService ?? AdMobRewardedAdService.instance;
    _rewardInventory = RewardInventory.instance;
    _analyticsService = LumoraAnalyticsService.instance;
    _rewardInventory.addListener(_onInventoryChanged);

    unawaited(_rewardedAdService.initialize());
    unawaited(_rewardInventory.load());

    // Connecter les callbacks
    _game.onVictory = _onVictory;
    _game.onDefeat = _onDefeat;
    _game.onStateChanged = _onStateChanged;
  }

  void _onInventoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onVictory() {
    if (!mounted) return;
    final completedObjectives = _gameState.secondaryObjectives
        .where((objective) => _gameState.isSecondaryObjectiveCompleted(objective))
        .toList(growable: false);
    final rewardSummary = _rewardInventory.grantSecondaryObjectiveRewards(
      levelId: _gameState.level.id,
      completedObjectives: completedObjectives,
      totalObjectives: _gameState.secondaryObjectives.length,
    );
    unawaited(
      _analyticsService.logMasteryRewardGranted(
        levelId: _gameState.level.id,
        worldId: _gameState.level.worldId,
        totalObjectives: _gameState.secondaryObjectives.length,
        completedObjectives: completedObjectives.length,
        stars: _gameState.stars,
        score: _gameState.score,
        rewardEntries: rewardSummary.rewardEntries,
      ),
    );
    setState(() {
      _victoryRewardSummary = rewardSummary;
      _showVictory = true;
    });
  }

  void _onDefeat() {
    if (!mounted) return;
    setState(() {
      _showDefeat = true;
      _rewardedVideosUsed = 0;
    });
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
    if (_gameState.lives <= 0) {
      return;
    }

    final usesStoredHint = _rewardInventory.hintCharges > 0;
    final used = _game.useHint(consumeAttempt: !usesStoredHint);
    if (used && usesStoredHint) {
      _rewardInventory.consumeHintCharge();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Indice précis utilisé. Stock restant : ${_rewardInventory.hintCharges}.')),
      );
      return;
    }

    if (!used && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indice indisponible pour le moment.')),
      );
    }
  }

  void _onUseBankedLife() {
    if (!_rewardInventory.consumeBankedLife()) {
      return;
    }

    _gameState.grantLives(1);
    setState(() {
      _showDefeat = false;
    });
    _game.retryLevelPreservingLives();
    _game.startLevel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vie de réserve utilisée. Réserve restante : ${_rewardInventory.bankedLives}.')),
    );
  }

  void _onActivateDoubleScore() {
    if (!_rewardInventory.consumeDoubleScoreCharge()) {
      return;
    }
    _gameState.armDoubleScore();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Double Score activé. Charges restantes : ${_rewardInventory.doubleScoreCharges}.')),
    );
  }

  void _onActivateSuperFilament() {
    if (!_rewardInventory.consumeSuperFilamentCharge()) {
      return;
    }
    _gameState.armSuperFilament();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Super Filament armé. La prochaine erreur sera absorbée.')),
    );
  }

  void _onStartGame() {
    _game.startLevel();
  }

  void _onRestart() {
    if (_gameState.lives <= 0) {
      return;
    }

    setState(() {
      _showDefeat = false;
      _showVictory = false;
      _victoryRewardSummary = const ObjectiveRewardSummary();
    });
    _game.restartLevel();
    _game.startLevel();
  }

  Future<void> _onWatchRewardedVideo() async {
    if (_rewardedVideosUsed >= 2 || _isRewardedAdPending) {
      return;
    }

    final livesReward = _rewardedVideosUsed == 0 ? 1 : 2;

    setState(() => _isRewardedAdPending = true);

    final rewardEarned = await _rewardedAdService.showRewardedAd(
      placement: RewardedPlacement.defeatContinue,
      onRewardEarned: () {
        _gameState.grantLives(livesReward);
      },
    );

    if (!mounted) {
      return;
    }

    setState(() => _isRewardedAdPending = false);

    if (!rewardEarned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video indisponible pour le moment.')),
      );
      return;
    }

    setState(() {
      _rewardedVideosUsed++;
      _showDefeat = false;
    });

    _game.retryLevelPreservingLives();
    _game.startLevel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video terminee: +$livesReward vie(s)')),
    );
  }

  void _onNextLevel() {
    setState(() {
      _showVictory = false;
      _victoryRewardSummary = const ObjectiveRewardSummary();
    });
    final hasNextLevel = _game.loadNextLevel();
    if (hasNextLevel) {
      _game.startLevel();
      return;
    }

    if (mounted) {
      context.go('/world-map?completed=${_gameState.level.id}');
    }
  }

  @override
  void dispose() {
    _rewardInventory.removeListener(_onInventoryChanged);
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

          Positioned.fill(
            child: IgnorePointer(
              child: _GameplayAura(worldId: _gameState.level.worldId),
            ),
          ),

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
                  if (_rewardInventory.bankedLives > 0 ||
                      _rewardInventory.hintCharges > 0 ||
                      _rewardInventory.doubleScoreCharges > 0 ||
                      _rewardInventory.superFilamentCharges > 0 ||
                      _gameState.isDoubleScoreActive ||
                      _gameState.hasSuperFilament) ...[
                    const SizedBox(height: 10),
                    _GameplayInventoryBar(
                      inventory: _rewardInventory,
                      gameState: _gameState,
                      onActivateDoubleScore: _onActivateDoubleScore,
                      onActivateSuperFilament: _onActivateSuperFilament,
                    ),
                  ],
                  if (_gameState.secondaryObjectives.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _SecondaryObjectivesStrip(gameState: _gameState),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StageRuleChip(
                          icon: Icons.public_rounded,
                          label: _gameState.level.worldLabel,
                          accent: _worldAccent(_gameState.level.worldId),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StageRuleChip(
                          icon: Icons.auto_awesome_rounded,
                          label: _gameState.level.specialRuleLabel,
                          accent: _ruleAccent(_gameState.level.specialRule),
                          subtitle: _gameState.level.specialRuleDescription,
                        ),
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
              objectives: _gameState.secondaryObjectives
                  .map(
                    (objective) => VictoryObjectiveStatus(
                      label: objective.label,
                      description: objective.description,
                      completed: _gameState.isSecondaryObjectiveCompleted(objective),
                    ),
                  )
                  .toList(growable: false),
              rewardEntries: _victoryRewardSummary.rewardEntries,
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
                      Text(
                        'Vies restantes : ${_gameState.lives} • Coups : ${_gameState.attemptsRemaining}/${_gameState.attemptsPerLife}',
                        style: LumoraTextStyles.bodyMedium(),
                      ),
                      const SizedBox(height: 16),
                      if (_gameState.lives > 0)
                        LumoraButton(
                          onPressed: _onRestart,
                          text: 'Réessayer',
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          gradientColors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
                          elevation: 8,
                        ),
                      if (_gameState.lives <= 0) ...[
                        if (_rewardInventory.bankedLives > 0) ...[
                          LumoraButton(
                            onPressed: _onUseBankedLife,
                            text: 'Utiliser 1 vie en réserve',
                            icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                            gradientColors: [LumoraColors.lifeCoral, LumoraColors.lifeRose],
                            elevation: 8,
                          ),
                          const SizedBox(height: 10),
                        ],
                        LumoraButton(
                          onPressed: _rewardedVideosUsed < 2 && !_isRewardedAdPending
                            ? _onWatchRewardedVideo
                            : null,
                          text: _isRewardedAdPending
                            ? 'Chargement video...'
                            : _rewardedVideosUsed == 0
                              ? 'Video récompensée (+1 vie)'
                              : (_rewardedVideosUsed == 1
                                  ? 'Video récompensée (+2 vies)'
                                  : 'Videos déjà utilisées'),
                          icon: const Icon(Icons.ondemand_video_rounded, color: Colors.white),
                          gradientColors: [LumoraColors.auroraOrange, LumoraColors.energyAmber],
                          elevation: 8,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Règle: 1ere video = +1 vie, 2eme video = +2 vies (max 3).',
                          style: LumoraTextStyles.bodyMedium(),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 14),
                      LumoraButton(
                        onPressed: () => context.go('/world-map?completed=${_gameState.level.id}'),
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

class _GameplayInventoryBar extends StatelessWidget {
  final RewardInventory inventory;
  final GameState gameState;
  final VoidCallback onActivateDoubleScore;
  final VoidCallback onActivateSuperFilament;

  const _GameplayInventoryBar({
    required this.inventory,
    required this.gameState,
    required this.onActivateDoubleScore,
    required this.onActivateSuperFilament,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (inventory.bankedLives > 0)
            _GameplayInventoryPill(
              icon: Icons.favorite_rounded,
              label: 'Réserve ${inventory.bankedLives}',
              accent: LumoraColors.lifeCoral,
            ),
          if (inventory.hintCharges > 0)
            _GameplayInventoryPill(
              icon: Icons.lightbulb_rounded,
              label: 'Indices ${inventory.hintCharges}',
              accent: LumoraColors.energyAmber,
            ),
          if (inventory.doubleScoreCharges > 0 || gameState.isDoubleScoreActive)
            _GameplayInventoryPill(
              icon: Icons.bolt_rounded,
              label: gameState.isDoubleScoreActive
                  ? 'Double Score actif'
                  : 'Double x${inventory.doubleScoreCharges}',
              accent: LumoraColors.auroraGold,
              onTap: gameState.isDoubleScoreActive ? null : onActivateDoubleScore,
            ),
          if (inventory.superFilamentCharges > 0 || gameState.hasSuperFilament)
            _GameplayInventoryPill(
              icon: Icons.polyline_rounded,
              label: gameState.hasSuperFilament
                  ? 'Filament armé'
                  : 'Super Filament x${inventory.superFilamentCharges}',
              accent: LumoraColors.auroraBlue,
              onTap: gameState.hasSuperFilament ? null : onActivateSuperFilament,
            ),
        ],
      ),
    );
  }
}

class _GameplayInventoryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  const _GameplayInventoryPill({
    required this.icon,
    required this.label,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.9 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LumoraRadii.bubble),
            gradient: LinearGradient(
              colors: [accent.withAlpha(42), LumoraColors.deepSpace.withAlpha(150)],
            ),
            border: Border.all(color: accent.withAlpha(90)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: LumoraTextStyles.label(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryObjectivesStrip extends StatelessWidget {
  final GameState gameState;

  const _SecondaryObjectivesStrip({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: gameState.secondaryObjectives.map((objective) {
            final completed = gameState.isSecondaryObjectiveCompleted(objective);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ObjectivePill(
                label: objective.label,
                completed: completed,
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _ObjectivePill extends StatelessWidget {
  final String label;
  final bool completed;

  const _ObjectivePill({required this.label, required this.completed});

  @override
  Widget build(BuildContext context) {
    final accent = completed ? LumoraColors.auroraGreen : LumoraColors.auroraPurple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        color: accent.withAlpha(28),
        border: Border.all(color: accent.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_rounded : Icons.flag_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(label, style: LumoraTextStyles.label(color: Colors.white)),
        ],
      ),
    );
  }
}

Color _ruleAccent(LevelSpecialRule rule) {
  switch (rule) {
    case LevelSpecialRule.standard:
      return LumoraColors.auroraBlue;
    case LevelSpecialRule.overload:
      return LumoraColors.lifeCoral;
    case LevelSpecialRule.resonance:
      return LumoraColors.auroraGold;
    case LevelSpecialRule.blackout:
      return LumoraColors.auroraPurple;
  }
}

Color _worldAccent(int worldId) {
  switch (worldId % 5) {
    case 1:
      return LumoraColors.auroraBlue;
    case 2:
      return LumoraColors.auroraPink;
    case 3:
      return LumoraColors.auroraOrange;
    case 4:
      return LumoraColors.auroraPurple;
    default:
      return LumoraColors.auroraGreen;
  }
}

class _StageRuleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final String? subtitle;

  const _StageRuleChip({
    required this.icon,
    required this.label,
    required this.accent,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.chip),
        gradient: LinearGradient(
          colors: [
            accent.withAlpha(70),
            LumoraColors.deepSpace.withAlpha(150),
          ],
        ),
        border: Border.all(color: accent.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(35),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withAlpha(45),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LumoraTextStyles.bodyLarge(color: Colors.white),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: LumoraTextStyles.label(color: LumoraColors.softMist),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameplayAura extends StatelessWidget {
  const _GameplayAura({required this.worldId});

  final int worldId;

  @override
  Widget build(BuildContext context) {
    final colors = switch (worldId) {
      1 => [LumoraColors.auroraBlue, LumoraColors.auroraPurple],
      2 => [LumoraColors.auroraPurple, LumoraColors.auroraPink],
      3 => [LumoraColors.auroraBlue, LumoraColors.auroraGold],
      _ => [LumoraColors.auroraGreen, LumoraColors.auroraGold],
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.08),
      duration: const Duration(milliseconds: 2800),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.75, -0.9),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [colors.first.withAlpha(80), Colors.transparent],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.9, 0.2),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [colors.last.withAlpha(70), Colors.transparent],
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