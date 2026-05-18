import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';
import 'package:lumora_mobile/features/game/engine/game_state.dart';

void main() {
  group('GameState', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState(level: LevelCatalog.firstLevel);
    });

    test('initial state uses level defaults', () {
      expect(gameState.status, GameStatus.idle);
      expect(gameState.lives, 3);
      expect(gameState.attemptsPerLife, 5);
      expect(gameState.attemptsRemaining, 5);
      expect(gameState.timeRemaining, 120.0);
      expect(gameState.score, 0);
      expect(gameState.connections, isEmpty);
    });

    test('invalid connection consumes one attempt before life loss', () {
      gameState.start();

      expect(gameState.addConnection(0, 2), isFalse);
      expect(gameState.lives, 3);
      expect(gameState.attemptsRemaining, 4);
    });

    test('exhausting attempts removes one life and refills attempts', () {
      gameState.start();

      for (var i = 0; i < 5; i++) {
        gameState.addConnection(0, 2);
      }

      expect(gameState.lives, 2);
      expect(gameState.attemptsRemaining, 5);
      expect(gameState.status, GameStatus.playing);
    });

    test('useHint costs score and one attempt while playing', () {
      gameState.start();
      gameState.addConnection(0, 1);

      final used = gameState.useHint();

      expect(used, isTrue);
      expect(gameState.score, 50);
      expect(gameState.attemptsRemaining, 4);
    });

    test('useHint is rejected outside playing state', () {
      expect(gameState.useHint(), isFalse);
      expect(gameState.attemptsRemaining, 5);
      expect(gameState.score, 0);
    });

    test('double score doubles score gains for the current level', () {
      gameState.start();
      gameState.armDoubleScore();

      expect(gameState.addConnection(0, 1), isTrue);
      expect(gameState.score, 200);

      expect(gameState.addConnection(1, 2), isTrue);
      expect(gameState.status, GameStatus.victory);
      expect(gameState.score, greaterThan(400));
    });

    test('super filament absorbs the next invalid connection without attempt loss', () {
      gameState.start();
      gameState.armSuperFilament();

      expect(gameState.addConnection(0, 2), isFalse);
      expect(gameState.lastAttemptResult, ConnectionAttemptResult.shielded);
      expect(gameState.attemptsRemaining, 5);
      expect(gameState.hasSuperFilament, isFalse);
    });

    test('victory completes when all required connections are made', () {
      gameState.start();

      expect(gameState.addConnection(0, 1), isTrue);
      expect(gameState.addConnection(1, 2), isTrue);

      expect(gameState.status, GameStatus.victory);
      expect(gameState.stars, 3);
      expect(gameState.score, greaterThan(200));
    });

    test('grantLives revives from defeat and clamps to max lives', () {
      gameState.start();

      for (var i = 0; i < 15; i++) {
        gameState.addConnection(0, 2);
      }

      expect(gameState.status, GameStatus.defeat);
      expect(gameState.lives, 0);

      gameState.grantLives(1);

      expect(gameState.status, GameStatus.idle);
      expect(gameState.lives, 1);
      expect(gameState.attemptsRemaining, 5);

      gameState.grantLives(10);
      expect(gameState.lives, gameState.maxLives);
    });

    test('retryPreservingLives resets board without restoring full lives', () {
      gameState.start();
      for (var i = 0; i < 5; i++) {
        gameState.addConnection(0, 2);
      }

      expect(gameState.lives, 2);

      gameState.retryPreservingLives();

      expect(gameState.status, GameStatus.idle);
      expect(gameState.lives, 2);
      expect(gameState.attemptsRemaining, gameState.attemptsPerLife);
      expect(gameState.connections, isEmpty);
    });

    test('loadLevel applies updated difficulty values', () {
      gameState.loadLevel(LevelCatalog.byId(4));

      expect(gameState.level.id, 4);
      expect(gameState.attemptsPerLife, 7);
      expect(gameState.attemptsRemaining, 7);
      expect(gameState.maxTime, 80.0);
    });

    test('rising flow objective fails when valid links move back upward', () {
      final customState = GameState(
        level: const LevelData(
          id: 99,
          name: 'Flux test',
          nodes: [
            NodePosition(0.2, 0.2),
            NodePosition(0.5, 0.4),
            NodePosition(0.8, 0.3),
          ],
          requiredConnections: [
            RequiredConnection(1, 2),
            RequiredConnection(0, 1),
          ],
          secondaryObjectives: [
            SecondaryObjective(SecondaryObjectiveType.risingFlow),
          ],
        ),
      )..start();

      customState.addConnection(1, 2);
      customState.addConnection(0, 1);

      expect(
        customState.isSecondaryObjectiveCompleted(
          customState.secondaryObjectives.first,
        ),
        isFalse,
      );
    });
  });

  group('LevelCatalog', () {
    test('handcrafted levels now cover at least ten stages', () {
      expect(World1Levels.levels.length, greaterThanOrEqualTo(10));
      expect(LevelCatalog.byId(10).timeLimit, 64.0);
    });

    test('procedural level generation extends progression beyond handcrafted levels', () {
      final generated = LevelCatalog.byId(14);

      expect(generated.id, 14);
      expect(generated.nodes.length, greaterThanOrEqualTo(8));
      expect(generated.requiredConnections.length, greaterThanOrEqualTo(8));
      expect(generated.timeLimit, lessThanOrEqualTo(78.0));
      expect(generated.attemptsPerLife, greaterThanOrEqualTo(5));
      expect(generated.secondaryObjectives, isNotEmpty);
    });

    test('nextLevel progresses beyond handcrafted range', () {
      final next = LevelCatalog.nextLevel(LevelCatalog.byId(10));

      expect(next.id, 11);
      expect(next.requiredConnections, isNotEmpty);
    });
  });

  group('Connection', () {
    test('equality is bidirectional', () {
      const c1 = Connection(0, 1);
      const c2 = Connection(1, 0);

      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
    });
  });
}
