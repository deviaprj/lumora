import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart' hide ParticleSystemComponent;
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Gradient;
import '../../../app/theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/audio/sound_manager.dart';
import '../domain/level_data.dart';
import 'energy_node.dart';
import 'filament_component.dart';
import 'game_state.dart';
import 'lumie_component.dart';
import 'particle_system.dart';
import 'procedural_background.dart';

/// LumoraGame — moteur de jeu Flame complet.
class LumoraGame extends FlameGame
    with MultiTouchTapDetector, MultiTouchDragDetector, ScaleDetector {
  final GameState gameState;
  LevelData levelData;

  // Composants du jeu
  final List<EnergyNode> _nodes = [];
  final List<FilamentComponent> _filaments = [];
  late LumieComponent _lumie;
  late ParticleSystemComponent _particles;
  ProceduralBackground? _background;

  // État du swipe — un seul drag actif à la fois
  int? _activePointerId;
  EnergyNode? _swipeStartNode;
  Vector2? _swipeCurrentPos;
  FilamentComponent? _swipeFilament;

  // Combo tracking
  int _comboCount = 0;
  double _comboTimer = 0.0;
  static const double _comboWindow = 3.0;

  // Pinch zoom
  double _baseZoom = 1.0;
  double _currentZoom = 1.0;

  // Audio
  final SoundManager _sound = SoundManager();

  // Suivi pour détecter les pertes de vie (comparison frame-à-frame)
  int _trackedLives = 3;

  // Callbacks vers l'UI Flutter
  VoidCallback? onVictory;
  VoidCallback? onDefeat;
  void Function(GameState state)? onStateChanged;

  /// Rayon de détection tactile — reduit pour limiter les accroches involontaires.
  static const double _hitRadiusMultiplier = 2.4;

  LumoraGame({required this.levelData, required this.gameState});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fond de jeu : parallax si images, sinon procédural
    try {
      final parallax = await loadParallaxComponent(
        [
          ParallaxImageData('parallax/stars.png'),
          ParallaxImageData('parallax/nebula.png'),
          ParallaxImageData('parallax/dust.png'),
        ],
        baseVelocity: Vector2(10, 0),
        velocityMultiplierDelta: Vector2(3, 0),
      );
      add(parallax);
    } catch (_) {
      _background = ProceduralBackground(worldId: levelData.worldId);
      add(_background!);
    }

    // Système de particules
    _particles = ParticleSystemComponent();
    add(_particles);

    // Connecter le listener du GameState
    gameState.addListener(_onGameStateChanged);

    // Charger les composants du niveau
    _loadLevel();

    // Initialiser l'audio
    await _sound.init();
    _sound.setWorld(levelData.worldId);
    _sound.startAmbientLoop();
    _trackedLives = gameState.lives;
    unawaited(_sound.playLevelStartSound());
  }

  // ─── Chargement / nettoyage des niveaux ───────────────────────────

  void _loadLevel() {
    // Nettoyage COMPLET : retirer TOUS les nœuds et filaments du jeu,
    // y compris ceux qui se sont auto-retirés (filaments cassés).
    children.whereType<EnergyNode>().toList().forEach(remove);
    children.whereType<FilamentComponent>().toList().forEach(remove);
    children.whereType<LumieComponent>().toList().forEach(remove);

    _nodes.clear();
    _filaments.clear();
    _activePointerId = null;
    _swipeStartNode = null;
    _swipeCurrentPos = null;
    _swipeFilament = null;
    _comboCount = 0;
    _comboTimer = 0.0;

    final canvasSize = size;
    final gameplayRect = _computeGameplayRect(canvasSize);

    // Générer des positions aléatoires pour les nœuds
    final randomPositions =
      _generateRandomPositions(levelData.nodes.length, gameplayRect);

    // Créer les nœuds d'énergie aux positions aléatoires
    for (var i = 0; i < levelData.nodes.length; i++) {
      final node = EnergyNode(
        nodeIndex: i,
        position: randomPositions[i],
      );
      _nodes.add(node);
      add(node);
    }

    // Marquer les nœuds cibles
    _markTargetNodes();

    // Créer la Lumie au centre
    _lumie = LumieComponent(
      initialPosition: Vector2(gameplayRect.center.dx, gameplayRect.center.dy),
    );
    add(_lumie);
  }

  /// Zone de jeu qui exclut les barres UI superieures et conserve
  /// une marge de confort en bas/cotes pour les interactions.
  Rect _computeGameplayRect(Vector2 canvasSize) {
    final sideInset = (canvasSize.x * 0.1).clamp(34.0, 74.0).toDouble();
    final topInset = (canvasSize.y * 0.28).clamp(170.0, 290.0).toDouble();
    final bottomInset = (canvasSize.y * 0.08).clamp(46.0, 96.0).toDouble();

    var left = sideInset;
    var top = topInset;
    var right = canvasSize.x - sideInset;
    var bottom = canvasSize.y - bottomInset;

    // Fallback pour petits ecrans: garantir une hauteur jouable minimale.
    const minPlayableHeight = 220.0;
    if (bottom - top < minPlayableHeight) {
      top = (canvasSize.y * 0.22).clamp(120.0, 220.0).toDouble();
      bottom = (canvasSize.y * 0.94).clamp(top + minPlayableHeight, canvasSize.y - 12).toDouble();
      left = (canvasSize.x * 0.08).clamp(24.0, 56.0).toDouble();
      right = (canvasSize.x - left).toDouble();
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Génère des positions semi-aléatoires: on garde la topologie du niveau
  /// (positions de base) puis on applique un léger jitter.
  List<Vector2> _generateRandomPositions(
    int count,
    Rect gameplayRect,
  ) {
    final positions = <Vector2>[];
    final margin = 30.0;
    final minDistance = 72.0;
    final maxAttempts = 80;
    final jitter = 36.0;
    final rng = Random();

    for (var i = 0; i < count; i++) {
      final normalized = levelData.nodes[i];
      final base = Vector2(
        gameplayRect.left + normalized.x * gameplayRect.width,
        gameplayRect.top + normalized.y * gameplayRect.height,
      );
      Vector2? pos;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final candidate = Vector2(
          (base.x + (rng.nextDouble() * 2 - 1) * jitter)
            .clamp(gameplayRect.left + margin, gameplayRect.right - margin),
          (base.y + (rng.nextDouble() * 2 - 1) * jitter)
            .clamp(gameplayRect.top + margin, gameplayRect.bottom - margin),
        );

        var tooClose = false;
        for (final existing in positions) {
          if (candidate.distanceTo(existing) < minDistance) {
            tooClose = true;
            break;
          }
        }

        if (!tooClose) {
          pos = candidate;
          break;
        }
      }

      positions.add(pos ?? base);
    }

    return positions;
  }

  /// Marque les nœuds qui sont des cibles de connexion.
  void _markTargetNodes() {
    final targetIndices = <int>{};
    for (final rc in levelData.requiredConnections) {
      if (_nodes[rc.from].state == NodeState.dormant) {
        targetIndices.add(rc.from);
      }
      if (_nodes[rc.to].state == NodeState.dormant) {
        targetIndices.add(rc.to);
      }
    }
    for (final idx in targetIndices) {
      if (_nodes[idx].state == NodeState.dormant) {
        _nodes[idx].markTarget();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Tick du timer
    if (gameState.status == GameStatus.playing) {
      final timeUp = gameState.tickTimer(dt);
      if (timeUp) {
        onDefeat?.call();
      }

      if (gameState.lives <= 0) {
        onDefeat?.call();
      }

      // Urgence sonore : tick-tock bombe sur les 10 dernières secondes
      if (gameState.maxTime > 0) {
        final secondsLeft = gameState.timerProgress * gameState.maxTime;
        _sound.updateTimerUrgency(1.0 - gameState.timerProgress,
            secondsRemaining: secondsLeft);
      }
    } else {
      // Hors jeu : stopper l'urgence
      _sound.updateTimerUrgency(0.0);
    }

    // Timer de combo
    if (_comboCount > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _comboCount = 0;
      }
    }
  }

  // ─── Tap Detection ─────────────────────────────────────────────────

  @override
  void onTapUp(int pointerId, TapUpInfo info) {
    if (gameState.status != GameStatus.playing) return;

    final tapPos = info.eventPosition.widget;

    for (final node in _nodes) {
      if (node.containsPoint(tapPos)) {
        _onNodeTapped(node);
        return;
      }
    }
  }

  void _onNodeTapped(EnergyNode node) {
    if (node.state == NodeState.dormant || node.state == NodeState.target) {
      node.activate();
      gameState.activateNode(node.nodeIndex);
      _markTargetNodes();

      _particles.emitNodeRipple(node.position, color: LumoraColors.auroraGreen);
      LumoraHaptics.nodeTap();
      _sound.playNodeNote('green');
    }
  }

  // ─── Drag Detection — un seul pointeur actif ──────────────────────

  void _cancelCurrentDrag() {
    if (_swipeFilament != null) {
      _swipeFilament!.markBroken();
      _filaments.add(_swipeFilament!);
    }
    _activePointerId = null;
    _swipeStartNode = null;
    _swipeCurrentPos = null;
    _swipeFilament = null;
  }

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    if (gameState.status != GameStatus.playing) return;

    // Si un drag est déjà en cours par un autre pointeur, l'annuler
    if (_activePointerId != null && _activePointerId != pointerId) {
      _cancelCurrentDrag();
    }

    final startPos = info.eventPosition.widget;

    // Trouver le nœud de départ le plus proche
    EnergyNode? closestNode;
    double closestDistance = double.infinity;

    for (final node in _nodes) {
      final distance = startPos.distanceTo(node.position);
      if (distance < node.radius * _hitRadiusMultiplier &&
          distance < closestDistance) {
        closestDistance = distance;
        closestNode = node;
      }
    }

    if (closestNode != null) {
      // Auto-activer les nœuds dormants/cibles
      if (closestNode.state == NodeState.dormant ||
          closestNode.state == NodeState.target) {
        closestNode.activate();
        gameState.activateNode(closestNode.nodeIndex);
        _markTargetNodes();
        _particles.emitNodeRipple(
          closestNode.position,
          color: LumoraColors.auroraGreen,
        );
        LumoraHaptics.nodeTap();
        _sound.playNodeNote('green');
      }

      _activePointerId = pointerId;
      _swipeStartNode = closestNode;
      _swipeCurrentPos = startPos;

      _swipeFilament = FilamentComponent(
        startPos: closestNode.position.clone(),
        endPos: startPos.clone(),
        state: FilamentState.drawing,
      );
      add(_swipeFilament!);
    }
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    if (pointerId != _activePointerId) return;
    if (_swipeStartNode == null || _swipeFilament == null) return;

    _swipeCurrentPos = info.eventPosition.widget;
    _swipeFilament!.updateEndPos(_swipeCurrentPos!);
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    if (pointerId != _activePointerId) return;
    if (_swipeStartNode == null || _swipeFilament == null) {
      _activePointerId = null;
      return;
    }

    final endPos = _swipeCurrentPos ?? _swipeStartNode!.position;

    // Trouver le nœud d'arrivée le plus proche
    EnergyNode? endNode;
    double closestDistance = double.infinity;

    for (final node in _nodes) {
      if (node == _swipeStartNode) continue;
      final distance = endPos.distanceTo(node.position);
      if (distance < node.radius * _hitRadiusMultiplier &&
          distance < closestDistance) {
        closestDistance = distance;
        endNode = node;
      }
    }

    if (endNode != null && endNode != _swipeStartNode) {
      final isValid = gameState.addConnection(
        _swipeStartNode!.nodeIndex,
        endNode.nodeIndex,
      );

      if (isValid) {
        remove(_swipeFilament!);
        final permanentFilament = FilamentComponent(
          startPos: _swipeStartNode!.position.clone(),
          endPos: endNode.position.clone(),
          state: FilamentState.connected,
          color: LumoraColors.auroraGold,
        );
        add(permanentFilament);
        _filaments.add(permanentFilament);

        _swipeStartNode!.markConnected();
        endNode.markConnected();

        _particles.emitConnectionBurst(
          (_swipeStartNode!.position + endNode.position) / 2,
          color: LumoraColors.auroraGold,
        );
        LumoraHaptics.connectionValid();
        _sound.playConnectionSound();

        // Combo
        _comboCount++;
        _comboTimer = _comboWindow;
        gameState.recordCombo(_comboCount);
        if (_comboCount >= 3) {
          _particles.emitComboSpiral(
            (_swipeStartNode!.position + endNode.position) / 2,
            combo: _comboCount,
          );
          LumoraHaptics.combo();
          _sound.playComboSound(_comboCount);
        }

        if (gameState.status == GameStatus.victory) {
          _particles.emitVictoryCascade(
            Vector2(size.x / 2, size.y / 2),
            size.x,
          );
          LumoraHaptics.victory();
          _sound.playVictorySound();
          onVictory?.call();
        }
      } else {
        final midPoint = (_swipeStartNode!.position + endNode.position) / 2;
        if (gameState.lastAttemptResult == ConnectionAttemptResult.shielded) {
          _particles.emitConnectionBurst(midPoint, color: LumoraColors.auroraBlue);
          LumoraHaptics.buttonPress();
          _sound.playNodeNote('blue');
          Future<void>.delayed(const Duration(milliseconds: 320), () {
            if (_swipeFilament?.isMounted ?? false) {
              _swipeFilament!.markBroken();
            }
          });
        } else {
          _swipeFilament!.markBroken();
          _filaments.add(_swipeFilament!);
          _particles.emitErrorScatter(midPoint);
          LumoraHaptics.connectionError();
          _sound.playErrorSound();
        }
      }
    } else {
      _swipeFilament!.markBroken();
      _filaments.add(_swipeFilament!);
    }

    _activePointerId = null;
    _swipeStartNode = null;
    _swipeCurrentPos = null;
    _swipeFilament = null;
  }

  // ─── Scale / Pinch Zoom ───────────────────────────────────────────

  @override
  void onScaleStart(ScaleStartInfo info) {
    _baseZoom = _currentZoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    if (info.pointerCount >= 2) {
      final scaleX = info.scale.global.x;
      final scaleY = info.scale.global.y;
      final avgScale = (scaleX + scaleY) / 2;
      final newZoom = (_baseZoom * avgScale).clamp(0.5, 3.0);
      _currentZoom = newZoom;
      camera.viewfinder.zoom = newZoom;
    }
  }

  // ─── Game State Listener ──────────────────────────────────────────

  void _onGameStateChanged() {    // Détecter la perte d'une vie pour jouer le son correspondant
    if (_trackedLives > 0 && gameState.lives < _trackedLives) {
      unawaited(_sound.playLifeLostSound());
    }
    _trackedLives = gameState.lives;    onStateChanged?.call(gameState);
  }

  // ─── Méthodes publiques pour l'UI ─────────────────────────────────

  void startLevel() {
    gameState.start();
  }

  void pauseGame() {
    gameState.pause();
  }

  void resumeGame() {
    gameState.resume();
  }

  bool useHint({bool consumeAttempt = true}) {
    final hintConsumed = gameState.useHint(consumeAttempt: consumeAttempt);
    if (!hintConsumed) {
      return false;
    }

    for (final rc in levelData.requiredConnections) {
      final conn = Connection(rc.from, rc.to);
      if (!gameState.connections.contains(conn)) {
        final fromNode = _nodes[rc.from];
        final toNode = _nodes[rc.to];

        fromNode.markTarget();
        toNode.markTarget();

        // Aperçu bref d'une connexion possible.
        final previewFilament = FilamentComponent(
          startPos: fromNode.position.clone(),
          endPos: toNode.position.clone(),
          state: FilamentState.connected,
          color: LumoraColors.auroraBlue,
        );
        add(previewFilament);

        Future<void>.delayed(const Duration(milliseconds: 850), () {
          if (previewFilament.isMounted) {
            previewFilament.markBroken();
          }
        });

        _particles.emitNodeRipple(fromNode.position, color: LumoraColors.auroraBlue);
        _particles.emitNodeRipple(toNode.position, color: LumoraColors.auroraBlue);
        _sound.playNodeNote('blue');
        break;
      }
    }

    return true;
  }

  void restartLevel() {
    gameState.reset();
    levelData = gameState.level;
    _cancelCurrentDrag();
    _loadLevel();
    _trackedLives = gameState.lives;
    gameState.addListener(_onGameStateChanged);
  }

  void retryLevelPreservingLives() {
    gameState.retryPreservingLives();
    levelData = gameState.level;
    _cancelCurrentDrag();
    _loadLevel();
    _trackedLives = gameState.lives;
    gameState.addListener(_onGameStateChanged);
  }

  bool loadNextLevel() {
    final nextLevel = LevelCatalog.nextLevel(levelData);
    gameState.loadLevel(nextLevel);
    levelData = nextLevel;
    _cancelCurrentDrag();
    _loadLevel();
    _trackedLives = gameState.lives;
    gameState.addListener(_onGameStateChanged);

    if (_background != null) {
      _background!.setWorldTheme(nextLevel.worldId);
    }
    _sound.setWorld(nextLevel.worldId);
    return true;
  }

  @override
  void onRemove() {
    _sound.stopAmbientLoop();
    super.onRemove();
  }
}