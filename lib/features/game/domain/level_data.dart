import 'package:flame/extensions.dart' show Vector2;
/// Position normalisée d'un nœud (0.0–1.0) relative à la taille du canvas.
class NodePosition {
  final double x;
  final double y;
  const NodePosition(this.x, this.y);
  /// Convertit en position absolue pour un canvas de taille [size].
  Vector2 toAbsolute(Vector2 size) => Vector2(x * size.x, y * size.y);
}
/// Connexion requise entre deux nœuds (index dans la liste de nœuds).
class RequiredConnection {
  final int from;
  final int to;
  const RequiredConnection(this.from, this.to);
}
enum WorldTheme {
  auroraSanctum,
  prismTide,
  solarFlare,
  abyssBloom,
  cometGarden,
}
enum LevelSpecialRule {
  standard,
  overload,
  resonance,
  blackout,
}
enum SecondaryObjectiveType {
  noDuplicate,
  comboChain,
  risingFlow,
}
class SecondaryObjective {
  final SecondaryObjectiveType type;
  final int threshold;
  const SecondaryObjective(this.type, {this.threshold = 0});
  String get label {
    switch (type) {
      case SecondaryObjectiveType.noDuplicate:
        return 'Sans doublon';
      case SecondaryObjectiveType.comboChain:
        return 'Combo x$threshold';
      case SecondaryObjectiveType.risingFlow:
        return 'Flux ascendant';
    }
  }
  String get description {
    switch (type) {
      case SecondaryObjectiveType.noDuplicate:
        return 'Terminer sans rejouer une liaison déjà tracée.';
      case SecondaryObjectiveType.comboChain:
        return 'Atteindre un combo de $threshold connexions valides.';
      case SecondaryObjectiveType.risingFlow:
        return 'Garder une trajectoire globale du haut vers le bas.';
    }
  }
}
extension WorldThemeLabel on WorldTheme {
  String get label {
    switch (this) {
      case WorldTheme.auroraSanctum:
        return 'Sanctuaire Aurore';
      case WorldTheme.prismTide:
        return 'Marée Prismatique';
      case WorldTheme.solarFlare:
        return 'Fournaise Solaire';
      case WorldTheme.abyssBloom:
        return 'Floraison Abyssale';
      case WorldTheme.cometGarden:
        return 'Jardin Comète';
    }
  }
}
extension LevelSpecialRuleLabel on LevelSpecialRule {
  String get label {
    switch (this) {
      case LevelSpecialRule.standard:
        return 'Flux stable';
      case LevelSpecialRule.overload:
        return 'Surcharge';
      case LevelSpecialRule.resonance:
        return 'Résonance';
      case LevelSpecialRule.blackout:
        return 'Blackout';
    }
  }
  String get description {
    switch (this) {
      case LevelSpecialRule.standard:
        return 'Rythme standard, idéale pour construire la chaîne.';
      case LevelSpecialRule.overload:
        return 'Chaque erreur ou doublon consomme 2 coups.';
      case LevelSpecialRule.resonance:
        return 'Chaque 3e connexion valide accorde un boost de score et de temps.';
      case LevelSpecialRule.blackout:
        return 'Le temps file plus vite et l\'indice coûte 2 coups.';
    }
  }
}
/// Définition d'un niveau Lumora.
class LevelData {
  final int id;
  final String name;
  final List<NodePosition> nodes;
  final List<RequiredConnection> requiredConnections;
  final double timeLimit;
  final int lives;
  final int attemptsPerLife;
  final int worldId;
  final WorldTheme worldTheme;
  final LevelSpecialRule specialRule;
  final List<SecondaryObjective> secondaryObjectives;
  const LevelData({
    required this.id,
    required this.name,
    required this.nodes,
    required this.requiredConnections,
    this.timeLimit = 90.0,
    this.lives = 3,
    this.attemptsPerLife = 5,
    this.worldId = 1,
    this.worldTheme = WorldTheme.auroraSanctum,
    this.specialRule = LevelSpecialRule.standard,
    this.secondaryObjectives = const <SecondaryObjective>[],
  });
  int get totalConnections => requiredConnections.length;
  String get worldLabel => worldTheme.label;
  String get specialRuleLabel => specialRule.label;
  String get specialRuleDescription => specialRule.description;
}
/// Niveaux prédéfinis pour le World 1.
class World1Levels {
  static const List<LevelData> levels = [
    LevelData(
      id: 1,
      name: 'Éveil',
      nodes: [
        NodePosition(0.25, 0.35),
        NodePosition(0.75, 0.35),
        NodePosition(0.5, 0.65),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(1, 2),
      ],
      timeLimit: 120.0,
      lives: 3,
      worldTheme: WorldTheme.auroraSanctum,
    ),
    LevelData(
      id: 2,
      name: 'Brume',
      nodes: [
        NodePosition(0.2, 0.25),
        NodePosition(0.8, 0.25),
        NodePosition(0.5, 0.5),
        NodePosition(0.3, 0.75),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(1, 2),
        RequiredConnection(2, 3),
      ],
      timeLimit: 100.0,
      lives: 3,
      worldTheme: WorldTheme.auroraSanctum,
    ),
    LevelData(
      id: 3,
      name: 'Constellation',
      nodes: [
        NodePosition(0.5, 0.15),
        NodePosition(0.2, 0.45),
        NodePosition(0.8, 0.45),
        NodePosition(0.3, 0.75),
        NodePosition(0.7, 0.75),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(0, 2),
        RequiredConnection(1, 3),
        RequiredConnection(2, 4),
        RequiredConnection(3, 4),
      ],
      timeLimit: 90.0,
      lives: 3,
      worldTheme: WorldTheme.auroraSanctum,
    ),
    LevelData(
      id: 4,
      name: 'Nova',
      nodes: [
        NodePosition(0.5, 0.12),
        NodePosition(0.2, 0.30),
        NodePosition(0.8, 0.30),
        NodePosition(0.15, 0.65),
        NodePosition(0.85, 0.65),
        NodePosition(0.5, 0.80),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(0, 2),
        RequiredConnection(1, 3),
        RequiredConnection(2, 4),
        RequiredConnection(3, 5),
        RequiredConnection(4, 5),
        RequiredConnection(1, 2),
      ],
      timeLimit: 80.0,
      lives: 3,
      attemptsPerLife: 7,
      worldTheme: WorldTheme.auroraSanctum,
    ),
    LevelData(
      id: 5,
      name: 'Nébuleuse',
      nodes: [
        NodePosition(0.5, 0.10),
        NodePosition(0.25, 0.28),
        NodePosition(0.75, 0.28),
        NodePosition(0.15, 0.55),
        NodePosition(0.5, 0.50),
        NodePosition(0.85, 0.55),
        NodePosition(0.5, 0.80),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(0, 2),
        RequiredConnection(1, 3),
        RequiredConnection(1, 4),
        RequiredConnection(2, 5),
        RequiredConnection(3, 6),
        RequiredConnection(4, 6),
        RequiredConnection(5, 6),
      ],
      timeLimit: 75.0,
      lives: 3,
      attemptsPerLife: 10,
      worldTheme: WorldTheme.auroraSanctum,
    ),
    LevelData(
      id: 6,
      name: 'Reflets',
      nodes: [
        NodePosition(0.18, 0.24),
        NodePosition(0.50, 0.16),
        NodePosition(0.82, 0.24),
        NodePosition(0.28, 0.50),
        NodePosition(0.72, 0.50),
        NodePosition(0.20, 0.78),
        NodePosition(0.50, 0.86),
        NodePosition(0.80, 0.78),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(1, 2),
        RequiredConnection(0, 3),
        RequiredConnection(2, 4),
        RequiredConnection(3, 6),
        RequiredConnection(4, 6),
        RequiredConnection(3, 5),
        RequiredConnection(4, 7),
      ],
      timeLimit: 72.0,
      lives: 3,
      worldId: 2,
      attemptsPerLife: 10,
      worldTheme: WorldTheme.prismTide,
    ),
    LevelData(
      id: 7,
      name: 'Sillage',
      nodes: [
        NodePosition(0.12, 0.30),
        NodePosition(0.34, 0.16),
        NodePosition(0.66, 0.16),
        NodePosition(0.88, 0.30),
        NodePosition(0.20, 0.62),
        NodePosition(0.50, 0.50),
        NodePosition(0.80, 0.62),
        NodePosition(0.50, 0.84),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(1, 2),
        RequiredConnection(2, 3),
        RequiredConnection(0, 4),
        RequiredConnection(4, 5),
        RequiredConnection(5, 6),
        RequiredConnection(6, 3),
        RequiredConnection(5, 7),
      ],
      timeLimit: 70.0,
      lives: 3,
      worldId: 2,
      attemptsPerLife: 10,
      worldTheme: WorldTheme.prismTide,
    ),
    LevelData(
      id: 8,
      name: 'Prisme',
      nodes: [
        NodePosition(0.50, 0.12),
        NodePosition(0.24, 0.28),
        NodePosition(0.76, 0.28),
        NodePosition(0.14, 0.52),
        NodePosition(0.40, 0.52),
        NodePosition(0.60, 0.52),
        NodePosition(0.86, 0.52),
        NodePosition(0.30, 0.78),
        NodePosition(0.70, 0.78),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(0, 2),
        RequiredConnection(1, 3),
        RequiredConnection(1, 4),
        RequiredConnection(2, 5),
        RequiredConnection(2, 6),
        RequiredConnection(4, 7),
        RequiredConnection(5, 8),
        RequiredConnection(7, 8),
      ],
      timeLimit: 68.0,
      lives: 3,
      worldId: 2,
      attemptsPerLife: 10,
      worldTheme: WorldTheme.prismTide,
    ),
    LevelData(
      id: 9,
      name: 'Halo',
      nodes: [
        NodePosition(0.18, 0.22),
        NodePosition(0.50, 0.12),
        NodePosition(0.82, 0.22),
        NodePosition(0.12, 0.50),
        NodePosition(0.34, 0.50),
        NodePosition(0.66, 0.50),
        NodePosition(0.88, 0.50),
        NodePosition(0.24, 0.80),
        NodePosition(0.50, 0.88),
        NodePosition(0.76, 0.80),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(1, 2),
        RequiredConnection(0, 3),
        RequiredConnection(3, 4),
        RequiredConnection(4, 1),
        RequiredConnection(1, 5),
        RequiredConnection(5, 6),
        RequiredConnection(4, 7),
        RequiredConnection(5, 9),
        RequiredConnection(7, 8),
        RequiredConnection(8, 9),
      ],
      timeLimit: 66.0,
      lives: 3,
      worldId: 2,
      attemptsPerLife: 10,
      worldTheme: WorldTheme.prismTide,
    ),
    LevelData(
      id: 10,
      name: 'Convergence',
      nodes: [
        NodePosition(0.10, 0.26),
        NodePosition(0.30, 0.14),
        NodePosition(0.50, 0.08),
        NodePosition(0.70, 0.14),
        NodePosition(0.90, 0.26),
        NodePosition(0.18, 0.56),
        NodePosition(0.40, 0.48),
        NodePosition(0.60, 0.48),
        NodePosition(0.82, 0.56),
        NodePosition(0.34, 0.84),
        NodePosition(0.66, 0.84),
      ],
      requiredConnections: [
        RequiredConnection(0, 1),
        RequiredConnection(1, 2),
        RequiredConnection(2, 3),
        RequiredConnection(3, 4),
        RequiredConnection(0, 5),
        RequiredConnection(5, 6),
        RequiredConnection(6, 7),
        RequiredConnection(7, 8),
        RequiredConnection(8, 4),
        RequiredConnection(6, 9),
        RequiredConnection(7, 10),
        RequiredConnection(9, 10),
      ],
      timeLimit: 64.0,
      lives: 3,
      worldId: 2,
      attemptsPerLife: 10,
      worldTheme: WorldTheme.prismTide,
    ),
  ];
}
class LevelCatalog {
  static List<LevelData> get handcraftedLevels => World1Levels.levels;
  static LevelData get firstLevel => handcraftedLevels.first;
  static LevelData byId(int id) {
    for (final level in handcraftedLevels) {
      if (level.id == id) {
        return level;
      }
    }
    return ProceduralLevelGenerator.generate(id);
  }
  static LevelData nextLevel(LevelData current) => byId(current.id + 1);
}
class ProceduralLevelGenerator {
  static const List<WorldTheme> _themeCycle = [
    WorldTheme.auroraSanctum,
    WorldTheme.prismTide,
    WorldTheme.solarFlare,
    WorldTheme.abyssBloom,
    WorldTheme.cometGarden,
  ];
  static LevelData generate(int id) {
    final progressionIndex = (id - LevelCatalog.handcraftedLevels.length - 1).clamp(0, 9999);
    final difficultyTier = progressionIndex ~/ 6;
    final phase = progressionIndex % 6;
    final worldTheme = _themeCycle[difficultyTier % _themeCycle.length];
    final specialRule = _resolveSpecialRule(difficultyTier, phase);
    final worldId = (difficultyTier % _themeCycle.length) + 1;
    final nodeCount = (8 + difficultyTier + (phase >= 2 ? 1 : 0) + (phase >= 4 ? 1 : 0))
      .clamp(8, 20);
    final layerCount = (3 + difficultyTier ~/ 2 + (phase >= 3 ? 1 : 0)).clamp(3, 7);
    final attemptsPerLife = (6 + difficultyTier - (specialRule == LevelSpecialRule.blackout ? 1 : 0))
        .clamp(5, 14);
    final timeLimit = _resolveTimeLimit(difficultyTier, phase, specialRule);
    final nodes = _generateNodes(nodeCount, layerCount);
    final requiredConnections = _generateConnections(nodeCount, layerCount, difficultyTier);
    return LevelData(
      id: id,
      name: '${worldTheme.label} $id',
      nodes: nodes,
      requiredConnections: requiredConnections,
      timeLimit: timeLimit,
      lives: 3,
      attemptsPerLife: attemptsPerLife,
      worldId: worldId,
      worldTheme: worldTheme,
      specialRule: specialRule,
      secondaryObjectives: _generateSecondaryObjectives(difficultyTier, phase, specialRule),
    );
  }
  static List<SecondaryObjective> _generateSecondaryObjectives(
    int tier,
    int phase,
    LevelSpecialRule specialRule,
  ) {
    final objectives = <SecondaryObjective>[
      const SecondaryObjective(SecondaryObjectiveType.noDuplicate),
      SecondaryObjective(
        SecondaryObjectiveType.comboChain,
        threshold: (3 + (tier ~/ 2)).clamp(3, 5),
      ),
    ];
    if (specialRule == LevelSpecialRule.resonance || tier >= 2 || phase >= 4) {
      objectives.add(const SecondaryObjective(SecondaryObjectiveType.risingFlow));
    }
    return objectives;
  }
  static LevelSpecialRule _resolveSpecialRule(int tier, int phase) {
    if (tier == 0 && phase < 2) {
      return LevelSpecialRule.standard;
    }
    final cycle = [
      LevelSpecialRule.standard,
      LevelSpecialRule.resonance,
      LevelSpecialRule.overload,
      LevelSpecialRule.blackout,
      LevelSpecialRule.resonance,
      LevelSpecialRule.overload,
    ];
    return cycle[(tier + phase) % cycle.length];
  }
  static double _resolveTimeLimit(int tier, int phase, LevelSpecialRule specialRule) {
    var base = (76.0 - tier * 2.4 - phase * 1.2).clamp(34.0, 76.0);
    if (specialRule == LevelSpecialRule.blackout) {
      base -= 4;
    }
    if (specialRule == LevelSpecialRule.resonance) {
      base += 2;
    }
    return base.clamp(30.0, 76.0);
  }
  static List<NodePosition> _generateNodes(int nodeCount, int layerCount) {
    final nodes = <NodePosition>[];
    final basePerLayer = nodeCount ~/ layerCount;
    var remainder = nodeCount % layerCount;
    for (var layer = 0; layer < layerCount; layer++) {
      final nodesInLayer = basePerLayer + (remainder > 0 ? 1 : 0);
      if (remainder > 0) {
        remainder--;
      }
      final y = layerCount == 1
          ? 0.5
          : 0.14 + (layer / (layerCount - 1)) * 0.72;
      for (var index = 0; index < nodesInLayer; index++) {
        final x = nodesInLayer == 1
            ? 0.5
            : 0.14 + (index / (nodesInLayer - 1)) * 0.72;
        final horizontalWave = ((layer + index).isEven ? 0.018 : -0.018);
        nodes.add(NodePosition(x + horizontalWave, y));
      }
    }
    return nodes.take(nodeCount).toList(growable: false);
  }
  static List<RequiredConnection> _generateConnections(int nodeCount, int layerCount, int difficultyTier) {
    final connections = <RequiredConnection>[];
    final layerOffsets = <int>[];
    final layerSizes = <int>[];
    final basePerLayer = nodeCount ~/ layerCount;
    var remainder = nodeCount % layerCount;
    var offset = 0;
    for (var layer = 0; layer < layerCount; layer++) {
      final size = basePerLayer + (remainder > 0 ? 1 : 0);
      if (remainder > 0) {
        remainder--;
      }
      layerOffsets.add(offset);
      layerSizes.add(size);
      offset += size;
    }
    for (var layer = 0; layer < layerCount - 1; layer++) {
      final currentOffset = layerOffsets[layer];
      final nextOffset = layerOffsets[layer + 1];
      final currentSize = layerSizes[layer];
      final nextSize = layerSizes[layer + 1];
      for (var index = 0; index < currentSize; index++) {
        final from = currentOffset + index;
        final primaryTarget = nextOffset + ((index * nextSize) ~/ currentSize);
        connections.add(RequiredConnection(from, primaryTarget));
        final shouldCreateBridge = currentSize > 1 && nextSize > 1 && (index + layer).isEven;
        if (shouldCreateBridge) {
          final secondaryTarget = nextOffset + ((primaryTarget - nextOffset + 1).clamp(0, nextSize - 1));
          if (secondaryTarget != primaryTarget) {
            connections.add(RequiredConnection(from, secondaryTarget));
          }
        }
      }
    }
    for (var layer = 1; layer < layerCount - 1; layer++) {
      final layerOffset = layerOffsets[layer];
      final layerSize = layerSizes[layer];
      if (layerSize >= 2) {
        connections.add(RequiredConnection(layerOffset, layerOffset + layerSize - 1));
      }
      if (difficultyTier >= 2 && layerSize >= 3) {
        final middle = layerOffset + (layerSize ~/ 2);
        connections.add(RequiredConnection(layerOffset, middle));
      }
    }
    final uniqueConnections = <RequiredConnection>[];
    for (final connection in connections) {
      final alreadyExists = uniqueConnections.any(
        (existing) =>
            (existing.from == connection.from && existing.to == connection.to) ||
            (existing.from == connection.to && existing.to == connection.from),
      );
      if (!alreadyExists) {
        uniqueConnections.add(connection);
      }
    }
    return uniqueConnections;
  }
}