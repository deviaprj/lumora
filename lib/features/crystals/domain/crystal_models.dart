import 'package:flutter/material.dart';

/// Forme organique d'un cristal.
///
/// La forme varie avec la couleur : elle sert de repère supplémentaire pour
/// les joueurs qui distinguent mal certaines teintes.
enum CrystalShape {
  round,
  diamond,
  hexagon,
  drop,
  star,
  oval,
}

/// Palette des cristaux de Lumora.
///
/// Les teintes reprennent les accents d'énergie du thème, et chaque couleur
/// possède sa note dans le gestionnaire audio pour prolonger l'ambiance.
enum CrystalColor {
  rose('Rose', Color(0xFFFF6B9D), 'red', CrystalShape.round),
  gold('Or', Color(0xFFFFD166), 'yellow', CrystalShape.star),
  mint('Menthe', Color(0xFF00F5A0), 'green', CrystalShape.hexagon),
  sky('Ciel', Color(0xFF00D9F5), 'blue', CrystalShape.oval),
  violet('Violet', Color(0xFF9D4EDD), 'purple', CrystalShape.diamond),
  pearl('Nacre', Color(0xFFF5F5FA), 'gold', CrystalShape.drop);

  const CrystalColor(this.label, this.color, this.soundKey, this.shape);

  /// Nom lisible, utilisé par l'accessibilité et le HUD.
  final String label;

  /// Teinte principale du cristal.
  final Color color;

  /// Clé de note du gestionnaire audio.
  final String soundKey;

  /// Silhouette dessinée par le rendu.
  final CrystalShape shape;
}

/// Coordonnée d'une case du plateau.
@immutable
class CrystalPosition {
  const CrystalPosition(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is CrystalPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'CrystalPosition($row, $col)';
}

/// Résultat d'une dissolution de groupe.
@immutable
class CrystalClearResult {
  const CrystalClearResult({
    required this.positions,
    required this.color,
  });

  const CrystalClearResult.empty()
      : positions = const <CrystalPosition>[],
        color = null;

  final List<CrystalPosition> positions;
  final CrystalColor? color;

  int get count => positions.length;
  bool get isEmpty => positions.isEmpty;
}

/// Paramètres d'un palier de cristaux.
///
/// La difficulté monte en douceur : le plateau s'agrandit, de nouvelles
/// couleurs apparaissent, puis l'objectif demande des séries plus longues.
@immutable
class CrystalLevelConfig {
  const CrystalLevelConfig({
    required this.level,
    required this.rows,
    required this.cols,
    required this.colorCount,
    required this.moveBudget,
    required this.targetScore,
  });

  /// Construit le palier correspondant à un niveau de progression.
  factory CrystalLevelConfig.forLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    final rows = safeLevel < 4 ? 6 : (safeLevel < 9 ? 7 : 8);
    final colorCount = safeLevel < 5 ? 4 : (safeLevel < 11 ? 5 : 6);
    final moveBudget = (14 + ((safeLevel - 1) ~/ 2)).clamp(14, 22);
    // L'objectif monte avec le palier, puis plafonne pour rester atteignable.
    final targetScore = (moveBudget * 55 + (safeLevel - 1) * 45).clamp(
      moveBudget * 55,
      moveBudget * 110,
    );

    return CrystalLevelConfig(
      level: safeLevel,
      rows: rows,
      cols: rows,
      colorCount: colorCount,
      moveBudget: moveBudget,
      targetScore: targetScore,
    );
  }

  final int level;
  final int rows;
  final int cols;
  final int colorCount;
  final int moveBudget;
  final int targetScore;

  int get boardSize => rows * cols;
}
