import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Résumé d'une partie enregistrée.
@immutable
class CrystalProgressionSummary {
  const CrystalProgressionSummary({
    required this.highestUnlockedLevel,
    required this.dailyStreak,
    required this.bestScore,
    required this.newBestScore,
    required this.levelUnlocked,
  });

  final int highestUnlockedLevel;
  final int dailyStreak;
  final int bestScore;
  final bool newBestScore;
  final bool levelUnlocked;
}

/// Progression persistante du mode Cristaux.
///
/// Elle garde le palier débloqué, le meilleur score, le total de cristaux
/// libérés et la série de jours joués — cette série est la « série à tenir »
/// hors partie, en écho à la série de dissolutions pendant un palier.
class CrystalProgressionService extends ChangeNotifier {
  CrystalProgressionService._();

  static final CrystalProgressionService instance =
      CrystalProgressionService._();

  static const String _highestUnlockedKey =
      'crystal_progression_highest_unlocked_level';
  static const String _bestScoreKey = 'crystal_progression_best_score';
  static const String _totalCrystalsKey = 'crystal_progression_total_cleared';
  static const String _dailyStreakKey = 'crystal_progression_daily_streak';
  static const String _lastPlayedDayKey = 'crystal_progression_last_played_day';

  SharedPreferences? _prefs;
  Future<void>? _loadFuture;

  int highestUnlockedLevel = 1;
  int bestScore = 0;
  int totalCrystals = 0;
  int dailyStreak = 0;

  bool get isLoaded => _prefs != null;

  Future<void> load() {
    if (_prefs != null) {
      return Future<void>.value();
    }
    final pending = _loadFuture;
    if (pending != null) {
      return pending;
    }

    late final Future<void> future;
    future = _loadFromPrefs().whenComplete(() {
      // Un chargement en échec doit pouvoir être retenté plus tard.
      if (identical(_loadFuture, future)) {
        _loadFuture = null;
      }
    });
    _loadFuture = future;
    return future;
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    highestUnlockedLevel = _prefs!.getInt(_highestUnlockedKey) ?? 1;
    if (highestUnlockedLevel < 1) {
      highestUnlockedLevel = 1;
    }
    bestScore = _prefs!.getInt(_bestScoreKey) ?? 0;
    totalCrystals = _prefs!.getInt(_totalCrystalsKey) ?? 0;
    dailyStreak = _prefs!.getInt(_dailyStreakKey) ?? 0;

    notifyListeners();
  }

  /// Enregistre une partie terminée et met à jour la série de jours.
  Future<CrystalProgressionSummary> recordRun({
    required int level,
    required int score,
    required int crystalsCleared,
    required bool victory,
    DateTime? now,
  }) async {
    await load();

    final newBestScore = score > bestScore;
    if (newBestScore) {
      bestScore = score;
    }
    if (crystalsCleared > 0) {
      totalCrystals += crystalsCleared;
    }

    final previousHighest = highestUnlockedLevel;
    if (victory && level + 1 > highestUnlockedLevel) {
      highestUnlockedLevel = level + 1;
    }

    _updateDailyStreak(now ?? DateTime.now());
    await _save();
    notifyListeners();

    return CrystalProgressionSummary(
      highestUnlockedLevel: highestUnlockedLevel,
      dailyStreak: dailyStreak,
      bestScore: bestScore,
      newBestScore: newBestScore,
      levelUnlocked: highestUnlockedLevel > previousHighest,
    );
  }

  void _updateDailyStreak(DateTime now) {
    // Dates en UTC : le passage à l'heure d'été ne fausse pas le décompte.
    final today = DateTime.utc(now.year, now.month, now.day);
    final lastPlayed = _readLastPlayedDay();

    if (lastPlayed == null) {
      dailyStreak = 1;
    } else {
      final difference = today.difference(lastPlayed).inDays;
      if (difference == 0) {
        if (dailyStreak < 1) {
          dailyStreak = 1;
        }
      } else if (difference == 1) {
        dailyStreak += 1;
      } else {
        dailyStreak = 1;
      }
    }

    _lastPlayedDay = today;
  }

  DateTime? _lastPlayedDay;

  DateTime? _readLastPlayedDay() {
    if (_lastPlayedDay != null) {
      return _lastPlayedDay;
    }
    final raw = _prefs?.getString(_lastPlayedDayKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parts = raw.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime.utc(year, month, day);
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    await Future.wait<void>([
      prefs.setInt(_highestUnlockedKey, highestUnlockedLevel),
      prefs.setInt(_bestScoreKey, bestScore),
      prefs.setInt(_totalCrystalsKey, totalCrystals),
      prefs.setInt(_dailyStreakKey, dailyStreak),
      prefs.setString(
        _lastPlayedDayKey,
        _formatDay(_lastPlayedDay ?? DateTime.now()),
      ),
    ]);
  }

  String _formatDay(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year.toString().padLeft(4, '0')}-$month-$dayOfMonth';
  }

  @visibleForTesting
  void resetForTest() {
    _prefs = null;
    _loadFuture = null;
    highestUnlockedLevel = 1;
    bestScore = 0;
    totalCrystals = 0;
    dailyStreak = 0;
    _lastPlayedDay = null;
    notifyListeners();
  }

  @visibleForTesting
  Future<void> flushForTest() async {
    await _save();
  }
}
