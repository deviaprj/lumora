import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/painting.dart' show RadialGradient;
import '../../../app/theme.dart';

/// Orbe Lumie — composant avec glow pulsant, trail lumineux amélioré,
/// snap-to avec spring physics et oscillation verticale idle.
/// L'interaction drag est gérée au niveau du LumoraGame.
class LumieComponent extends PositionComponent {
  double _pulseTime = 0.0;
  final List<_TrailPoint> _trail = [];
  static const int _maxTrailPoints = 30;

  final double baseRadius;

  // Spring physics pour snap-to
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  double _targetX = 0.0;
  double _targetY = 0.0;
  bool _isSnapping = false;

  // Idle oscillation
  double _idleOffsetY = 0.0;
  double _idlePhase = 0.0;

  // Breathing effect (scale + rotation lente)
  double _breatheScale = 1.0;

  LumieComponent({
    required Vector2 initialPosition,
    this.baseRadius = 20.0,
  }) {
    position = initialPosition;
    _targetX = initialPosition.x;
    _targetY = initialPosition.y;
    anchor = Anchor.center;
    size = Vector2(baseRadius * 10, baseRadius * 10);
    _idlePhase = Random().nextDouble() * 6.28;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;

    // Idle oscillation verticale
    _idleOffsetY = sin(_pulseTime * 1.2 + _idlePhase) * 3.0;

    // Breathing effect
    _breatheScale = 1.0 + 0.03 * sin(_pulseTime * 1.8);

    // Spring physics pour snap-to
    if (_isSnapping) {
      final stiffness = 300.0;
      final damping = 15.0;

      final dx = _targetX - position.x;
      final dy = _targetY - position.y;

      _velocityX += (stiffness * dx - damping * _velocityX) * dt;
      _velocityY += (stiffness * dy - damping * _velocityY) * dt;

      position.x += _velocityX * dt;
      position.y += _velocityY * dt;

      // Arrêter le snap quand on est assez proche et lent
      if (dx.abs() < 0.5 && dy.abs() < 0.5 &&
          _velocityX.abs() < 5 && _velocityY.abs() < 5) {
        _isSnapping = false;
        _velocityX = 0;
        _velocityY = 0;
      }
    }

    // Atténuation du trail — supprimer les points anciens
    _trail.removeWhere((p) {
      p.age += dt;
      return p.age > p.maxAge;
    });
  }

  @override
  void render(Canvas canvas) {
    // Centrer le dessin — anchor=center place Offset.zero au coin top-left
    // de la bounding box. On translate au centre pour que
    // Offset.zero = centre de la Lumie = position dans les coords jeu.
    canvas.translate(size.x / 2, size.y / 2);

    final pulseScale = 1.0 + 0.12 * sin(_pulseTime * 2.5);
    final effectiveRadius = baseRadius * pulseScale * _breatheScale;

    // Décalage idle
    canvas.translate(0, _idleOffsetY);

    // ── Trail lumineux (gradient fade) ──
    _renderTrail(canvas, effectiveRadius);

    // ── Halo externe (grand glow diffus, 4x rayon) ──
    final outerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          LumoraColors.auroraGreen.withAlpha(50),
          LumoraColors.auroraBlue.withAlpha(25),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: effectiveRadius * 4));
    canvas.drawCircle(Offset.zero, effectiveRadius * 4, outerGlow);

    // ── Glow moyen (2.2x rayon) ──
    final midGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          LumoraColors.auroraGreen.withAlpha(120),
          LumoraColors.auroraBlue.withAlpha(50),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: effectiveRadius * 2.2));
    canvas.drawCircle(Offset.zero, effectiveRadius * 2.2, midGlow);

    // ── Corps principal (dégradé blanc → vert → bleu) ──
    final bodyOffset = Offset(effectiveRadius * -0.2, effectiveRadius * -0.3);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF),
          LumoraColors.auroraGreen,
          LumoraColors.auroraBlue,
          LumoraColors.auroraBlue.withAlpha(180),
        ],
      ).createShader(Rect.fromCircle(center: bodyOffset, radius: effectiveRadius * 1.2));
    canvas.drawCircle(Offset.zero, effectiveRadius, bodyPaint);

    // ── Spécular highlight (reflet dynamique) ──
    final specAngle = -0.78;
    final specX = cos(specAngle) * effectiveRadius * 0.25;
    final specY = sin(specAngle) * effectiveRadius * 0.25;
    final specPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xAAFFFFFF),
          const Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(specX, specY),
        radius: effectiveRadius * 0.35,
      ));
    canvas.drawCircle(Offset(specX, specY), effectiveRadius * 0.35, specPaint);

    // ── Point central blanc lumineux ──
    final corePaint = Paint()..color = const Color(0xFFFFFFFF).withAlpha(240);
    canvas.drawCircle(Offset.zero, effectiveRadius * 0.25, corePaint);
  }

  void _renderTrail(Canvas canvas, double effectiveRadius) {
    if (_trail.length < 2) return;

    // Trail gradient — chaque segment a un alpha qui décroît avec l'âge
    for (var i = 1; i < _trail.length; i++) {
      final current = _trail[i];
      final previous = _trail[i - 1];

      final progress = 1.0 - (current.age / current.maxAge);
      final alpha = (120 * progress).toInt().clamp(0, 255);
      final strokeWidth = (4.0 * progress).clamp(1.0, 5.0);

      final from = Offset(
        previous.x - position.x,
        previous.y - position.y - _idleOffsetY,
      );
      final to = Offset(
        current.x - position.x,
        current.y - position.y - _idleOffsetY,
      );

      // Glow du trail
      final trailGlow = Paint()
        ..color = LumoraColors.auroraGreen.withAlpha((alpha * 0.3).toInt().clamp(0, 255))
        ..strokeWidth = strokeWidth * 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(from, to, trailGlow);

      // Trail principal
      final trailPaint = Paint()
        ..color = LumoraColors.auroraGreen.withAlpha(alpha)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, trailPaint);
    }
  }

  /// Ajoute un point au trail (appelé par le game lors du drag ou du snap).
  void addTrailPoint() {
    _trail.add(_TrailPoint(
      x: position.x,
      y: position.y,
      age: 0.0,
      maxAge: 0.5 + Random().nextDouble() * 0.3,
    ));
    if (_trail.length > _maxTrailPoints) {
      _trail.removeAt(0);
    }
  }

  /// Snap vers une position cible avec spring physics.
  void snapTo(Vector2 target) {
    _targetX = target.x;
    _targetY = target.y;
    _isSnapping = true;
    _velocityX = 0;
    _velocityY = 0;
  }

  /// Réinitialise la Lumie.
  void reset(Vector2 initialPosition) {
    position = initialPosition;
    _targetX = initialPosition.x;
    _targetY = initialPosition.y;
    _trail.clear();
    _pulseTime = 0.0;
    _isSnapping = false;
    _velocityX = 0;
    _velocityY = 0;
  }
}

class _TrailPoint {
  final double x;
  final double y;
  double age;
  final double maxAge;

  _TrailPoint({
    required this.x,
    required this.y,
    required this.age,
    required this.maxAge,
  });
}