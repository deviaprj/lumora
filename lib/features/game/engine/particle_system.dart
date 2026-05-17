import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart' hide ParticleSystemComponent;
import '../../../app/theme.dart';

/// Types d'effets de particules disponibles.
enum ParticleEffectType {
  starDust,
  connectionBurst,
  victoryCascade,
  comboSpiral,
  nodeRipple,
  errorScatter,
}

/// Particle individuelle — recyclée via object pooling.
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;
  double radius;
  Color color;
  double alpha;
  double rotation;
  double rotationSpeed;
  double gravity;
  double drag;

  bool get isDead => life <= 0;

  _Particle()
      : x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        life = 0,
        maxLife = 1,
        radius = 2,
        color = const Color(0xFFFFFFFF),
        alpha = 1,
        rotation = 0,
        rotationSpeed = 0,
        gravity = 0,
        drag = 0.98;

  void reset() {
    x = 0;
    y = 0;
    vx = 0;
    vy = 0;
    life = 0;
    maxLife = 1;
    radius = 2;
    color = const Color(0xFFFFFFFF);
    alpha = 1;
    rotation = 0;
    rotationSpeed = 0;
    gravity = 0;
    drag = 0.98;
  }
}

/// Pool de particules recyclées pour performances.
class _ParticlePool {
  final List<_Particle> _pool = [];
  final List<_Particle> _active = [];

  _Particle get() {
    final p = _pool.isNotEmpty ? _pool.removeLast() : _Particle();
    _active.add(p);
    return p;
  }

  void release(_Particle p) {
    p.reset();
    _active.remove(p);
    _pool.add(p);
  }

  List<_Particle> get active => _active;

  void releaseAll() {
    for (final p in _active) {
      p.reset();
      _pool.add(p);
    }
    _active.clear();
  }

  int get activeCount => _active.length;
}

/// Système de particules Flame — effets visuels pour connexions, victoires, combos.
/// Pooling avec max 300 particules actives simultanément.
class ParticleSystemComponent extends Component {
  final _ParticlePool _pool = _ParticlePool();
  final int _maxParticles = 300;
  double _time = 0;
  double _canvasWidth = 400;
  double _canvasHeight = 800;

  // Poussières d'étoiles ambiantes
  final List<_AmbientStar> _ambientStars = [];
  bool _ambientEnabled = true;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _canvasWidth = size.x;
    _canvasHeight = size.y;
  }

  @override
  void onLoad() {
    // Utiliser une taille par défaut si le jeu n'est pas encore prêt
    _generateAmbientStars();
  }

  void _generateAmbientStars() {
    final rng = Random(7);
    final w = _canvasWidth;
    final h = _canvasHeight;

    for (var i = 0; i < 40; i++) {
      _ambientStars.add(_AmbientStar(
        x: rng.nextDouble() * w,
        y: rng.nextDouble() * h,
        radius: 0.5 + rng.nextDouble() * 1.5,
        alpha: 40 + rng.nextInt(80),
        speed: 0.3 + rng.nextDouble() * 0.8,
        phase: rng.nextDouble() * 6.28,
      ));
    }
  }

  /// Burst radial pour connexion valide de nœud.
  void emitConnectionBurst(Vector2 position, {Color? color}) {
    final c = color ?? LumoraColors.auroraGold;
    final count = 20;
    for (var i = 0; i < count; i++) {
      if (_pool.activeCount >= _maxParticles) break;
      final angle = (i / count) * 2 * pi + Random().nextDouble() * 0.3;
      final speed = 60 + Random().nextDouble() * 120;
      final p = _pool.get();
      p.x = position.x;
      p.y = position.y;
      p.vx = cos(angle) * speed;
      p.vy = sin(angle) * speed;
      p.life = 0.4 + Random().nextDouble() * 0.4;
      p.maxLife = p.life;
      p.radius = 2 + Random().nextDouble() * 3;
      p.color = c;
      p.gravity = 30;
      p.drag = 0.95;
    }
  }

  /// Cascade dorée pour victoire.
  void emitVictoryCascade(Vector2 center, double canvasWidth) {
    final count = 40;
    for (var i = 0; i < count; i++) {
      if (_pool.activeCount >= _maxParticles) break;
      final p = _pool.get();
      p.x = center.x - canvasWidth / 2 + Random().nextDouble() * canvasWidth;
      p.y = center.y - 400 + Random().nextDouble() * 100;
      p.vx = (Random().nextDouble() - 0.5) * 40;
      p.vy = 30 + Random().nextDouble() * 80;
      p.life = 1.5 + Random().nextDouble() * 1.0;
      p.maxLife = p.life;
      p.radius = 2 + Random().nextDouble() * 4;
      p.color = Random().nextBool() ? LumoraColors.auroraGold : LumoraColors.auroraOrange;
      p.gravity = 60;
      p.drag = 0.99;
    }
  }

  /// Spirale ascendante pour combo x3+.
  void emitComboSpiral(Vector2 position, {int combo = 3}) {
    final count = 15 + combo * 5;
    for (var i = 0; i < count; i++) {
      if (_pool.activeCount >= _maxParticles) break;
      final angle = (i / count) * 4 * pi;
      final radius = 5.0 + (i / count) * 40;
      final p = _pool.get();
      p.x = position.x + cos(angle) * radius;
      p.y = position.y + sin(angle) * radius;
      p.vx = cos(angle) * 30;
      p.vy = -60 - Random().nextDouble() * 40;
      p.life = 0.8 + Random().nextDouble() * 0.6;
      p.maxLife = p.life;
      p.radius = 2 + Random().nextDouble() * 3;
      p.color = LumoraColors.auroraGold;
      p.gravity = -20;
      p.drag = 0.96;
    }
  }

  /// Anneau d'ondulation pour activation de nœud.
  void emitNodeRipple(Vector2 position, {Color? color}) {
    final c = color ?? LumoraColors.auroraGreen;
    final count = 12;
    for (var i = 0; i < count; i++) {
      if (_pool.activeCount >= _maxParticles) break;
      final angle = (i / count) * 2 * pi;
      final p = _pool.get();
      p.x = position.x;
      p.y = position.y;
      p.vx = cos(angle) * 80;
      p.vy = sin(angle) * 80;
      p.life = 0.5;
      p.maxLife = 0.5;
      p.radius = 3;
      p.color = c;
      p.gravity = 0;
      p.drag = 0.92;
    }
  }

  /// Éparpillement pour connexion invalide.
  void emitErrorScatter(Vector2 position) {
    final count = 10;
    for (var i = 0; i < count; i++) {
      if (_pool.activeCount >= _maxParticles) break;
      final angle = Random().nextDouble() * 2 * pi;
      final speed = 30 + Random().nextDouble() * 60;
      final p = _pool.get();
      p.x = position.x;
      p.y = position.y;
      p.vx = cos(angle) * speed;
      p.vy = sin(angle) * speed;
      p.life = 0.3 + Random().nextDouble() * 0.3;
      p.maxLife = p.life;
      p.radius = 1.5 + Random().nextDouble() * 2;
      p.color = LumoraColors.errorRose;
      p.gravity = 40;
      p.drag = 0.94;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final toRemove = <_Particle>[];
    for (final p in _pool.active) {
      p.life -= dt;
      if (p.isDead) {
        toRemove.add(p);
        continue;
      }

      p.vy += p.gravity * dt;
      p.vx *= p.drag;
      p.vy *= p.drag;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      p.rotation += p.rotationSpeed * dt;
    }

    for (final p in toRemove) {
      _pool.release(p);
    }
  }

  @override
  void render(Canvas canvas) {
    // Particules ambiantes (poussières d'étoiles)
    if (_ambientEnabled) {
      for (final star in _ambientStars) {
        final twinkle = 0.4 + 0.6 * sin(_time * star.speed + star.phase);
        final alpha = (star.alpha * twinkle).toInt().clamp(30, 200);
        final paint = Paint()
          ..color = Color.fromARGB(alpha, 255, 255, 240)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
        canvas.drawCircle(Offset(star.x, star.y), star.radius * twinkle, paint);
      }
    }

    // Particules actives
    for (final p in _pool.active) {
      final alphaVal = (p.alpha * 255).toInt().clamp(0, 255);
      final paint = Paint()
        ..color = p.color.withAlpha(alphaVal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      if (p.radius >= 3) {
        // Grosses particules avec glow
        final glowPaint = Paint()
          ..color = p.color.withAlpha((alphaVal * 0.3).toInt().clamp(0, 255))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(p.x, p.y), p.radius * 2.5, glowPaint);
      }

      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  void setAmbientEnabled(bool enabled) {
    _ambientEnabled = enabled;
  }

  void clearAll() {
    _pool.releaseAll();
  }
}

class _AmbientStar {
  final double x;
  final double y;
  final double radius;
  final int alpha;
  final double speed;
  final double phase;

  _AmbientStar({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    required this.speed,
    required this.phase,
  });
}