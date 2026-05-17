import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedPlacement {
  defeatContinue,
  shopLives,
  shopHints,
  shopThemeTrial,
  eventDailyBoost,
  eventWeekendBoost,
  eventTournamentBoost,
  eventHappyHour,
}

abstract class RewardedAdService {
  Future<void> initialize();
  Future<bool> showRewardedAd({
    required RewardedPlacement placement,
    required VoidCallback onRewardEarned,
  });
}

class AdMobRewardedAdService implements RewardedAdService {
  AdMobRewardedAdService({String? rewardedAdUnitId})
      : _rewardedAdUnitId = rewardedAdUnitId ?? _defaultRewardedAdUnitId;

  static final AdMobRewardedAdService instance = AdMobRewardedAdService();

  final String _rewardedAdUnitId;
  RewardedAd? _rewardedAd;
  Future<void>? _loadingFuture;
  bool _initialized = false;

  static const String _defaultRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await MobileAds.instance.initialize();
    _initialized = true;
    await _ensureLoaded();
  }

  @override
  Future<bool> showRewardedAd({
    required RewardedPlacement placement,
    required VoidCallback onRewardEarned,
  }) async {
    await _ensureLoaded();
    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('Rewarded ad unavailable for placement: $placement');
      return false;
    }

    final completer = Completer<bool>();
    var rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        unawaited(_ensureLoaded());
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        unawaited(_ensureLoaded());
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
        onRewardEarned();
      },
    );

    _rewardedAd = null;
    return completer.future;
  }

  Future<void> _ensureLoaded() {
    if (_rewardedAd != null) {
      return Future<void>.value();
    }
    if (_loadingFuture != null) {
      return _loadingFuture!;
    }

    final completer = Completer<void>();
    _loadingFuture = completer.future;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingFuture = null;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _loadingFuture = null;
          completer.complete();
        },
      ),
    );

    return _loadingFuture!;
  }
}