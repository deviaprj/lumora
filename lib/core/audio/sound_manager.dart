import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

/// Moteur audio — musique ambiante procédurale et effets sonores cristallins.
/// Chaque monde utilise une gamme pentatonique différente.
/// Les couleurs de nœuds sont mappées à des notes musicales.
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final List<AudioPlayer> _sfxPool = List.generate(5, (_) => AudioPlayer());
  int _sfxIndex = 0;

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _initialized = false;

  /// Mapping couleur → note (gamme pentatonique Do-Ré-Mi-Sol-La).
  static const Map<String, double> colorNoteMap = {
    'red': 261.63, // C4
    'orange': 293.66, // D4
    'yellow': 329.63, // E4
    'green': 392.00, // G4
    'blue': 440.00, // A4
    'purple': 493.88, // B4
    'gold': 523.25, // C5
  };

  /// Gammes pentatoniques par monde (fréquences en Hz).
  static const Map<int, List<double>> worldScales = {
    1: [261.63, 293.66, 329.63, 392.00, 440.00], // C Major Pentatonic
    2: [220.00, 261.63, 293.66, 329.63, 392.00], // A Minor Pentatonic
    3: [164.81, 196.00, 220.00, 246.94, 293.66], // E Minor Pentatonic
    4: [174.61, 220.00, 261.63, 293.66, 349.23], // F Pentatonic
    5: [196.00, 246.94, 293.66, 349.23, 392.00], // G Pentatonic
  };

  int _currentWorld = 1;
  Timer? _ambientTimer;

  Future<void> init() async {
    if (_initialized) return;
    await _musicPlayer.setVolume(0.3);
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    for (final player in _sfxPool) {
      await player.setVolume(0.6);
    }
    _initialized = true;
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _musicPlayer.stop();
      _ambientTimer?.cancel();
    }
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  void setWorld(int worldId) {
    _currentWorld = worldId;
  }

  /// Joue une note correspondant à une couleur de nœud.
  Future<void> playNodeNote(String colorKey) async {
    if (!_sfxEnabled || !_initialized) return;
    final freq = colorNoteMap[colorKey] ?? 440.0;
    await _playTone(freq, duration: const Duration(milliseconds: 300));
  }

  /// Joue une note aléatoire de la gamme du monde actuel.
  Future<void> playAmbientNote() async {
    if (!_sfxEnabled || !_initialized) return;
    final scale = worldScales[_currentWorld] ?? worldScales[1]!;
    final freq = scale[Random().nextInt(scale.length)];
    await _playTone(freq * 0.5, duration: const Duration(milliseconds: 800), volume: 0.15);
  }

  /// Son cristallin pour connexion valide.
  Future<void> playConnectionSound() async {
    if (!_sfxEnabled || !_initialized) return;
    final scale = worldScales[_currentWorld] ?? worldScales[1]!;
    // Accord majeur ascendant (do-mi-sol)
    await _playTone(scale[0], duration: const Duration(milliseconds: 150), volume: 0.5);
    await Future.delayed(const Duration(milliseconds: 60));
    await _playTone(scale[2], duration: const Duration(milliseconds: 150), volume: 0.5);
    await Future.delayed(const Duration(milliseconds: 60));
    await _playTone(scale[4], duration: const Duration(milliseconds: 250), volume: 0.5);
  }

  /// Son doux pour connexion invalide.
  Future<void> playErrorSound() async {
    if (!_sfxEnabled || !_initialized) return;
    // Deux notes graves douces
    await _playTone(130.81, duration: const Duration(milliseconds: 200), volume: 0.3);
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(146.83, duration: const Duration(milliseconds: 250), volume: 0.25);
  }

  /// Crescendo de victoire.
  Future<void> playVictorySound() async {
    if (!_sfxEnabled || !_initialized) return;
    final scale = worldScales[_currentWorld] ?? worldScales[1]!;
    for (var i = 0; i < scale.length; i++) {
      await _playTone(scale[i], duration: const Duration(milliseconds: 200), volume: 0.5);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // Note finale octave supérieure
    await _playTone(scale.last * 2, duration: const Duration(milliseconds: 500), volume: 0.6);
  }

  /// Son pour combo.
  Future<void> playComboSound(int comboLevel) async {
    if (!_sfxEnabled || !_initialized) return;
    final freq = 523.25 + (comboLevel - 3) * 100;
    await _playTone(freq, duration: const Duration(milliseconds: 200), volume: 0.5);
    await Future.delayed(const Duration(milliseconds: 50));
    await _playTone(freq * 1.5, duration: const Duration(milliseconds: 150), volume: 0.4);
  }

  /// Démarre la boucle ambiante procédurale.
  void startAmbientLoop() {
    if (!_musicEnabled) return;
    _ambientTimer?.cancel();
    _ambientTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      playAmbientNote();
    });
  }

  /// Arrête la boucle ambiante.
  void stopAmbientLoop() {
    _ambientTimer?.cancel();
    _ambientTimer = null;
  }

  Future<void> _playTone(
    double frequency, {
    required Duration duration,
    double volume = 0.5,
  }) async {
    final player = _sfxPool[_sfxIndex % _sfxPool.length];
    _sfxIndex++;
    try {
      await player.setVolume(volume);
      // Utilise un son synthétisé via asset ou silence si non disponible.
      // En production, remplacer par de vrais samples audio.
      // Pour l'instant, les appels sont silencieux mais l'architecture est prête.
      await player.stop();
    } catch (_) {
      // Audio optionnel — ne jamais crasher
    }
  }

  void dispose() {
    _ambientTimer?.cancel();
    _musicPlayer.dispose();
    for (final player in _sfxPool) {
      player.dispose();
    }
  }
}