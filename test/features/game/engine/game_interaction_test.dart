import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/engine/game_state.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';

void main() {
  group('Game interaction flow', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState(level: World1Levels.levels.first);
    });

    group('Node activation', () {
      test('tapping a dormant node activates it', () {
        expect(gameState.activatedNodes, 0);
        gameState.start();
        gameState.activateNode(0);
        expect(gameState.activatedNodes, 1);
      });

      test('activating multiple nodes tracks count', () {
        gameState.start();
        gameState.activateNode(0);
        gameState.activateNode(1);
        gameState.activateNode(2);
        expect(gameState.activatedNodes, 3);
      });

      test('activation count persists across connections', () {
        gameState.start();
        gameState.activateNode(0);
        gameState.addConnection(0, 1);
        gameState.activateNode(2);
        expect(gameState.activatedNodes, 2);
      });
    });

    group('Connection creation', () {
      test('valid connection is accepted', () {
        gameState.start();
        // Niveau 1 : connexion requise 0→1
        final result = gameState.addConnection(0, 1);
        expect(result, true);
        expect(gameState.connections.length, 1);
        expect(gameState.score, 100);
      });

      test('valid connection is accepted in reverse order', () {
        gameState.start();
        // La connexion 0→1 est aussi valide en 1→0
        final result = gameState.addConnection(1, 0);
        expect(result, true);
        expect(gameState.connections.length, 1);
      });

      test('duplicate connection is rejected without losing a life', () {
        gameState.start();
        gameState.addConnection(0, 1);
        final result = gameState.addConnection(0, 1);
        expect(result, false);
        expect(gameState.lives, 5); // Pas de perte de vie
        expect(gameState.connections.length, 1); // Pas de doublon
      });

      test('duplicate connection in reverse is rejected', () {
        gameState.start();
        gameState.addConnection(0, 1);
        final result = gameState.addConnection(1, 0);
        expect(result, false);
        expect(gameState.lives, 5); // Pas de perte de vie
      });

      test('invalid connection loses a life', () {
        gameState.start();
        // Niveau 1 : pas de connexion 0→2
        final result = gameState.addConnection(0, 2);
        expect(result, false);
        expect(gameState.lives, 4);
      });

      test('self-connection is invalid and loses a life', () {
        gameState.start();
        final result = gameState.addConnection(0, 0);
        expect(result, false);
        expect(gameState.lives, 4);
      });

      test('multiple invalid connections drain lives', () {
        gameState.start();
        gameState.addConnection(0, 2); // -1 vie
        expect(gameState.lives, 4);
        gameState.addConnection(2, 0); // -1 vie (même connexion que 0→2)
        // 0→2 n'est pas dans les requiredConnections, donc invalide
        expect(gameState.lives, 3);
      });
    });

    group('Victory flow', () {
      test('completing all connections triggers victory', () {
        gameState.start();
        // Niveau 1 : connexions 0→1 et 1→2
        gameState.addConnection(0, 1);
        expect(gameState.status, GameStatus.playing);
        gameState.addConnection(1, 2);
        expect(gameState.status, GameStatus.victory);
      });

      test('victory awards score bonus for time remaining', () {
        gameState.start();
        gameState.addConnection(0, 1);
        gameState.addConnection(1, 2);
        // Score = 200 (connections) + time bonus
        expect(gameState.score, greaterThan(200));
      });

      test('stars are awarded on victory', () {
        gameState.start();
        gameState.addConnection(0, 1);
        gameState.addConnection(1, 2);
        expect(gameState.stars, greaterThanOrEqualTo(1));
      });

      test('3 stars when most time remains', () {
        gameState.start();
        // Pas de tick du timer, donc tout le temps reste
        gameState.addConnection(0, 1);
        gameState.addConnection(1, 2);
        expect(gameState.stars, 3);
      });

      test('partial completion does not trigger victory', () {
        gameState.start();
        gameState.addConnection(0, 1);
        expect(gameState.status, GameStatus.playing);
        expect(gameState.completionProgress, 0.5);
      });
    });

    group('Defeat flow', () {
      test('losing all lives triggers defeat', () {
        gameState.start();
        for (var i = 0; i < 5; i++) {
          gameState.addConnection(0, 2); // Connexion invalide
        }
        expect(gameState.lives, 0);
        expect(gameState.status, GameStatus.defeat);
      });

      test('timer running out triggers defeat', () {
        gameState.start();
        final timeUp = gameState.tickTimer(gameState.level.timeLimit + 1);
        expect(timeUp, true);
        expect(gameState.status, GameStatus.defeat);
      });

      test('timer ticking decreases remaining time', () {
        gameState.start();
        final initial = gameState.timeRemaining;
        gameState.tickTimer(5.0);
        expect(gameState.timeRemaining, initial - 5.0);
      });
    });

    group('Game state lifecycle', () {
      test('game starts in idle state', () {
        expect(gameState.status, GameStatus.idle);
      });

      test('start transitions to playing', () {
        gameState.start();
        expect(gameState.status, GameStatus.playing);
      });

      test('pause and resume cycle', () {
        gameState.start();
        gameState.pause();
        expect(gameState.status, GameStatus.paused);
        gameState.resume();
        expect(gameState.status, GameStatus.playing);
      });

      test('reset restores initial state', () {
        gameState.start();
        gameState.addConnection(0, 1);
        gameState.tickTimer(10.0);

        gameState.reset();
        expect(gameState.status, GameStatus.idle);
        expect(gameState.lives, gameState.maxLives);
        expect(gameState.timeRemaining, gameState.maxTime);
        expect(gameState.score, 0);
        expect(gameState.connections.isEmpty, true);
        expect(gameState.activatedNodes, 0);
      });

      test('loadLevel resets for new level', () {
        gameState.start();
        gameState.addConnection(0, 1);
        gameState.loadLevel(World1Levels.levels[1]);
        expect(gameState.level.id, 2);
        expect(gameState.status, GameStatus.idle);
        expect(gameState.lives, 5);
        expect(gameState.connections.isEmpty, true);
      });
    });

    group('Full gameplay sequence', () {
      test('complete level 1 with perfect score', () {
        gameState.start();

        // Activer les nœuds
        gameState.activateNode(0);
        gameState.activateNode(1);
        gameState.activateNode(2);
        expect(gameState.activatedNodes, 3);

        // Connecter 0→1
        final conn1 = gameState.addConnection(0, 1);
        expect(conn1, true);
        expect(gameState.completionProgress, 0.5);
        expect(gameState.status, GameStatus.playing);

        // Connecter 1→2
        final conn2 = gameState.addConnection(1, 2);
        expect(conn2, true);
        expect(gameState.completionProgress, 1.0);
        expect(gameState.status, GameStatus.victory);
        expect(gameState.stars, 3);
      });

      test('complete level 1 with errors then succeed', () {
        gameState.start();

        // Tentative de connexion invalide
        gameState.addConnection(0, 2);
        expect(gameState.lives, 4);

        // Connexions valides
        gameState.addConnection(0, 1);
        expect(gameState.status, GameStatus.playing);

        gameState.addConnection(1, 2);
        expect(gameState.status, GameStatus.victory);
        // Score = 200 (connexions) + bonus temps
        expect(gameState.score, greaterThanOrEqualTo(200));
      });

      test('attempt connection after victory does nothing', () {
        gameState.start();
        gameState.addConnection(0, 1);
        gameState.addConnection(1, 2);
        expect(gameState.status, GameStatus.victory);

        // Les connexions après victoire ne font plus rien
        // (le status est déjà victory)
        final result = gameState.addConnection(0, 2);
        // La connexion est invalide, mais le status est déjà victory
        expect(result, false);
      });
    });

    group('Connection bidirectionality', () {
      test('Connection equality is bidirectional', () {
        const c1 = Connection(0, 1);
        const c2 = Connection(1, 0);
        expect(c1 == c2, true);
        expect(c1.hashCode == c2.hashCode, true);
      });

      test('Connection set prevents duplicates in both directions', () {
        final connections = <Connection>{};
        connections.add(const Connection(0, 1));
        connections.add(const Connection(1, 0)); // Doublon
        expect(connections.length, 1);
      });

      test('addConnection accepts both directions', () {
        gameState.start();
        // La connexion 0→1 est requise. Tester dans les deux sens.
        expect(gameState.addConnection(0, 1), true);
        gameState.reset();
        gameState.start();
        expect(gameState.addConnection(1, 0), true);
      });
    });

    group('Level progression', () {
      test('remainingConnections decreases with each valid connection', () {
        expect(gameState.remainingConnections, 2);
        gameState.start();
        gameState.addConnection(0, 1);
        expect(gameState.remainingConnections, 1);
        gameState.addConnection(1, 2);
        expect(gameState.remainingConnections, 0);
      });

      test('completionProgress goes from 0 to 1', () {
        expect(gameState.completionProgress, 0.0);
        gameState.start();
        gameState.addConnection(0, 1);
        expect(gameState.completionProgress, 0.5);
        gameState.addConnection(1, 2);
        expect(gameState.completionProgress, 1.0);
      });
    });
  });
}