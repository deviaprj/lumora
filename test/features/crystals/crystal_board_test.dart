import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/crystals/domain/crystal_board.dart';
import 'package:lumora_mobile/features/crystals/domain/crystal_models.dart';

void main() {
  group('CrystalBoard.generate', () {
    test('produit un plateau plein, jouable et de la bonne taille', () {
      final board = CrystalBoard.generate(
        rows: 6,
        cols: 6,
        colorCount: 4,
        random: Random(7),
      );

      expect(board.rows, 6);
      expect(board.cols, 6);
      expect(board.cells.length, 36);
      expect(board.isFull, isTrue);
      expect(board.hasMoves(), isTrue);
      expect(board.largestGroup().length, greaterThanOrEqualTo(2));
    });

    test('limite les cristaux à la palette demandée', () {
      final board = CrystalBoard.generate(
        rows: 5,
        cols: 5,
        colorCount: 3,
        random: Random(11),
      );
      final allowed = CrystalColor.values.take(3).toSet();

      for (final color in board.cells) {
        expect(allowed.contains(color), isTrue);
      }
    });

    test('borne la palette entre deux couleurs et la palette complète', () {
      final tiny = CrystalBoard.generate(
        rows: 3,
        cols: 3,
        colorCount: 1,
        random: Random(3),
      );
      final huge = CrystalBoard.generate(
        rows: 3,
        cols: 3,
        colorCount: 99,
        random: Random(4),
      );

      expect(tiny.colorCount, 2);
      expect(huge.colorCount, CrystalColor.values.length);
    });
  });

  group('CrystalBoard.fromGrid', () {
    test('détecte le groupe connecté orthogonalement', () {
      final board = CrystalBoard.fromGrid([
        [CrystalColor.rose, CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.gold, CrystalColor.mint],
        [CrystalColor.gold, CrystalColor.gold, CrystalColor.gold],
      ]);

      expect(board.groupAt(0, 0).length, 2);
      expect(board.groupAt(0, 2).length, 2);
      expect(board.groupAt(2, 0).length, 4);
      expect(board.largestGroup().length, 4);
    });

    test('ne confond pas les diagonales avec des voisins', () {
      final board = CrystalBoard.fromGrid([
        [CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.rose],
      ]);

      expect(board.groupAt(0, 0).length, 1);
      expect(board.hasMoves(), isFalse);
    });

    test('ignore les cases hors du plateau', () {
      final board = CrystalBoard.fromGrid([
        [CrystalColor.rose, CrystalColor.rose],
        [CrystalColor.mint, CrystalColor.mint],
      ]);

      expect(board.isInside(1, 1), isTrue);
      expect(board.isInside(2, 0), isFalse);
      expect(board.cellAt(-1, 0), isNull);
      expect(board.cellAt(0, 5), isNull);
      expect(board.groupAt(-1, 0), isEmpty);
    });
  });

  group('CrystalBoard.clearGroupAt', () {
    test('refuse un cristal isolé', () {
      final board = CrystalBoard.fromGrid([
        [CrystalColor.rose, CrystalColor.mint],
        [CrystalColor.mint, CrystalColor.rose],
      ]);
      final before = board.cells;

      final result = board.clearGroupAt(0, 0);

      expect(result.isEmpty, isTrue);
      expect(result.color, isNull);
      expect(board.cells, before);
    });

    test('dissout le groupe et laisse tomber les cristaux au-dessus', () {
      final board = CrystalBoard.fromGrid(
        [
          [CrystalColor.rose, CrystalColor.mint],
          [CrystalColor.rose, CrystalColor.mint],
          [CrystalColor.gold, CrystalColor.gold],
        ],
        random: Random(5),
      );

      final result = board.clearGroupAt(2, 0);

      expect(result.count, 2);
      expect(result.color, CrystalColor.gold);
      expect(board.isFull, isTrue);
      expect(board.hasMoves(), isTrue);
      // Les deux colonnes ont glissé d'une case vers le bas.
      expect(board.cellAt(2, 0), CrystalColor.rose);
      expect(board.cellAt(1, 0), CrystalColor.rose);
      expect(board.cellAt(2, 1), CrystalColor.mint);
      expect(board.cellAt(1, 1), CrystalColor.mint);
    });

    test('recomplète le plateau et garde toujours un coup possible', () {
      final board = CrystalBoard.fromGrid(
        [
          [CrystalColor.rose, CrystalColor.rose, CrystalColor.mint],
          [CrystalColor.mint, CrystalColor.gold, CrystalColor.mint],
          [CrystalColor.gold, CrystalColor.gold, CrystalColor.gold],
        ],
        random: Random(13),
      );

      board.clearGroupAt(2, 0);

      expect(board.isFull, isTrue);
      expect(board.hasMoves(), isTrue);
      for (final color in board.cells) {
        expect(color, isNotNull);
      }
    });
  });
}
