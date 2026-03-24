import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/widget/list%20tile/app_icon.dart';
import '../../../controllers/height_width.dart';
import '../../../controllers/icons.dart';
import '../../../service/provider/auth_provider.dart';
import '../provider/discount_provider.dart';
import '../provider/publish_provider.dart';

class Step4TesterSelection extends StatelessWidget {
  const Step4TesterSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final p  = context.watch<PublishProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(baseScreenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.group_rounded, size: 18, color: cs.onSurface),
              const SizedBox(width: 8),
              Text('Select Testers',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Choose how many testers will test your app.',
              style: tt.labelSmall?.copyWith(color: cs.onPrimary)),
          const SizedBox(height: 16),

          _TesterStepper(
            options:  kTesterOptions,
            selected: p.selectedTesterCount,
            onSelect: p.setSelectedTesterCount,
          ),

          SizedBox(height: bottomPadding),

          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 18, color: cs.onSurface),
              const SizedBox(width: 8),
              Text('Cost Preview',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),

          _CostPreviewCard(provider: p),

          // ── Not enough coins ───────────────────────────────────────────────
          _GetCoinsCardConditional(provider: p),

          SizedBox(height: bottomPadding + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tester Stepper
// ─────────────────────────────────────────────────────────────────────────────

class _TesterStepper extends StatelessWidget {
  const _TesterStepper({
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final List<int>         options;
  final int               selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: options.map((count) {
          final isSelected = count == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(count),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin:   const EdgeInsets.all(3),
                padding:  const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color:        isSelected ? Colors.blue.withOpacity(0.4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),

                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_rounded,
                        size:  isSelected ? 20 : 18,
                        color: isSelected ? Colors.white : cs.onSurface),
                    const SizedBox(height: 4),
                    Text('$count',
                        style: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : cs.primary)),
                    Text('testers',
                        style: TextStyle(
                            fontSize:   10,
                            fontWeight: FontWeight.w500,
                            color:      isSelected
                                ? Colors.white.withOpacity(0.75)
                                : cs.primary)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Cost Preview Card
// ─────────────────────────────────────────────────────────────────────────────

class _CostPreviewCard extends StatelessWidget {
  const _CostPreviewCard({required this.provider});
  final PublishProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final tt           = Theme.of(context).textTheme;
    final p            = provider;
    final discount     = context.watch<DiscountProvider>();
    final auth         = context.watch<AuthProvider>();

    final userCoins    = auth.coins;
    final originalCost = p.totalCoinsRequired;
    final finalCost    = discount.discountedCost(originalCost);
    final saved        = discount.savedCoins(originalCost);
    final canAfford    = userCoins >= finalCost;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:       Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppIcon(
                imageUrl: p.uploadedIconUrl,
                size:  50,
                borderRadius: 8,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.step3AppName.trim().isEmpty
                          ? 'Your App'
                          : p.step3AppName.trim(),
                      style: tt.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      p.step3PackageName.trim().isEmpty
                          ? 'com.example.app'
                          : p.step3PackageName.trim(),
                      style: tt.labelMedium?.copyWith(
                          color:      cs.onPrimary,
                          fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: cs.outline),
          const SizedBox(height: 10),

          // ── Line items ─────────────────────────────────────────────────────
          _ReceiptRow(
            label:      'Testers',
            value:      '${p.selectedTesterCount}',
            valueColor: cs.onSurface,
          ),
          const SizedBox(height: 10),
          _ReceiptRow(
            label:      'Reward per tester',
            value:      '${p.rewardPerTester} coins',
            valueColor: cs.primary,
          ),

          if (discount.hasDiscount) ...[
            const SizedBox(height: 10),
            _ReceiptRow(
              label: discount.label.isNotEmpty
                  ? '${discount.label} (${discount.percentage}% off)'
                  : 'Discount (${discount.percentage}% off)',
              value:      '− $saved coins',
              valueColor: Colors.green,
            ),
          ],

          const SizedBox(height: 10),
          Divider(height: 1, color: cs.outline),
          const SizedBox(height: 10),

          // ── Total ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: tt.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Row(
                children: [
                  Image.asset(coinIcon, width: 15, height: 15),
                  const SizedBox(width: 5),
                  if (discount.hasDiscount) ...[
                    Text(
                      '$originalCost',
                      style: tt.bodySmall?.copyWith(
                        color:           cs.onPrimary,
                        decoration:      TextDecoration.lineThrough,
                        decorationColor: cs.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '$finalCost coins',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: canAfford ? cs.primary : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Receipt Row
// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color  valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: tt.bodySmall?.copyWith(color: cs.onPrimary)),
        Text(value,
            style: tt.bodySmall
                ?.copyWith(color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Get Coins — conditional wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _GetCoinsCardConditional extends StatelessWidget {
  const _GetCoinsCardConditional({required this.provider});
  final PublishProvider provider;

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final discount = context.watch<DiscountProvider>();
    final finalCost = discount.discountedCost(provider.totalCoinsRequired);
    final canAfford = auth.coins >= finalCost;

    if (canAfford) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 12),
        _GetCoinsCard(
          deficit:   finalCost - auth.coins,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Get Coins CTA
// ─────────────────────────────────────────────────────────────────────────────

class _GetCoinsCard extends StatelessWidget {
  const _GetCoinsCard({required this.deficit});
  final int deficit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You need $deficit more coins to publish.',
              style: tt.labelMedium?.copyWith(
                  color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {/* Navigator.pushNamed(context, '/get-coins') */},
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
            child: const Text('Get Coins',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}