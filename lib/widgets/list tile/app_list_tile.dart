import 'package:flutter/material.dart';
import 'package:testers/utils/height_width.dart';
import 'package:testers/constants/icons.dart';
import 'package:testers/widgets/list tile/app_icon.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.appName,
    required this.developerName,
    required this.coins,
    this.appIconUrl,
    this.onTap,
  });

  final String        appName;
  final String        developerName;
  final int           coins;
  final String?       appIconUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(baseBorderRadius),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(baseBorderRadius),
        child: Ink(
          decoration: BoxDecoration(
            color:        cs.primaryContainer,
            borderRadius: BorderRadius.circular(baseBorderRadius),
            border:       Border.all(color: cs.outline, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                AppIcon(imageUrl: appIconUrl, size: 50, borderRadius: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text(
                        appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:    tt.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        developerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _CoinBadge(coins: coins, cs: cs, tt: tt),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge(
      {required this.coins, required this.cs, required this.tt});
  final int         coins;
  final ColorScheme cs;
  final TextTheme   tt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(coinIcon, width: 16, height: 16),
        const SizedBox(width: 5),
        Text(
          '$coins',
          style: tt.bodyMedium?.copyWith(
            color:      Colors.amber,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}