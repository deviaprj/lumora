import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/crystals/data/crystal_progression_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CrystalProgressionService service;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = CrystalProgressionService.instance;
    service.resetForTest();
  });

  tearDown(() {
    service.resetForTest();
  });

  test('charge des valeurs neutres au premier lancement', () async {
    await service.load();

    expect(service.isLoaded, isTrue);
    expect(service.highestUnlockedLevel, 1);
    expect(service.bestScore, 0);
    expect(service.totalCrystals, 0);
    expect(service.dailyStreak, 0);
  });

  test('une victoire débloque le palier suivant et lance la série', () async {
    await service.load();

    final summary = await service.recordRun(
      level: 1,
      score: 500,
      crystalsCleared: 12,
      victory: true,
      now: DateTime(2026, 10, 22, 10),
    );

    expect(summary.highestUnlockedLevel, 2);
    expect(summary.levelUnlocked, isTrue);
    expect(summary.newBestScore, isTrue);
    expect(summary.bestScore, 500);
    expect(summary.dailyStreak, 1);
    expect(service.totalCrystals, 12);
  });

  test('une défaite ne débloque rien mais enregistre le score', () async {
    await service.load();

    final summary = await service.recordRun(
      level: 1,
      score: 120,
      crystalsCleared: 4,
      victory: false,
      now: DateTime(2026, 10, 22, 10),
    );

    expect(summary.highestUnlockedLevel, 1);
    expect(summary.levelUnlocked, isFalse);
    expect(summary.bestScore, 120);
    expect(summary.newBestScore, isTrue);
    expect(summary.dailyStreak, 1);
  });

  test('le meilleur score ne baisse jamais', () async {
    await service.load();
    await service.recordRun(
      level: 1,
      score: 500,
      crystalsCleared: 10,
      victory: true,
      now: DateTime(2026, 10, 22, 10),
    );

    final summary = await service.recordRun(
      level: 2,
      score: 300,
      crystalsCleared: 6,
      victory: false,
      now: DateTime(2026, 10, 22, 18),
    );

    expect(summary.bestScore, 500);
    expect(summary.newBestScore, isFalse);
    expect(service.totalCrystals, 16);
  });

  test('la série de jours grandit une fois par jour joué', () async {
    await service.load();

    final dayOne = await service.recordRun(
      level: 1,
      score: 100,
      crystalsCleared: 3,
      victory: false,
      now: DateTime(2026, 10, 22, 9),
    );
    final sameDay = await service.recordRun(
      level: 1,
      score: 150,
      crystalsCleared: 4,
      victory: false,
      now: DateTime(2026, 10, 22, 20),
    );
    final nextDay = await service.recordRun(
      level: 1,
      score: 200,
      crystalsCleared: 5,
      victory: false,
      now: DateTime(2026, 10, 23, 8),
    );

    expect(dayOne.dailyStreak, 1);
    expect(sameDay.dailyStreak, 1);
    expect(nextDay.dailyStreak, 2);
  });

  test('un jour manqué remet la série à un', () async {
    await service.load();
    await service.recordRun(
      level: 1,
      score: 100,
      crystalsCleared: 3,
      victory: false,
      now: DateTime(2026, 10, 22, 9),
    );
    final afterGap = await service.recordRun(
      level: 1,
      score: 100,
      crystalsCleared: 3,
      victory: false,
      now: DateTime(2026, 10, 26, 9),
    );

    expect(afterGap.dailyStreak, 1);
  });

  test('la progression survit à un rechargement', () async {
    await service.load();
    await service.recordRun(
      level: 3,
      score: 900,
      crystalsCleared: 20,
      victory: true,
      now: DateTime(2026, 10, 22, 9),
    );
    await service.flushForTest();

    service.resetForTest();
    await service.load();

    expect(service.highestUnlockedLevel, 4);
    expect(service.bestScore, 900);
    expect(service.totalCrystals, 20);
    expect(service.dailyStreak, 1);
  });
}
