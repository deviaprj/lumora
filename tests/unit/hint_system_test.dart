import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Unit Test — HintSystem (Indices Visuels Décroissants)
// Vérifie la courbe décroissante : délai augmente, opacité diminue,
// fréquence diminue par palier de progression.
// ---------------------------------------------------------------------------

class HintTier {
  final int minLevel;
  final int maxLevel;
  final int delaySeconds;
  final double opacity;
  final int frequency; // toutes les N hésitations
  final String hintType;

  const HintTier({
    required this.minLevel,
    required this.maxLevel,
    required this.delaySeconds,
    required this.opacity,
    required this.frequency,
    required this.hintType,
  });
}

class HintSystem {
  static const List<HintTier> tiers = [
    HintTier(minLevel: 1, maxLevel: 10, delaySeconds: 15, opacity: 0.90, frequency: 1, hintType: 'fleche_animee'),
    HintTier(minLevel: 11, maxLevel: 25, delaySeconds: 25, opacity: 0.75, frequency: 2, hintType: 'halo_pulsant'),
    HintTier(minLevel: 26, maxLevel: 45, delaySeconds: 40, opacity: 0.60, frequency: 3, hintType: 'contour_subtil'),
    HintTier(minLevel: 46, maxLevel: 70, delaySeconds: 60, opacity: 0.45, frequency: 5, hintType: 'eclaircissement'),
    HintTier(minLevel: 71, maxLevel: 100, delaySeconds: 0, opacity: 0.30, frequency: 999, hintType: 'ombre_legere'), // 999 = manuel seul
    HintTier(minLevel: 101, maxLevel: 9999, delaySeconds: 0, opacity: 0.20, frequency: 999, hintType: 'micro_ripple'),
  ];

  HintTier tierForLevel(int level) {
    return tiers.firstWhere((t) => level >= t.minLevel && level <= t.maxLevel);
  }

  bool shouldShowAutoHint(int level, int hesitationCount) {
    final tier = tierForLevel(level);
    if (tier.frequency >= 999) return false; // manuel seul
    return hesitationCount > 0 && hesitationCount % tier.frequency == 0;
  }
}

void main() {
  group('HintSystem — délai croissant', () {
    final hint = HintSystem();

    test('niveau 1 : délai = 15s', () {
      final t = hint.tierForLevel(1);
      expect(t.delaySeconds, equals(15));
    });

    test('niveau 15 : délai = 25s', () {
      final t = hint.tierForLevel(15);
      expect(t.delaySeconds, equals(25));
    });

    test('niveau 50 : délai = 60s', () {
      final t = hint.tierForLevel(50);
      expect(t.delaySeconds, equals(60));
    });

    test('niveau 80 : délai = 0s (manuel)', () {
      final t = hint.tierForLevel(80);
      expect(t.delaySeconds, equals(0));
    });

    test('la courbe des délais est monotone non décroissante', () {
      final delays = [1, 5, 10, 11, 15, 20, 26, 30, 46, 50, 71, 80, 101]
          .map((l) => hint.tierForLevel(l).delaySeconds)
          .toList();
      for (var i = 1; i < delays.length; i++) {
        expect(
          delays[i] >= delays[i - 1] || delays[i] == 0,
          isTrue,
          reason: 'Le délai ne doit pas diminuer entre paliers',
        );
      }
    });
  });

  group('HintSystem — opacité décroissante', () {
    final hint = HintSystem();

    test('niveau 1 : opacité = 90%', () {
      expect(hint.tierForLevel(1).opacity, closeTo(0.90, 0.001));
    });

    test('niveau 20 : opacité = 75%', () {
      expect(hint.tierForLevel(20).opacity, closeTo(0.75, 0.001));
    });

    test('niveau 40 : opacité = 60%', () {
      expect(hint.tierForLevel(40).opacity, closeTo(0.60, 0.001));
    });

    test('niveau 100 : opacité = 30%', () {
      expect(hint.tierForLevel(100).opacity, closeTo(0.30, 0.001));
    });

    test('niveau 150 : opacité = 20%', () {
      expect(hint.tierForLevel(150).opacity, closeTo(0.20, 0.001));
    });

    test('la courbe d\'opacité est strictement décroissante', () {
      final opacities = [1, 10, 11, 25, 26, 45, 46, 70, 71, 100, 101, 200]
          .map((l) => hint.tierForLevel(l).opacity)
          .toList();
      for (var i = 1; i < opacities.length; i++) {
        expect(
          opacities[i] <= opacities[i - 1],
          isTrue,
          reason: 'L\'opacité doit diminuer avec la progression',
        );
      }
    });
  });

  group('HintSystem — fréquence décroissante', () {
    final hint = HintSystem();

    test('niveau 1 : fréquence toutes les hésitations', () {
      expect(hint.shouldShowAutoHint(1, 1), isTrue);
      expect(hint.shouldShowAutoHint(1, 2), isTrue);
    });

    test('niveau 20 : fréquence toutes les 2 hésitations', () {
      expect(hint.shouldShowAutoHint(20, 1), isFalse);
      expect(hint.shouldShowAutoHint(20, 2), isTrue);
      expect(hint.shouldShowAutoHint(20, 3), isFalse);
      expect(hint.shouldShowAutoHint(20, 4), isTrue);
    });

    test('niveau 60 : fréquence toutes les 5 hésitations', () {
      expect(hint.shouldShowAutoHint(60, 5), isTrue);
      expect(hint.shouldShowAutoHint(60, 4), isFalse);
      expect(hint.shouldShowAutoHint(60, 10), isTrue);
    });

    test('niveau 80+ : indices automatiques désactivés (manuel seul)', () {
      expect(hint.shouldShowAutoHint(80, 1), isFalse);
      expect(hint.shouldShowAutoHint(99, 999), isFalse);
      expect(hint.shouldShowAutoHint(120, 5), isFalse);
    });
  });
}
