import 'dart:math';

import 'package:flutter/foundation.dart';

import 'crystal_board.dart';
import 'crystal_models.dart';

/// État d'une partie de cristaux.
enum CrystalRunStatus {
  playing,
  victory,
  defeat,
}

/// Résultat de la dernière interaction du joueur.
enum CrystalAction {
  none,
  selected,
  deselected,
  moved,
  cleared,
  invalid,
  ignored,
}

/// Partie de cristaux en cours.
///
/// La boucle est simple : sélectionner un cristal, toucher un voisin de même
/// couleur, libérer le groupe. Chaque dissolution réussie entretient une
/// série qui augmente le multiplicateur ; une tentative ratée remet la série
/// à zéro sans faire perdre de geste.
class CrystalRun extends ChangeNotifier {
  CrystalRun({
    required this.config,
    CrystalBoard? board,
  })  : _board = board ??
            CrystalBoard.generate(
              rows: config.rows,
              cols: config.cols,
              colorCount: config.colorCount,
            ),
        _movesRemaining = config.moveBudget;

  final CrystalLevelConfig config;

  CrystalBoard _board;
  int _score = 0;
  int _movesRemaining = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _crystalsCleared = 0;
  int _lastPoints = 0;
  int _victoryBonus = 0;
  int _lastMovesRemaining = 0;
  CrystalPosition? _selected;
  CrystalRunStatus _status = CrystalRunStatus.playing;
  CrystalAction _lastAction = CrystalAction.none;
  List<CrystalPosition> _lastCleared = const <CrystalPosition>[];
  CrystalColor? _lastColor;

  CrystalBoard get board => _board;
  int get score => _score;
  int get movesRemaining => _movesRemaining;
  int get movesUsed => config.moveBudget - _movesRemaining;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  int get crystalsCleared => _crystalsCleared;
  int get lastPoints => _lastPoints;
  int get victoryBonus => _victoryBonus;
  int get lastMovesRemaining => _lastMovesRemaining;
  CrystalPosition? get selected => _selected;
  CrystalRunStatus get status => _status;
  CrystalAction get lastAction => _lastAction;
  List<CrystalPosition> get lastCleared => _lastCleared;
  CrystalColor? get lastColor => _lastColor;

  /// Multiplicateur appliqué à la prochaine dissolution.
  double get streakMultiplier => 1 + (min(_streak, 10) * 0.1);

  /// Progression vers l'objectif, bornée pour l'affichage.
  double get progress =>
      (config.targetScore == 0 ? 1.0 : _score / config.targetScore)
          .clamp(0.0, 1.0);

  /// Étoiles gagnées : elles récompensent les gestes encore disponibles.
  int get stars {
    if (_status != CrystalRunStatus.victory) {
      return 0;
    }
    final ratio = _lastMovesRemaining / config.moveBudget;
    if (ratio >= 0.45) {
      return 3;
    }
    if (ratio >= 0.2) {
      return 2;
    }
    return 1;
  }

  /// Sélectionne une case et applique l'action correspondante.
  ///
  /// Taper une case éloignée déplace simplement la sélection. Seul un voisin
  /// de couleur différente casse la série : le jeu ne punit jamais une
  /// exploration hésitante.
  CrystalAction select(int row, int col) {
    if (_status != CrystalRunStatus.playing) {
      return CrystalAction.ignored;
    }
    if (!_board.isInside(row, col) || _board.cellAt(row, col) == null) {
      return CrystalAction.ignored;
    }

    final position = CrystalPosition(row, col);
    final selected = _selected;

    if (selected == null) {
      _selected = position;
      _lastAction = CrystalAction.selected;
      notifyListeners();
      return _lastAction;
    }

    if (selected == position) {
      _selected = null;
      _lastAction = CrystalAction.deselected;
      notifyListeners();
      return _lastAction;
    }

    if (!_areAdjacent(selected, position)) {
      _selected = position;
      _lastAction = CrystalAction.moved;
      notifyListeners();
      return _lastAction;
    }

    final selectedColor = _board.cellAt(selected.row, selected.col);
    final targetColor = _board.cellAt(row, col);
    if (selectedColor == null ||
        targetColor == null ||
        selectedColor != targetColor) {
      _streak = 0;
      _selected = null;
      _lastAction = CrystalAction.invalid;
      notifyListeners();
      return _lastAction;
    }

    final result = _board.clearGroupAt(row, col);
    if (result.isEmpty) {
      _streak = 0;
      _selected = null;
      _lastAction = CrystalAction.invalid;
      notifyListeners();
      return _lastAction;
    }

    _applyClear(result);
    notifyListeners();
    return _lastAction;
  }

  /// Relance le palier courant avec un plateau neuf.
  ///
  /// [board] permet d'imposer un plateau déterministe (tests, tutoriel).
  void retry({CrystalBoard? board}) {
    _board = board ??
        CrystalBoard.generate(
          rows: config.rows,
          cols: config.cols,
          colorCount: config.colorCount,
        );
    _score = 0;
    _movesRemaining = config.moveBudget;
    _streak = 0;
    _bestStreak = 0;
    _crystalsCleared = 0;
    _lastPoints = 0;
    _victoryBonus = 0;
    _lastMovesRemaining = 0;
    _selected = null;
    _status = CrystalRunStatus.playing;
    _lastAction = CrystalAction.none;
    _lastCleared = const <CrystalPosition>[];
    _lastColor = null;
    notifyListeners();
  }

  void _applyClear(CrystalClearResult result) {
    final multiplier = streakMultiplier;
    final basePoints =
        result.count * 25 + result.count * (result.count - 1) * 5;
    _lastPoints = (basePoints * multiplier).round();
    _score += _lastPoints;
    _crystalsCleared += result.count;
    _lastCleared = result.positions;
    _lastColor = result.color;
    _streak += 1;
    if (_streak > _bestStreak) {
      _bestStreak = _streak;
    }
    _movesRemaining = (_movesRemaining - 1).clamp(0, config.moveBudget);
    _selected = null;
    _lastAction = CrystalAction.cleared;

    if (_score >= config.targetScore) {
      _lastMovesRemaining = _movesRemaining;
      _victoryBonus = _movesRemaining * 25;
      _score += _victoryBonus;
      _status = CrystalRunStatus.victory;
      return;
    }

    if (_movesRemaining <= 0) {
      _status = CrystalRunStatus.defeat;
    }
  }

  bool _areAdjacent(CrystalPosition a, CrystalPosition b) {
    final rowDistance = (a.row - b.row).abs();
    final colDistance = (a.col - b.col).abs();
    return rowDistance + colDistance == 1;
  }
}
