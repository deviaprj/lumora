import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';
import 'package:lumora_mobile/features/monetization/data/reward_inventory.dart';
import 'package:lumora_mobile/features/monetization/data/rewarded_ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RewardInventory', () {
    late RewardInventory inventory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      inventory = RewardInventory.instance;
      inventory.resetForTest();
      await inventory.load();
    });

    test('claim persists rewards and cooldowns across reloads', () async {
      final claimed = inventory.claim(
        RewardedPlacement.shopLives,
        now: DateTime(2026, 5, 17, 10),
      );
      await inventory.flushForTest();

      expect(claimed, isTrue);
      expect(inventory.bankedLives, 1);
      expect(inventory.canClaim(RewardedPlacement.shopLives, now: DateTime(2026, 5, 17, 10, 10)), isFalse);

      inventory.resetForTest();
      await inventory.load();

      expect(inventory.bankedLives, 1);
      expect(inventory.canClaim(RewardedPlacement.shopLives, now: DateTime(2026, 5, 17, 10, 10)), isFalse);
      expect(inventory.canClaim(RewardedPlacement.shopLives, now: DateTime(2026, 5, 17, 10, 31)), isTrue);
    });

    test('consuming persisted hint charge updates stored inventory', () async {
      inventory.claim(
        RewardedPlacement.shopHints,
        now: DateTime(2026, 5, 17, 12),
      );
      await inventory.flushForTest();

      expect(inventory.hintCharges, 1);
      expect(inventory.consumeHintCharge(), isTrue);
      expect(inventory.hintCharges, 0);
      await inventory.flushForTest();

      inventory.resetForTest();
      await inventory.load();

      expect(inventory.hintCharges, 0);
    });

    test('double score and super filament charges persist after claim and consume', () async {
      inventory.claim(
        RewardedPlacement.eventTournamentBoost,
        now: DateTime(2026, 5, 17, 14),
      );
      inventory.claim(
        RewardedPlacement.eventWeekendBoost,
        now: DateTime(2026, 5, 17, 15),
      );
      await inventory.flushForTest();

      expect(inventory.doubleScoreCharges, 1);
      expect(inventory.superFilamentCharges, 1);
      expect(inventory.consumeDoubleScoreCharge(), isTrue);
      expect(inventory.consumeSuperFilamentCharge(), isTrue);
      await inventory.flushForTest();

      inventory.resetForTest();
      await inventory.load();

      expect(inventory.doubleScoreCharges, 0);
      expect(inventory.superFilamentCharges, 0);
    });

    test('secondary objective rewards are granted once per level and persisted', () async {
      final summary = inventory.grantSecondaryObjectiveRewards(
        levelId: 18,
        completedObjectives: const [
          SecondaryObjective(SecondaryObjectiveType.noDuplicate),
          SecondaryObjective(SecondaryObjectiveType.comboChain, threshold: 4),
          SecondaryObjective(SecondaryObjectiveType.risingFlow),
        ],
        totalObjectives: 3,
      );
      await inventory.flushForTest();

      expect(summary.hasRewards, isTrue);
      expect(summary.hintCharges, 1);
      expect(summary.doubleScoreCharges, 1);
      expect(summary.superFilamentCharges, 1);
      expect(summary.bankedLives, 1);
      expect(inventory.hintCharges, 1);
      expect(inventory.doubleScoreCharges, 1);
      expect(inventory.superFilamentCharges, 1);
      expect(inventory.bankedLives, 1);

      final duplicateSummary = inventory.grantSecondaryObjectiveRewards(
        levelId: 18,
        completedObjectives: const [
          SecondaryObjective(SecondaryObjectiveType.noDuplicate),
          SecondaryObjective(SecondaryObjectiveType.comboChain, threshold: 4),
          SecondaryObjective(SecondaryObjectiveType.risingFlow),
        ],
        totalObjectives: 3,
      );

      expect(duplicateSummary.hasRewards, isFalse);

      inventory.resetForTest();
      await inventory.load();

      expect(inventory.hintCharges, 1);
      expect(inventory.doubleScoreCharges, 1);
      expect(inventory.superFilamentCharges, 1);
      expect(inventory.bankedLives, 1);
    });

    test('remaining secondary objective reward count reflects claimed mastery rewards', () async {
      const level = LevelData(
        id: 23,
        name: 'Meta test',
        nodes: [
          NodePosition(0.2, 0.2),
          NodePosition(0.8, 0.2),
          NodePosition(0.5, 0.8),
        ],
        requiredConnections: [
          RequiredConnection(0, 1),
          RequiredConnection(1, 2),
        ],
        secondaryObjectives: [
          SecondaryObjective(SecondaryObjectiveType.noDuplicate),
          SecondaryObjective(SecondaryObjectiveType.comboChain, threshold: 3),
          SecondaryObjective(SecondaryObjectiveType.risingFlow),
        ],
      );

      expect(inventory.remainingSecondaryObjectiveRewardCount(level), 4);

      inventory.grantSecondaryObjectiveRewards(
        levelId: level.id,
        completedObjectives: const [
          SecondaryObjective(SecondaryObjectiveType.noDuplicate),
        ],
        totalObjectives: level.secondaryObjectives.length,
      );

      expect(inventory.remainingSecondaryObjectiveRewardCount(level), 3);
      expect(inventory.hasRemainingSecondaryObjectiveRewards(level), isTrue);
    });
  });
}