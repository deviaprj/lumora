import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/core/utils/haptics.dart';

void main() {
  group('LumoraHaptics', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      // Réactiver les haptics avant chaque test
      LumoraHaptics.setEnabled(true);
    });

    test('nodeTap does not throw', () async {
      expect(() => LumoraHaptics.nodeTap(), returnsNormally);
    });

    test('connectionValid does not throw', () async {
      expect(() => LumoraHaptics.connectionValid(), returnsNormally);
    });

    test('connectionError does not throw', () async {
      expect(() => LumoraHaptics.connectionError(), returnsNormally);
    });

    test('combo does not throw', () async {
      expect(() => LumoraHaptics.combo(), returnsNormally);
    });

    test('victory does not throw', () async {
      expect(() => LumoraHaptics.victory(), returnsNormally);
    });

    test('buttonPress does not throw', () async {
      expect(() => LumoraHaptics.buttonPress(), returnsNormally);
    });

    test('defeat does not throw', () async {
      expect(() => LumoraHaptics.defeat(), returnsNormally);
    });

    test('setEnabled(false) disables all haptics', () async {
      LumoraHaptics.setEnabled(false);
      // Aucun crash = les méthodes retournent sans appeler HapticFeedback
      expect(() => LumoraHaptics.nodeTap(), returnsNormally);
      expect(() => LumoraHaptics.victory(), returnsNormally);
    });

    test('setEnabled(true) re-enables haptics', () async {
      LumoraHaptics.setEnabled(false);
      LumoraHaptics.setEnabled(true);
      expect(() => LumoraHaptics.nodeTap(), returnsNormally);
    });
  });
}