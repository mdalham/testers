// app_grid_card.dart
import 'package:flutter/material.dart';
import '../../controllers/height_width.dart';
import '../../controllers/icons.dart'; // coinIcon asset path

class AppGridCard extends StatelessWidget {
  const AppGridCard({
    super.key,
    required this.title,
    required this.developerName,
    required this.coinCost,
    this.appIconUrl,
    this.isBoosted = false,
    this.onTap,
  });

  final String title;
  final String developerName;
  final int coinCost;
  final String? appIconUrl;
  final bool isBoosted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(baseBorderRadius),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Icon fills the top rounded section
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(baseBorderRadius),
                    topRight: Radius.circular(baseBorderRadius),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: appIconUrl != null && appIconUrl!.isNotEmpty
                        ? Image.network(
                            appIconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _IconPlaceholder(cs: cs),
                            loadingBuilder: (_, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: cs.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                ),
                              );
                            },
                          )
                        : _IconPlaceholder(cs: cs),
                  ),
                ),

                // ── Boosted badge (top-right) ────────────────────────────
                if (isBoosted)
                  Positioned(top: 8, right: 8, child: _BoostedChip()),
              ],
            ),

            // ── Info section ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Developer name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            developerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(color: cs.onPrimary),
                          ),
                        ),
                        _CoinBadge(coinCost: coinCost, tt: tt),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Icon placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _IconPlaceholder extends StatelessWidget {
  const _IconPlaceholder({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.grid_view_rounded,
          size: 36,
          color: cs.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Coin badge
// ─────────────────────────────────────────────────────────────────────────────

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coinCost, required this.tt});
  final int coinCost;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(coinIcon, width: 13, height: 13),
        const SizedBox(width: 4),
        Text(
          '$coinCost',
          style: tt.labelSmall?.copyWith(
            color: Colors.amber,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Boosted chip
// ─────────────────────────────────────────────────────────────────────────────

class _BoostedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.bolt_rounded, size: 14, color: Colors.amber);
  }
}
