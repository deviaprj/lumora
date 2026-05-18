import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';
import 'package:lumora_mobile/features/game/engine/game_state.dart';

void main() {
  group('Game interaction flow', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState(level: LevelCatalog.firstLevel);
    });

    test('valid connection is accepted in both directions', () {
      gameState.start();
      expect(gameState.addConnection(0, 1), isTrue);

      gameState.reset();
      gameState.start();
      expect(gameState.addConnection(1, 0), isTrue);
    });

    test('duplicate connection consumes an attempt', () {
      gameState.start();
      gameState.addConnection(0, 1);

      expect(gameState.addConnection(1, 0), isFalse);
      expect(gameState.attemptsRemaining, 4);
      expect(gameState.lives, 3);
    });

    test('no duplicate objective is lost after replaying a valid connection', () {
      final objectiveState = GameState(
        level: const LevelData(
          id: 77,
          name: 'Sans doublon',
          nodes: [
            NodePosition(0.2, 0.2),
            NodePosition(0.8, 0.2),
            NodePosition(0.5, 0.8),
          ],
          requiredConnections: [
            RequiredConnection(0, 1),
            RequiredConnection(1, 2),
          ],
          secondaryObjectives: [
            SecondaryObjective(SecondaryObjectiveType.noDuplicate),
          ],
        ),
      )..start();

      objectiveState.addConnection(0, 1);
      objectiveState.addConnection(1, 0);

      expect(objectiveState.duplicateAttempts, 1);
      expect(
        objectiveState.isSecondaryObjectiveCompleted(
          objectiveState.secondaryObjectives.first,
        ),
        isFalse,
      );
    });

    test('perfect sequence completes level 1 with 3 stars', () {
      gameState.start();
      gameState.activateNode(0);
      gameState.activateNode(1);
      gameState.activateNode(2);

      expect(gameState.addConnection(0, 1), isTrue);
      expect(gameState.status, GameStatus.playing);
      expect(gameState.addConnection(1, 2), isTrue);

      expect(gameState.status, GameStatus.victory);
      expect(gameState.stars, 3);
      expect(gameState.activatedNodes, 3);
    });

    test('invalid attempts eventually lead to defeat', () {
      gameState.start();

      for (var i = 0; i < 15; i++) {
        gameState.addConnection(0, 2);
      }

      expect(gameState.status, GameStatus.defeat);
      expect(gameState.lives, 0);
    });

    test('rewarded lives enable a fresh retry without refilling to max', () {
      gameState.start();

      for (var i = 0; i < 15; i++) {
        gameState.addConnection(0, 2);
      }

      gameState.grantLives(2);
      gameState.retryPreservingLives();
      gameState.start();

      expect(gameState.status, GameStatus.playing);
      expect(gameState.lives, 2);
      expect(gameState.attemptsRemaining, gameState.attemptsPerLife);
    });

    test('procedural level exposes at least one valid connection immediately', () {
      final generatedLevel = LevelCatalog.byId(18);
      final generatedState = GameState(level: generatedLevel)..start();
      final firstConnection = generatedLevel.requiredConnections.first;

      expect(generatedLevel.nodes.length, greaterThanOrEqualTo(9));
      expect(generatedLevel.requiredConnections.length, greaterThanOrEqualTo(8));
      expect(
        generatedState.addConnection(firstConnection.from, firstConnection.to),
        isTrue,
      );
    });
  });
}
