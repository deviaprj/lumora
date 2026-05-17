import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';

/// Overlay de victoire — fond glassmorphism, étoiles animées avec glow,
/// compteur de score avec animation, cascade de particules dorées.
class VictoryOverlay extends StatefulWidget {
  final int stars;
  final int score;
  final List<VictoryObjectiveStatus> objectives;
  final List<String> rewardEntries;
  final VoidCallback onNextLevel;
  final VoidCallback onShare;
  final VoidCallback onMenu;

  const VictoryOverlay({
    super.key,
    required this.stars,
    required this.score,
    required this.objectives,
    required this.rewardEntries,
    required this.onNextLevel,
    required this.onShare,
    required this.onMenu,
  });

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with TickerProviderStateMixin {
  late final List<AnimationController> _starControllers;
  late final AnimationController _scoreController;
  late final AnimationController _fadeController;
  final List<_VictoryParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _starControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeController.forward();

    // Séquence d'apparition étoile par étoile
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 400 + i * 350), () {
        if (mounted) _starControllers[i].forward();
      });
    }

    // Animation du compteur de score
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scoreController.forward();
    });

    // Cascade de particules dorées
    _spawnVictoryParticles();
  }

  void _spawnVictoryParticles() {
    final rng = Random();
    for (var i = 0; i < 30; i++) {
      _particles.add(_VictoryParticle(
        x: rng.nextDouble() * 400,
        y: -50.0 - rng.nextDouble() * 200,
        vy: 60 + rng.nextDouble() * 120,
        vx: (rng.nextDouble() - 0.5) * 40,
        radius: 2 + rng.nextDouble() * 4,
        alpha: 150 + rng.nextInt(105),
        color: rng.nextBool() ? LumoraColors.auroraGold : LumoraColors.auroraOrange,
        life: 2.0 + rng.nextDouble() * 2.0,
      ));
    }
  }

  @override
  void dispose() {
    for (final c in _starControllers) {
      c.dispose();
    }
    _scoreController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Stack(
        children: [
          // Fond sombre semi-transparent
          Container(color: const Color(0xDD000000)),

          Positioned.fill(
            child: IgnorePointer(
              child: _VictoryAuroraBackdrop(progress: _fadeController.value),
            ),
          ),

          // Particules dorées en arrière-plan
          Positioned.fill(
            child: _VictoryParticleCanvas(particles: _particles),
          ),

          // Carte glassmorphism
          Center(
            child: LumoraCard(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              borderRadius: LumoraRadii.modal,
              shadows: [
                LumoraShadows.glow(color: LumoraColors.auroraGold),
                LumoraShadows.floating(color: LumoraColors.auroraPurple),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Titre avec glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: LumoraColors.auroraGold.withAlpha(60),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      '✨',
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Monde illuminé !',
                    style: LumoraTextStyles.displayMedium().copyWith(
                      shadows: [
                        Shadow(
                          color: LumoraColors.auroraGold.withAlpha(100),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Score animé
                  AnimatedBuilder(
                    animation: _scoreController,
                    builder: (context, child) {
                      final displayScore = (widget.score * _scoreController.value).toInt();
                      return Text(
                        'Score : $displayScore',
                        style: LumoraTextStyles.bodyLarge().copyWith(
                          color: LumoraColors.auroraGold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Étoiles avec animation elastic scale + glow halos
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _starControllers[index],
                            curve: Curves.elasticOut,
                          ),
                          child: _StarWithGlow(
                            isFilled: index < widget.stars,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (widget.objectives.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Column(
                      children: widget.objectives.map((objective) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VictoryObjectiveRow(objective: objective),
                        );
                      }).toList(growable: false),
                    ),
                  ],
                  if (widget.rewardEntries.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Récompenses de maîtrise',
                        style: LumoraTextStyles.bodyLarge(color: LumoraColors.auroraGold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.rewardEntries.map((entry) {
                        return _VictoryRewardChip(label: entry);
                      }).toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Bouton Niveau Suivant
                  LumoraButton(
                    onPressed: widget.onNextLevel,
                    text: 'Niveau Suivant',
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    gradientColors: [LumoraColors.successMint, LumoraColors.auroraGreen],
                    elevation: 8,
                  ),
                  const SizedBox(height: 14),

                  // Bouton Partager
                  LumoraButton(
                    onPressed: widget.onShare,
                    text: 'Partager',
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    gradientColors: [LumoraColors.auroraBlue, const Color(0xFF3A86FF)],
                    elevation: 6,
                  ),
                  const SizedBox(height: 14),

                  // Bouton Menu
                  LumoraButton(
                    onPressed: widget.onMenu,
                    text: 'Menu',
                    icon: const Icon(Icons.map_rounded, color: Colors.white70),
                    gradientColors: [
                      const Color(0x44FFFFFF),
                      const Color(0x22FFFFFF),
                    ],
                    elevation: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VictoryObjectiveStatus {
  final String label;
  final String description;
  final bool completed;

  const VictoryObjectiveStatus({
    required this.label,
    required this.description,
    required this.completed,
  });
}

class _VictoryObjectiveRow extends StatelessWidget {
  final VictoryObjectiveStatus objective;

  const _VictoryObjectiveRow({required this.objective});

  @override
  Widget build(BuildContext context) {
    final accent = objective.completed
        ? LumoraColors.auroraGreen
        : LumoraColors.disabledMist;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.chip),
        color: accent.withAlpha(28),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(
            objective.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective.label,
                  style: LumoraTextStyles.bodyLarge(color: Colors.white),
                ),
                Text(
                  objective.description,
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

class _VictoryRewardChip extends StatelessWidget {
  final String label;

  const _VictoryRewardChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        gradient: LinearGradient(
          colors: [
            LumoraColors.auroraGold.withAlpha(55),
            LumoraColors.auroraOrange.withAlpha(26),
          ],
        ),
        border: Border.all(color: LumoraColors.auroraGold.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: LumoraTextStyles.label(color: Colors.white)),
        ],
      ),
    );
  }
}

class _VictoryAuroraBackdrop extends StatelessWidget {
  final double progress;

  const _VictoryAuroraBackdrop({required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VictoryAuroraPainter(progress: progress),
    );
  }
}

class _VictoryAuroraPainter extends CustomPainter {
  final double progress;

  const _VictoryAuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final radius = size.shortestSide * (0.32 + progress * 0.05);

    final goldAura = Paint()
      ..shader = RadialGradient(
        colors: [
          LumoraColors.auroraGold.withAlpha((60 + progress * 40).toInt().clamp(0, 255)),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius * 1.4, goldAura);

    final violetAura = Paint()
      ..shader = RadialGradient(
        colors: [
          LumoraColors.auroraPurple.withAlpha((55 + progress * 30).toInt().clamp(0, 255)),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: Offset(center.dx, center.dy + 40), radius: radius * 2.1));
    canvas.drawCircle(Offset(center.dx, center.dy + 40), radius * 2.1, violetAura);
  }

  @override
  bool shouldRepaint(covariant _VictoryAuroraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Étoile avec halo lumineux pour la victoire.
class _StarWithGlow extends StatelessWidget {
  final bool isFilled;

  const _StarWithGlow({required this.isFilled});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: LumoraColors.auroraGold.withAlpha(80),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: LumoraColors.auroraGold.withAlpha(40),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ]
            : [],
      ),
      child: Icon(
        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
        color: isFilled ? LumoraColors.auroraGold : LumoraColors.disabledMist,
        size: 48,
      ),
    );
  }
}

/// Canvas pour les particules de victoire (dorées tombantes).
class _VictoryParticleCanvas extends StatefulWidget {
  final List<_VictoryParticle> particles;

  const _VictoryParticleCanvas({required this.particles});

  @override
  State<_VictoryParticleCanvas> createState() => _VictoryParticleCanvasState();
}

class _VictoryParticleCanvasState extends State<_VictoryParticleCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VictoryParticlePainter(
        particles: widget.particles,
        time: _controller.value * 5,
      ),
    );
  }
}

class _VictoryParticlePainter extends CustomPainter {
  final List<_VictoryParticle> particles;
  final double time;

  _VictoryParticlePainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = p.y + p.vy * time;
      final x = p.x + p.vx * time;
      final life = (p.life - time).clamp(0.0, p.life);
      if (life <= 0) continue;

      final alpha = (p.alpha * (life / p.life)).toInt().clamp(0, 255);

      // Glow
      final glowPaint = Paint()
        ..color = p.color.withAlpha((alpha * 0.3).toInt().clamp(0, 255))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), p.radius * 3, glowPaint);

      // Particle
      final paint = Paint()..color = p.color.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VictoryParticlePainter oldDelegate) => true;
}

class _VictoryParticle {
  final double x;
  final double y;
  final double vy;
  final double vx;
  final double radius;
  final int alpha;
  final Color color;
  final double life;

  _VictoryParticle({
    required this.x,
    required this.y,
    required this.vy,
    required this.vx,
    required this.radius,
    required this.alpha,
    required this.color,
    required this.life,
  });
}