import 'package:flutter/foundation.dart';
import '../domain/level_data.dart';

/// État du jeu en cours.
enum GameStatus {
  /// En attente de démarrage.
  idle,

  /// Jeu en cours.
  playing,

  /// Jeu en pause.
  paused,

  /// Niveau réussi.
  victory,

  /// Niveau échoué (temps écoulé ou vies épuisées).
  defeat,
}

/// Connexion réalisée entre deux nœuds.
class Connection {
  final int from;
  final int to;

  const Connection(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      other is Connection &&
      ((from == other.from && to == other.to) ||
          (from == other.to && to == other.from));

  @override
  int get hashCode =>
      Object.hash(from < to ? from : to, from < to ? to : from);
}

/// État du jeu — score, vies, coups, timer, connexions, statut.
///
/// Système de vies et coups :
/// - Chaque niveau a un nombre de vies (ex: 3) et de coups par vie (ex: 5).
/// - Le joueur commence avec [lives] vies et [attemptsPerLife] coups.
/// - Une tentative ratée (connexion invalide) consomme 1 coup.
/// - Une tentative réussie ne consomme rien.
/// - Quand tous les coups d'une vie sont épuisés, on perd 1 vie et on
///   récupère [attemptsPerLife] coups.
/// - Quand toutes les vies sont épuisées, la partie est perdue.
class GameState extends ChangeNotifier {
  LevelData _level;
  GameStatus _status = GameStatus.idle;
  int _lives;
  int _attemptsPerLife;
  int _attemptsRemaining;
  double _timeRemaining;
  int _score = 0;
  final Set<Connection> _connections = {};
  int _activatedNodes = 0;

  GameState({LevelData? level})
      : _level = level ?? World1Levels.levels.first,
        _lives = level?.lives ?? 3,
        _attemptsPerLife = level?.attemptsPerLife ?? 5,
        _timeRemaining = level?.timeLimit ?? 90.0,
        _attemptsRemaining = level?.attemptsPerLife ?? 5;

  // Getters
  LevelData get level => _level;
  GameStatus get status => _status;
  int get lives => _lives;
  int get attemptsPerLife => _attemptsPerLife;
  int get attemptsRemaining => _attemptsRemaining;
  double get timeRemaining => _timeRemaining;
  int get score => _score;
  Set<Connection> get connections => Set.unmodifiable(_connections);
  int get activatedNodes => _activatedNodes;

  double get maxTime => _level.timeLimit;
  int get maxLives => _level.lives;

  /// Progression du timer (0.0 à 1.0).
  double get timerProgress =>
      (_timeRemaining / _level.timeLimit).clamp(0.0, 1.0);

  /// Nombre de connexions requises restantes.
  int get remainingConnections => _level.requiredConnections
      .where((rc) => !_connections.contains(Connection(rc.from, rc.to)))
      .length;

  /// Pourcentage de complétion du niveau.
  double get completionProgress =>
      _connections.length / _level.totalConnections;

  /// Nombre d'étoiles gagnées (0-3).
  int get stars {
    final progress = completionProgress;
    if (progress >= 1.0) {
      if (_timeRemaining > _level.timeLimit * 0.6) return 3;
      if (_timeRemaining > _level.timeLimit * 0.3) return 2;
      return 1;
    }
    return 0;
  }

  /// Charge un niveau.
  void loadLevel(LevelData level) {
    _level = level;
    _lives = level.lives;
    _attemptsPerLife = level.attemptsPerLife;
    _attemptsRemaining = level.attemptsPerLife;
    _timeRemaining = level.timeLimit;
    _score = 0;
    _connections.clear();
    _activatedNodes = 0;
    _status = GameStatus.idle;
    notifyListeners();
  }

  /// Démarre le jeu.
  void start() {
    _status = GameStatus.playing;
    notifyListeners();
  }

  /// Met en pause.
  void pause() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      notifyListeners();
    }
  }

  /// Reprend après pause.
  void resume() {
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      notifyListeners();
    }
  }

  /// Tick du timer — appelé chaque frame par le moteur Flame.
  /// Retourne true si le temps est écoulé.
  bool tickTimer(double dt) {
    if (_status != GameStatus.playing) return false;

    _timeRemaining -= dt;
    if (_timeRemaining <= 0) {
      _timeRemaining = 0;
      _status = GameStatus.defeat;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  /// Un nœud a été activé (tap).
  void activateNode(int index) {
    _activatedNodes++;
    notifyListeners();
  }

  /// Ajoute une connexion entre deux nœuds.
  /// - Connexion valide : +100 points, pas de consommation de coup.
  /// - Connexion invalide : -1 coup. Si plus de coups, -1 vie + coups
  ///   réinitialisés. Si plus de vies, défaite.
  /// - Connexion dupliquée (valide mais déjà faite) : coup perdu.
  bool addConnection(int from, int to) {
    final conn = Connection(from, to);
    final isValid = _level.requiredConnections.any(
      (rc) =>
          (rc.from == from && rc.to == to) ||
          (rc.from == to && rc.to == from),
    );

    if (isValid && !_connections.contains(conn)) {
      // Connexion valide et nouvelle : succès, pas de coût
      _connections.add(conn);
      _score += 100;
      _checkVictory();
      notifyListeners();
      return true;
    }

    // Connexion invalide ou dupliquée : coûte un coup
    _attemptsRemaining--;

    if (_attemptsRemaining <= 0) {
      // Plus de coups pour cette vie : on perd une vie
      _lives--;
      if (_lives <= 0) {
        // Plus de vies : défaite
        _lives = 0;
        _status = GameStatus.defeat;
      } else {
        // Vie suivante : on récupère les coups
        _attemptsRemaining = _attemptsPerLife;
      }
    }

    notifyListeners();
    return false;
  }

  /// Utilise un indice (réduction du score, pas de coût en coups).
  void useHint() {
    _score = (_score - 50).clamp(0, _score);
    notifyListeners();
  }

  /// Vérifie si toutes les connexions sont réalisées.
  void _checkVictory() {
    for (final rc in _level.requiredConnections) {
      final conn = Connection(rc.from, rc.to);
      if (!_connections.contains(conn)) return;
    }
    _status = GameStatus.victory;
    // Bonus de temps
    _score += (_timeRemaining * 10).toInt();
    notifyListeners();
  }

  /// Réinitialise l'état pour rejouer le niveau.
  void reset() {
    _lives = _level.lives;
    _attemptsPerLife = _level.attemptsPerLife;
    _attemptsRemaining = _attemptsPerLife;
    _timeRemaining = _level.timeLimit;
    _score = 0;
    _connections.clear();
    _activatedNodes = 0;
    _status = GameStatus.idle;
    notifyListeners();
  }
}