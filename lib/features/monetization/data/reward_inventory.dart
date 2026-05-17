import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../game/domain/level_data.dart';
import 'rewarded_ad_service.dart';

class ObjectiveRewardSummary {
  final int hintCharges;
  final int doubleScoreCharges;
  final int superFilamentCharges;
  final int bankedLives;

  const ObjectiveRewardSummary({
    this.hintCharges = 0,
    this.doubleScoreCharges = 0,
    this.superFilamentCharges = 0,
    this.bankedLives = 0,
  });

  bool get hasRewards =>
      hintCharges > 0 ||
      doubleScoreCharges > 0 ||
      superFilamentCharges > 0 ||
      bankedLives > 0;

  List<String> get rewardEntries {
    final entries = <String>[];
    if (hintCharges > 0) {
      entries.add('+$hintCharges indice${hintCharges > 1 ? 's' : ''}');
    }
    if (doubleScoreCharges > 0) {
      entries.add('+$doubleScoreCharges Double Score');
    }
    if (superFilamentCharges > 0) {
      entries.add('+$superFilamentCharges Super Filament');
    }
    if (bankedLives > 0) {
      entries.add('+$bankedLives vie${bankedLives > 1 ? 's' : ''} de réserve');
    }
    return entries;
  }
}

extension RewardedPlacementInventoryUi on RewardedPlacement {
  String get label => switch (this) {
        RewardedPlacement.defeatContinue => 'Continuer la partie',
        RewardedPlacement.shopLives => 'Vie bonus',
        RewardedPlacement.shopHints => 'Indice bonus',
        RewardedPlacement.shopThemeTrial => 'Essai thème',
        RewardedPlacement.eventDailyBoost => 'Aide quotidienne',
        RewardedPlacement.eventWeekendBoost => 'Super Filament',
        RewardedPlacement.eventTournamentBoost => 'Double Score',
        RewardedPlacement.eventHappyHour => 'Happy Hour',
      };

  String get rewardDescription => switch (this) {
        RewardedPlacement.defeatContinue => '+1 ou +2 vies selon la tentative',
        RewardedPlacement.shopLives => '+1 vie en réserve',
        RewardedPlacement.shopHints => '+1 indice manuel',
        RewardedPlacement.shopThemeTrial => 'Thème Nébula pendant 30 min',
        RewardedPlacement.eventDailyBoost => '+1 indice manuel',
        RewardedPlacement.eventWeekendBoost => '+1 charge Super Filament',
        RewardedPlacement.eventTournamentBoost => '+1 charge Double Score',
        RewardedPlacement.eventHappyHour => '+2 vies en réserve',
      };

  Duration? get cooldown => switch (this) {
        RewardedPlacement.defeatContinue => null,
        RewardedPlacement.shopLives => const Duration(minutes: 30),
        RewardedPlacement.shopHints => const Duration(minutes: 30),
        RewardedPlacement.shopThemeTrial => const Duration(hours: 12),
        RewardedPlacement.eventDailyBoost => const Duration(hours: 24),
        RewardedPlacement.eventWeekendBoost => const Duration(hours: 8),
        RewardedPlacement.eventTournamentBoost => const Duration(hours: 12),
        RewardedPlacement.eventHappyHour => const Duration(hours: 4),
      };
}

class RewardInventory extends ChangeNotifier {
  RewardInventory._();

  static final RewardInventory instance = RewardInventory._();

  static const String _bankedLivesKey = 'reward_inventory_banked_lives';
  static const String _hintChargesKey = 'reward_inventory_hint_charges';
  static const String _doubleScoreChargesKey = 'reward_inventory_double_score_charges';
  static const String _superFilamentChargesKey = 'reward_inventory_super_filament_charges';
  static const String _activeThemeTrialsKey = 'reward_inventory_active_theme_trials';
  static const String _lastRewardAtKey = 'reward_inventory_last_reward_at';
  static const String _rewardedObjectivesKey = 'reward_inventory_rewarded_objectives';

  int bankedLives = 0;
  int hintCharges = 0;
  int doubleScoreCharges = 0;
  int superFilamentCharges = 0;
  final Map<String, DateTime> activeThemeTrials = <String, DateTime>{};
  final Map<RewardedPlacement, DateTime> _lastRewardAt = <RewardedPlacement, DateTime>{};
  final Set<String> _rewardedObjectiveKeys = <String>{};
  SharedPreferences? _prefs;
  Future<void>? _loadFuture;

  bool get isLoaded => _prefs != null;

  Future<void> load() {
    if (_prefs != null) {
      return Future<void>.value();
    }
    if (_loadFuture != null) {
      return _loadFuture!;
    }

    final completer = Completer<void>();
    _loadFuture = completer.future;
    _loadFromPrefs().then(completer.complete).catchError(completer.completeError);
    return _loadFuture!;
  }

  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    bankedLives = _prefs!.getInt(_bankedLivesKey) ?? 0;
    hintCharges = _prefs!.getInt(_hintChargesKey) ?? 0;
    doubleScoreCharges = _prefs!.getInt(_doubleScoreChargesKey) ?? 0;
    superFilamentCharges = _prefs!.getInt(_superFilamentChargesKey) ?? 0;

    activeThemeTrials
      ..clear()
      ..addAll(_decodeStringDateMap(_prefs!.getString(_activeThemeTrialsKey)));

    _lastRewardAt
      ..clear()
      ..addAll(_decodePlacementDateMap(_prefs!.getString(_lastRewardAtKey)));

    _rewardedObjectiveKeys
      ..clear()
      ..addAll(_decodeStringSet(_prefs!.getString(_rewardedObjectivesKey)));

    _pruneExpiredRewards();
    _loadFuture = null;
    notifyListeners();
  }

  bool canClaim(RewardedPlacement placement, {DateTime? now}) {
    final cooldown = placement.cooldown;
    if (cooldown == null) {
      return true;
    }

    final referenceNow = now ?? DateTime.now();
    final lastRewardAt = _lastRewardAt[placement];
    if (lastRewardAt == null) {
      return true;
    }

    return referenceNow.difference(lastRewardAt) >= cooldown;
  }

  Duration? remainingCooldown(RewardedPlacement placement, {DateTime? now}) {
    final cooldown = placement.cooldown;
    if (cooldown == null) {
      return null;
    }

    final referenceNow = now ?? DateTime.now();
    final lastRewardAt = _lastRewardAt[placement];
    if (lastRewardAt == null) {
      return Duration.zero;
    }

    final remaining = cooldown - referenceNow.difference(lastRewardAt);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool claim(RewardedPlacement placement, {DateTime? now}) {
    if (!canClaim(placement, now: now)) {
      return false;
    }

    final referenceNow = now ?? DateTime.now();
    switch (placement) {
      case RewardedPlacement.defeatContinue:
        return true;
      case RewardedPlacement.shopLives:
        bankedLives += 1;
      case RewardedPlacement.shopHints:
      case RewardedPlacement.eventDailyBoost:
        hintCharges += 1;
      case RewardedPlacement.shopThemeTrial:
        activeThemeTrials['Nebula'] = referenceNow.add(const Duration(minutes: 30));
      case RewardedPlacement.eventWeekendBoost:
        superFilamentCharges += 1;
      case RewardedPlacement.eventTournamentBoost:
        doubleScoreCharges += 1;
      case RewardedPlacement.eventHappyHour:
        bankedLives += 2;
    }

    _lastRewardAt[placement] = referenceNow;
    _scheduleSave();
    notifyListeners();
    return true;
  }

  bool consumeBankedLife() {
    if (bankedLives <= 0) {
      return false;
    }
    bankedLives -= 1;
    _scheduleSave();
    notifyListeners();
    return true;
  }

  bool consumeHintCharge() {
    if (hintCharges <= 0) {
      return false;
    }
    hintCharges -= 1;
    _scheduleSave();
    notifyListeners();
    return true;
  }

  bool consumeDoubleScoreCharge() {
    if (doubleScoreCharges <= 0) {
      return false;
    }
    doubleScoreCharges -= 1;
    _scheduleSave();
    notifyListeners();
    return true;
  }

  bool consumeSuperFilamentCharge() {
    if (superFilamentCharges <= 0) {
      return false;
    }
    superFilamentCharges -= 1;
    _scheduleSave();
    notifyListeners();
    return true;
  }

  ObjectiveRewardSummary grantSecondaryObjectiveRewards({
    required int levelId,
    required List<SecondaryObjective> completedObjectives,
    required int totalObjectives,
  }) {
    var hintReward = 0;
    var doubleScoreReward = 0;
    var superFilamentReward = 0;
    var bankedLifeReward = 0;

    for (final objective in completedObjectives) {
      final key = _objectiveRewardKey(levelId, objective.type.name);
      if (!_rewardedObjectiveKeys.add(key)) {
        continue;
      }

      switch (objective.type) {
        case SecondaryObjectiveType.noDuplicate:
          hintCharges += 1;
          hintReward += 1;
        case SecondaryObjectiveType.comboChain:
          doubleScoreCharges += 1;
          doubleScoreReward += 1;
        case SecondaryObjectiveType.risingFlow:
          superFilamentCharges += 1;
          superFilamentReward += 1;
      }
    }

    final completedAllObjectives =
        totalObjectives > 0 && completedObjectives.length == totalObjectives;
    if (completedAllObjectives) {
      final perfectKey = _objectiveRewardKey(levelId, 'perfect_bundle');
      if (_rewardedObjectiveKeys.add(perfectKey)) {
        bankedLives += 1;
        bankedLifeReward += 1;
      }
    }

    final summary = ObjectiveRewardSummary(
      hintCharges: hintReward,
      doubleScoreCharges: doubleScoreReward,
      superFilamentCharges: superFilamentReward,
      bankedLives: bankedLifeReward,
    );

    if (summary.hasRewards) {
      _scheduleSave();
      notifyListeners();
    }

    return summary;
  }

  int remainingSecondaryObjectiveRewardCount(LevelData level) {
    if (level.secondaryObjectives.isEmpty) {
      return 0;
    }

    var remaining = 0;
    for (final objective in level.secondaryObjectives) {
      final key = _objectiveRewardKey(level.id, objective.type.name);
      if (!_rewardedObjectiveKeys.contains(key)) {
        remaining++;
      }
    }

    final perfectKey = _objectiveRewardKey(level.id, 'perfect_bundle');
    if (!_rewardedObjectiveKeys.contains(perfectKey)) {
      remaining++;
    }

    return remaining;
  }

  int totalSecondaryObjectiveRewardCount(LevelData level) {
    if (level.secondaryObjectives.isEmpty) {
      return 0;
    }
    return level.secondaryObjectives.length + 1;
  }

  int claimedSecondaryObjectiveRewardCount(LevelData level) {
    final total = totalSecondaryObjectiveRewardCount(level);
    if (total == 0) {
      return 0;
    }
    return total - remainingSecondaryObjectiveRewardCount(level);
  }

  bool hasRemainingSecondaryObjectiveRewards(LevelData level) {
    return remainingSecondaryObjectiveRewardCount(level) > 0;
  }

  bool isThemeTrialActive(String themeName, {DateTime? now}) {
    final expiresAt = activeThemeTrials[themeName];
    if (expiresAt == null) {
      return false;
    }
    return expiresAt.isAfter(now ?? DateTime.now());
  }

  void _pruneExpiredRewards() {
    final now = DateTime.now();
    activeThemeTrials.removeWhere((_, expiresAt) => !expiresAt.isAfter(now));
  }

  void _scheduleSave() {
    if (_prefs == null) {
      return;
    }
    unawaited(_save());
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    _pruneExpiredRewards();
    await prefs.setInt(_bankedLivesKey, bankedLives);
    await prefs.setInt(_hintChargesKey, hintCharges);
    await prefs.setInt(_doubleScoreChargesKey, doubleScoreCharges);
    await prefs.setInt(_superFilamentChargesKey, superFilamentCharges);
    await prefs.setString(_activeThemeTrialsKey, jsonEncode(
      activeThemeTrials.map((key, value) => MapEntry(key, value.toIso8601String())),
    ));
    await prefs.setString(_lastRewardAtKey, jsonEncode(
      _lastRewardAt.map((key, value) => MapEntry(key.name, value.toIso8601String())),
    ));
    await prefs.setString(
      _rewardedObjectivesKey,
      jsonEncode(_rewardedObjectiveKeys.toList(growable: false)),
    );
  }

  Map<String, DateTime> _decodeStringDateMap(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return <String, DateTime>{};
    }

    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, DateTime.parse(value as String)),
    );
  }

  Map<RewardedPlacement, DateTime> _decodePlacementDateMap(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return <RewardedPlacement, DateTime>{};
    }

    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    final valuesByName = {
      for (final value in RewardedPlacement.values) value.name: value,
    };

    final result = <RewardedPlacement, DateTime>{};
    for (final entry in decoded.entries) {
      final placement = valuesByName[entry.key];
      if (placement != null) {
        result[placement] = DateTime.parse(entry.value as String);
      }
    }
    return result;
  }

  Set<String> _decodeStringSet(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return <String>{};
    }

    final decoded = jsonDecode(rawValue) as List<dynamic>;
    return decoded.cast<String>().toSet();
  }

  String _objectiveRewardKey(int levelId, String suffix) => 'level:$levelId:$suffix';

  @visibleForTesting
  void resetForTest() {
    bankedLives = 0;
    hintCharges = 0;
    doubleScoreCharges = 0;
    superFilamentCharges = 0;
    activeThemeTrials.clear();
    _lastRewardAt.clear();
    _rewardedObjectiveKeys.clear();
    _prefs = null;
    _loadFuture = null;
  }

  @visibleForTesting
  Future<void> flushForTest() => _save();
}

