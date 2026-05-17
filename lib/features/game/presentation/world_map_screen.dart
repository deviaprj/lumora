import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../domain/level_data.dart';

/// État de progression d'un niveau.
enum LevelProgress {
  locked,
  available,
  completed,
}

/// Carte des mondes — niveaux affichés comme bulles flottantes reliées
/// par des courbes de Bézier animées. L'état (complété/disponible/verrouillé)
/// est déduit dynamiquement. Navigation vers /game avec le niveau sélectionné.
class WorldMapScreen extends StatefulWidget {
  final int completedLevelId;

  const WorldMapScreen({super.key, this.completedLevelId = 0});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with TickerProviderStateMixin {
  int get _completedLevelId => widget.completedLevelId;

  // Animation controllers pour les bulles flottantes
  late List<AnimationController> _floatControllers;

  @override
  void initState() {
    super.initState();
    _floatControllers = List.generate(
      World1Levels.levels.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + index * 200),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
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
    final levels = World1Levels.levels;

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
                      const Spacer(),
                      Text('Carte des Mondes', style: LumoraTextStyles.titleLarge()),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),

              // Légende
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: LumoraColors.auroraGold, label: 'Complété'),
                    const SizedBox(width: 16),
                    _LegendDot(color: LumoraColors.auroraGreen, label: 'Disponible'),
                    const SizedBox(width: 16),
                    _LegendDot(color: LumoraColors.lockOverlay, label: 'Verrouillé'),
                  ],
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
                child: _LevelBubble(
                  level: level,
                  progress: progress,
                  onTap: progress != LevelProgress.locked
                      ? () => context.go('/game', extra: level)
                      : null,
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
  Offset _levelPosition(int index, int total, Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;
    final startY = screenHeight * 0.12;
    final endY = screenHeight * 0.78;
    final stepY = total > 1 ? (endY - startY) / (total - 1) : 0.0;

    final y = startY + index * stepY;
    final xOffset = sin(index * 1.2) * screenWidth * 0.18;
    final x = screenWidth / 2 + xOffset;

    return Offset(x, y);
  }
}

/// Bulle de niveau sur la carte — avec glow animé.
class _LevelBubble extends StatelessWidget {
  final LevelData level;
  final LevelProgress progress;
  final VoidCallback? onTap;

  const _LevelBubble({
    required this.level,
    required this.progress,
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
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
    final startY = size.height * 0.12;
    final endY = size.height * 0.78;
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