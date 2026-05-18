import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../data/player_progression_service.dart';
import '../../monetization/data/reward_inventory.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../domain/level_data.dart';

/// État de progression d'un niveau.
enum LevelProgress {
  locked,
  available,
  completed,
}

enum MasteryMapFilter {
  all,
  remaining,
  partial,
  complete,
}

enum MasteryRewardState {
  none,
  remaining,
  partial,
  complete,
}

/// Carte des mondes — niveaux affichés comme bulles flottantes reliées
/// par des courbes de Bézier animées. L'état (complété/disponible/verrouillé)
/// est déduit dynamiquement. Navigation vers /game avec le niveau sélectionné.
class WorldMapScreen extends StatefulWidget {
  final int completedLevelId;
  final ValueChanged<LevelData>? onLevelSelected;

  const WorldMapScreen({
    super.key,
    this.completedLevelId = 0,
    this.onLevelSelected,
  });

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  int get _completedLevelId {
    final persistedCompletedId = PlayerProgressionService.instance.completedLevelId;
    return widget.completedLevelId > persistedCompletedId
        ? widget.completedLevelId
        : persistedCompletedId;
  }
  late final RewardInventory _rewardInventory;
  MasteryMapFilter _masteryFilter = MasteryMapFilter.all;

  // Animation controllers pour les bulles flottantes
  late List<AnimationController> _floatControllers;

  @override
  void initState() {
    super.initState();
    _rewardInventory = RewardInventory.instance;
    _rewardInventory.addListener(_onInventoryChanged);
    unawaited(_rewardInventory.load());
    final levels = _visibleLevels;
    _floatControllers = List.generate(
      levels.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + index * 200),
      )..repeat(reverse: true),
    );
  }

  List<LevelData> get _visibleLevels {
    final visibleCount = max(World1Levels.levels.length, _completedLevelId + 1);
    return List<LevelData>.generate(
      visibleCount,
      (index) => LevelCatalog.byId(index + 1),
      growable: false,
    );
  }

  void _onInventoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openLevel(BuildContext context, LevelData level) {
    final onLevelSelected = widget.onLevelSelected;
    if (onLevelSelected != null) {
      onLevelSelected(level);
      return;
    }

    context.go('/game', extra: level);
  }

  @override
  void dispose() {
    _rewardInventory.removeListener(_onInventoryChanged);
    for (final c in _floatControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Détermine l'état d'un niveau selon le dernier niveau complété.
  LevelProgress _progressForLevel(int levelId) {
    if (levelId <= _completedLevelId) return LevelProgress.completed;
    if (levelId == _completedLevelId + 1) return LevelProgress.available;
    return LevelProgress.locked;
  }

  @override
  Widget build(BuildContext context) {
    final levels = _visibleLevels;
    final levelsWithPendingMastery = levels
        .where((level) => _progressForLevel(level.id) != LevelProgress.locked)
        .where((level) => _rewardInventory.hasRemainingSecondaryObjectiveRewards(level))
        .length;
    final levelsWithPartialMastery = levels
      .where((level) => _progressForLevel(level.id) != LevelProgress.locked)
      .where((level) => _masteryStateForLevel(level) == MasteryRewardState.partial)
      .length;
    final levelsWithCompleteMastery = levels
      .where((level) => _progressForLevel(level.id) != LevelProgress.locked)
      .where((level) => _masteryStateForLevel(level) == MasteryRewardState.complete)
      .length;
    final nextRelevantLevel = _nextRelevantLevel(levels);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LumoraGradients.homeBg,
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Fond étoilé procédural
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarfieldPainter(),
                ),
              ),

              // Courbes de Bézier entre les niveaux
              Positioned.fill(
                child: CustomPaint(
                  painter: _BezierPathPainter(
                    levels: levels,
                    completedLevelId: _completedLevelId,
                  ),
                ),
              ),

              // Bulles de niveaux
              ..._buildLevelBubbles(context, levels),

              // Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      LumoraButton(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        gradientColors: [LumoraColors.midnight, LumoraColors.deepSpace],
                        size: 44,
                        elevation: 3,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Carte des Mondes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: LumoraTextStyles.titleLarge(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (levelsWithPendingMastery > 0)
                        _MasteryMapCounter(levelCount: levelsWithPendingMastery)
                      else
                        const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 72,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MasteryFilterChip(
                            key: const ValueKey<String>('mastery-filter-all'),
                            label: 'Tout',
                            count: levels.length,
                            selected: _masteryFilter == MasteryMapFilter.all,
                            accent: LumoraColors.auroraBlue,
                            onTap: () => setState(() => _masteryFilter = MasteryMapFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _MasteryFilterChip(
                            key: const ValueKey<String>('mastery-filter-remaining'),
                            label: 'À gagner',
                            count: levelsWithPendingMastery,
                            selected: _masteryFilter == MasteryMapFilter.remaining,
                            accent: LumoraColors.auroraPurple,
                            onTap: () => setState(() => _masteryFilter = MasteryMapFilter.remaining),
                          ),
                          const SizedBox(width: 8),
                          _MasteryFilterChip(
                            key: const ValueKey<String>('mastery-filter-partial'),
                            label: 'En cours',
                            count: levelsWithPartialMastery,
                            selected: _masteryFilter == MasteryMapFilter.partial,
                            accent: LumoraColors.energyAmber,
                            onTap: () => setState(() => _masteryFilter = MasteryMapFilter.partial),
                          ),
                          const SizedBox(width: 8),
                          _MasteryFilterChip(
                            key: const ValueKey<String>('mastery-filter-complete'),
                            label: 'Complète',
                            count: levelsWithCompleteMastery,
                            selected: _masteryFilter == MasteryMapFilter.complete,
                            accent: LumoraColors.auroraGreen,
                            onTap: () => setState(() => _masteryFilter = MasteryMapFilter.complete),
                          ),
                        ],
                      ),
                    ),
                    if (nextRelevantLevel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _JumpToRelevantLevelChip(
                          levelId: nextRelevantLevel.id,
                          filter: _masteryFilter,
                          onTap: () => _openLevel(context, nextRelevantLevel),
                        ),
                      ),
                  ],
                ),
              ),

              // Légende
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: LumoraColors.auroraGold, label: 'Complété'),
                      const SizedBox(width: 16),
                      _LegendDot(color: LumoraColors.auroraGreen, label: 'Disponible'),
                      const SizedBox(width: 16),
                      _LegendDot(color: LumoraColors.auroraPurple, label: 'Maîtrise restante'),
                      const SizedBox(width: 16),
                      _LegendDot(color: LumoraColors.lockOverlay, label: 'Verrouillé'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLevelBubbles(BuildContext context, List<LevelData> levels) {
    final bubbles = <Widget>[];
    final size = MediaQuery.of(context).size;

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final progress = _progressForLevel(level.id);
      final pos = _levelPosition(i, levels.length, size);
      final pendingMasteryCount = progress == LevelProgress.locked
          ? 0
          : _rewardInventory.remainingSecondaryObjectiveRewardCount(level);
      final masteryState = _masteryStateForLevel(level);
      final isVisibleForFilter = _matchesMasteryFilter(level, masteryState);
      final canNavigate = progress != LevelProgress.locked && isVisibleForFilter;

      bubbles.add(
        Positioned(
          left: pos.dx - 28,
          top: pos.dy - 28,
          child: AnimatedBuilder(
            animation: _floatControllers[i],
            builder: (context, _) {
              final floatOffset = _floatControllers[i].value * 4 - 2;
              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: Opacity(
                  opacity: isVisibleForFilter ? 1.0 : 0.18,
                  child: _LevelBubble(
                    level: level,
                    progress: progress,
                    masteryState: masteryState,
                    pendingMasteryCount: pendingMasteryCount,
                    onTap: canNavigate
                        ? () => _openLevel(context, level)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return bubbles;
  }

  /// Position normalisée des bulles en arc de cercle.
  /// startY commence à 28% pour éviter le header + filtre chips (≈160dp sur Xiaomi 12).
  Offset _levelPosition(int index, int total, Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;
    final startY = screenHeight * 0.28;
    final endY = screenHeight * 0.88;
    final stepY = total > 1 ? (endY - startY) / (total - 1) : 0.0;

    final y = startY + index * stepY;
    final xOffset = sin(index * 1.2) * screenWidth * 0.18;
    final x = screenWidth / 2 + xOffset;

    return Offset(x, y);
  }

  MasteryRewardState _masteryStateForLevel(LevelData level) {
    if (level.secondaryObjectives.isEmpty || _progressForLevel(level.id) == LevelProgress.locked) {
      return MasteryRewardState.none;
    }

    final total = _rewardInventory.totalSecondaryObjectiveRewardCount(level);
    final claimed = _rewardInventory.claimedSecondaryObjectiveRewardCount(level);
    final remaining = _rewardInventory.remainingSecondaryObjectiveRewardCount(level);

    if (remaining == 0 && total > 0) {
      return MasteryRewardState.complete;
    }
    if (claimed > 0 && remaining > 0) {
      return MasteryRewardState.partial;
    }
    if (remaining > 0) {
      return MasteryRewardState.remaining;
    }
    return MasteryRewardState.none;
  }

  bool _matchesMasteryFilter(LevelData level, MasteryRewardState masteryState) {
    if (_progressForLevel(level.id) == LevelProgress.locked) {
      return _masteryFilter == MasteryMapFilter.all;
    }

    switch (_masteryFilter) {
      case MasteryMapFilter.all:
        return true;
      case MasteryMapFilter.remaining:
        return masteryState == MasteryRewardState.remaining;
      case MasteryMapFilter.partial:
        return masteryState == MasteryRewardState.partial;
      case MasteryMapFilter.complete:
        return masteryState == MasteryRewardState.complete;
    }
  }

  LevelData? _nextRelevantLevel(List<LevelData> levels) {
    final candidates = levels.where((level) {
      final progress = _progressForLevel(level.id);
      if (progress == LevelProgress.locked) {
        return false;
      }
      return _matchesMasteryFilter(level, _masteryStateForLevel(level));
    }).toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }

    final currentThreshold = _completedLevelId + 1;
    for (final candidate in candidates) {
      if (candidate.id >= currentThreshold) {
        return candidate;
      }
    }

    return candidates.first;
  }
}

/// Bulle de niveau sur la carte — avec glow animé.
class _LevelBubble extends StatelessWidget {
  final LevelData level;
  final LevelProgress progress;
  final MasteryRewardState masteryState;
  final int pendingMasteryCount;
  final VoidCallback? onTap;

  const _LevelBubble({
    required this.level,
    required this.progress,
    required this.masteryState,
    required this.pendingMasteryCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress == LevelProgress.completed;
    final isAvailable = progress == LevelProgress.available;
    final isLocked = progress == LevelProgress.locked;

    final gradientColors = isCompleted
        ? [LumoraColors.auroraGold, LumoraColors.auroraOrange]
        : isAvailable
            ? [LumoraColors.auroraGreen, LumoraColors.auroraBlue]
            : [LumoraColors.midnight, LumoraColors.dawn];

    final glowColor = isCompleted
        ? LumoraColors.auroraGold
        : isAvailable
            ? LumoraColors.auroraGreen
            : LumoraColors.lockOverlay;

    final ringColor = switch (masteryState) {
      MasteryRewardState.remaining => LumoraColors.auroraPurple,
      MasteryRewardState.partial => LumoraColors.energyAmber,
      MasteryRewardState.complete => LumoraColors.auroraGreen,
      MasteryRewardState.none => Colors.transparent,
    };

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: ringColor == Colors.transparent
                  ? null
                  : Border.all(color: ringColor.withAlpha(210), width: 2.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: glowColor.withAlpha(isAvailable ? 100 : 80),
                        blurRadius: 16,
                        spreadRadius: isAvailable ? 2 : -2,
                        offset: const Offset(0, 4),
                      ),
                      if (isAvailable)
                        BoxShadow(
                          color: glowColor.withAlpha(40),
                          blurRadius: 30,
                          spreadRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                    ],
            ),
            child: Center(
              child: isLocked
                  ? Icon(Icons.lock_rounded, color: LumoraColors.disabledMist, size: 20)
                  : Text(
                      '${level.id}',
                      style: LumoraTextStyles.label(color: LumoraColors.pearl).copyWith(fontSize: 16),
                    ),
            ),
          ),
          if (pendingMasteryCount > 0)
            Positioned(
              right: -4,
              top: -6,
              child: _MasteryRewardBadge(count: pendingMasteryCount),
            ),
          if (masteryState == MasteryRewardState.partial)
            Positioned(
              left: -4,
              bottom: -4,
              child: _MasteryStatusMarker(
                icon: Icons.timelapse_rounded,
                accent: LumoraColors.energyAmber,
              ),
            ),
          if (masteryState == MasteryRewardState.complete)
            Positioned(
              left: -4,
              bottom: -4,
              child: _MasteryStatusMarker(
                icon: Icons.check_rounded,
                accent: LumoraColors.auroraGreen,
              ),
            ),
        ],
      ),
    );
  }
}

class _MasteryStatusMarker extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _MasteryStatusMarker({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent,
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(120),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}

class _MasteryRewardBadge extends StatelessWidget {
  final int count;

  const _MasteryRewardBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        gradient: LinearGradient(
          colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
        ),
        boxShadow: [
          BoxShadow(
            color: LumoraColors.auroraPurple.withAlpha(110),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '$count',
        style: LumoraTextStyles.label(color: Colors.white),
      ),
    );
  }
}

class _MasteryMapCounter extends StatelessWidget {
  final int levelCount;

  const _MasteryMapCounter({required this.levelCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        color: LumoraColors.auroraPurple.withAlpha(36),
        border: Border.all(color: LumoraColors.auroraPurple.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '$levelCount maitrise',
            style: LumoraTextStyles.label(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MasteryFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _MasteryFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LumoraRadii.bubble),
          color: selected ? accent.withAlpha(46) : Colors.white.withAlpha(12),
          border: Border.all(
            color: selected ? accent.withAlpha(120) : Colors.white.withAlpha(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: LumoraTextStyles.label(color: Colors.white),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LumoraRadii.bubble),
                color: accent.withAlpha(selected ? 80 : 36),
              ),
              child: Text(
                '$count',
                style: LumoraTextStyles.label(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpToRelevantLevelChip extends StatelessWidget {
  final int levelId;
  final MasteryMapFilter filter;
  final VoidCallback onTap;

  const _JumpToRelevantLevelChip({
    required this.levelId,
    required this.filter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      MasteryMapFilter.all => 'Reprendre au niveau $levelId',
      MasteryMapFilter.remaining => 'Prochain niveau à maîtriser: $levelId',
      MasteryMapFilter.partial => 'Reprendre la maîtrise du niveau $levelId',
      MasteryMapFilter.complete => 'Voir une maîtrise complète: $levelId',
    };

    final accent = switch (filter) {
      MasteryMapFilter.all => LumoraColors.auroraBlue,
      MasteryMapFilter.remaining => LumoraColors.auroraPurple,
      MasteryMapFilter.partial => LumoraColors.energyAmber,
      MasteryMapFilter.complete => LumoraColors.auroraGreen,
    };

    return GestureDetector(
      key: ValueKey<String>('jump-to-${filter.name}-$levelId'),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LumoraRadii.bubble),
          color: accent.withAlpha(34),
          border: Border.all(color: accent.withAlpha(96)),
        ),
        child: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LumoraTextStyles.label(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Point de légende.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: LumoraTextStyles.label()),
      ],
    );
  }
}

/// Peintre du fond étoilé procédural — avec étoiles et nébuleuses animées.
class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fond dégradé
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [LumoraColors.deepSpace, LumoraColors.twilight, LumoraColors.dawn],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final rng = Random(42);

    // Nébuleuses (3 blobs avec glow)
    final nebulas = [
      (size.width * 0.7, size.height * 0.3, 180.0, LumoraColors.auroraPurple.withAlpha(30)),
      (size.width * 0.3, size.height * 0.6, 150.0, LumoraColors.auroraBlue.withAlpha(25)),
      (size.width * 0.5, size.height * 0.8, 120.0, LumoraColors.auroraPink.withAlpha(20)),
    ];

    for (final (nx, ny, nr, nc) in nebulas) {
      final nebulaPaint = Paint()
        ..shader = RadialGradient(
          colors: [nc, Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(nx, ny), radius: nr));
      canvas.drawCircle(Offset(nx, ny), nr, nebulaPaint);
    }

    // Étoiles (120 points avec variations de taille)
    for (var i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 0.5 + rng.nextDouble() * 2.0;
      final alpha = 60 + rng.nextInt(140);
      final starPaint = Paint()
        ..color = Color.fromARGB(alpha, 255, 255, 240);

      // Glow pour les étoiles plus grandes
      if (radius > 1.5) {
        final glowPaint = Paint()
          ..color = Color.fromARGB((alpha * 0.3).toInt().clamp(0, 80), 200, 220, 255)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      }

      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Peintre des courbes de Bézier entre les bulles de niveau — glow pulsant.
class _BezierPathPainter extends CustomPainter {
  final List<LevelData> levels;
  final int completedLevelId;

  _BezierPathPainter({required this.levels, required this.completedLevelId});

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePositions = <Offset>[];
    for (var i = 0; i < levels.length; i++) {
      bubblePositions.add(_levelPosition(i, levels.length, size));
    }

    // Courbes de connexion avec glow pulsant
    for (var i = 0; i < bubblePositions.length - 1; i++) {
      final isCompleted = i < completedLevelId;
      final baseColor = isCompleted
          ? LumoraColors.auroraGold
          : LumoraColors.auroraGreen;

      final path = Path();
      path.moveTo(bubblePositions[i].dx, bubblePositions[i].dy);
      path.quadraticBezierTo(
        (bubblePositions[i].dx + bubblePositions[i + 1].dx) / 2,
        (bubblePositions[i].dy + bubblePositions[i + 1].dy) / 2 - 40,
        bubblePositions[i + 1].dx,
        bubblePositions[i + 1].dy,
      );

      // Glow externe (large, flou)
      final glowPaint = Paint()
        ..color = baseColor.withAlpha(25)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);

      // Glow moyen
      final midGlowPaint = Paint()
        ..color = baseColor.withAlpha(50)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, midGlowPaint);

      // Filament principal
      final paint = Paint()
        ..color = baseColor.withAlpha(isCompleted ? 120 : 60)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);

      // Ligne blanche centrale (effet néon) pour chemins complétés
      if (isCompleted) {
        final corePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withAlpha(60)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, corePaint);
      }
    }
  }

  Offset _levelPosition(int index, int total, Size size) {
    final startY = size.height * 0.28;
    final endY = size.height * 0.88;
    final stepY = total > 1 ? (endY - startY) / (total - 1) : 0.0;

    final y = startY + index * stepY;
    final xOffset = sin(index * 1.2) * size.width * 0.18;
    final x = size.width / 2 + xOffset;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! _BezierPathPainter || oldDelegate.completedLevelId != completedLevelId;
}