import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../monetization/data/reward_inventory.dart';
import '../../monetization/data/rewarded_ad_service.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';

/// Écran événements — cartes organiques pour chaque événement actif,
/// compte à rebours circulaire, fond parallaxe saisonnier placeholder.
class EventsScreen extends StatefulWidget {
  final RewardedAdService? rewardedAdService;

  const EventsScreen({super.key, this.rewardedAdService});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final RewardedAdService _rewardedAdService;
  late final RewardInventory _rewardInventory;
  bool _isRewardPending = false;

  @override
  void initState() {
    super.initState();
    _rewardedAdService = widget.rewardedAdService ?? AdMobRewardedAdService.instance;
    _rewardInventory = RewardInventory.instance;
    _rewardInventory.addListener(_onInventoryChanged);
    _initializeState();
  }

  Future<void> _initializeState() async {
    await _rewardInventory.load();
    await _rewardedAdService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _onInventoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _claimEventReward(_EventReward reward) async {
    if (_isRewardPending) {
      return;
    }

    if (!_rewardInventory.canClaim(reward.placement)) {
      final cooldown = _rewardInventory.remainingCooldown(reward.placement) ?? Duration.zero;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bonus déjà récupéré. Retour dans ${_formatCooldown(cooldown)}.')),
      );
      return;
    }

    setState(() => _isRewardPending = true);
    final rewardEarned = await _rewardedAdService.showRewardedAd(
      placement: reward.placement,
      onRewardEarned: () {},
    );

    if (!mounted) {
      return;
    }

    setState(() => _isRewardPending = false);

    if (!rewardEarned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video indisponible pour le moment.')),
      );
      return;
    }

    _rewardInventory.claim(reward.placement);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${reward.message} Stock sauvegardé.')),
    );
  }

  @override
  void dispose() {
    _rewardInventory.removeListener(_onInventoryChanged);
    super.dispose();
  }

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
        rewardedOffer: const _EventReward(
          id: 'event_daily_boost',
          ctaLabel: 'Booster via vidéo',
          message: 'Bonus quotidien récupéré : +1 vie et aide légère.',
          placement: RewardedPlacement.eventDailyBoost,
        ),
      ),
      _EventItem(
        title: 'Défi Week-End',
        subtitle: 'Filaments Fous — Vitesse x1.5',
        endsIn: const Duration(hours: 18, minutes: 15),
        reward: '3 vies + avatar exclusif',
        colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
        icon: Icons.weekend_rounded,
        rewardedOffer: const _EventReward(
          id: 'event_weekend_boost',
          ctaLabel: 'Super Filament via vidéo',
          message: 'Charge Super Filament ajoutée à ton inventaire.',
          placement: RewardedPlacement.eventWeekendBoost,
        ),
      ),
      _EventItem(
        title: 'Tournoi Automatique',
        subtitle: 'Leaderboard mondial — 10 niveaux',
        endsIn: const Duration(days: 2, hours: 6),
        reward: 'Thème Champion exclusif',
        colors: [LumoraColors.auroraGold, LumoraColors.energyAmber],
        icon: Icons.emoji_events_rounded,
        rewardedOffer: const _EventReward(
          id: 'event_tournament_boost',
          ctaLabel: 'Double Score via vidéo',
          message: 'Charge Double Score ajoutée à ton inventaire.',
          placement: RewardedPlacement.eventTournamentBoost,
        ),
      ),
      _EventItem(
        title: 'Happy Hour',
        subtitle: 'Pubs récompensées x2',
        endsIn: const Duration(hours: 2, minutes: 45),
        reward: '2 vies par vidéo',
        colors: [LumoraColors.lifeCoral, LumoraColors.auroraPink],
        icon: Icons.local_bar_rounded,
        rewardedOffer: const _EventReward(
          id: 'event_happy_hour',
          ctaLabel: 'Réclamer le bonus x2',
          message: 'Happy Hour : 2 vies bonus ajoutées pour cette session.',
          placement: RewardedPlacement.eventHappyHour,
        ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EventInventoryBanner(inventory: _rewardInventory),
                  ),
                  const SizedBox(height: 8),

                  // Liste d'événements
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _EventCard(
                            event: events[index],
                            isRewardPending: _isRewardPending,
                            rewardAvailable: events[index].rewardedOffer == null ||
                              _rewardInventory.canClaim(events[index].rewardedOffer!.placement),
                            cooldown: events[index].rewardedOffer == null
                              ? null
                              : _rewardInventory.remainingCooldown(events[index].rewardedOffer!.placement),
                            onRewardTap: events[index].rewardedOffer == null
                                ? null
                                : () => _claimEventReward(events[index].rewardedOffer!),
                          ),
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
  final _EventReward? rewardedOffer;

  _EventItem({
    required this.title,
    required this.subtitle,
    required this.endsIn,
    required this.reward,
    required this.colors,
    required this.icon,
    this.rewardedOffer,
  });
}

class _EventReward {
  final String id;
  final String ctaLabel;
  final String message;
  final RewardedPlacement placement;

  const _EventReward({
    required this.id,
    required this.ctaLabel,
    required this.message,
    required this.placement,
  });
}

class _EventCard extends StatelessWidget {
  final _EventItem event;
  final bool isRewardPending;
  final bool rewardAvailable;
  final Duration? cooldown;
  final VoidCallback? onRewardTap;

  const _EventCard({
    required this.event,
    required this.isRewardPending,
    required this.rewardAvailable,
    required this.cooldown,
    required this.onRewardTap,
  });

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
          if (event.rewardedOffer != null) ...[
            const SizedBox(height: 10),
            LumoraButton(
              onPressed: !rewardAvailable || isRewardPending ? null : onRewardTap,
              text: isRewardPending
                  ? 'Chargement vidéo...'
                  : !rewardAvailable
                      ? 'Recharge ${_formatCooldown(cooldown)}'
                      : event.rewardedOffer!.ctaLabel,
              gradientColors: [LumoraColors.midnight, event.colors.last],
              elevation: 3,
            ),
          ],
        ],
      ),
    );
  }
}

class _EventInventoryBanner extends StatelessWidget {
  final RewardInventory inventory;

  const _EventInventoryBanner({required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        children: [
          _InventoryBadge(
            icon: Icons.favorite_rounded,
            label: 'Réserve ${inventory.bankedLives}',
            accent: LumoraColors.lifeCoral,
          ),
          _InventoryBadge(
            icon: Icons.lightbulb_rounded,
            label: 'Indices ${inventory.hintCharges}',
            accent: LumoraColors.energyAmber,
          ),
          _InventoryBadge(
            icon: Icons.bolt_rounded,
            label: 'Double ${inventory.doubleScoreCharges}',
            accent: LumoraColors.auroraGold,
          ),
          _InventoryBadge(
            icon: Icons.polyline_rounded,
            label: 'Filaments ${inventory.superFilamentCharges}',
            accent: LumoraColors.auroraBlue,
          ),
        ],
      ),
    );
  }
}

class _InventoryBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _InventoryBadge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        color: accent.withAlpha(28),
        border: Border.all(color: accent.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: LumoraTextStyles.label(color: Colors.white)),
        ],
      ),
    );
  }
}

String _formatCooldown(Duration? duration) {
  if (duration == null) {
    return '';
  }
  if (duration.inHours > 0) {
    return '${duration.inHours}h${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}';
  }
  return '${duration.inMinutes} min';
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
