import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../core/utils/haptics.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';
import '../data/crystal_progression_service.dart';
import '../domain/crystal_board.dart';
import '../domain/crystal_models.dart';
import '../domain/crystal_run.dart';

/// Écran du mode « Cristaux de couleur ».
///
/// Une boucle courte et contemplative : sélectionner un cristal, toucher un
/// voisin de même couleur, faire grandir la série. La difficulté monte par
/// paliers et la progression est conservée d'une session à l'autre.
class CrystalScreen extends StatefulWidget {
  const CrystalScreen({
    super.key,
    this.level,
    this.boardBuilder,
  });

  /// Palier à jouer. Sans valeur, le dernier palier débloqué est utilisé.
  final int? level;

  /// Fabrique de plateau injectable pour les tests.
  final CrystalBoard Function(CrystalLevelConfig config)? boardBuilder;

  @override
  State<CrystalScreen> createState() => _CrystalScreenState();
}

class _CrystalScreenState extends State<CrystalScreen>
    with TickerProviderStateMixin {
  final CrystalProgressionService _progression =
      CrystalProgressionService.instance;

  late final AnimationController _ambientController;
  late final AnimationController _burstController;

  late CrystalRun _run;
  bool _runInitialized = false;
  bool _hasInteracted = false;
  CrystalRunStatus _lastStatus = CrystalRunStatus.playing;
  CrystalProgressionSummary? _summary;
  List<_BurstParticle> _burstParticles = const <_BurstParticle>[];

  @override
  void initState() {
    super.initState();
    _configureRun(widget.level ?? _progression.highestUnlockedLevel);

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // L'audio peut être indisponible (tests, plateforme sans plugin).
    unawaited(SoundManager().init().catchError((Object _) {}));
    unawaited(_loadProgression());
  }

  @override
  void dispose() {
    _run.removeListener(_onRunChanged);
    _ambientController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  Future<void> _loadProgression() async {
    try {
      await _progression.load();
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    if (!_hasInteracted &&
        widget.level == null &&
        _run.config.level != _progression.highestUnlockedLevel) {
      _configureRun(_progression.highestUnlockedLevel);
    }
    setState(() {});
  }

  void _configureRun(int level) {
    final config = CrystalLevelConfig.forLevel(level);
    final nextRun = CrystalRun(
      config: config,
      board: widget.boardBuilder?.call(config),
    );

    if (_runInitialized) {
      _run.removeListener(_onRunChanged);
    }
    _run = nextRun;
    _runInitialized = true;
    _run.addListener(_onRunChanged);
    _lastStatus = nextRun.status;
    _hasInteracted = false;
    _summary = null;
    _burstParticles = const <_BurstParticle>[];
  }

  void _onRunChanged() {
    if (!mounted) {
      return;
    }
    final status = _run.status;
    if (status != _lastStatus) {
      _lastStatus = status;
      if (status == CrystalRunStatus.victory) {
        _handleVictory();
      } else if (status == CrystalRunStatus.defeat) {
        _handleDefeat();
      }
    }
    setState(() {});
  }

  void _handleVictory() {
    unawaited(SoundManager().playVictorySound());
    unawaited(LumoraHaptics.victory());
    unawaited(_recordRun(victory: true));
  }

  void _handleDefeat() {
    unawaited(SoundManager().playDefeatSound());
    unawaited(LumoraHaptics.defeat());
    unawaited(_recordRun(victory: false));
  }

  Future<void> _recordRun({required bool victory}) async {
    try {
      final summary = await _progression.recordRun(
        level: _run.config.level,
        score: _run.score,
        crystalsCleared: _run.crystalsCleared,
        victory: victory,
      );
      if (!mounted) {
        return;
      }
      setState(() => _summary = summary);
    } catch (_) {
      // La partie reste jouable même si la sauvegarde locale échoue.
    }
  }

  void _onGemTap(int row, int col) {
    _hasInteracted = true;
    final color = _run.board.cellAt(row, col);
    final action = _run.select(row, col);

    switch (action) {
      case CrystalAction.selected:
      case CrystalAction.moved:
        if (color != null) {
          unawaited(SoundManager().playNodeNote(color.soundKey));
        }
        unawaited(LumoraHaptics.nodeTap());
        break;
      case CrystalAction.cleared:
        final clearedColor = _run.lastColor;
        if (clearedColor != null) {
          _spawnBurst(_run.lastCleared, clearedColor);
        }
        unawaited(SoundManager().playConnectionSound());
        if (_run.streak >= 3) {
          unawaited(SoundManager().playComboSound(_run.streak));
          unawaited(LumoraHaptics.combo());
        } else {
          unawaited(LumoraHaptics.connectionValid());
        }
        break;
      case CrystalAction.invalid:
        unawaited(SoundManager().playErrorSound());
        unawaited(LumoraHaptics.connectionError());
        break;
      case CrystalAction.deselected:
        unawaited(LumoraHaptics.buttonPress());
        break;
      case CrystalAction.none:
      case CrystalAction.ignored:
        break;
    }
  }

  void _spawnBurst(
    List<CrystalPosition> positions,
    CrystalColor color,
  ) {
    final particles = <_BurstParticle>[];
    for (final position in positions.take(24)) {
      for (var index = 0; index < 5; index++) {
        final angle = (index / 5) * math.pi * 2 + position.row * 0.6;
        particles.add(
          _BurstParticle(
            origin: Offset(
              (position.col + 0.5) / _run.board.cols,
              (position.row + 0.5) / _run.board.rows,
            ),
            angle: angle,
            speed: 0.08 + (index % 3) * 0.035,
            size: 2.0 + (index % 2) * 1.6,
            color: color.color,
          ),
        );
      }
    }
    setState(() => _burstParticles = particles);
    _burstController.forward(from: 0);
  }

  void _retry() {
    _summary = null;
    _burstParticles = const <_BurstParticle>[];
    _run.retry(board: widget.boardBuilder?.call(_run.config));
    _lastStatus = _run.status;
    if (mounted) {
      setState(() {});
    }
  }

  void _goToNextLevel() {
    _configureRun(_run.config.level + 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final run = _run;
    final showOverlay = run.status != CrystalRunStatus.playing;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LumoraGradients.homeBg),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Column(
                  children: [
                    _buildTopBar(run),
                    const SizedBox(height: 12),
                    _buildScoreCard(run),
                    const SizedBox(height: 10),
                    _buildStreakRow(run),
                    const SizedBox(height: 6),
                    Expanded(child: Center(child: _buildBoard(run))),
                    const SizedBox(height: 6),
                    _buildInstruction(run),
                  ],
                ),
              ),
            ),
            if (showOverlay) Positioned.fill(child: _buildOverlay(run)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(CrystalRun run) {
    return Row(
      children: [
        LumoraButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
          size: 44,
          gradientColors: const [
            LumoraColors.midnight,
            LumoraColors.twilight,
          ],
          elevation: 3,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LumoraCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: LumoraColors.auroraGreen,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cristaux de couleur',
                        style: LumoraTextStyles.bodyLarge(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Niv. ${run.config.level} · ${run.config.rows}×${run.config.cols}',
                        style: LumoraTextStyles.label(
                          color: LumoraColors.softMist,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _DailyStreakChip(streak: _progression.dailyStreak),
      ],
    );
  }

  Widget _buildScoreCard(CrystalRun run) {
    return LumoraCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          _MetricBubble(
            value: '${run.score}',
            label: 'Éclats',
            color: LumoraColors.auroraGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Objectif',
                      style: LumoraTextStyles.label(
                        color: LumoraColors.softMist,
                      ),
                    ),
                    Text(
                      '${run.config.targetScore}',
                      style: LumoraTextStyles.label(
                        color: LumoraColors.pearl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _GlowProgressBar(value: run.progress),
                const SizedBox(height: 6),
                Text(
                  run.status == CrystalRunStatus.victory
                      ? 'Objectif atteint'
                      : '${run.crystalsCleared} cristaux libérés',
                  style: LumoraTextStyles.label(
                    color: LumoraColors.softMist.withAlpha(190),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MetricBubble(
            value: '${run.movesRemaining}',
            label: 'Gestes',
            color: LumoraColors.auroraBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRow(CrystalRun run) {
    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            key: ValueKey<int>(run.streak),
            tween: Tween<double>(begin: 0.94, end: 1.0),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: LumoraCard(
              borderRadius: LumoraRadii.chip,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    run.streak > 0
                        ? Icons.local_fire_department_rounded
                        : Icons.auto_awesome_rounded,
                    color: run.streak > 0
                        ? LumoraColors.auroraGold
                        : LumoraColors.softMist,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _streakMessage(run),
                      style: LumoraTextStyles.bodyMedium(
                        color: LumoraColors.pearl,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (run.streak > 0)
                    Text(
                      'x${run.streakMultiplier.toStringAsFixed(1)}',
                      style: LumoraTextStyles.titleLarge(
                        color: LumoraColors.auroraGold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        LumoraButton(
          onPressed: _retry,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 20,
          ),
          size: 44,
          gradientColors: const [
            LumoraColors.midnight,
            LumoraColors.twilight,
          ],
          elevation: 3,
        ),
      ],
    );
  }

  String _streakMessage(CrystalRun run) {
    if (run.streak == 0) {
      return 'Relie deux voisins identiques';
    }
    if (run.streak == 1) {
      return 'Série lancée, continue';
    }
    return 'Série de ${run.streak} dissolutions';
  }

  Widget _buildBoard(CrystalRun run) {
    final board = run.board;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          final cellWidth = side / board.cols;
          final cellHeight = side / board.rows;

          return SizedBox(
            width: side,
            height: side,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoardHaloPainter(
                      breathe: _ambientController,
                      selected: run.selected != null,
                    ),
                  ),
                ),
                for (var row = 0; row < board.rows; row++)
                  for (var col = 0; col < board.cols; col++)
                    if (board.cellAt(row, col) != null)
                      Positioned(
                        left: col * cellWidth,
                        top: row * cellHeight,
                        width: cellWidth,
                        height: cellHeight,
                        // La case entière reste tactile, même sur un grand
                        // plateau : le cristal dessiné garde son air intérieur.
                        child: _CrystalGem(
                          key: ValueKey<String>('crystal-gem-$row-$col'),
                          color: board.cellAt(row, col)!,
                          selected: run.selected?.row == row &&
                              run.selected?.col == col,
                          breathe: _ambientController,
                          phase: (row + col) * 0.55,
                          onTap: () => _onGemTap(row, col),
                        ),
                      ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _burstController,
                      builder: (context, _) => CustomPaint(
                        painter: _BurstPainter(
                          progress: _burstController.value,
                          particles: _burstParticles,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstruction(CrystalRun run) {
    final selected = run.selected;
    final color =
        selected == null ? null : run.board.cellAt(selected.row, selected.col);
    final message = color == null
        ? 'Touche un cristal, puis un voisin de la même couleur.'
        : 'Choisis un voisin ${color.label.toLowerCase()} pour libérer sa lumière.';

    return Text(
      message,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: LumoraTextStyles.label(
        color: LumoraColors.softMist.withAlpha(200),
      ),
    );
  }

  Widget _buildOverlay(CrystalRun run) {
    final victory = run.status == CrystalRunStatus.victory;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LumoraColors.deepSpace.withAlpha(230),
            LumoraColors.midnight.withAlpha(242),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: LumoraCard(
              key: ValueKey<String>(
                victory ? 'crystal-victory-overlay' : 'crystal-defeat-overlay',
              ),
              enableBlur: true,
              padding: const EdgeInsets.all(24),
              borderRadius: LumoraRadii.modal,
              shadows: [
                LumoraShadows.glow(
                  color: victory
                      ? LumoraColors.auroraGold
                      : LumoraColors.auroraPurple,
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: victory
                    ? _buildVictoryContent(run)
                    : _buildDefeatContent(run),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVictoryContent(CrystalRun run) {
    final summary = _summary;
    return [
      const _OverlayIcon(
        icon: Icons.auto_awesome_rounded,
        colors: [LumoraColors.auroraGold, LumoraColors.auroraOrange],
      ),
      const SizedBox(height: 18),
      Text(
        'Le prisme s\'illumine',
        textAlign: TextAlign.center,
        style: LumoraTextStyles.titleLarge(),
      ),
      const SizedBox(height: 6),
      Text(
        'Palier ${run.config.level} terminé',
        textAlign: TextAlign.center,
        style: LumoraTextStyles.bodyMedium(
          color: LumoraColors.softMist,
        ),
      ),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(3, (index) {
          final earned = index < run.stars;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              earned ? Icons.star_rounded : Icons.star_border_rounded,
              color: earned
                  ? LumoraColors.auroraGold
                  : LumoraColors.softMist.withAlpha(120),
              size: 34,
            ),
          );
        }),
      ),
      const SizedBox(height: 16),
      _SummaryRow(
        label: 'Score',
        value: '${run.score}',
        color: LumoraColors.auroraGold,
      ),
      const SizedBox(height: 8),
      _SummaryRow(
        label: 'Cristaux libérés',
        value: '${run.crystalsCleared}',
        color: LumoraColors.auroraGreen,
      ),
      const SizedBox(height: 8),
      _SummaryRow(
        label: 'Meilleure série',
        value: '${run.bestStreak}',
        color: LumoraColors.auroraBlue,
      ),
      if (summary != null) ...[
        const SizedBox(height: 8),
        _SummaryRow(
          label: 'Série de jours',
          value: '${summary.dailyStreak}',
          color: LumoraColors.auroraOrange,
        ),
      ],
      if (summary?.levelUnlocked == true) ...[
        const SizedBox(height: 14),
        Text(
          'Palier ${summary!.highestUnlockedLevel} débloqué',
          textAlign: TextAlign.center,
          style: LumoraTextStyles.bodyMedium(
            color: LumoraColors.auroraGreen,
          ),
        ),
      ] else if (summary?.newBestScore == true) ...[
        const SizedBox(height: 14),
        Text(
          'Nouveau meilleur score',
          textAlign: TextAlign.center,
          style: LumoraTextStyles.bodyMedium(
            color: LumoraColors.auroraGold,
          ),
        ),
      ],
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: LumoraButton(
          onPressed: _goToNextLevel,
          text: 'Palier suivant',
          icon: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 22,
          ),
          gradientColors: const [
            LumoraColors.auroraGreen,
            LumoraColors.auroraBlue,
          ],
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: LumoraButton(
          onPressed: _retry,
          text: 'Rejouer',
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 20,
          ),
          gradientColors: const [
            LumoraColors.twilight,
            LumoraColors.auroraPurple,
          ],
        ),
      ),
      const SizedBox(height: 10),
      const _BackToHomeButton(),
    ];
  }

  List<Widget> _buildDefeatContent(CrystalRun run) {
    return [
      const _OverlayIcon(
        icon: Icons.wb_twilight_rounded,
        colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
      ),
      const SizedBox(height: 18),
      Text(
        'La lumière s\'apaise',
        textAlign: TextAlign.center,
        style: LumoraTextStyles.titleLarge(),
      ),
      const SizedBox(height: 6),
      Text(
        'Les gestes sont épuisés, mais les cristaux t\'attendent.',
        textAlign: TextAlign.center,
        style: LumoraTextStyles.bodyMedium(
          color: LumoraColors.softMist,
        ),
      ),
      const SizedBox(height: 16),
      _SummaryRow(
        label: 'Score',
        value: '${run.score}',
        color: LumoraColors.auroraGold,
      ),
      const SizedBox(height: 8),
      _SummaryRow(
        label: 'Cristaux libérés',
        value: '${run.crystalsCleared}',
        color: LumoraColors.auroraGreen,
      ),
      const SizedBox(height: 8),
      _SummaryRow(
        label: 'Meilleure série',
        value: '${run.bestStreak}',
        color: LumoraColors.auroraBlue,
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: LumoraButton(
          onPressed: _retry,
          text: 'Réessayer',
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 20,
          ),
          gradientColors: const [
            LumoraColors.auroraGreen,
            LumoraColors.auroraBlue,
          ],
        ),
      ),
      const SizedBox(height: 10),
      const _BackToHomeButton(),
    ];
  }
}

class _BackToHomeButton extends StatelessWidget {
  const _BackToHomeButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LumoraButton(
        onPressed: () => context.go('/home'),
        text: 'Retour à l\'accueil',
        icon: const Icon(
          Icons.home_rounded,
          color: Colors.white,
          size: 20,
        ),
        gradientColors: const [
          LumoraColors.midnight,
          LumoraColors.twilight,
        ],
      ),
    );
  }
}

class _DailyStreakChip extends StatelessWidget {
  const _DailyStreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Série de $streak jours',
      child: LumoraCard(
        borderRadius: LumoraRadii.chip,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        shadows: [LumoraShadows.glow(color: LumoraColors.auroraOrange)],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: LumoraColors.auroraOrange,
              size: 19,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: LumoraTextStyles.bodyLarge(color: LumoraColors.pearl),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBubble extends StatelessWidget {
  const _MetricBubble({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      width: 64,
      borderRadius: LumoraRadii.chip,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      shadows: [LumoraShadows.soft(color: color)],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: LumoraTextStyles.titleLarge(color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: LumoraTextStyles.label(color: LumoraColors.softMist),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: LumoraTextStyles.bodyMedium(
              color: LumoraColors.softMist,
            ),
          ),
        ),
        Text(
          value,
          style: LumoraTextStyles.titleLarge(color: color),
        ),
      ],
    );
  }
}

class _OverlayIcon extends StatelessWidget {
  const _OverlayIcon({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [LumoraShadows.glow(color: colors.last)],
      ),
      child: Icon(icon, color: Colors.white, size: 38),
    );
  }
}

class _GlowProgressBar extends StatelessWidget {
  const _GlowProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(LumoraRadii.bubble),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withAlpha(24),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: animatedValue,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
                        gradient: const LinearGradient(
                          colors: [
                            LumoraColors.auroraGreen,
                            LumoraColors.auroraGold,
                          ],
                        ),
                        boxShadow: [
                          LumoraShadows.glow(
                            color: LumoraColors.auroraGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CrystalGem extends StatelessWidget {
  const _CrystalGem({
    super.key,
    required this.color,
    required this.selected,
    required this.breathe,
    required this.phase,
    required this.onTap,
  });

  final CrystalColor color;
  final bool selected;
  final Animation<double> breathe;
  final double phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Cristal ${color.label}',
      hint: selected
          ? 'Touche à nouveau pour annuler'
          : 'Touche, puis choisis un voisin de la même couleur',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: CustomPaint(
            painter: _GemPainter(
              color: color,
              selected: selected,
              breathe: breathe,
              phase: phase,
            ),
          ),
        ),
      ),
    );
  }
}

class _GemPainter extends CustomPainter {
  _GemPainter({
    required this.color,
    required this.selected,
    required this.breathe,
    required this.phase,
  }) : super(repaint: breathe);

  final CrystalColor color;
  final bool selected;
  final Animation<double> breathe;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.36;
    final pulse = 0.5 + 0.5 * math.sin(breathe.value * math.pi * 2 + phase);
    final glowRadius = radius * (selected ? 1.95 : 1.5) + pulse * 2;

    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.color.withAlpha(selected ? 150 : 95),
            color.color.withAlpha(24),
            Colors.transparent,
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );

    if (selected) {
      canvas.drawCircle(
        center,
        radius * 1.28,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withAlpha(190),
      );
    }

    final gemRect = Rect.fromCircle(center: center, radius: radius);
    final shape = _shapePath(color.shape, gemRect);

    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color.color, Colors.white, 0.62)!,
            color.color,
            Color.lerp(color.color, Colors.black, 0.34)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(gemRect),
    );

    final facet = _shapePath(color.shape, gemRect.deflate(radius * 0.28));
    canvas.drawPath(
      facet,
      Paint()..color = Colors.white.withAlpha(34),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withAlpha(86),
    );

    canvas.drawCircle(
      center + Offset(-radius * 0.3, -radius * 0.32),
      radius * 0.17,
      Paint()..color = Colors.white.withAlpha(190),
    );
    canvas.drawCircle(
      center + Offset(radius * 0.2, radius * 0.24),
      radius * 0.09,
      Paint()..color = Colors.white.withAlpha(90),
    );
  }

  static Path _shapePath(CrystalShape shape, Rect rect) {
    final center = rect.center;
    final rx = rect.width / 2;
    final ry = rect.height / 2;

    switch (shape) {
      case CrystalShape.round:
        return Path()..addOval(rect);
      case CrystalShape.oval:
        return Path()
          ..addOval(
            Rect.fromCenter(
              center: center,
              width: rect.width * 0.84,
              height: rect.height,
            ),
          );
      case CrystalShape.diamond:
        return _roundedPolygon(
          [
            Offset(center.dx, rect.top),
            Offset(rect.right, center.dy),
            Offset(center.dx, rect.bottom),
            Offset(rect.left, center.dy),
          ],
          rect.width * 0.16,
        );
      case CrystalShape.hexagon:
        final points = List<Offset>.generate(6, (index) {
          final angle = -math.pi / 2 + index * math.pi / 3;
          return Offset(
            center.dx + math.cos(angle) * rx,
            center.dy + math.sin(angle) * ry,
          );
        });
        return _roundedPolygon(points, rect.width * 0.12);
      case CrystalShape.star:
        final points = List<Offset>.generate(8, (index) {
          final angle = -math.pi / 2 + index * math.pi / 4;
          final factor = index.isEven ? 1.0 : 0.52;
          return Offset(
            center.dx + math.cos(angle) * rx * factor,
            center.dy + math.sin(angle) * ry * factor,
          );
        });
        return Path()..addPolygon(points, true);
      case CrystalShape.drop:
        return Path()
          ..moveTo(center.dx, rect.top)
          ..cubicTo(
            rect.right,
            center.dy - ry * 0.25,
            rect.right,
            rect.bottom,
            center.dx,
            rect.bottom,
          )
          ..cubicTo(
            rect.left,
            rect.bottom,
            rect.left,
            center.dy - ry * 0.25,
            center.dx,
            rect.top,
          )
          ..close();
    }
  }

  static Path _roundedPolygon(List<Offset> points, double radius) {
    final path = Path();
    final count = points.length;

    for (var index = 0; index < count; index++) {
      final current = points[index];
      final previous = points[(index - 1 + count) % count];
      final next = points[(index + 1) % count];

      final toPrevious = previous - current;
      final toNext = next - current;
      final previousLength = toPrevious.distance;
      final nextLength = toNext.distance;
      if (previousLength == 0 || nextLength == 0) {
        continue;
      }

      final cornerRadius =
          math.min(radius, math.min(previousLength, nextLength) / 2);
      final start = current + toPrevious / previousLength * cornerRadius;
      final end = current + toNext / nextLength * cornerRadius;

      if (index == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _GemPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.selected != selected ||
      oldDelegate.phase != phase;
}

class _BoardHaloPainter extends CustomPainter {
  _BoardHaloPainter({required this.breathe, required this.selected})
      : super(repaint: breathe);

  final Animation<double> breathe;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pulse = 0.5 + 0.5 * math.sin(breathe.value * math.pi * 2);
    final shortestSide = size.shortestSide;
    final glowRadius = shortestSide * (0.52 + pulse * 0.02);

    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            LumoraColors.auroraPurple.withAlpha(selected ? 50 : 34),
            LumoraColors.auroraBlue.withAlpha(12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );

    for (var index = 1; index <= 3; index++) {
      canvas.drawCircle(
        center,
        shortestSide * (0.12 + index * 0.15),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withAlpha(14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardHaloPainter oldDelegate) =>
      oldDelegate.selected != selected;
}

class _BurstParticle {
  const _BurstParticle({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  final Offset origin;
  final double angle;
  final double speed;
  final double size;
  final Color color;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress, required this.particles});

  final double progress;
  final List<_BurstParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }

    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final particle in particles) {
      final origin = Offset(
        particle.origin.dx * size.width,
        particle.origin.dy * size.height,
      );
      final distance = particle.speed * eased * size.shortestSide;
      final position = origin +
          Offset(
                math.cos(particle.angle),
                math.sin(particle.angle),
              ) *
              distance;

      canvas.drawCircle(
        position,
        particle.size * 2.4,
        Paint()..color = particle.color.withAlpha((55 * fade).round()),
      );
      canvas.drawCircle(
        position,
        particle.size * (0.55 + 0.45 * (1 - eased)),
        Paint()..color = particle.color.withAlpha((225 * fade).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.particles != particles;
}
