import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Unit Test — Logique Monétisation (Pubs + IAP)
// ---------------------------------------------------------------------------

class AdConfig {
  final int interstitialFrequency; // niveaux complets entre chaque pub
  final Duration interstitialCooldown;
  final bool seasonPassDisablesInterstitial;

  const AdConfig({
    this.interstitialFrequency = 5,
    this.interstitialCooldown = const Duration(seconds: 60),
    this.seasonPassDisablesInterstitial = true,
  });
}

class MonetizationLogic {
  final AdConfig config;
  int _levelsCompletedSinceLastAd = 0;
  DateTime? _lastInterstitialShownAt;
  bool _seasonPassActive = false;
  int _rewardedShowsToday = 0;

  MonetizationLogic({required this.config});

  void setSeasonPass(bool active) => _seasonPassActive = active;
  bool get seasonPassActive => _seasonPassActive;

  void recordLevelCompleted() => _levelsCompletedSinceLastAd++;

  void recordInterstitialShown({DateTime? now}) {
    _lastInterstitialShownAt = now ?? DateTime.now();
    _levelsCompletedSinceLastAd = 0;
  }

  bool canShowInterstitial({DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    if (config.seasonPassDisablesInterstitial && _seasonPassActive) return false;

    if (_levelsCompletedSinceLastAd < config.interstitialFrequency) return false;

    if (_lastInterstitialShownAt != null &&
        currentTime.difference(_lastInterstitialShownAt!) < config.interstitialCooldown) {
      return false;
    }

    return true;
  }

  void showRewardedAd() => _rewardedShowsToday++;
  int get rewardedShowsToday => _rewardedShowsToday;

  bool isRewardedVoluntary() => true; // toujours volontaire
}

void main() {
  group('Interstitielles — fréquence', () {
    test('ne s\'affiche pas avant d\'avoir complété N niveaux', () {
      final logic = MonetizationLogic(config: const AdConfig(interstitialFrequency: 5));
      logic.recordLevelCompleted();
      logic.recordLevelCompleted();
      logic.recordLevelCompleted();
      expect(logic.canShowInterstitial(), isFalse);
    });

    test('s\'affiche après exactement N niveaux complets', () {
      final logic = MonetizationLogic(config: const AdConfig(interstitialFrequency: 5));
      for (var i = 0; i < 5; i++) logic.recordLevelCompleted();
      expect(logic.canShowInterstitial(), isTrue);
    });

    test('ne s\'affiche pas deux fois de suite sans nouveau niveau', () {
      final logic = MonetizationLogic(config: const AdConfig(interstitialFrequency: 5));
      for (var i = 0; i < 5; i++) logic.recordLevelCompleted();
      expect(logic.canShowInterstitial(), isTrue);
      logic.recordInterstitialShown(now: DateTime(2026, 5, 7, 12, 0, 0));
      expect(logic.canShowInterstitial(), isFalse);
    });
  });

  group('Interstitielles — exemption Passe Saisonnier', () {
    test('jamais d\'interstitielle si Passe Saisonnier actif', () {
      final logic = MonetizationLogic(config: const AdConfig(interstitialFrequency: 5));
      logic.setSeasonPass(true);
      for (var i = 0; i < 20; i++) logic.recordLevelCompleted();
      expect(logic.canShowInterstitial(), isFalse);
    });

    test('affiche de nouveau si le passe expire', () {
      final logic = MonetizationLogic(config: const AdConfig(interstitialFrequency: 5));
      logic.setSeasonPass(true);
      for (var i = 0; i < 10; i++) logic.recordLevelCompleted();
      expect(logic.canShowInterstitial(), isFalse);

      logic.setSeasonPass(false);
      expect(logic.canShowInterstitial(), isTrue);
    });
  });

  group('Interstitielles — cooldown 60s', () {
    test('ne s\'affiche pas si cooldown de 60s non écoulé', () {
      final logic = MonetizationLogic(config: const AdConfig(interstitialFrequency: 5));
      final base = DateTime(2026, 5, 7, 12, 0, 0);

      for (var i = 0; i < 5; i++) logic.recordLevelCompleted();
      expect(logic.canShowInterstitial(now: base), isTrue);

      logic.recordInterstitialShown(now: base);
      // Avance de 30s seulement
      expect(
        logic.canShowInterstitial(now: base.add(const Duration(seconds: 30))),
        isFalse,
      );
    });

    test('s\'affiche à nouveau après 60s et 5 niveaux', () {
      final logic = MonetizationLogic(config: const AdConfig(interstitialFrequency: 5));
      final base = DateTime(2026, 5, 7, 12, 0, 0);

      for (var i = 0; i < 5; i++) logic.recordLevelCompleted();
      logic.recordInterstitialShown(now: base);
      // Compléter 5 nouveaux niveaux après le cooldown
      for (var i = 0; i < 5; i++) logic.recordLevelCompleted();

      expect(
        logic.canShowInterstitial(now: base.add(const Duration(seconds: 61))),
        isTrue,
      );
    });
  });

  group('Récompensées — volontaires', () {
    test('sont toujours volontaires', () {
      final logic = MonetizationLogic(config: const AdConfig());
      expect(logic.isRewardedVoluntary(), isTrue);
    });

    test('incrémentent le compteur de visionnements', () {
      final logic = MonetizationLogic(config: const AdConfig());
      logic.showRewardedAd();
      logic.showRewardedAd();
      expect(logic.rewardedShowsToday, equals(2));
    });
  });
}
