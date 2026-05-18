import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/painting.dart' show RadialGradient, Alignment;
import '../../../app/theme.dart';

/// États visuels d'un nœud d'énergie.
enum NodeState {
  dormant,
  activated,
  connected,
  target,
}

/// Nœud d'énergie interactif — dessin 100% procédural (Canvas).
/// Animations enrichies : oscillation idle, bounce d'activation,
/// rotation 360° à la connexion, ripple ring, glow pulsant.
/// L'interaction tactile est gérée au niveau du LumoraGame.
class EnergyNode extends PositionComponent {
  final int nodeIndex;
  NodeState state;
  final double radius;

  double _pulseTime = 0.0;

  // Animation de transition d'état
  double _scaleAnimation = 1.0;
  double _targetScale = 1.0;
  double _rotationAngle = 0.0;
  double _glowIntensity = 1.0;
  double _targetGlowIntensity = 1.0;

  // Ripple effect
  double _rippleProgress = -1.0; // -1 = pas de ripple
  Color _rippleColor = LumoraColors.auroraGreen;

  // Spécular highlight — position fixe en haut-droite
  double _specularAngle = -0.78; // ~-45°

  // Idle oscillation
  double _idleOffsetY = 0.0;
  double _idlePhase = 0.0;
  double _orbitPhase = 0.0;

  // Bounce d'activation
  double _bounceProgress = -1.0; // -1 = pas de bounce

  // Flash de connexion
  double _flashProgress = -1.0;

  EnergyNode({
    required this.nodeIndex,
    required Vector2 position,
    this.state = NodeState.dormant,
    this.radius = 18.0,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2(radius * 8, radius * 8);
    // Phase aléatoire pour déphaser les oscillations
    _idlePhase = Random().nextDouble() * 6.28;
  }

  Color get _coreColor {
    switch (state) {
      case NodeState.dormant:
        return const Color(0xFF4A4A6A);
      case NodeState.activated:
        return LumoraColors.auroraGreen;
      case NodeState.connected:
        return LumoraColors.auroraGold;
      case NodeState.target:
        return LumoraColors.waitOrange;
    }
  }

  Color get _haloColor {
    switch (state) {
      case NodeState.dormant:
        return const Color(0x224A4A6A);
      case NodeState.activated:
        return LumoraColors.auroraGreen.withAlpha(80);
      case NodeState.connected:
        return LumoraColors.auroraGold.withAlpha(100);
      case NodeState.target:
        return LumoraColors.waitOrange.withAlpha(80);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;

    // Idle oscillation verticale (sin wave)
    _idleOffsetY = sin(_pulseTime * 1.5 + _idlePhase) * 2.0;
    _orbitPhase += dt * (0.8 + _glowIntensity * 0.2);

    // Animation de scale (spring amorti)
    _scaleAnimation += (_targetScale - _scaleAnimation) * min(dt * 12, 1.0);

    // Intensité du glow (transition douce)
    _glowIntensity += (_targetGlowIntensity - _glowIntensity) * min(dt * 6, 1.0);

    // Ripple
    if (_rippleProgress >= 0) {
      _rippleProgress += dt * 2.5;
      if (_rippleProgress > 1.0) {
        _rippleProgress = -1.0;
      }
    }

    // Bounce d'activation
    if (_bounceProgress >= 0) {
      _bounceProgress += dt * 4.0;
      if (_bounceProgress > 1.0) {
        _bounceProgress = -1.0;
      }
    }

    // Flash de connexion
    if (_flashProgress >= 0) {
      _flashProgress += dt * 3.0;
      if (_flashProgress > 1.0) {
        _flashProgress = -1.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Centrer le dessin — anchor=center place Offset.zero au coin top-left
    // de la bounding box, pas au centre. On translate au centre pour que
    // Offset.zero = centre du nœud = position dans les coordonnées jeu.
    canvas.translate(size.x / 2, size.y / 2);

    final pulseScale = 1.0 + 0.08 * sin(_pulseTime * 3.0);
    var effectiveRadius = radius * pulseScale * _scaleAnimation;

    // Bounce d'activation — overshoot puis stabilisation
    if (_bounceProgress >= 0) {
      final t = _bounceProgress;
      final bounce = 1.0 + 0.3 * sin(t * pi) * (1.0 - t);
      effectiveRadius *= bounce;
    }

    // Décalage idle
    canvas.translate(0, _idleOffsetY);

    // Rotation pour l'effet connected
    if (_rotationAngle > 0) {
      canvas.rotate(_rotationAngle);
    }

    // ── Ripple ring (ondulation circulaire) ──
    if (_rippleProgress >= 0) {
      final rippleRadius = effectiveRadius * (1.5 + _rippleProgress * 3.0);
      final rippleAlpha = (255 * (1.0 - _rippleProgress)).toInt().clamp(0, 200);
      final ripplePaint = Paint()
        ..color = _rippleColor.withAlpha(rippleAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - _rippleProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset.zero, rippleRadius, ripplePaint);

      // Deuxième anneau plus subtil
      if (_rippleProgress < 0.7) {
        final ripple2Radius = effectiveRadius * (1.5 + _rippleProgress * 2.0);
        final ripple2Alpha = (150 * (1.0 - _rippleProgress / 0.7)).toInt().clamp(0, 150);
        final ripple2Paint = Paint()
          ..color = _rippleColor.withAlpha(ripple2Alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1.0 - _rippleProgress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset.zero, ripple2Radius, ripple2Paint);
      }
    }

    // ── Flash de connexion (blanc qui fade) ──
    if (_flashProgress >= 0) {
      final flashAlpha = (255 * (1.0 - _flashProgress) * 0.6).toInt().clamp(0, 255);
      final flashPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha(flashAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset.zero, effectiveRadius * (1.5 + _flashProgress * 2.0), flashPaint);
    }

    // ── Halo externe (blur, pulsant) ──
    final glowMultiplier = _glowIntensity;
    final haloRadius = effectiveRadius * 2.8;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _haloColor.withAlpha((_haloColor.alpha * glowMultiplier * 1.2).toInt().clamp(0, 255)),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: haloRadius));
    canvas.drawCircle(Offset.zero, haloRadius, haloPaint);

      final chromaHaloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            _coreColor.withAlpha((70 * glowMultiplier).toInt().clamp(0, 255)),
            const Color(0xFFFFFFFF).withAlpha((25 * glowMultiplier).toInt().clamp(0, 255)),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: effectiveRadius * 3.4));
      canvas.drawCircle(Offset.zero, effectiveRadius * 3.4, chromaHaloPaint);

      // ── Anneaux orbitaux lumineux ──
      final orbitPaint = Paint()
        ..color = _coreColor.withAlpha((120 * glowMultiplier).toInt().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.save();
      canvas.rotate(_orbitPhase * 0.8);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: effectiveRadius * 1.45),
        0.0,
        1.9,
        false,
        orbitPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: effectiveRadius * 1.8),
        pi,
        1.3,
        false,
        orbitPaint,
      );
      canvas.restore();

      // ── Étincelles orbitales ──
      for (var index = 0; index < 3; index++) {
        final sparkAngle = _orbitPhase * (index.isEven ? 1.4 : -1.2) + index * 2.1;
        final sparkRadius = effectiveRadius * (1.4 + index * 0.22);
        final sparkOffset = Offset(
          cos(sparkAngle) * sparkRadius,
          sin(sparkAngle) * sparkRadius,
        );
        final sparkPaint = Paint()
          ..color = const Color(0xFFFFFFFF).withAlpha((150 - index * 30).clamp(0, 255))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(sparkOffset, effectiveRadius * (0.08 + index * 0.03), sparkPaint);
      }

    // ── Glow interne (multi-couche) ──
    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _coreColor.withAlpha((200 * glowMultiplier).toInt().clamp(0, 255)),
          _coreColor.withAlpha((80 * glowMultiplier).toInt().clamp(0, 255)),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: effectiveRadius * 2.0));
    canvas.drawCircle(Offset.zero, effectiveRadius * 2.0, innerGlowPaint);

    // ── Corps du nœud (dégradé radial avec offset pour effet 3D) ──
    final coreOffset = Offset(effectiveRadius * -0.3, effectiveRadius * -0.3);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF),
          _coreColor,
          _coreColor.withAlpha(200),
        ],
      ).createShader(Rect.fromCircle(center: coreOffset, radius: effectiveRadius * 1.2));
    canvas.drawCircle(Offset.zero, effectiveRadius, corePaint);

    // ── Specular highlight (reflet dynamique) ──
    final specX = cos(_specularAngle) * effectiveRadius * 0.3;
    final specY = sin(_specularAngle) * effectiveRadius * 0.3;
    final specCenter = Offset(specX, specY);
    final specRadius = effectiveRadius * 0.4;
    final specPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x88FFFFFF),
          const Color(0x00FFFFFF),
        ],
        center: Alignment(
          specCenter.dx / (effectiveRadius * 2),
          specCenter.dy / (effectiveRadius * 2),
        ),
        radius: 0.4,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: effectiveRadius));
    canvas.drawCircle(specCenter, specRadius, specPaint);

    // ── Point central blanc lumineux ──
    final dotPaint = Paint()..color = const Color(0xFFFFFFFF).withAlpha(230);
    canvas.drawCircle(Offset.zero, effectiveRadius * 0.25, dotPaint);
  }

  /// Vérifie si un point est dans la zone de tap du nœud.
  @override
  bool containsPoint(Vector2 point) {
    return point.distanceTo(position) < radius * 3;
  }

  void activate() {
    state = NodeState.activated;
    _targetScale = 1.15;
    _targetGlowIntensity = 1.5;
    _bounceProgress = 0.0;
    _rippleProgress = 0.0;
    _rippleColor = LumoraColors.auroraGreen;
    // Retour à la taille normale après le bounce
    Future.delayed(const Duration(milliseconds: 300), () {
      _targetScale = 1.0;
    });
  }

  void markConnected() {
    state = NodeState.connected;
    _targetScale = 1.2;
    _targetGlowIntensity = 2.0;
    _flashProgress = 0.0;
    _rippleProgress = 0.0;
    _rippleColor = LumoraColors.auroraGold;
    // Rotation douce
    _rotationAngle = 0;
    // Retour progressif
    Future.delayed(const Duration(milliseconds: 500), () {
      _targetScale = 1.05;
      _targetGlowIntensity = 1.3;
    });
  }

  void markTarget() {
    state = NodeState.target;
    _targetGlowIntensity = 1.2;
  }

  void reset() {
    state = NodeState.dormant;
    _pulseTime = 0.0;
    _scaleAnimation = 1.0;
    _targetScale = 1.0;
    _glowIntensity = 1.0;
    _targetGlowIntensity = 1.0;
    _rotationAngle = 0.0;
    _orbitPhase = 0.0;
    _rippleProgress = -1.0;
    _bounceProgress = -1.0;
    _flashProgress = -1.0;
  }
}