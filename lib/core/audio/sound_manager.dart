import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Moteur audio spatial — synthèse PCM avancée en temps réel.
///
/// Sons redessinés pour l'espace :
///  • Connexion filament réussie : sweep fréquentiel ascendant + étincelle
///  • Connexion échouée       : sweep descendant avec harmoniques dures
///  • Victoire                : jingle mélodique ascendant (Do-Mi-Sol-Do…) avec vibrato
///  • Défaite                 : descente mineure lente et grave
///  • Vie perdue              : sweep descendant rapide
///  • 10 dernières secondes   : tick-tock de bombe qui s'accélère
///
/// Aucun fichier audio externe requis — tout généré via [BytesSource].
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  // Pool de 10 joueurs pour la polyphonie (jingles multi-notes)
  final List<AudioPlayer> _sfxPool = List.generate(10, (_) => AudioPlayer());
  int _sfxIndex = 0;

  // Joueur dédié à la musique ambiante en boucle
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _initialized = false;

  // Boucle ambiante (Timer de secours : notes ponctuelles si le joueur principal échoue)
  Timer? _ambientTimer;
  int _currentWorld = 1;

  // Tick-tock bombe
  Timer? _urgentTimer;
  double _secondsRemaining = 0.0;
  int _tickCount = 0;
  bool _isTicking = false;

  // ─── Mapping couleur → note ───────────────────────────────────────

  static const Map<String, double> colorNoteMap = {
    'red':    261.63, // Do4
    'orange': 293.66, // Ré4
    'yellow': 329.63, // Mi4
    'green':  392.00, // Sol4
    'blue':   440.00, // La4
    'purple': 493.88, // Si4
    'gold':   523.25, // Do5
  };

  /// Gammes pentatoniques par monde (fréquences en Hz).
  static const Map<int, List<double>> worldScales = {
    1: [261.63, 293.66, 329.63, 392.00, 440.00], // Do Majeur Pentatonique
    2: [220.00, 261.63, 293.66, 329.63, 392.00], // La Mineur Pentatonique
    3: [164.81, 196.00, 220.00, 246.94, 293.66], // Mi Mineur Pentatonique
    4: [174.61, 220.00, 261.63, 293.66, 349.23], // Fa Pentatonique
    5: [196.00, 246.94, 293.66, 349.23, 392.00], // Sol Pentatonique
  };

  // ─── Initialisation ──────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    for (final player in _sfxPool) {
      await player.setReleaseMode(ReleaseMode.stop);
    }
    // ReleaseMode.loop ne boucle pas fiablement avec BytesSource sur Android.
    // On gère la boucle manuellement via onPlayerComplete.
    await _ambientPlayer.setReleaseMode(ReleaseMode.stop);
    await _ambientPlayer.setVolume(0.85);
    _ambientPlayer.onPlayerComplete.listen((_) {
      if (_musicEnabled && _initialized) {
        final wav = _buildAmbientWav(_currentWorld);
        unawaited(_ambientPlayer.play(BytesSource(wav)));
      }
    });
    _initialized = true;
  }

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _ambientTimer?.cancel();
      _ambientTimer = null;
      unawaited(_ambientPlayer.stop());
      _stopUrgentBeat();
    } else {
      startAmbientLoop();
    }
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    if (!enabled) _stopUrgentBeat();
  }

  void setWorld(int worldId) {
    if (_currentWorld == worldId) return;
    _currentWorld = worldId;
    if (_musicEnabled && _initialized) {
      stopAmbientLoop();
      startAmbientLoop();
    }
  }

  // ─── Effets sonores ───────────────────────────────────────────────

  /// Note cristalline avec vibrato léger sur tap nœud.
  Future<void> playNodeNote(String colorKey) async {
    if (!_sfxEnabled || !_initialized) return;
    final freq = colorNoteMap[colorKey] ?? 440.0;
    unawaited(_playVibrato(freq,
        duration: const Duration(milliseconds: 200),
        volume: 0.40,
        vibratoRate: 6.0,
        vibratoDepth: 0.008));
  }

  /// Connexion réussie : sweep spatial ascendant + étincelle finale.
  /// Inspiré d'une énergie qui s'écoule dans un filament lumineux.
  Future<void> playConnectionSound() async {
    if (!_sfxEnabled || !_initialized) return;
    // Élan de fréquence montant (filament qui s'illumine)
    unawaited(_playSweep(160.0, 920.0,
        duration: const Duration(milliseconds: 210),
        volume: 0.52,
        harmonicAmps: [0.38, 0.16]));
    // Étincelle haute fréquence en fin de connexion
    await Future.delayed(const Duration(milliseconds: 180));
    unawaited(_playClick(2800.0,
        duration: const Duration(milliseconds: 30),
        volume: 0.30));
  }

  /// Connexion échouée : distorsion spatiale grave.
  /// Sweep descendant avec harmoniques impaires (son dur/métallique).
  Future<void> playErrorSound() async {
    if (!_sfxEnabled || !_initialized) return;
    // Descente grave avec harmoniques riches = timbre agressif
    unawaited(_playSweep(300.0, 72.0,
        duration: const Duration(milliseconds: 290),
        volume: 0.90,
        harmonicAmps: [0.70, 0.50, 0.28]));
    // Battement légèrement désaccordé pour distorsion spatiale
    await Future.delayed(const Duration(milliseconds: 15));
    unawaited(_playTone(215.0,
        duration: const Duration(milliseconds: 200), volume: 0.55));
  }

  /// Jingle de victoire cosmique : mélodie ascendante Do-Mi-Sol-Do-Mi-Sol-Do.
  /// Chaque note avec vibrato progressif, finale tenue longue.
  Future<void> playVictorySound() async {
    if (!_sfxEnabled || !_initialized) return;
    _stopUrgentBeat();

    // Arpège majeur ascendant sur deux octaves
    const melody = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50];
    const vols   = [0.42,   0.46,   0.50,   0.54,   0.57,   0.60,   0.0 ];

    for (var i = 0; i < melody.length - 1; i++) {
      unawaited(_playVibrato(melody[i],
          duration: const Duration(milliseconds: 180),
          volume: vols[i],
          vibratoRate: 4.8 + i * 0.25,
          vibratoDepth: 0.007 + i * 0.002,
          harmonicAmps: [0.28, 0.10]));
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // Note finale haute : tenue avec vibrato prononcé
    unawaited(_playVibrato(melody.last,
        duration: const Duration(milliseconds: 800),
        volume: 0.72,
        vibratoRate: 5.5,
        vibratoDepth: 0.028,
        attackMs: 18.0,
        decayMs: 180.0,
        harmonicAmps: [0.40, 0.20, 0.08]));
  }

  /// Jingle de défaite : descente mineure grave et lente.
  /// La3 → Fa3 → Mi3 → Ré3 → La2, timbre sombre avec harmoniques.
  Future<void> playDefeatSound() async {
    if (!_sfxEnabled || !_initialized) return;
    _stopUrgentBeat();

    // Gamme mineure descendante (La Aeolien)
    const melody = [220.00, 174.61, 164.81, 146.83, 110.00];
    const vols   = [0.85,   0.78,   0.72,   0.65,   0.0  ];

    for (var i = 0; i < melody.length - 1; i++) {
      unawaited(_playVibrato(melody[i],
          duration: const Duration(milliseconds: 310),
          volume: vols[i],
          vibratoRate: 3.2 + i * 0.25,
          vibratoDepth: 0.012,
          attackMs: 22.0,
          decayMs: 85.0,
          harmonicAmps: [0.55, 0.28, 0.12]));
      await Future.delayed(const Duration(milliseconds: 195));
    }
    // Note finale grave tenue — fondu long
    unawaited(_playVibrato(melody.last,
        duration: const Duration(milliseconds: 950),
        volume: 0.82,
        vibratoRate: 2.5,
        vibratoDepth: 0.018,
        attackMs: 35.0,
        decayMs: 250.0,
        harmonicAmps: [0.65, 0.35, 0.15]));
  }

  /// Vie perdue : sweep descendant rapide (alarme spatiale).
  Future<void> playLifeLostSound() async {
    if (!_sfxEnabled || !_initialized) return;
    unawaited(_playSweep(900.0, 220.0,
        duration: const Duration(milliseconds: 290),
        volume: 0.50,
        harmonicAmps: [0.35]));
  }

  /// Intro de niveau : courte fanfare spatiale ascendante.
  Future<void> playLevelStartSound() async {
    if (!_sfxEnabled || !_initialized) return;
    final scale = worldScales[_currentWorld] ?? worldScales[1]!;
    unawaited(_playTone(scale[0] * 0.5,
        duration: const Duration(milliseconds: 70), volume: 0.28));
    await Future.delayed(const Duration(milliseconds: 52));
    unawaited(_playSweep(scale[1], scale[3],
        duration: const Duration(milliseconds: 120),
        volume: 0.38,
        harmonicAmps: [0.20]));
    await Future.delayed(const Duration(milliseconds: 88));
    unawaited(_playVibrato(scale[4],
        duration: const Duration(milliseconds: 220),
        volume: 0.50,
        vibratoRate: 5.0,
        vibratoDepth: 0.012));
  }

  /// Combo (≥ 3) : sweep ascendant court, plus aigu avec le niveau.
  Future<void> playComboSound(int comboLevel) async {
    if (!_sfxEnabled || !_initialized) return;
    final freq = 523.25 + (comboLevel - 3) * 85.0;
    unawaited(_playSweep(freq, freq * 1.55,
        duration: const Duration(milliseconds: 175),
        volume: 0.48,
        harmonicAmps: [0.22]));
  }

  // ─── Musique ambiante ─────────────────────────────────────────────

  /// Démarre la boucle ambiante procédurale.
  void startAmbientLoop() {
    if (!_musicEnabled) return;
    if (!_initialized) return;
    _ambientTimer?.cancel();
    // Timer de secours : relance si onPlayerComplete ne se déclenche pas (bug plateforme)
    _ambientTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (_musicEnabled && _initialized) {
        unawaited(_ambientPlayer.stop());
        final wav = _buildAmbientWav(_currentWorld);
        unawaited(_ambientPlayer.play(BytesSource(wav)));
      }
    });
    final wav = _buildAmbientWav(_currentWorld);
    unawaited(_ambientPlayer.play(BytesSource(wav)));
  }

  /// Arrête toute la boucle ambiante et l'urgence.
  void stopAmbientLoop() {
    _ambientTimer?.cancel();
    _ambientTimer = null;
    unawaited(_ambientPlayer.stop());
    _stopUrgentBeat();
  }

  /// Génère un WAV ambiant de 8 secondes en boucle seamless.
  ///
  /// Couches :
  ///  1. Drone basse (fondamentale 2 octaves sous la gamme)
  ///  2. Pad accord (tonique + tierce + quinte, 1 octave dessous, tremolo lent)
  ///  3. Arpège mélodique (notes de la gamme, 0.5 s chacune, vibrato léger)
  ///
  /// Un fade-in/fade-out de 80 ms lisse le point de bouclage.
  Uint8List _buildAmbientWav(int worldId) {
    const sr = 22050;
    const durSec = 8;
    const n = sr * durSec;
    final scale = worldScales[worldId] ?? worldScales[1]!;
    final buf = List<double>.filled(n, 0.0);

    // --- Couche 1 : drone basse (2 octaves sous la tonique)
    final bassFreq = scale[0] * 0.25;
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      buf[i] += 0.10 * sin(2 * pi * bassFreq * t);
      buf[i] += 0.04 * sin(2 * pi * bassFreq * 2 * t);
    }

    // --- Couche 2 : pad accord (tonique + tierce + quinte, 1 octave dessous)
    for (final freq in [scale[0] * 0.5, scale[2] * 0.5, scale[4] * 0.5]) {
      for (var i = 0; i < n; i++) {
        final t = i / sr;
        final env = 0.055 + 0.015 * sin(2 * pi * 0.25 * t); // tremolo 0.25 Hz
        buf[i] += env * sin(2 * pi * freq * t);
      }
    }

    // --- Couche 3 : arpège mélodique (8 notes × 1 s)
    final arpPattern = [0, 2, 4, 2, 1, 3, 4, 1];
    final noteDur = sr; // 1 s par note
    final attack = (sr * 0.05).round();
    final release = (sr * 0.25).round();
    for (var k = 0; k < arpPattern.length; k++) {
      final freq = scale[arpPattern[k]];
      final start = k * noteDur;
      for (var i = 0; i < noteDur && start + i < n; i++) {
        final t = i / sr;
        double env = 0.08;
        if (i < attack) {
          env *= i / attack;
        } else if (i > noteDur - release) {
          env *= (noteDur - i) / release;
        }
        final vib = sin(2 * pi * 5.0 * t);
        buf[start + i] += env * sin(2 * pi * freq * (1 + 0.005 * vib) * t);
      }
    }

    // --- Fade in/out 80 ms pour seamless loop
    final fade = (sr * 0.08).round();
    for (var i = 0; i < fade; i++) {
      final f = i / fade;
      buf[i] *= f;
      buf[n - 1 - i] *= f;
    }

    // --- Pack en PCM 16 bits
    final raw = Int16List(n);
    for (var i = 0; i < n; i++) {
      raw[i] = (buf[i] * 32767).round().clamp(-32767, 32767);
    }
    return _packWav(raw, sr);
  }

  // ─── Tick-tock bombe (10 dernières secondes) ─────────────────────

  /// Met à jour l'urgence et déclenche le tick-tock quand il reste ≤ 10 s.
  ///
  /// [urgency] : 0.0 (plein) → 1.0 (expiré).
  /// [secondsRemaining] : secondes réelles restantes (0 si pas de chrono).
  void updateTimerUrgency(double urgency,
      {double secondsRemaining = 0.0}) {
    if (!_sfxEnabled || !_initialized) return;
    _secondsRemaining = secondsRemaining;

    final shouldTick =
        secondsRemaining > 0 && secondsRemaining <= 10.0;

    if (shouldTick && !_isTicking) {
      _isTicking = true;
      _tickCount = 0;
      _scheduleNextTickTock();
    } else if (!shouldTick && _isTicking) {
      _stopUrgentBeat();
    }
    // Si déjà en cours, la prochaine itération lira le nouveau _secondsRemaining
  }

  void _stopUrgentBeat() {
    _urgentTimer?.cancel();
    _urgentTimer = null;
    _isTicking = false;
    _secondsRemaining = 0.0;
  }

  /// Planifie le prochain son tick ou tock.
  /// Période : 500 ms à 10 s → 150 ms à 0 s (accélération linéaire).
  void _scheduleNextTickTock() {
    if (!_sfxEnabled || !_initialized || !_isTicking) return;
    _urgentTimer?.cancel();

    final s = _secondsRemaining.clamp(0.0, 10.0);
    // 10 s → 500 ms,  0 s → 150 ms
    final periodMs = (150 + (s / 10.0) * 350).round().clamp(150, 500);

    _urgentTimer = Timer(Duration(milliseconds: periodMs), () {
      if (!_sfxEnabled || !_initialized || !_isTicking) return;
      _tickCount++;

      if (_tickCount.isOdd) {
        // TICK : aigu, sec — clic métallique haute fréquence
        unawaited(_playBytes(
          _buildPercussiveClick(2400.0, const Duration(milliseconds: 12),
              amplitude: 0.62, harmonicAmps: [0.28]),
          volume: 0.62,
        ));
      } else {
        // TOCK : plus grave, légère résonance
        unawaited(_playBytes(
          _buildPercussiveClick(1200.0, const Duration(milliseconds: 18),
              amplitude: 0.55, harmonicAmps: [0.45, 0.18]),
          volume: 0.55,
        ));
        // Sous-fondamental grave pour épaisseur (comme une bombe mécanique)
        unawaited(_playBytes(
          _buildPercussiveClick(300.0, const Duration(milliseconds: 22),
              amplitude: 0.32),
          volume: 0.32,
        ));
      }

      _scheduleNextTickTock();
    });
  }

  // ─── Synthèse PCM ────────────────────────────────────────────────

  // ── Helpers joueurs ──────────────────────────────────────────────

  /// Joue des bytes WAV pré-construits via le pool de joueurs.
  Future<void> _playBytes(Uint8List bytes, {double volume = 0.5}) async {
    if (!_initialized) return;
    final player = _sfxPool[_sfxIndex % _sfxPool.length];
    _sfxIndex++;
    try {
      await player.play(BytesSource(bytes), volume: volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  /// Sine simple (note tenue).
  Future<void> _playTone(double frequency,
      {required Duration duration, double volume = 0.5}) async {
    if (!_initialized) return;
    unawaited(_playBytes(
        _buildSineWav(frequency, duration,
            amplitude: volume.clamp(0.0, 1.0)),
        volume: volume));
  }

  /// Sweep fréquentiel (glide ascendant ou descendant).
  Future<void> _playSweep(double startFreq, double endFreq,
      {required Duration duration,
      double volume = 0.5,
      List<double> harmonicAmps = const []}) async {
    if (!_initialized) return;
    unawaited(_playBytes(
        _buildSweepWav(startFreq, endFreq, duration,
            amplitude: volume.clamp(0.0, 1.0), harmonicAmps: harmonicAmps),
        volume: volume));
  }

  /// Click percussif court (déclin exponentiel).
  Future<void> _playClick(double frequency,
      {required Duration duration,
      double volume = 0.6,
      List<double> harmonicAmps = const []}) async {
    if (!_initialized) return;
    unawaited(_playBytes(
        _buildPercussiveClick(frequency, duration,
            amplitude: volume.clamp(0.0, 1.0), harmonicAmps: harmonicAmps),
        volume: volume));
  }

  /// Note avec vibrato (pour jingles et nœuds).
  Future<void> _playVibrato(double frequency,
      {required Duration duration,
      double volume = 0.5,
      double vibratoRate = 5.5,
      double vibratoDepth = 0.02,
      double attackMs = 12.0,
      double decayMs = 40.0,
      List<double> harmonicAmps = const []}) async {
    if (!_initialized) return;
    unawaited(_playBytes(
        _buildVibratoWav(frequency, duration,
            amplitude: volume.clamp(0.0, 1.0),
            vibratoRate: vibratoRate,
            vibratoDepth: vibratoDepth,
            attackMs: attackMs,
            decayMs: decayMs,
            harmonicAmps: harmonicAmps),
        volume: volume));
  }

  // ── Générateurs de waveforms ──────────────────────────────────────

  /// WAV sinusoïdal mono 16-bit (note tenue) avec enveloppe A/R linéaire.
  static Uint8List _buildSineWav(
    double frequency,
    Duration duration, {
    double amplitude = 0.5,
  }) {
    const sampleRate = 22050;
    final numSamples =
        (sampleRate * duration.inMilliseconds / 1000.0).round().clamp(1, 88200);
    final attackN = (sampleRate * 0.012).round();
    final decayN  = (sampleRate * 0.040).round();
    final raw = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double env = 1.0;
      if (i < attackN) {
        env = i / attackN;
      } else if (i >= numSamples - decayN) {
        env = (numSamples - 1 - i) / decayN;
      }
      final sample = amplitude * 0.9 * env * sin(2 * pi * frequency * t);
      raw[i] = (sample * 32767).round().clamp(-32767, 32767);
    }
    return _packWav(raw, sampleRate);
  }

  /// WAV avec balayage de fréquence linéaire (glide/portamento).
  /// [harmonicAmps] : amplitudes relatives des harmoniques 2, 3, 4…
  static Uint8List _buildSweepWav(
    double startFreq,
    double endFreq,
    Duration duration, {
    double amplitude = 0.5,
    double attackMs = 6.0,
    double decayMs = 50.0,
    List<double> harmonicAmps = const [],
  }) {
    const sampleRate = 22050;
    final numSamples =
        (sampleRate * duration.inMilliseconds / 1000.0).round().clamp(1, 88200);
    final attackN = (sampleRate * attackMs  / 1000.0).round();
    final decayN  = (sampleRate * decayMs   / 1000.0).round();
    final raw = Int16List(numSamples);

    // Intégration de phase (évite les sauts de phase)
    double phase = 0.0;
    final normFactor = 1.0 + harmonicAmps.fold(0.0, (a, b) => a + b);

    for (var i = 0; i < numSamples; i++) {
      // Fréquence interpolée en log pour un glide plus naturel
      final t = i / numSamples;
      final freq = startFreq * pow(endFreq / startFreq, t);
      phase += 2 * pi * freq / sampleRate;
      if (phase > 2 * pi) phase -= 2 * pi;

      double env = 1.0;
      if (i < attackN) {
        env = i / attackN;
      } else if (i >= numSamples - decayN) {
        env = (numSamples - 1 - i) / decayN;
      }

      double signal = sin(phase);
      for (var h = 0; h < harmonicAmps.length; h++) {
        signal += harmonicAmps[h] * sin(phase * (h + 2));
      }

      raw[i] = ((amplitude * env * signal / normFactor) * 32767)
          .round()
          .clamp(-32767, 32767);
    }
    return _packWav(raw, sampleRate);
  }

  /// WAV percussif avec déclin exponentiel très rapide (tick-tock, clicks).
  static Uint8List _buildPercussiveClick(
    double frequency,
    Duration duration, {
    double amplitude = 0.6,
    List<double> harmonicAmps = const [],
  }) {
    const sampleRate = 22050;
    final numSamples =
        (sampleRate * duration.inMilliseconds / 1000.0).round().clamp(1, 4410);
    final raw = Int16List(numSamples);
    const tau = 0.0035; // constante de temps exponentielle (3.5 ms)
    final attackN = max(1, (sampleRate * 0.0008).round()); // 0.8 ms
    final normFactor = 1.0 + harmonicAmps.fold(0.0, (a, b) => a + b);

    double phase = 0.0;
    for (var i = 0; i < numSamples; i++) {
      phase += 2 * pi * frequency / sampleRate;
      if (phase > 2 * pi) phase -= 2 * pi;

      final t = i / sampleRate;
      final env = i < attackN
          ? i / attackN
          : exp(-(t - attackN / sampleRate) / tau);

      double signal = sin(phase);
      for (var h = 0; h < harmonicAmps.length; h++) {
        signal += harmonicAmps[h] * sin(phase * (h + 2));
      }

      raw[i] = ((amplitude * env * signal / normFactor) * 32767)
          .round()
          .clamp(-32767, 32767);
    }
    return _packWav(raw, sampleRate);
  }

  /// WAV sinusoïdal avec vibrato (modulation de fréquence) pour jingles.
  static Uint8List _buildVibratoWav(
    double frequency,
    Duration duration, {
    double amplitude = 0.5,
    double vibratoRate  = 5.5,   // Hz
    double vibratoDepth = 0.02,  // fraction de la fréquence
    double attackMs  = 15.0,
    double decayMs   = 60.0,
    List<double> harmonicAmps = const [],
  }) {
    const sampleRate = 22050;
    final numSamples =
        (sampleRate * duration.inMilliseconds / 1000.0).round().clamp(1, 88200);
    final attackN = (sampleRate * attackMs / 1000.0).round();
    final decayN  = (sampleRate * decayMs  / 1000.0).round();
    final normFactor = 1.0 + harmonicAmps.fold(0.0, (a, b) => a + b);
    final raw = Int16List(numSamples);

    double phase = 0.0;
    for (var i = 0; i < numSamples; i++) {
      // Vibrato uniquement après l'attaque (naturel)
      final vibratoT = i > attackN ? (i - attackN) / sampleRate : 0.0;
      final vibrato  = vibratoDepth * sin(2 * pi * vibratoRate * vibratoT);
      final instFreq = frequency * (1.0 + vibrato);
      phase += 2 * pi * instFreq / sampleRate;
      if (phase > 2 * pi) phase -= 2 * pi;

      double env = 1.0;
      if (i < attackN) {
        env = i / attackN;
      } else if (i >= numSamples - decayN) {
        env = (numSamples - 1 - i) / decayN;
      }

      double signal = sin(phase);
      for (var h = 0; h < harmonicAmps.length; h++) {
        signal += harmonicAmps[h] * sin(phase * (h + 2));
      }

      raw[i] = ((amplitude * env * signal / normFactor) * 32767)
          .round()
          .clamp(-32767, 32767);
    }
    return _packWav(raw, sampleRate);
  }

  /// Encode un Int16List en fichier WAV RIFF valide (little-endian).
  static Uint8List _packWav(Int16List samples, int sampleRate) {
    final byteCount = samples.length * 2;
    final result = Uint8List(44 + byteCount);
    final hdr = result.buffer.asByteData();

    // RIFF chunk
    hdr.setUint8(0, 0x52); hdr.setUint8(1, 0x49);
    hdr.setUint8(2, 0x46); hdr.setUint8(3, 0x46); // "RIFF"
    hdr.setUint32(4, 36 + byteCount, Endian.little);
    hdr.setUint8(8, 0x57); hdr.setUint8(9, 0x41);
    hdr.setUint8(10, 0x56); hdr.setUint8(11, 0x45); // "WAVE"
    // fmt chunk
    hdr.setUint8(12, 0x66); hdr.setUint8(13, 0x6D);
    hdr.setUint8(14, 0x74); hdr.setUint8(15, 0x20); // "fmt "
    hdr.setUint32(16, 16, Endian.little);
    hdr.setUint16(20,  1, Endian.little); // PCM
    hdr.setUint16(22,  1, Endian.little); // mono
    hdr.setUint32(24, sampleRate,     Endian.little);
    hdr.setUint32(28, sampleRate * 2, Endian.little);
    hdr.setUint16(32,  2, Endian.little);
    hdr.setUint16(34, 16, Endian.little);
    // data chunk
    hdr.setUint8(36, 0x64); hdr.setUint8(37, 0x61);
    hdr.setUint8(38, 0x74); hdr.setUint8(39, 0x61); // "data"
    hdr.setUint32(40, byteCount, Endian.little);

    // Échantillons PCM (little-endian 16-bit)
    for (var i = 0; i < samples.length; i++) {
      final v = samples[i];
      result[44 + i * 2]     =  v        & 0xFF;
      result[44 + i * 2 + 1] = (v >> 8)  & 0xFF;
    }
    return result;
  }

  void dispose() {
    _ambientTimer?.cancel();
    _urgentTimer?.cancel();
    unawaited(_ambientPlayer.stop());
    _ambientPlayer.dispose();
    for (final player in _sfxPool) {
      player.dispose();
    }
  }
}