import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/data/player_progression_service.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerProgressionService', () {
    late PlayerProgressionService progressionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      progressionService = PlayerProgressionService.instance;
      progressionService.resetForTest();
      await progressionService.load();
    });

    test('markLevelCompleted persists the highest completed level and seen metadata', () async {
      final level11 = LevelCatalog.byId(11);
      final level12 = LevelCatalog.byId(12);

      await progressionService.markLevelCompleted(level11);
      await progressionService.markLevelCompleted(level12);
      await progressionService.flushForTest();

      expect(progressionService.completedLevelId, 12);
      expect(progressionService.seenWorldIds.contains(level11.worldId), isTrue);
      expect(progressionService.seenRuleKeys.contains(level12.specialRule.name), isTrue);

      progressionService.resetForTest();
      await progressionService.load();

      expect(progressionService.completedLevelId, 12);
      expect(progressionService.seenWorldIds.contains(level11.worldId), isTrue);
      expect(progressionService.seenRuleKeys.contains(level12.specialRule.name), isTrue);
    });

    test('markLevelSeen records world and rule without inflating completed progress', () async {
      final level15 = LevelCatalog.byId(15);

      await progressionService.markLevelSeen(level15);
      await progressionService.flushForTest();

      expect(progressionService.completedLevelId, 0);
      expect(progressionService.seenWorldIds, contains(level15.worldId));
      expect(progressionService.seenRuleKeys, contains(level15.specialRule.name));
    });
  });
}