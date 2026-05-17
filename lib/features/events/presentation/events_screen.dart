import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';

/// Écran événements — cartes organiques pour chaque événement actif,
/// compte à rebours circulaire, fond parallaxe saisonnier placeholder.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = [
      _EventItem(
        title: 'Défi Quotidien',
        subtitle: 'Couleur Pure — Termine sans indice',
        endsIn: const Duration(hours: 4, minutes: 32),
        reward: '1 vie + 1 étoile bonus',
        colors: [LumoraColors.auroraGreen, LumoraColors.auroraBlue],
        icon: Icons.wb_sunny_rounded,
      ),
      _EventItem(
        title: 'Défi Week-End',
        subtitle: 'Filaments Fous — Vitesse x1.5',
        endsIn: const Duration(hours: 18, minutes: 15),
        reward: '3 vies + avatar exclusif',
        colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
        icon: Icons.weekend_rounded,
      ),
      _EventItem(
        title: 'Tournoi Automatique',
        subtitle: 'Leaderboard mondial — 10 niveaux',
        endsIn: const Duration(days: 2, hours: 6),
        reward: 'Thème Champion exclusif',
        colors: [LumoraColors.auroraGold, LumoraColors.energyAmber],
        icon: Icons.emoji_events_rounded,
      ),
      _EventItem(
        title: 'Happy Hour',
        subtitle: 'Pubs récompensées x2',
        endsIn: const Duration(hours: 2, minutes: 45),
        reward: '2 vies par vidéo',
        colors: [LumoraColors.lifeCoral, LumoraColors.auroraPink],
        icon: Icons.local_bar_rounded,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LumoraGradients.homeBg, borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Stack(
            children: [
              // Fond parallaxe saisonnier placeholder
              Positioned.fill(
                child: CustomPaint(
                  painter: _SeasonalParallaxPainter(),
                ),
              ),

              Column(
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
                          'Événements',
                          style: LumoraTextStyles.titleLarge(),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Liste d'événements
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _EventCard(event: events[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventItem {
  final String title;
  final String subtitle;
  final Duration endsIn;
  final String reward;
  final List<Color> colors;
  final IconData icon;

  _EventItem({
    required this.title,
    required this.subtitle,
    required this.endsIn,
    required this.reward,
    required this.colors,
    required this.icon,
  });
}

class _EventCard extends StatelessWidget {
  final _EventItem event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final totalSeconds = event.endsIn.inSeconds;
    final maxSeconds = const Duration(days: 3).inSeconds;
    final progress = (totalSeconds / maxSeconds).clamp(0.0, 1.0);

    return LumoraCard(
      padding: const EdgeInsets.all(20),
      borderRadius: LumoraRadii.modal,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          event.colors.first.withAlpha(50),
          event.colors.last.withAlpha(20),
        ],
      ),
      shadows: [
        LumoraShadows.floating(color: event.colors.last),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône organique
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: event.colors),
                  boxShadow: [LumoraShadows.glow(color: event.colors.first)],
                ),
                child: Icon(event.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),

              // Textes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: LumoraTextStyles.titleLarge(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle,
                      style: LumoraTextStyles.bodyMedium(),
                    ),
                  ],
                ),
              ),

              // Compte à rebours circulaire
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 3,
                      backgroundColor: LumoraColors.disabledMist,
                      valueColor: AlwaysStoppedAnimation<Color>(LumoraColors.disabledMist),
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(event.colors.first),
                    ),
                    Center(
                      child: Text(
                        '${event.endsIn.inHours}h',
                        style: LumoraTextStyles.label(color: event.colors.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Récompense
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LumoraRadii.bubble),
              color: event.colors.last.withAlpha(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard_rounded,
                    size: 16, color: event.colors.first),
                const SizedBox(width: 8),
                Text(
                  event.reward,
                  style: LumoraTextStyles.label(color: event.colors.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CTA
          LumoraButton(
            onPressed: () {
              // TODO: naviguer vers le niveau événement ou l'inscrire
            },
            text: 'Participer',
            gradientColors: event.colors,
            elevation: 4,
          ),
        ],
      ),
    );
  }
}

/// Painter placeholder pour le fond parallaxe saisonnier.
class _SeasonalParallaxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Couche saison — feuilles/pétales placeholder
    final petalPaint = Paint()
      ..color = LumoraColors.auroraPink.withAlpha(30)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 8; i++) {
      final x = (i * 0.13 + 0.05) * size.width;
      final y = (i * 0.11 + 0.1) * size.height;
      canvas.drawCircle(Offset(x, y), 18, petalPaint);
    }

    // Brume saisonnière
    final mistPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          LumoraColors.auroraGreen.withAlpha(25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.8),
        radius: 220,
      ));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 220, mistPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
