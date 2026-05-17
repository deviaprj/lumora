import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Unit Test — Offline Sync Conflict Resolution
// Règles : max étoiles par niveau, max niveau atteint, somme des consommables.
// ---------------------------------------------------------------------------

class ProgressData {
  int currentLevel;
  Map<int, int> starsByLevel;
  int totalStars;

  ProgressData({
    required this.currentLevel,
    required this.starsByLevel,
    required this.totalStars,
  });

  ProgressData copyWith({
    int? currentLevel,
    Map<int, int>? starsByLevel,
    int? totalStars,
  }) =>
      ProgressData(
        currentLevel: currentLevel ?? this.currentLevel,
        starsByLevel: starsByLevel ?? Map.unmodifiable(this.starsByLevel),
        totalStars: totalStars ?? this.totalStars,
      );
}

class InventoryData {
  int lives;
  int hintTokens;

  InventoryData({required this.lives, required this.hintTokens});
}

class SyncResolver {
  /// Règle : conserve le maximum d'étoiles par niveau.
  ProgressData resolveStars(ProgressData local, ProgressData cloud) {
    final mergedStars = Map<int, int>.from(cloud.starsByLevel);
    for (final entry in local.starsByLevel.entries) {
      final level = entry.key;
      final localStars = entry.value;
      final cloudStars = cloud.starsByLevel[level] ?? 0;
      mergedStars[level] = localStars > cloudStars ? localStars : cloudStars;
    }

    final total = mergedStars.values.fold(0, (a, b) => a + b);

    return ProgressData(
      currentLevel: resolveMaxLevel(local.currentLevel, cloud.currentLevel),
      starsByLevel: mergedStars,
      totalStars: total,
    );
  }

  /// Règle : conserve le niveau le plus avancé.
  int resolveMaxLevel(int localLevel, int cloudLevel) {
    return localLevel > cloudLevel ? localLevel : cloudLevel;
  }

  /// Règle : somme des consommables (delta positif + delta négatif = net).
  InventoryData resolveInventory(InventoryData local, InventoryData cloud) {
    // Hypothèse : les données brutes stockées sont les valeurs actuelles,
    // pas les deltas. Pour simuler une résolution par "somme des consommables",
    // on suppose que local et cloud partent d'une valeur commune et que
    // les différences sont des deltas à additionner.
    // Simplification ici : on prend la somme des deux stocks (règle métier
    // de fusion pour les consommables lors d'un conflit de sync cross-device).
    return InventoryData(
      lives: (local.lives + cloud.lives).clamp(0, 999),
      hintTokens: (local.hintTokens + cloud.hintTokens).clamp(0, 999),
    );
  }
}

void main() {
  group('SyncResolver — max étoiles par niveau', () {
    final resolver = SyncResolver();

    test('garde le max quand local > cloud', () {
      final local = ProgressData(
        currentLevel: 5,
        starsByLevel: {1: 3, 2: 2},
        totalStars: 5,
      );
      final cloud = ProgressData(
        currentLevel: 5,
        starsByLevel: {1: 2, 2: 2},
        totalStars: 4,
      );
      final merged = resolver.resolveStars(local, cloud);
      expect(merged.starsByLevel[1], equals(3));
      expect(merged.starsByLevel[2], equals(2));
    });

    test('garde le max quand cloud > local', () {
      final local = ProgressData(
        currentLevel: 5,
        starsByLevel: {1: 1, 2: 2},
        totalStars: 3,
      );
      final cloud = ProgressData(
        currentLevel: 5,
        starsByLevel: {1: 3, 2: 2},
        totalStars: 5,
      );
      final merged = resolver.resolveStars(local, cloud);
      expect(merged.starsByLevel[1], equals(3));
      expect(merged.starsByLevel[2], equals(2));
    });

    test('fusionne les niveaux présents uniquement côté local', () {
      final local = ProgressData(
        currentLevel: 10,
        starsByLevel: {5: 3, 6: 2},
        totalStars: 5,
      );
      final cloud = ProgressData(
        currentLevel: 4,
        starsByLevel: {1: 3},
        totalStars: 3,
      );
      final merged = resolver.resolveStars(local, cloud);
      expect(merged.starsByLevel[1], equals(3));
      expect(merged.starsByLevel[5], equals(3));
      expect(merged.starsByLevel[6], equals(2));
    });

    test('totalStars est recalculé à partir du map fusionné', () {
      final local = ProgressData(
        currentLevel: 3,
        starsByLevel: {1: 3, 2: 1},
        totalStars: 99, // incohérent volontairement
      );
      final cloud = ProgressData(
        currentLevel: 3,
        starsByLevel: {1: 2, 2: 2},
        totalStars: 88,
      );
      final merged = resolver.resolveStars(local, cloud);
      expect(merged.totalStars, equals(5)); // 3 + 2
    });
  });

  group('SyncResolver — max niveau atteint', () {
    final resolver = SyncResolver();

    test('conserve le niveau le plus élevé', () {
      expect(resolver.resolveMaxLevel(7, 5), equals(7));
      expect(resolver.resolveMaxLevel(4, 9), equals(9));
      expect(resolver.resolveMaxLevel(10, 10), equals(10));
    });

    test('progression fusionnée conserve le max niveau', () {
      final local = ProgressData(currentLevel: 12, starsByLevel: {}, totalStars: 0);
      final cloud = ProgressData(currentLevel: 8, starsByLevel: {}, totalStars: 0);
      final merged = resolver.resolveStars(local, cloud);
      expect(merged.currentLevel, equals(12));
    });
  });

  group('SyncResolver — somme des consommables (vies)', () {
    final resolver = SyncResolver();

    test('additionne les vies des deux devices', () {
      final local = InventoryData(lives: 2, hintTokens: 1);
      final cloud = InventoryData(lives: 3, hintTokens: 2);
      final merged = resolver.resolveInventory(local, cloud);
      expect(merged.lives, equals(5));
      expect(merged.hintTokens, equals(3));
    });

    test('clamp à 0 minimum (pas de négatif)', () {
      final local = InventoryData(lives: -1, hintTokens: 0);
      final cloud = InventoryData(lives: -2, hintTokens: 0);
      final merged = resolver.resolveInventory(local, cloud);
      expect(merged.lives, equals(0));
    });
  });
}
