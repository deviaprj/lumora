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

  // Callbacks vers l'UI Flutter
  VoidCallback? onVictory;
  VoidCallback? onDefeat;
  void Function(GameState state)? onStateChanged;

  /// Rayon de détection tactile — généreux pour la précision du doigt mobile.
  static const double _hitRadiusMultiplier = 5.0;

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
    _sound.init();
    _sound.setWorld(levelData.worldId);
    _sound.startAmbientLoop();
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

    // Générer des positions aléatoires pour les nœuds
    final randomPositions =
        _generateRandomPositions(levelData.nodes.length, canvasSize);

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
      initialPosition: Vector2(canvasSize.x / 2, canvasSize.y / 2),
    );
    add(_lumie);
  }

  /// Génère des positions aléatoires bien espacées pour les nœuds.
  List<Vector2> _generateRandomPositions(int count, Vector2 canvasSize) {
    final positions = <Vector2>[];
    final margin = 60.0;
    final minDistance = 80.0;
    final maxAttempts = 150;
    final rng = Random();

    for (var i = 0; i < count; i++) {
      Vector2? pos;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final x = margin + rng.nextDouble() * (canvasSize.x - 2 * margin);
        final y = margin + rng.nextDouble() * (canvasSize.y - 2 * margin);
        final candidate = Vector2(x, y);

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

      // Fallback si aucune position valide trouvée
      positions.add(pos ??
          Vector2(
            margin + rng.nextDouble() * (canvasSize.x - 2 * margin),
            margin + rng.nextDouble() * (canvasSize.y - 2 * margin),
          ));
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
        _swipeFilament!.markBroken();
        _filaments.add(_swipeFilament!);
        final midPoint = (_swipeStartNode!.position + endNode.position) / 2;
        _particles.emitErrorScatter(midPoint);
        LumoraHaptics.connectionError();
        _sound.playErrorSound();
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

  void _onGameStateChanged() {
    onStateChanged?.call(gameState);
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

  void useHint() {
    gameState.useHint();

    for (final rc in levelData.requiredConnections) {
      final conn = Connection(rc.from, rc.to);
      if (!gameState.connections.contains(conn)) {
        _nodes[rc.from].markTarget();
        _nodes[rc.to].markTarget();
        break;
      }
    }
  }

  void restartLevel() {
    gameState.reset();
    levelData = gameState.level;
    _cancelCurrentDrag();
    _loadLevel();
    gameState.addListener(_onGameStateChanged);
  }

  void loadNextLevel() {
    final currentIndex =
        World1Levels.levels.indexWhere((l) => l.id == levelData.id);
    if (currentIndex < World1Levels.levels.length - 1) {
      final nextLevel = World1Levels.levels[currentIndex + 1];
      gameState.loadLevel(nextLevel);
      levelData = nextLevel;
      _cancelCurrentDrag();
      _loadLevel();
      gameState.addListener(_onGameStateChanged);

      if (_background != null) {
        _background!.setWorldTheme(nextLevel.worldId);
      }
      _sound.setWorld(nextLevel.worldId);
    }
  }

  @override
  void onRemove() {
    _sound.stopAmbientLoop();
    super.onRemove();
  }
}