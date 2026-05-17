import 'package:flutter/services.dart';

/// Retours haptiques subtils pour chaque interaction importante.
/// Utilise HapticFeedback de Flutter — aucun package supplémentaire requis.
class LumoraHaptics {
  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Tap sur un nœud d'énergie — impact léger.
  static Future<void> nodeTap() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Connexion valide — impact moyen.
  static Future<void> connectionValid() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Connexion invalide — vibration d'erreur.
  static Future<void> connectionError() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Combo x3+ — impact moyen répété.
  static Future<void> combo() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// Victoire niveau — double impact fort.
  static Future<void> victory() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Tap sur bouton UI — sélection tick.
  static Future<void> buttonPress() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Défaite — vibration d'erreur douce.
  static Future<void> defeat() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
}