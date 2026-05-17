import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../data/reward_inventory.dart';
import '../data/rewarded_ad_service.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';

/// Boutique — fond dégradé, scroll horizontal organique avec snap elastic,
/// cartes organiques pour chaque produit (Pack Vies, Thèmes, Passe Saisonnier)
/// avec aperçu placeholder.
class ShopScreen extends StatefulWidget {
  final RewardedAdService? rewardedAdService;

  const ShopScreen({super.key, this.rewardedAdService});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
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

  Future<void> _claimReward(_RewardedOffer offer) async {
    if (_isRewardPending) {
      return;
    }

    if (!_rewardInventory.canClaim(offer.placement)) {
      final cooldown = _rewardInventory.remainingCooldown(offer.placement) ?? Duration.zero;
      final hours = cooldown.inHours;
      final minutes = cooldown.inMinutes.remainder(60);
      final label = hours > 0 ? '${hours}h${minutes.toString().padLeft(2, '0')}' : '${cooldown.inMinutes} min';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bonus déjà récupéré. Réessaie dans $label.')),
      );
      return;
    }

    setState(() => _isRewardPending = true);
    final rewardEarned = await _rewardedAdService.showRewardedAd(
      placement: offer.placement,
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

    _rewardInventory.claim(offer.placement);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${offer.rewardMessage} Stock sauvegardé.')),
    );
  }

  @override
  void dispose() {
    _rewardInventory.removeListener(_onInventoryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = [
      _Product(
        name: 'Pack 5 Vies',
        price: '0.99 \$',
        description: 'Recharge instantanée pour continuer ta lumière.',
        colors: [LumoraColors.lifeCoral, LumoraColors.lifeRose],
        icon: Icons.favorite_rounded,
        badge: null,
        rewardedOffer: const _RewardedOffer(
          id: 'shop_life_reward',
          ctaLabel: '1 vie via vidéo',
          rewardMessage: '1 vie de secours ajoutée a ta session.',
          placement: RewardedPlacement.shopLives,
        ),
      ),
      _Product(
        name: 'Pack 20 Vies',
        price: '2.99 \$',
        description: 'Meilleur rapport qualité/prix.',
        colors: [LumoraColors.lifeCoral, LumoraColors.auroraGold],
        icon: Icons.favorite_rounded,
        badge: 'Populaire',
      ),
      _Product(
        name: 'Thème Nébula',
        price: '1.99 \$',
        description: 'Fond cosmétique + effets 3D exclusifs.',
        colors: [LumoraColors.auroraPurple, LumoraColors.auroraPink],
        icon: Icons.palette_rounded,
        badge: null,
        rewardedOffer: const _RewardedOffer(
          id: 'shop_theme_trial',
          ctaLabel: 'Essai via vidéo',
          rewardMessage: 'Theme Nébula débloqué en essai de session.',
          placement: RewardedPlacement.shopThemeTrial,
        ),
      ),
      _Product(
        name: 'Passe Saisonnier',
        price: '4.99 \$',
        description: 'Niveaux événementiels, récompenses x2, 0 pub.',
        colors: [LumoraColors.auroraGold, LumoraColors.energyAmber],
        icon: Icons.star_rounded,
        badge: 'Best',
      ),
      _Product(
        name: 'Pack Indices x10',
        price: '1.99 \$',
        description: '10 jetons d\'indice manuel.',
        colors: [LumoraColors.energyAmber, LumoraColors.auroraGold],
        icon: Icons.lightbulb_rounded,
        badge: null,
        rewardedOffer: const _RewardedOffer(
          id: 'shop_hint_reward',
          ctaLabel: '1 indice via vidéo',
          rewardMessage: '1 indice bonus ajouté pour cette session.',
          placement: RewardedPlacement.shopHints,
        ),
      ),
    ];

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
                      'Boutique',
                      style: LumoraTextStyles.titleLarge(),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InventorySummaryRibbon(inventory: _rewardInventory),
              ),

              // Scroll horizontal organique
              Expanded(
                child: PageView.builder(
                  controller: PageController(
                    viewportFraction: 0.82,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 24,
                      ),
                      child: _ProductCard(
                        product: product,
                        isRewardPending: _isRewardPending,
                        rewardAvailable: product.rewardedOffer == null ||
                          _rewardInventory.canClaim(product.rewardedOffer!.placement),
                        cooldown: product.rewardedOffer == null
                          ? null
                          : _rewardInventory.remainingCooldown(product.rewardedOffer!.placement),
                        onRewardTap: product.rewardedOffer == null
                            ? null
                            : () => _claimReward(product.rewardedOffer!),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Product {
  final String name;
  final String price;
  final String description;
  final List<Color> colors;
  final IconData icon;
  final String? badge;
  final _RewardedOffer? rewardedOffer;

  _Product({
    required this.name,
    required this.price,
    required this.description,
    required this.colors,
    required this.icon,
    this.badge,
    this.rewardedOffer,
  });
}

class _RewardedOffer {
  final String id;
  final String ctaLabel;
  final String rewardMessage;
  final RewardedPlacement placement;

  const _RewardedOffer({
    required this.id,
    required this.ctaLabel,
    required this.rewardMessage,
    required this.placement,
  });
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final bool isRewardPending;
  final bool rewardAvailable;
  final Duration? cooldown;
  final VoidCallback? onRewardTap;

  const _ProductCard({
    required this.product,
    required this.isRewardPending,
    required this.rewardAvailable,
    required this.cooldown,
    required this.onRewardTap,
  });

  @override
  Widget build(BuildContext context) {
    return LumoraCard(
      padding: const EdgeInsets.all(24),
      borderRadius: LumoraRadii.screen,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          product.colors.first.withAlpha(80),
          product.colors.last.withAlpha(40),
        ],
      ),
      shadows: [
        LumoraShadows.floating(color: product.colors.last),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          if (product.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LumoraRadii.bubble),
                gradient: LumoraGradients.victory,
              ),
              child: Text(
                product.badge!,
                style: LumoraTextStyles.label(color: LumoraColors.deepSpace),
              ),
            ),
          const Spacer(),

          // Aperçu placeholder
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: product.colors,
                ),
                boxShadow: [LumoraShadows.glow(color: product.colors.first)],
              ),
              child: Icon(product.icon, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),

          // Nom
          Text(
            product.name,
            style: LumoraTextStyles.displayMedium(),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            product.description,
            style: LumoraTextStyles.bodyMedium(),
          ),
          const Spacer(),

          // Prix + CTA
          Row(
            children: [
              Text(
                product.price,
                style: LumoraTextStyles.displayMedium(color: LumoraColors.auroraGold),
              ),
              const Spacer(),
              LumoraButton(
                onPressed: () {
                  // TODO: lancer achat via RevenueCat adapter
                },
                text: 'Acheter',
                gradientColors: product.colors,
                elevation: 6,
              ),
            ],
          ),
          if (product.rewardedOffer != null) ...[
            const SizedBox(height: 12),
            LumoraButton(
              onPressed: !rewardAvailable || isRewardPending ? null : onRewardTap,
              text: isRewardPending
                  ? 'Chargement vidéo...'
                  : !rewardAvailable
                      ? 'Recharge ${_formatCooldown(cooldown)}'
                      : product.rewardedOffer!.ctaLabel,
              gradientColors: [LumoraColors.midnight, product.colors.last],
              elevation: 3,
            ),
          ],
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

class _InventorySummaryRibbon extends StatelessWidget {
  final RewardInventory inventory;

  const _InventorySummaryRibbon({required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InventoryChip(
          icon: Icons.favorite_rounded,
          label: 'Vies réserve',
          value: inventory.bankedLives,
          accent: LumoraColors.lifeCoral,
        ),
        _InventoryChip(
          icon: Icons.lightbulb_rounded,
          label: 'Indices',
          value: inventory.hintCharges,
          accent: LumoraColors.energyAmber,
        ),
      ],
    );
  }
}

class _InventoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  const _InventoryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumoraRadii.bubble),
        gradient: LinearGradient(
          colors: [accent.withAlpha(45), LumoraColors.deepSpace.withAlpha(150)],
        ),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '$label : $value',
            style: LumoraTextStyles.label(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
