import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';

/// Paramètres — liste de cartes organiques empilées, toggles iOS-style arrondis
/// (musique, son, vibrations, notifications, indices auto), bouton
/// "Restaurer les Achats".
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _music = true;
  bool _sound = true;
  bool _vibrations = true;
  bool _notifications = true;
  bool _autoHints = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LumoraGradients.homeBg, borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    LumoraButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      gradientColors: [LumoraColors.midnight, LumoraColors.deepSpace],
                      size: 44,
                      elevation: 3,
                    ),
                    const Spacer(),
                    Text(
                      'Paramètres',
                      style: LumoraTextStyles.titleLarge(),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ],
                ),
              ),

              // Liste de cartes empilées
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      _SettingCard(
                        icon: Icons.music_note_rounded,
                        label: 'Musique',
                        value: _music,
                        color: LumoraColors.auroraPurple,
                        onChanged: (v) => setState(() => _music = v),
                      ),
                      const SizedBox(height: 12),
                      _SettingCard(
                        icon: Icons.volume_up_rounded,
                        label: 'Effets sonores',
                        value: _sound,
                        color: LumoraColors.auroraBlue,
                        onChanged: (v) => setState(() => _sound = v),
                      ),
                      const SizedBox(height: 12),
                      _SettingCard(
                        icon: Icons.vibration_rounded,
                        label: 'Vibrations',
                        value: _vibrations,
                        color: LumoraColors.auroraGreen,
                        onChanged: (v) => setState(() => _vibrations = v),
                      ),
                      const SizedBox(height: 12),
                      _SettingCard(
                        icon: Icons.notifications_active_rounded,
                        label: 'Notifications',
                        value: _notifications,
                        color: LumoraColors.auroraGold,
                        onChanged: (v) => setState(() => _notifications = v),
                      ),
                      const SizedBox(height: 12),
                      _SettingCard(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Indices automatiques',
                        subtitle: 'Désactiver débloque le badge Puriste',
                        value: _autoHints,
                        color: LumoraColors.energyAmber,
                        onChanged: (v) => setState(() => _autoHints = v),
                      ),
                      const SizedBox(height: 24),

                      // Bouton restaurer achats
                      LumoraButton(
                        onPressed: () {
                          // TODO: appeler RevenueCat restorePurchases()
                        },
                        text: 'Restaurer les Achats',
                        icon: const Icon(Icons.restore_rounded, color: Colors.white),
                        gradientColors: [LumoraColors.twilight, LumoraColors.dawn],
                        elevation: 4,
                      ),
                      const SizedBox(height: 12),

                      // Bouton supprimer données (GDPR)
                      LumoraButton(
                        onPressed: () {
                          // TODO: confirmation + appel Cloud Function deleteUserData
                        },
                        text: 'Supprimer mes données',
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                        gradientColors: [
                          const Color(0x44FFFFFF),
                          const Color(0x22FFFFFF),
                        ],
                        elevation: 2,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de paramètre organique — icône arrondie, toggle iOS-style,
/// jamais de rectangle gris, jamais de bord droit.
class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _SettingCard({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: LumoraRadii.card,
      child: Row(
        children: [
          // Icône organique
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(40),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),

          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: LumoraTextStyles.bodyLarge()),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: LumoraTextStyles.bodyMedium(color: LumoraColors.disabledMist),
                  ),
              ],
            ),
          ),

          // Toggle iOS-style arrondi (pas Material switch rectangulaire)
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}
