import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class LumoraAnalyticsService {
  LumoraAnalyticsService._();

  static final LumoraAnalyticsService instance = LumoraAnalyticsService._();

  FirebaseAnalytics? get _firebaseAnalytics {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseAnalytics.instance;
  }

  Future<void> logMasteryRewardGranted({
    required int levelId,
    required int worldId,
    required int totalObjectives,
    required int completedObjectives,
    required int stars,
    required int score,
    required List<String> rewardEntries,
  }) async {
    final payload = <String, Object>{
      'event': 'mastery_reward_granted',
      'level_id': levelId,
      'world_id': worldId,
      'objectives_total': totalObjectives,
      'objectives_completed': completedObjectives,
      'stars': stars,
      'score': score,
      'rewards_count': rewardEntries.length,
      'rewards': rewardEntries.join('|'),
    };

    debugPrint('[LumoraAnalytics] $payload');

    final analytics = _firebaseAnalytics;
    if (analytics == null) {
      return;
    }

    await analytics.logEvent(
      name: 'mastery_reward_granted',
      parameters: <String, Object>{
        'level_id': levelId,
        'world_id': worldId,
        'objectives_total': totalObjectives,
        'objectives_completed': completedObjectives,
        'stars': stars,
        'score': score,
        'rewards_count': rewardEntries.length,
        'rewards_compact': rewardEntries.join('_').replaceAll(' ', '_'),
      },
    );
  }
}