import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/icons.dart';
import 'app_icon.dart';

const List<String> _kMonths = [
  'Jan','Feb','Mar','Apr','May','Jun',
  'Jul','Aug','Sep','Oct','Nov','Dec',
];

String _fmtDate(DateTime dt) =>
    '${_kMonths[dt.month - 1]} ${dt.day}, ${dt.year}';

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable list item
//  showDivider: pass false only for the last item
// ─────────────────────────────────────────────────────────────────────────────

class HistoryListItem extends StatelessWidget {
  const HistoryListItem({
    super.key,
    required this.appName,
    required this.coins,
    required this.claimedAt,
    this.appIconUrl,
    this.showDivider = true,
  });

  final String     appName;
  final int        coins;
  final Timestamp? claimedAt;
  final String?    appIconUrl;
  final bool       showDivider;

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final dateStr = claimedAt != null ? _fmtDate(claimedAt!.toDate()) : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [

              // ── App icon ──────────────────────────────────────────
              AppIcon(imageUrl: appIconUrl,size: 44,borderRadius: 8,),
              const SizedBox(width: 14),

              // ── App name + date ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleMedium
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        dateStr,
                        style: tt.bodySmall
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Coins earned ──────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(coinIcon, width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+$coins',
                    style: tt.titleSmall?.copyWith(
                      color:      cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),

        // ── Divider — hidden for last item via showDivider flag ─────
        if (showDivider)
          Divider(
            height:    1,
            thickness: 1,
            color:     Theme.of(context).colorScheme.outline,
          ),
      ],
    );
  }
}
