import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show LinearGradient, RadialGradient, Alignment;
import '../../../app/theme.dart';

/// Fond procédural 5 couches — remplace le parallax quand les images sont absentes.
/// Couches (de loin à proche) :
/// 1. Nébuleuse lointaine (shader avec bruit Perlin simplifié, très lent)
/// 2. Nuages lumineux grands (vitesse 0.3x)
/// 3. Étoiles lointaines (300, vitesse 0.5x)
/// 4. Nuages moyens (vitesse 0.7x)
/// 5. Brume proche + étoiles proches + poussière (vitesse 1x)
class ProceduralBackground extends Component {
  final List<_Star> _stars = [];
  final List<_Nebula> _nebulas = [];
  final List<_Dust> _dusts = [];
  final List<_ShootingStar> _shootingStars = [];
  double _time = 0.0;
  double _canvasWidth = 400;
  double _canvasHeight = 800;
  bool _initialized = false;

  // Thème de monde (couleurs)
  List<Color> _nebulaColors = [
    LumoraColors.auroraPurple,
    LumoraColors.auroraBlue,
    LumoraColors.auroraPink,
    LumoraColors.auroraGreen,
  ];

  ProceduralBackground({int worldId = 1}) {
    setWorldTheme(worldId);
  }

  /// Change les couleurs en fonction du monde.
  void setWorldTheme(int worldId) {
    switch (worldId) {
      case 1: // Aube Dorée
        _nebulaColors = [
          LumoraColors.auroraGold,
          LumoraColors.auroraOrange,
          const Color(0xFFE8B4B8), // rose doré
          LumoraColors.auroraGreen.withAlpha(180),
        ];
      case 2: // Crépuscule Violet
        _nebulaColors = [
          LumoraColors.auroraPurple,
          LumoraColors.auroraPink,
          LumoraColors.auroraBlue.withAlpha(180),
          const Color(0xFF6B3FA0), // violet profond
        ];
      case 3: // Nuit Étoilée
        _nebulaColors = [
          LumoraColors.auroraBlue,
          const Color(0xFF1A1A4E), // bleu nuit profond
          LumoraColors.auroraPurple.withAlpha(180),
          const Color(0xFF0D0D2B), // bleu-noir
        ];
      case 4: // Aurore Boréale
        _nebulaColors = [
          LumoraColors.auroraGreen,
          LumoraColors.auroraBlue,
          LumoraColors.auroraPurple,
          const Color(0xFF00E5FF), // cyan boréal
        ];
      case 5: // Soleil de Midi
        _nebulaColors = [
          LumoraColors.auroraGold,
          LumoraColors.auroraOrange,
          const Color(0xFFFFD700), // or brillant
          const Color(0xFFFF8C00), // orange profond
        ];
      default:
        _nebulaColors = [
          LumoraColors.auroraPurple,
          LumoraColors.auroraBlue,
          LumoraColors.auroraPink,
          LumoraColors.auroraGreen,
        ];
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _canvasWidth = size.x;
    _canvasHeight = size.y;
    _generateElements();
  }

  void _generateElements() {
    _stars.clear();
    _nebulas.clear();
    _dusts.clear();

    final rng = Random(42);
    final w = _canvasWidth;
    final h = _canvasHeight;

    // ── Couche 3 : Étoiles lointaines (300) ──
    for (var i = 0; i < 300; i++) {
      _stars.add(_Star(
        x: rng.nextDouble() * w,
        y: rng.nextDouble() * h,
        radius: 0.3 + rng.nextDouble() * 1.8,
        alpha: 60 + rng.nextInt(140),
        twinkleSpeed: 0.8 + rng.nextDouble() * 3.5,
        twinkleOffset: rng.nextDouble() * 6.28,
        layer: rng.nextDouble() < 0.7 ? _StarLayer.far : _StarLayer.near,
      ));
    }

    // ── Couches 2 & 4 : Nébuleuses (6 au total) ──
    // Grandes nébuleuses lointaines
    for (var i = 0; i < 3; i++) {
      _nebulas.add(_Nebula(
        x: w * (0.15 + rng.nextDouble() * 0.7),
        y: h * (0.1 + rng.nextDouble() * 0.8),
        radius: 100 + rng.nextDouble() * 160,
        color: _nebulaColors[i % _nebulaColors.length],
        alpha: 15 + rng.nextInt(20),
        driftSpeed: 0.2 + rng.nextDouble() * 0.3,
        layer: _NebulaLayer.far,
      ));
    }
    // Nébuleuses moyennes plus proches
    for (var i = 0; i < 3; i++) {
      _nebulas.add(_Nebula(
        x: w * (0.2 + rng.nextDouble() * 0.6),
        y: h * (0.15 + rng.nextDouble() * 0.7),
        radius: 60 + rng.nextDouble() * 100,
        color: _nebulaColors[(i + 2) % _nebulaColors.length],
        alpha: 20 + rng.nextInt(25),
        driftSpeed: 0.4 + rng.nextDouble() * 0.5,
        layer: _NebulaLayer.near,
      ));
    }

    // ── Couche 5 : Poussière ──
    for (var i = 0; i < 80; i++) {
      _dusts.add(_Dust(
        x: rng.nextDouble() * w,
        y: rng.nextDouble() * h,
        radius: 0.8 + rng.nextDouble() * 2.5,
        alpha: 25 + rng.nextInt(60),
        speed: 8 + rng.nextDouble() * 20,
      ));
    }

    _initialized = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Poussière — déplacement horizontal
    for (final d in _dusts) {
      d.x += d.speed * dt;
      if (d.x > _canvasWidth + 10) {
        d.x = -10;
        d.y = Random().nextDouble() * _canvasHeight;
      }
    }

    // Étoiles filantes (probabilité faible)
    if (Random().nextDouble() < 0.003) {
      _spawnShootingStar();
    }

    // Mise à jour des étoiles filantes
    _shootingStars.removeWhere((s) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.life -= dt;
      return s.life <= 0 || s.x > _canvasWidth || s.y > _canvasHeight;
    });
  }

  void _spawnShootingStar() {
    final rng = Random();
    _shootingStars.add(_ShootingStar(
      x: rng.nextDouble() * _canvasWidth * 0.6,
      y: rng.nextDouble() * _canvasHeight * 0.3,
      vx: 200 + rng.nextDouble() * 300,
      vy: 100 + rng.nextDouble() * 200,
      life: 0.6 + rng.nextDouble() * 0.8,
      length: 30 + rng.nextDouble() * 50,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (!_initialized) return;

    final w = _canvasWidth;
    final h = _canvasHeight;

    // ── Couche 1 : Fond profond (dégradé) ──
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          LumoraColors.deepSpace,
          LumoraColors.twilight,
          LumoraColors.dawn,
          const Color(0xFF1A0A2E), // Violet très profond en bas
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // ── Couche 2 : Nébuleuses lointaines ──
    for (final n in _nebulas.where((n) => n.layer == _NebulaLayer.far)) {
      final dx = sin(_time * n.driftSpeed) * 15;
      final dy = cos(_time * n.driftSpeed * 0.7) * 10;
      final nebulaPaint = Paint()
        ..shader = RadialGradient(
          colors: [n.color.withAlpha(n.alpha), const Color(0x00000000)],
        ).createShader(
          Rect.fromCircle(center: Offset(n.x + dx, n.y + dy), radius: n.radius),
        );
      canvas.drawCircle(Offset(n.x + dx, n.y + dy), n.radius, nebulaPaint);
    }

    // ── Couche 3 : Étoiles lointaines ──
    for (final s in _stars.where((s) => s.layer == _StarLayer.far)) {
      final twinkle = 0.4 + 0.6 * sin(_time * s.twinkleSpeed + s.twinkleOffset);
      final alpha = (s.alpha * twinkle).toInt().clamp(30, 220);
      final starPaint = Paint()
        ..color = Color.fromARGB(alpha, 255, 255, 240);
      canvas.drawCircle(Offset(s.x, s.y), s.radius * twinkle, starPaint);
    }

    // ── Couche 4 : Nébuleuses moyennes ──
    for (final n in _nebulas.where((n) => n.layer == _NebulaLayer.near)) {
      final dx = sin(_time * n.driftSpeed + 1.5) * 12;
      final dy = cos(_time * n.driftSpeed * 0.8 + 0.5) * 8;
      final nebulaPaint = Paint()
        ..shader = RadialGradient(
          colors: [n.color.withAlpha(n.alpha), const Color(0x00000000)],
        ).createShader(
          Rect.fromCircle(center: Offset(n.x + dx, n.y + dy), radius: n.radius),
        );
      canvas.drawCircle(Offset(n.x + dx, n.y + dy), n.radius, nebulaPaint);
    }

    // ── Étoiles proches (plus brillantes) ──
    for (final s in _stars.where((s) => s.layer == _StarLayer.near)) {
      final twinkle = 0.5 + 0.5 * sin(_time * s.twinkleSpeed + s.twinkleOffset);
      final alpha = (s.alpha * twinkle).toInt().clamp(40, 255);
      final starPaint = Paint()
        ..color = Color.fromARGB(alpha, 255, 255, 255);

      // Glow autour des étoiles proches
      if (s.radius > 1.2) {
        final glowPaint = Paint()
          ..color = Color.fromARGB((alpha * 0.3).toInt().clamp(0, 80), 200, 220, 255)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(s.x, s.y), s.radius * twinkle * 3, glowPaint);
      }

      canvas.drawCircle(Offset(s.x, s.y), s.radius * twinkle, starPaint);
    }

    // ── Étoiles filantes ──
    for (final s in _shootingStars) {
      final alpha = (255 * (s.life / s.maxLife)).toInt().clamp(0, 255);
      final trailLen = s.length * (s.life / s.maxLife);
      final angle = atan2(s.vy, s.vx);
      final endX = s.x - cos(angle) * trailLen;
      final endY = s.y - sin(angle) * trailLen;

      final trailPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha(alpha)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawLine(Offset(s.x, s.y), Offset(endX, endY), trailPaint);

      // Point lumineux de tête
      final headPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(s.x, s.y), 3, headPaint);
    }

    // ── Couche 5 : Brume proche + poussière ──
    // Brume subtile
    final mistPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          LumoraColors.auroraPurple.withAlpha(8),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.7),
        radius: w * 0.6,
      ));
    canvas.drawCircle(Offset(w * 0.5, h * 0.7), w * 0.6, mistPaint);

    // Poussière
    for (final d in _dusts) {
      final dustPaint = Paint()
        ..color = Color.fromARGB(d.alpha, 200, 210, 255);
      canvas.drawCircle(Offset(d.x, d.y), d.radius, dustPaint);
    }
  }
}

enum _StarLayer { far, near }
enum _NebulaLayer { far, near }

class _Star {
  double x;
  double y;
  final double radius;
  final int alpha;
  final double twinkleSpeed;
  final double twinkleOffset;
  final _StarLayer layer;

  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.layer,
  });
}

class _Nebula {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final int alpha;
  final double driftSpeed;
  final _NebulaLayer layer;

  _Nebula({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.alpha,
    required this.driftSpeed,
    required this.layer,
  });
}

class _Dust {
  double x;
  double y;
  final double radius;
  final int alpha;
  final double speed;

  _Dust({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    required this.speed,
  });
}

class _ShootingStar {
  double x;
  double y;
  final double vx;
  final double vy;
  double life;
  final double maxLife;
  final double length;

  _ShootingStar({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.length,
  }) : maxLife = life;
}