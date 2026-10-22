import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/crystals/domain/crystal_board.dart';
import 'package:lumora_mobile/features/crystals/domain/crystal_models.dart';
import 'package:lumora_mobile/features/crystals/domain/crystal_run.dart';

CrystalLevelConfig _config({int moves = 3, int target = 1000}) {
  return CrystalLevelConfig(
    level: 1,
    rows: 2,
    cols: 2,
    colorCount: 2,
    moveBudget: moves,
    targetScore: target,
  );
}

CrystalRun _runWith(
  List<List<CrystalColor>> grid, {
  int moves = 3,
  int target = 1000,
  int seed = 1,
}) {
  return CrystalRun(
    config: _config(moves: moves, target: target),
    board: CrystalBoard.fromGrid(grid, random: Random(seed)),
  );
}

/// Première paire voisine de même couleur, pour rejouer après un remplissage.
({int row, int col, int otherRow, int otherCol})? _findPair(
    CrystalBoard board) {
  for (var row = 0; row < board.rows; row++) {
    for (var col = 0; col < board.cols; col++) {
      final color = board.cellAt(row, col);
      if (color == null) {
        continue;
      }
      if (col + 1 < board.cols && board.cellAt(row, col + 1) == color) {
        return (row: row, col: col, otherRow: row, otherCol: col + 1);
      }
      if (row + 1 < board.rows && board.cellAt(row + 1, col) == color) {
        return (row: row, col: col, otherRow: row + 1, otherCol: col);
      }
    }
  }
  return null;
}

/// Première paire voisine de couleurs différentes, pour casser la série.
({int row, int col, int otherRow, int otherCol})? _findDifferentNeighbors(
  CrystalBoard board,
) {
  for (var row = 0; row < board.rows; row++) {
    for (var col = 0; col < board.cols; col++) {
      final color = board.cellAt(row, col);
      if (color == null) {
        continue;
      }
      if (col + 1 < board.cols) {
        final next = board.cellAt(row, col + 1);
        if (next != null && next != color) {
          return (row: row, col: col, otherRow: row, otherCol: col + 1);
        }
      }
      if (row + 1 < board.rows) {
        final next = board.cellAt(row + 1, col);
        if (next != null && next != color) {
          return (row: row, col: col, otherRow: row + 1, otherCol: col);
        }
      }
    }
  }
  return null;
}

void main() {
  group('CrystalRun — état initial', () {
    test('démarre sans score, avec tous les gestes disponibles', () {
      final run = _runWith([
        [CrystalColor.rose, CrystalColor.rose],
        [CrystalColor.mint, CrystalColor.mint],
      ]);

      expect(run.status, CrystalRunStatus.playing);
      expect(run.score, 0);
      expect(run.movesRemaining, 3);
      expect(run.movesUsed, 0);
      expect(run.streak, 0);
      expect(run.bestStreak, 0);
      expect(run.crystalsCleared, 0);
      expect(run.progress, 0);
      expect(run.stars, 0);
      expect(run.selected, isNull);
      expect(run.lastAction, CrystalAction.none);
    });

    test('sélectionne, désélectionne et déplace la sélection', () {
      final run = _runWith([
        [CrystalColor.rose, CrystalColor.rose],
        [CrystalColor.mint, CrystalColor.mint],
      ]);

      expect(run.select(0, 0), CrystalAction.selected);
      expect(run.selected, const CrystalPosition(0, 0));

      expect(run.select(0, 0), CrystalAction.deselected);
      expect(run.selected, isNull);

      expect(run.select(0, 0), CrystalAction.selected);
      expect(run.select(1, 1), CrystalAction.moved);
      expect(run.selected, const CrystalPosition(1, 1));
      expect(run.movesRemaining, 3);
    });

    test('ignore les cases hors plateau ou vides', () {
      final run = _runWith([
        [CrystalColor.rose, CrystalColor.rose],
        [CrystalColor.mint, CrystalColor.mint],
      ]);

      expect(run.select(-1, 0), CrystalAction.ignored);
      expect(run.select(0, 4), CrystalAction.ignored);
      expect(run.selected, isNull);
    });
  });

  group('CrystalRun — dissolutions', () {
    test('libère le groupe, compte les points et consomme un geste', () {
      final run = _runWith([
        [CrystalColor.rose, CrystalColor.rose],
        [CrystalColor.rose, CrystalColor.mint],
      ]);

      run.select(0, 0);
      final action = run.select(0, 1);

      expect(action, CrystalAction.cleared);
      // 3 cristaux : 3*25 + 3*2*5 = 105 points.
      expect(run.score, 105);
      expect(run.lastPoints, 105);
      expect(run.crystalsCleared, 3);
      expect(run.lastCleared.length, 3);
      expect(run.lastColor, CrystalColor.rose);
      expect(run.movesRemaining, 2);
      expect(run.streak, 1);
      expect(run.bestStreak, 1);
      expect(run.selected, isNull);
      expect(run.board.isFull, isTrue);
    });

    test('une paire de couleurs différentes casse la série sans coût', () {
      final run = _runWith([
        [CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.gold],
      ]);

      run.select(0, 0);
      final action = run.select(1, 0);

      expect(action, CrystalAction.invalid);
      expect(run.streak, 0);
      expect(run.movesRemaining, 3);
      expect(run.score, 0);
      expect(run.selected, isNull);
    });

    test('la série augmente le multiplicateur de la dissolution suivante', () {
      final run = _runWith(
        [
          [CrystalColor.rose, CrystalColor.rose, CrystalColor.mint],
          [CrystalColor.mint, CrystalColor.gold, CrystalColor.mint],
          [CrystalColor.gold, CrystalColor.gold, CrystalColor.gold],
        ],
        seed: 13,
      );

      run.select(2, 0);
      expect(run.select(2, 1), CrystalAction.cleared);
      expect(run.streak, 1);
      // Quatre cristaux d'or : 4*25 + 4*3*5 = 160 points.
      expect(run.lastPoints, 160);

      final pair = _findPair(run.board);
      expect(pair, isNotNull);
      final groupSize = run.board.groupAt(pair!.row, pair.col).length;

      expect(run.select(pair.row, pair.col), CrystalAction.selected);
      expect(
        run.select(pair.otherRow, pair.otherCol),
        CrystalAction.cleared,
      );

      final base = groupSize * 25 + groupSize * (groupSize - 1) * 5;
      expect(run.lastPoints, (base * 1.1).round());
      expect(run.streak, 2);
      expect(run.streakMultiplier, closeTo(1.2, 1e-9));
    });

    test('une tentative ratée remet la série à zéro après un succès', () {
      final run = _runWith(
        [
          [CrystalColor.rose, CrystalColor.rose, CrystalColor.mint],
          [CrystalColor.mint, CrystalColor.gold, CrystalColor.mint],
          [CrystalColor.gold, CrystalColor.gold, CrystalColor.gold],
        ],
        seed: 21,
      );

      run.select(2, 0);
      run.select(2, 1);
      expect(run.streak, 1);

      final pair = _findDifferentNeighbors(run.board);
      expect(pair, isNotNull);
      run.select(pair!.row, pair.col);
      final action = run.select(pair.otherRow, pair.otherCol);

      expect(action, CrystalAction.invalid);
      expect(run.streak, 0);
      expect(run.bestStreak, 1);
      expect(run.movesRemaining, 2);
    });
  });

  group('CrystalRun — fin de palier', () {
    test('atteint l’objectif et accorde le bonus des gestes restants', () {
      final run = _runWith(
        [
          [CrystalColor.rose, CrystalColor.rose],
          [CrystalColor.rose, CrystalColor.rose],
        ],
        target: 100,
      );

      run.select(0, 0);
      final action = run.select(0, 1);

      expect(action, CrystalAction.cleared);
      // 4 cristaux : 100 + 60 = 160, puis bonus de 2 gestes * 25.
      expect(run.status, CrystalRunStatus.victory);
      expect(run.lastPoints, 160);
      expect(run.victoryBonus, 50);
      expect(run.score, 210);
      expect(run.lastMovesRemaining, 2);
      expect(run.stars, 3);
      expect(run.progress, 1.0);
    });

    test('s’arrête en défaite quand les gestes sont épuisés', () {
      final run = _runWith(
        [
          [CrystalColor.rose, CrystalColor.rose],
          [CrystalColor.rose, CrystalColor.rose],
        ],
        moves: 1,
        target: 100000,
      );

      run.select(0, 0);
      run.select(0, 1);

      expect(run.status, CrystalRunStatus.defeat);
      expect(run.movesRemaining, 0);
      expect(run.stars, 0);
      expect(run.victoryBonus, 0);
    });

    test('ignore les interactions une fois le palier terminé', () {
      final run = _runWith(
        [
          [CrystalColor.rose, CrystalColor.rose],
          [CrystalColor.rose, CrystalColor.rose],
        ],
        target: 100,
      );

      run.select(0, 0);
      run.select(0, 1);
      expect(run.status, CrystalRunStatus.victory);

      expect(run.select(0, 2), CrystalAction.ignored);
      expect(run.select(0, 0), CrystalAction.ignored);
    });

    test('relance un palier neuf après une défaite', () {
      final run = _runWith(
        [
          [CrystalColor.rose, CrystalColor.rose],
          [CrystalColor.rose, CrystalColor.rose],
        ],
        moves: 1,
        target: 100000,
      );

      run.select(0, 0);
      run.select(0, 1);
      expect(run.status, CrystalRunStatus.defeat);

      run.retry();

      expect(run.status, CrystalRunStatus.playing);
      expect(run.score, 0);
      expect(run.movesRemaining, 1);
      expect(run.streak, 0);
      expect(run.bestStreak, 0);
      expect(run.crystalsCleared, 0);
      expect(run.selected, isNull);
      expect(run.lastAction, CrystalAction.none);
      expect(run.board.isFull, isTrue);
      expect(run.board.hasMoves(), isTrue);
    });

    test('relance avec un plateau imposé', () {
      final run = _runWith(
        [
          [CrystalColor.rose, CrystalColor.rose],
          [CrystalColor.rose, CrystalColor.rose],
        ],
        moves: 1,
        target: 100000,
      );

      run.select(0, 0);
      run.select(0, 1);
      expect(run.status, CrystalRunStatus.defeat);

      final fresh = CrystalBoard.fromGrid([
        [CrystalColor.mint, CrystalColor.mint],
        [CrystalColor.gold, CrystalColor.gold],
      ]);
      run.retry(board: fresh);

      expect(identical(run.board, fresh), isTrue);
      expect(run.status, CrystalRunStatus.playing);
    });
  });

  group('CrystalLevelConfig', () {
    test('fait monter la difficulté par paliers', () {
      final first = CrystalLevelConfig.forLevel(1);
      final middle = CrystalLevelConfig.forLevel(5);
      final last = CrystalLevelConfig.forLevel(12);

      expect(first.rows, 6);
      expect(first.colorCount, 4);
      expect(middle.rows, 7);
      expect(middle.colorCount, 5);
      expect(last.rows, 8);
      expect(last.colorCount, 6);
      expect(last.moveBudget, greaterThanOrEqualTo(first.moveBudget));
      expect(last.targetScore, greaterThan(first.targetScore));
    });

    test('ramène un niveau invalide au premier palier', () {
      final config = CrystalLevelConfig.forLevel(0);

      expect(config.level, 1);
      expect(config.rows, 6);
      expect(config.cols, config.rows);
      expect(config.boardSize, config.rows * config.cols);
    });
  });
}
