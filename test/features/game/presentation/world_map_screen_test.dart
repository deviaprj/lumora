import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/domain/level_data.dart';
import 'package:lumora_mobile/features/game/presentation/world_map_screen.dart';
import 'package:lumora_mobile/features/monetization/data/reward_inventory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorldMapScreen', () {
    late RewardInventory inventory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      inventory = RewardInventory.instance;
      inventory.resetForTest();
      await inventory.load();
    });

    testWidgets('jump chip targets the next relevant level for mastery filters', (
      WidgetTester tester,
    ) async {
      Future<void> tapFilter(MasteryMapFilter filter) async {
        final suffix = switch (filter) {
          MasteryMapFilter.all => 'all',
          MasteryMapFilter.remaining => 'remaining',
          MasteryMapFilter.partial => 'partial',
          MasteryMapFilter.complete => 'complete',
        };

        final finder = find.byKey(ValueKey<String>('mastery-filter-$suffix'));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 200));
      }

      Future<void> tapJumpChip(MasteryMapFilter filter, int levelId) async {
        final finder = find.byKey(ValueKey<String>('jump-to-${filter.name}-$levelId'));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 200));
      }

      final level11 = LevelCatalog.byId(11);
      final level12 = LevelCatalog.byId(12);
      LevelData? selectedLevel;

      inventory.grantSecondaryObjectiveRewards(
        levelId: level11.id,
        completedObjectives: [level11.secondaryObjectives.first],
        totalObjectives: level11.secondaryObjectives.length,
      );
      inventory.grantSecondaryObjectiveRewards(
        levelId: level12.id,
        completedObjectives: level12.secondaryObjectives,
        totalObjectives: level12.secondaryObjectives.length,
      );

      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: WorldMapScreen(
            completedLevelId: 12,
            onLevelSelected: (level) => selectedLevel = level,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Reprendre au niveau 13'), findsOneWidget);

      await tapFilter(MasteryMapFilter.partial);

      await tapJumpChip(MasteryMapFilter.partial, 11);

      expect(selectedLevel?.id, 11);

      selectedLevel = null;

      await tapFilter(MasteryMapFilter.complete);

      await tapJumpChip(MasteryMapFilter.complete, 12);

      expect(selectedLevel?.id, 12);

      selectedLevel = null;

      await tapFilter(MasteryMapFilter.remaining);

      await tapJumpChip(MasteryMapFilter.remaining, 13);

      expect(selectedLevel?.id, 13);
    });
  });
}