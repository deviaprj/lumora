import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

/// État d'un filament.
enum FilamentState {
  drawing,
  connected,
  broken,
}

/// Filament lumineux entre deux nœuds — courbe de Bézier avec glow néon,
/// animation de révélation progressive, trail de particules et effet électrique.
class FilamentComponent extends PositionComponent {
  Vector2 startPos;
  Vector2 endPos;

  FilamentState state;
  double _revealProgress = 0.0;
  double _breakAnimation = 0.0;
  double _glowPhase = 0.0;
  final Color color;

  // Points de contrôle Bézier — calculés dynamiquement
  Offset _control1 = Offset.zero;
  Offset _control2 = Offset.zero;

  // Trail de particules lumineuses le long du filament
  final List<_TrailParticle> _trail = [];
  double _trailTimer = 0.0;
  static const double _trailSpawnInterval = 0.08;
  static const int _maxTrailParticles = 15;

  // Variation d'épaisseur (effet électrique)
  double _thicknessNoise = 0.0;

  FilamentComponent({
    required this.startPos,
    required this.endPos,
    this.state = FilamentState.drawing,
    this.color = const Color(0xFF00F5A0),
  }) {
    _updateBounds();
    _computeControlPoints();
  }

  void _updateBounds() {
    final left = min(startPos.x, endPos.x) - 40;
    final top = min(startPos.y, endPos.y) - 40;
    final right = max(startPos.x, endPos.x) + 40;
    final bottom = max(startPos.y, endPos.y) + 40;
    position = Vector2(left, top);
    size = Vector2(right - left, bottom - top);
  }

  /// Calcule les points de contrôle pour une courbe de Bézier cubique organique.
  void _computeControlPoints() {
    final dx = endPos.x - startPos.x;
    final dy = endPos.y - startPos.y;
    final dist = sqrt(dx * dx + dy * dy);

    // Perpendiculaire pour créer la courbure
    final perpX = -dy;
    final perpY = dx;
    final norm = sqrt(perpX * perpX + perpY * perpY);
    final normalizedPerpX = norm > 0 ? perpX / norm : 0;
    final normalizedPerpY = norm > 0 ? perpY / norm : 0;

    // Courbure proportionnelle à la distance, avec variation
    final curvature = dist * 0.2;

    _control1 = Offset(
      startPos.x + dx * 0.33 + normalizedPerpX * curvature * 0.8,
      startPos.y + dy * 0.33 + normalizedPerpY * curvature * 0.8,
    );
    _control2 = Offset(
      startPos.x + dx * 0.66 - normalizedPerpX * curvature * 0.6,
      startPos.y + dy * 0.66 - normalizedPerpY * curvature * 0.6,
    );
  }

  Offset get _startLocal => Offset(startPos.x - position.x, startPos.y - position.y);

  Offset get _endLocal => Offset(endPos.x - position.x, endPos.y - position.y);

  Offset get _c1Local => Offset(_control1.dx - position.x, _control1.dy - position.y);

  Offset get _c2Local => Offset(_control2.dx - position.x, _control2.dy - position.y);

  /// Point interpolé sur la courbe de Bézier cubique à la position t.
  Offset _bezierPoint(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
    final mt = 1.0 - t;
    return Offset(
      mt * mt * mt * p0.dx + 3 * mt * mt * t * p1.dx + 3 * mt * t * t * p2.dx + t * t * t * p3.dx,
      mt * mt * mt * p0.dy + 3 * mt * mt * t * p1.dy + 3 * mt * t * t * p2.dy + t * t * t * p3.dy,
    );
  }

  void markConnected() {
    state = FilamentState.connected;
    _revealProgress = 1.0;
  }

  void markBroken() {
    state = FilamentState.broken;
    _breakAnimation = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _glowPhase += dt;

    // Variation d'épaisseur électrique (noise 1D)
    _thicknessNoise = sin(_glowPhase * 8.0) * 0.3 + sin(_glowPhase * 13.0) * 0.1;

    switch (state) {
      case FilamentState.drawing:
        _revealProgress = (_revealProgress + dt * 4.0).clamp(0.0, 1.0);
      case FilamentState.connected:
        _revealProgress = 1.0;
        // Trail de particules
        _trailTimer += dt;
        if (_trailTimer >= _trailSpawnInterval && _trail.length < _maxTrailParticles) {
          _trailTimer = 0.0;
          final t = Random().nextDouble();
          final point = _bezierPoint(
            t,
            _startLocal,
            _c1Local,
            _c2Local,
            _endLocal,
          );
          _trail.add(_TrailParticle(
            x: point.dx,
            y: point.dy,
            life: 0.6 + Random().nextDouble() * 0.4,
            radius: 1.5 + Random().nextDouble() * 2.0,
            vx: (Random().nextDouble() - 0.5) * 15,
            vy: (Random().nextDouble() - 0.5) * 15,
          ));
        }
        // Mise à jour des particules du trail
        _trail.removeWhere((p) {
          p.life -= dt;
          p.x += p.vx * dt;
          p.y += p.vy * dt;
          return p.life <= 0;
        });
      case FilamentState.broken:
        _breakAnimation += dt;
        if (_breakAnimation > 0.8) {
          removeFromParent();
        }
    }

    // Recalculer les points de contrôle si positions changent
    _computeControlPoints();
  }

  @override
  void render(Canvas canvas) {
    final start = _startLocal;
    final end = state == FilamentState.drawing ? _bezierPoint(_revealProgress, _startLocal, _c1Local, _c2Local, _endLocal) : _endLocal;
    final c1 = _c1Local;
    // Ajuster c2 pour le reveal progress
    final c2 = _c2Local;

    if (state == FilamentState.broken) {
      _renderBrokenFilament(canvas);
      return;
    }

    // Créer le path Bézier
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Bézier cubique — si on est en mode drawing, on tronque le path
    if (state == FilamentState.drawing && _revealProgress < 1.0) {
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    } else {
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    }

    final glowIntensity = 0.6 + 0.4 * sin(_glowPhase * 2.5);
    final thicknessVariation = 1.0 + _thicknessNoise * 0.15;

    // ── Couche 1 : Glow externe large ──
    final glowPaint = Paint()
      ..color = color.withAlpha((50 * glowIntensity).toInt().clamp(0, 255))
      ..strokeWidth = (14 * thicknessVariation)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glowPaint);

    // ── Couche 2 : Glow moyen ──
    final midGlowPaint = Paint()
      ..color = color.withAlpha((100 * glowIntensity).toInt().clamp(0, 255))
      ..strokeWidth = (6 * thicknessVariation)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, midGlowPaint);

    // ── Couche 3 : Filament principal ──
    final linePaint = Paint()
      ..color = color.withAlpha((220 * glowIntensity).toInt().clamp(0, 255))
      ..strokeWidth = (3.0 * thicknessVariation).clamp(2.0, 5.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // ── Couche 4 : Ligne blanche centrale (effet néon) ──
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha((150 * glowIntensity).toInt().clamp(0, 255))
      ..strokeWidth = (1.5 * thicknessVariation).clamp(1.0, 2.5)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, corePaint);

    // ── Particules du trail (mode connecté uniquement) ──
    for (final p in _trail) {
      final alpha = (255 * (p.life / p.maxLife)).toInt().clamp(0, 255);
      final trailPaint = Paint()
        ..color = color.withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(p.x, p.y), p.radius * (p.life / p.maxLife), trailPaint);
    }
  }

  void _renderBrokenFilament(Canvas canvas) {
    final start = _startLocal;
    final end = _endLocal;
    final progress = _breakAnimation / 0.8;
    final alpha = (255 * (1 - progress)).toInt().clamp(0, 255);
    final fragmentCount = 5;

    final c1 = _c1Local;
    final c2 = _c2Local;

    for (var i = 0; i < fragmentCount; i++) {
      if ((i / fragmentCount) < progress * 1.5) continue;

      // Points de Bézier pour chaque fragment
      final t0 = i / fragmentCount;
      final t1 = (i + 0.7) / fragmentCount;
      final p0 = _bezierPoint(t0, start, c1, c2, end);
      final p1 = _bezierPoint(t1, start, c1, c2, end);

      // Déplacement du fragment (dispersion)
      final offsetX = progress * 12 * (i.isEven ? 1 : -1);
      final offsetY = progress * 18 * (i.isOdd ? 1 : -1);

      final fragStart = Offset(p0.dx + offsetX, p0.dy + offsetY);
      final fragEnd = Offset(p1.dx + offsetX, p1.dy + offsetY);

      // Glow du fragment
      final glowPaint = Paint()
        ..color = color.withAlpha((alpha * 0.4).toInt().clamp(0, 255))
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawLine(fragStart, fragEnd, glowPaint);

      // Fragment principal
      final fragPaint = Paint()
        ..color = color.withAlpha(alpha)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(fragStart, fragEnd, fragPaint);

      // Fragment blanc (noyau)
      final fragCore = Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha((alpha * 0.5).toInt().clamp(0, 255))
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(fragStart, fragEnd, fragCore);
    }
  }

  void updateEndPos(Vector2 newPos) {
    endPos = newPos.clone();
    _updateBounds();
    _computeControlPoints();
  }
}

/// Particule de trail le long du filament.
class _TrailParticle {
  double x;
  double y;
  double life;
  final double maxLife;
  final double radius;
  final double vx;
  final double vy;

  _TrailParticle({
    required this.x,
    required this.y,
    required this.life,
    required this.radius,
    required this.vx,
    required this.vy,
  }) : maxLife = life;
}