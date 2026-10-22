import 'dart:math';

import 'crystal_models.dart';

/// Plateau de cristaux.
///
/// Le joueur relie deux cristaux voisins de même couleur ; tout le groupe
/// connecté de cette couleur se dissout, les cristaux restants glissent vers
/// le bas et de nouveaux éclats apparaissent en haut.
class CrystalBoard {
  CrystalBoard._({
    required this.rows,
    required this.cols,
    required this.colorCount,
    required List<CrystalColor?> cells,
    required Random random,
  })  : _cells = cells,
        _random = random;

  /// Génère un plateau jouable, sans groupe préexistant imposé.
  factory CrystalBoard.generate({
    required int rows,
    required int cols,
    required int colorCount,
    Random? random,
  }) {
    assert(
        rows > 1 && cols > 1, 'Le plateau doit contenir au moins 2x2 cases.');
    final paletteSize = colorCount.clamp(2, CrystalColor.values.length);
    final board = CrystalBoard._(
      rows: rows,
      cols: cols,
      colorCount: paletteSize,
      cells: List<CrystalColor?>.filled(rows * cols, null),
      random: random ?? Random(),
    );

    for (var attempt = 0; attempt < 32; attempt++) {
      board._fillRandom();
      if (board.hasMoves()) {
        break;
      }
    }
    if (!board.hasMoves()) {
      board._forcePair();
    }
    return board;
  }

  /// Construit un plateau déterministe, utile pour les tests et les tutoriels.
  factory CrystalBoard.fromGrid(
    List<List<CrystalColor>> grid, {
    Random? random,
    int? colorCount,
  }) {
    assert(grid.isNotEmpty && grid.first.isNotEmpty);
    final rows = grid.length;
    final cols = grid.first.length;
    for (final row in grid) {
      assert(row.length == cols,
          'Toutes les lignes doivent avoir la même taille.');
    }

    final flattened = <CrystalColor?>[];
    var highestColorIndex = 1;
    for (final row in grid) {
      for (final color in row) {
        flattened.add(color);
        highestColorIndex = max(highestColorIndex, color.index + 1);
      }
    }

    return CrystalBoard._(
      rows: rows,
      cols: cols,
      colorCount: (colorCount ?? highestColorIndex)
          .clamp(2, CrystalColor.values.length),
      cells: flattened,
      random: random ?? Random(),
    );
  }

  final int rows;
  final int cols;
  final int colorCount;
  final List<CrystalColor?> _cells;
  final Random _random;

  /// Copie non modifiable des cases (null pendant une dissolution).
  List<CrystalColor?> get cells => List<CrystalColor?>.unmodifiable(_cells);

  bool get isFull => !_cells.contains(null);

  bool isInside(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  CrystalColor? cellAt(int row, int col) =>
      isInside(row, col) ? _cells[_index(row, col)] : null;

  /// Groupe de cristaux de même couleur connectés orthogonalement.
  List<CrystalPosition> groupAt(int row, int col) {
    if (!isInside(row, col)) {
      return const <CrystalPosition>[];
    }
    final color = _cells[_index(row, col)];
    if (color == null) {
      return const <CrystalPosition>[];
    }

    final seen = <int>{_index(row, col)};
    final queue = <CrystalPosition>[CrystalPosition(row, col)];
    final group = <CrystalPosition>[];

    while (queue.isNotEmpty) {
      final position = queue.removeLast();
      group.add(position);
      for (final neighbor in _neighbors(position)) {
        final index = _index(neighbor.row, neighbor.col);
        if (seen.add(index) && _cells[index] == color) {
          queue.add(neighbor);
        }
      }
    }
    return group;
  }

  /// Vrai si au moins une paire voisine partage la même couleur.
  bool hasMoves() {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final color = _cells[_index(row, col)];
        if (color == null) {
          continue;
        }
        if (col + 1 < cols && _cells[_index(row, col + 1)] == color) {
          return true;
        }
        if (row + 1 < rows && _cells[_index(row + 1, col)] == color) {
          return true;
        }
      }
    }
    return false;
  }

  /// Plus grand groupe disponible, utilisé pour un indice discret.
  List<CrystalPosition> largestGroup() {
    final visited = <int>{};
    var best = <CrystalPosition>[];

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final index = _index(row, col);
        if (visited.contains(index)) {
          continue;
        }
        final group = groupAt(row, col);
        if (group.isEmpty) {
          continue;
        }
        for (final position in group) {
          visited.add(_index(position.row, position.col));
        }
        if (group.length > best.length) {
          best = group;
        }
      }
    }
    return best;
  }

  /// Dissout le groupe contenant [row, col], puis stabilise le plateau.
  ///
  /// Un groupe d'un seul cristal n'est pas une action valide.
  CrystalClearResult clearGroupAt(int row, int col) {
    final group = groupAt(row, col);
    if (group.length < 2) {
      return const CrystalClearResult.empty();
    }

    final color = _cells[_index(row, col)];
    for (final position in group) {
      _cells[_index(position.row, position.col)] = null;
    }

    _collapseAndRefill();
    _ensurePlayable();

    return CrystalClearResult(positions: group, color: color);
  }

  List<CrystalPosition> _neighbors(CrystalPosition position) {
    final neighbors = <CrystalPosition>[];
    if (position.row > 0) {
      neighbors.add(CrystalPosition(position.row - 1, position.col));
    }
    if (position.row + 1 < rows) {
      neighbors.add(CrystalPosition(position.row + 1, position.col));
    }
    if (position.col > 0) {
      neighbors.add(CrystalPosition(position.row, position.col - 1));
    }
    if (position.col + 1 < cols) {
      neighbors.add(CrystalPosition(position.row, position.col + 1));
    }
    return neighbors;
  }

  void _fillRandom() {
    for (var index = 0; index < _cells.length; index++) {
      _cells[index] = _randomColor();
    }
  }

  void _collapseAndRefill() {
    for (var col = 0; col < cols; col++) {
      var writeRow = rows - 1;
      for (var row = rows - 1; row >= 0; row--) {
        final color = _cells[_index(row, col)];
        if (color == null) {
          continue;
        }
        if (writeRow != row) {
          _cells[_index(writeRow, col)] = color;
          _cells[_index(row, col)] = null;
        }
        writeRow--;
      }
      for (var row = writeRow; row >= 0; row--) {
        _cells[_index(row, col)] = _randomColor();
      }
    }
  }

  /// Garantit qu'une paire jouable existe après une réaction en chaîne.
  ///
  /// On harmonise une paire voisine au lieu de tout redistribuer : le plateau
  /// garde ainsi sa forme et les cristaux déjà tombés restent en place.
  void _ensurePlayable() {
    if (hasMoves() || cols < 2) {
      return;
    }
    final row = _random.nextInt(rows);
    final col = _random.nextInt(cols - 1);
    final color = _randomColor();
    _cells[_index(row, col)] = color;
    _cells[_index(row, col + 1)] = color;
  }

  void _forcePair() {
    if (rows < 1 || cols < 2) {
      return;
    }
    final color = _randomColor();
    _cells[_index(0, 0)] = color;
    _cells[_index(0, 1)] = color;
  }

  CrystalColor _randomColor() =>
      CrystalColor.values[_random.nextInt(colorCount)];

  int _index(int row, int col) => row * cols + col;
}
