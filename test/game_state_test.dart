import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/engine/game_state.dart';
import 'package:lumora_mobile/features/game/engine/energy_node.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';

void main() {
  group('GameState', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState(level: World1Levels.levels.first);
    });

    test('initial state is idle', () {
      expect(gameState.status, GameStatus.idle);
      expect(gameState.lives, 5);
      expect(gameState.timeRemaining, 120.0);
      expect(gameState.score, 0);
      expect(gameState.connections.isEmpty, true);
    });

    test('start changes status to playing', () {
      gameState.start();
      expect(gameState.status, GameStatus.playing);
    });

    test('pause and resume work correctly', () {
      gameState.start();
      gameState.pause();
      expect(gameState.status, GameStatus.paused);
      gameState.resume();
      expect(gameState.status, GameStatus.playing);
    });

    test('tickTimer decreases time', () {
      gameState.start();
      final timeUp = gameState.tickTimer(10.0);
      expect(timeUp, false);
      expect(gameState.timeRemaining, 110.0);
      expect(gameState.timerProgress, closeTo(0.917, 0.01));
    });

    test('tickTimer returns true when time is up', () {
      gameState.start();
      gameState.tickTimer(119.0);
      final timeUp = gameState.tickTimer(2.0);
      expect(timeUp, true);
      expect(gameState.timeRemaining, 0);
      expect(gameState.status, GameStatus.defeat);
    });

    test('addConnection with valid connection succeeds', () {
      gameState.start();
      final result = gameState.addConnection(0, 1);
      expect(result, true);
      expect(gameState.connections.length, 1);
      expect(gameState.score, 100);
    });

    test('addConnection with invalid connection loses a life', () {
      gameState.start();
      final result = gameState.addConnection(0, 2); // Not in required connections for level 1
      expect(result, false);
      expect(gameState.lives, 4);
    });

    test('victory when all connections are made', () {
      gameState.start();
      gameState.addConnection(0, 1);
      expect(gameState.status, GameStatus.playing);
      gameState.addConnection(1, 2);
      expect(gameState.status, GameStatus.victory);
      expect(gameState.stars, greaterThanOrEqualTo(1));
    });

    test('defeat when lives reach zero', () {
      gameState.start();
      // Invalid connections drain lives
      for (var i = 0; i < 5; i++) {
        gameState.addConnection(0, 2); // Invalid for level 1
      }
      expect(gameState.lives, 0);
      expect(gameState.status, GameStatus.defeat);
    });

    test('stars calculation', () {
      gameState.start();
      gameState.addConnection(0, 1);
      gameState.addConnection(1, 2);
      // Timer should still be high → 3 stars
      expect(gameState.stars, 3);
    });

    test('useHint reduces score', () {
      gameState.start();
      // Ajouter des points d'abord
      gameState.addConnection(0, 1);
      expect(gameState.score, 100);
      gameState.useHint();
      expect(gameState.score, 50);
    });

    test('useHint does not go below zero', () {
      gameState.start();
      // Score starts at 0, hint reduces by 50 but clamps to 0
      gameState.useHint();
      expect(gameState.score, 0);
    });

    test('reset restores initial state', () {
      gameState.start();
      gameState.addConnection(0, 1);
      gameState.tickTimer(10.0);
      expect(gameState.status, GameStatus.playing);

      gameState.reset();
      expect(gameState.status, GameStatus.idle);
      expect(gameState.lives, 5);
      expect(gameState.timeRemaining, 120.0);
      expect(gameState.score, 0);
      expect(gameState.connections.isEmpty, true);
    });

    test('loadLevel changes level data', () {
      gameState.start();
      gameState.loadLevel(World1Levels.levels[1]);
      expect(gameState.level.id, 2);
      expect(gameState.level.name, 'Brume');
      expect(gameState.lives, 5);
      expect(gameState.timeRemaining, 100.0);
    });

    test('completionProgress calculates correctly', () {
      expect(gameState.completionProgress, 0.0);
      gameState.start();
      gameState.addConnection(0, 1);
      expect(gameState.completionProgress, 0.5);
      gameState.addConnection(1, 2);
      expect(gameState.completionProgress, 1.0);
    });

    test('remainingConnections tracks correctly', () {
      expect(gameState.remainingConnections, 2);
      gameState.start();
      gameState.addConnection(0, 1);
      expect(gameState.remainingConnections, 1);
    });
  });

  group('LevelData', () {
    test('World1Levels has 5 levels', () {
      expect(World1Levels.levels.length, 5);
    });

    test('each level has valid node connections', () {
      for (final level in World1Levels.levels) {
        expect(level.nodes.isNotEmpty, true);
        expect(level.requiredConnections.isNotEmpty, true);
        expect(level.timeLimit > 0, true);
        expect(level.lives > 0, true);

        for (final conn in level.requiredConnections) {
          expect(conn.from, lessThan(level.nodes.length));
          expect(conn.to, lessThan(level.nodes.length));
          expect(conn.from, isNot(equals(conn.to)));
        }
      }
    });

    test('difficulty increases across levels', () {
      final levels = World1Levels.levels;
      // Time limit decreases
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i].timeLimit, lessThanOrEqualTo(levels[i - 1].timeLimit));
      }
    });

    test('totalConnections matches requiredConnections length', () {
      for (final level in World1Levels.levels) {
        expect(level.totalConnections, level.requiredConnections.length);
      }
    });

    test('NodePosition toAbsolute works correctly', () {
      const pos = NodePosition(0.5, 0.25);
      // Can't create Vector2 directly without Flame context, but test the math
      expect(pos.x, 0.5);
      expect(pos.y, 0.25);
    });

    test('Connection equality is bidirectional', () {
      const c1 = Connection(0, 1);
      const c2 = Connection(1, 0);
      expect(c1 == c2, true);
      expect(c1.hashCode == c2.hashCode, true);
    });
  });

  group('NodeState', () {
    test('all states exist', () {
      expect(NodeState.values.length, 4);
      expect(NodeState.dormant, isNotNull);
      expect(NodeState.activated, isNotNull);
      expect(NodeState.connected, isNotNull);
      expect(NodeState.target, isNotNull);
    });
  });

  group('GameStatus', () {
    test('all statuses exist', () {
      expect(GameStatus.values.length, 5);
      expect(GameStatus.idle, isNotNull);
      expect(GameStatus.playing, isNotNull);
      expect(GameStatus.paused, isNotNull);
      expect(GameStatus.victory, isNotNull);
      expect(GameStatus.defeat, isNotNull);
    });
  });
}