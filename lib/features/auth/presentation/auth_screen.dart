import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../app/router.dart';
import '../../../shared/widgets/lumora_button.dart';

/// Écran d'authentification — fond dégradé, logo Lumora avec particules placeholder,
/// 4 bulles organiques flottantes (Google, Apple, Email, Anonyme).
/// LumoraButton uniquement — jamais de boutons carrés gris.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LumoraGradients.authBg,
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo / Particules placeholder
                  _LogoWithParticles(),
                  const SizedBox(height: 20),
                  Text(
                    'Lumora',
                    style: LumoraTextStyles.displayLarge(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecte-toi pour sauvegarder ta lumière',
                    textAlign: TextAlign.center,
                    style: LumoraTextStyles.bodyMedium(),
                  ),
                  const SizedBox(height: 48),
                  // Bulles organiques flottantes d'auth
                  _AuthBubble(
                    label: 'Continuer avec Google',
                    icon: Icons.g_mobiledata_rounded,
                    colors: [const Color(0xFFEA4335), const Color(0xFFFBBC05)],
                    onTap: () => _signIn(context, 'google'),
                  ),
                  const SizedBox(height: 16),
                  _AuthBubble(
                    label: 'Continuer avec Apple',
                    icon: Icons.apple_rounded,
                    colors: [const Color(0xFF555555), const Color(0xFFBBBBBB)],
                    onTap: () => _signIn(context, 'apple'),
                  ),
                  const SizedBox(height: 16),
                  _AuthBubble(
                    label: 'Continuer avec Email',
                    icon: Icons.email_rounded,
                    colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
                    onTap: () => _signIn(context, 'email'),
                  ),
                  const SizedBox(height: 16),
                  _AuthBubble(
                    label: 'Jouer anonymement',
                    icon: Icons.person_outline_rounded,
                    colors: [LumoraColors.twilight, LumoraColors.dawn],
                    onTap: () => _signIn(context, 'anonymous'),
                  ),
                  const SizedBox(height: 32),
                  // Bouton retour anonyme compact
                  LumoraButton(
                    onPressed: () => context.go('/home'),
                    text: 'Retour',
                    gradientColors: [LumoraColors.midnight, LumoraColors.deepSpace],
                    elevation: 2,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signIn(BuildContext context, String provider) {
    // TODO: implémenter Firebase Auth + anonymous_linker.
    isAuthenticated = true;
    context.go('/home');
  }
}

/// Bulle organique d'authentification — wrapper autour de LumoraButton
/// avec micro-animation flottante.
class _AuthBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _AuthBubble({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LumoraButton(
      onPressed: onTap,
      text: label,
      icon: Icon(icon, color: Colors.white, size: 22),
      gradientColors: colors,
      elevation: 6,
      isFloating: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    );
  }
}

/// Logo Lumora avec particules placeholder.
/// Remplace par un vrai ParticleSystem plus tard.
class _LogoWithParticles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bulle principale
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LumoraGradients.primaryBubble,
              boxShadow: [
                LumoraShadows.glow(),
                LumoraShadows.floating(),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.bubble_chart_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          // Petites particules placeholder
          Positioned(
            top: 10,
            right: 20,
            child: _ParticleDot(color: LumoraColors.auroraGold),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: _ParticleDot(color: LumoraColors.auroraPurple),
          ),
          Positioned(
            top: 40,
            left: 0,
            child: _ParticleDot(color: LumoraColors.auroraPink, size: 6),
          ),
        ],
      ),
    );
  }
}

class _ParticleDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ParticleDot({required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(120),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
