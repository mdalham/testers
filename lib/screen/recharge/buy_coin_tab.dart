import 'package:flutter/material.dart';
import 'package:testers/widget/snackbar/custom_snackbar.dart';

import '../../controllers/icons.dart';
import '../../widget/internet/internet_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Coin package model
// ─────────────────────────────────────────────────────────────────────────────

class _CoinPackage {
  const _CoinPackage({
    required this.coins,
    required this.price,
    this.badge,
    this.isBestValue = false,
  });

  final int coins;
  final String price;
  final String? badge;
  final bool isBestValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// BuyCoinTab
// ─────────────────────────────────────────────────────────────────────────────

class BuyCoinTab extends StatelessWidget {
  const BuyCoinTab({super.key});

  static const _packages = [
    _CoinPackage(coins: 100, price: '\$0.39'),
    _CoinPackage(coins: 250, price: '\$0.79', badge: '🔥 Popular'),
    _CoinPackage(
      coins: 500,
      price: '\$1.29',
      badge: '✨ Best Value',
      isBestValue: true,
    ),
    _CoinPackage(coins: 1000, price: '\$2.59', badge: '💎 Premium'),
    _CoinPackage(coins: 2000, price: '\$4.99'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _packages.length + 2, // +2 for Header and Footer
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {

        const InternetBanner();

        // 1. Header Section
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Choose a Package',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        // 2. Footer Section (Security Note)
        if (index == _packages.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  'Secure payment via Google Play',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        // 3. The Package List Item
        final pkg = _packages[index - 1];
        return _PackageCard(pkg: pkg);
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.pkg});
  final _CoinPackage pkg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isHighlight = pkg.isBestValue;

    // Brand Colors
    const orange = Color(0xFFFF9800);
    const blue = Color(0xFF1565C0);
    final Color accent = isHighlight ? blue : orange;

    return GestureDetector(
      onTap: () => _onBuy(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlight ? accent : cs.outline,
            width: isHighlight ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Left: Icon Container
            Container(
              width: 56,
              height: 56,
              padding: .all(14),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:Image.asset(coinIcon),

            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pkg.badge != null) ...[
                    Text(
                      pkg.badge!.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Text(
                        '${pkg.coins}',
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Coins',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: Price Button
            ElevatedButton(
              onPressed: () => _onBuy(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                pkg.price,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBuy(BuildContext context) {
    CustomSnackbar.show(
      context,
      message: "Coming Soon! This feature is under development.",
      type: SnackBarType.success
    );
  }
}
