import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/core/audio/sound_manager.dart';

void main() {
  group('SoundManager', () {
    late SoundManager soundManager;

    setUp(() {
      soundManager = SoundManager();
    });

    test('colorNoteMap has all required colors', () {
      expect(SoundManager.colorNoteMap.containsKey('red'), true);
      expect(SoundManager.colorNoteMap.containsKey('orange'), true);
      expect(SoundManager.colorNoteMap.containsKey('yellow'), true);
      expect(SoundManager.colorNoteMap.containsKey('green'), true);
      expect(SoundManager.colorNoteMap.containsKey('blue'), true);
      expect(SoundManager.colorNoteMap.containsKey('purple'), true);
      expect(SoundManager.colorNoteMap.containsKey('gold'), true);
    });

    test('colorNoteMap frequencies are in valid range', () {
      for (final entry in SoundManager.colorNoteMap.entries) {
        expect(entry.value, greaterThan(100));
        expect(entry.value, lessThan(2000));
      }
    });

    test('worldScales has all 5 worlds', () {
      expect(SoundManager.worldScales.containsKey(1), true);
      expect(SoundManager.worldScales.containsKey(2), true);
      expect(SoundManager.worldScales.containsKey(3), true);
      expect(SoundManager.worldScales.containsKey(4), true);
      expect(SoundManager.worldScales.containsKey(5), true);
    });

    test('worldScales each have 5 notes (pentatonic)', () {
      for (final entry in SoundManager.worldScales.entries) {
        expect(entry.value.length, 5);
      }
    });

    test('worldScales frequencies are in valid range', () {
      for (final entry in SoundManager.worldScales.entries) {
        for (final freq in entry.value) {
          expect(freq, greaterThan(100));
          expect(freq, lessThan(600));
        }
      }
    });

    test('setMusicEnabled does not crash', () {
      expect(() => SoundManager().setMusicEnabled(true), returnsNormally);
      expect(() => SoundManager().setMusicEnabled(false), returnsNormally);
    });

    test('setSfxEnabled does not crash', () {
      expect(() => SoundManager().setSfxEnabled(true), returnsNormally);
      expect(() => SoundManager().setSfxEnabled(false), returnsNormally);
    });

    test('setWorld does not crash', () {
      expect(() => SoundManager().setWorld(1), returnsNormally);
      expect(() => SoundManager().setWorld(5), returnsNormally);
    });

    test('playNodeNote does not crash with valid color', () async {
      soundManager.setSfxEnabled(true);
      expect(() => soundManager.playNodeNote('green'), returnsNormally);
    });

    test('playConnectionSound does not crash', () async {
      soundManager.setSfxEnabled(true);
      expect(() => soundManager.playConnectionSound(), returnsNormally);
    });

    test('playErrorSound does not crash', () async {
      soundManager.setSfxEnabled(true);
      expect(() => soundManager.playErrorSound(), returnsNormally);
    });

    test('playVictorySound does not crash', () async {
      soundManager.setSfxEnabled(true);
      expect(() => soundManager.playVictorySound(), returnsNormally);
    });

    test('playComboSound does not crash', () async {
      soundManager.setSfxEnabled(true);
      expect(() => soundManager.playComboSound(3), returnsNormally);
      expect(() => soundManager.playComboSound(5), returnsNormally);
    });

    test('sfx disabled skips playback without crash', () async {
      soundManager.setSfxEnabled(false);
      expect(() => soundManager.playNodeNote('green'), returnsNormally);
      expect(() => soundManager.playConnectionSound(), returnsNormally);
      expect(() => soundManager.playVictorySound(), returnsNormally);
    });

    test('dispose does not crash', () {
      expect(() => SoundManager().dispose(), returnsNormally);
    });
  });
}