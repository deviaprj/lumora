import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/lumora_button.dart';
import '../../../shared/widgets/lumora_card.dart';

/// Boutique — fond dégradé, scroll horizontal organique avec snap elastic,
/// cartes organiques pour chaque produit (Pack Vies, Thèmes, Passe Saisonnier)
/// avec aperçu placeholder.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

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
                      child: _ProductCard(product: product),
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

  _Product({
    required this.name,
    required this.price,
    required this.description,
    required this.colors,
    required this.icon,
    this.badge,
  });
}

class _ProductCard extends StatelessWidget {
  final _Product product;

  const _ProductCard({required this.product});

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
        ],
      ),
    );
  }
}
