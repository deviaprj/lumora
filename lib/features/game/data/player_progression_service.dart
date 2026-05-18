import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/level_data.dart';

class PlayerProgressionService extends ChangeNotifier {
  PlayerProgressionService._();

  static final PlayerProgressionService instance = PlayerProgressionService._();

  static const String _completedLevelIdKey = 'player_progression_completed_level_id';
  static const String _seenWorldIdsKey = 'player_progression_seen_world_ids';
  static const String _seenRuleKeysKey = 'player_progression_seen_rule_keys';

  SharedPreferences? _prefs;
  Future<void>? _loadFuture;

  int completedLevelId = 0;
  final Set<int> seenWorldIds = <int>{};
  final Set<String> seenRuleKeys = <String>{};

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
    completedLevelId = _prefs!.getInt(_completedLevelIdKey) ?? 0;

    seenWorldIds
      ..clear()
      ..addAll(
        (_decodeIntList(_prefs!.getString(_seenWorldIdsKey))).toSet(),
      );

    seenRuleKeys
      ..clear()
      ..addAll(_decodeStringList(_prefs!.getString(_seenRuleKeysKey)));

    _loadFuture = null;
    notifyListeners();
  }

  Future<void> markLevelSeen(LevelData level) async {
    await load();
    final changed = seenWorldIds.add(level.worldId) | seenRuleKeys.add(level.specialRule.name);
    if (!changed) {
      return;
    }

    await _save();
    notifyListeners();
  }

  Future<void> markLevelCompleted(LevelData level) async {
    await load();

    var changed = false;
    if (level.id > completedLevelId) {
      completedLevelId = level.id;
      changed = true;
    }

    changed = seenWorldIds.add(level.worldId) || changed;
    changed = seenRuleKeys.add(level.specialRule.name) || changed;

    if (!changed) {
      return;
    }

    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    await Future.wait<void>([
      prefs.setInt(_completedLevelIdKey, completedLevelId),
      prefs.setString(_seenWorldIdsKey, jsonEncode(seenWorldIds.toList()..sort())),
      prefs.setString(_seenRuleKeysKey, jsonEncode(seenRuleKeys.toList()..sort())),
    ]);
  }

  @visibleForTesting
  void resetForTest() {
    _prefs = null;
    _loadFuture = null;
    completedLevelId = 0;
    seenWorldIds.clear();
    seenRuleKeys.clear();
    notifyListeners();
  }

  @visibleForTesting
  Future<void> flushForTest() async {
    await _save();
  }

  List<int> _decodeIntList(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return const <int>[];
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is List) {
        return decoded.whereType<num>().map((value) => value.toInt()).toList(growable: false);
      }
    } catch (_) {
      // Ignore legacy or malformed values and keep defaults.
    }

    return const <int>[];
  }

  List<String> _decodeStringList(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return const <String>[];
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } catch (_) {
      // Ignore legacy or malformed values and keep defaults.
    }

    return const <String>[];
  }
}