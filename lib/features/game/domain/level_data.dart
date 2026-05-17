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

  const LevelData({
    required this.id,
    required this.name,
    required this.nodes,
    required this.requiredConnections,
    this.timeLimit = 90.0,
    this.lives = 3,
    this.attemptsPerLife = 5,
    this.worldId = 1,
  });

  int get totalConnections => requiredConnections.length;
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
      attemptsPerLife: 5,
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
      attemptsPerLife: 5,
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
      attemptsPerLife: 5,
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
    ),
  ];
}