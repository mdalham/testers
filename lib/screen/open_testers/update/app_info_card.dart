import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../controllers/height_width.dart';
import '../../../widget/button/custom_buttons.dart';


class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.appId,
    required this.currentUid,
    required this.publisherUid,
    required this.appName,
    required this.developerName,
    required this.packageName,
    this.appIconUrl,
    this.onEdit,
    this.onBoost,
  });

  final String        appId;
  final String        currentUid;
  final String        publisherUid;
  final String        appName;
  final String        developerName;
  final String        packageName;
  final String?       appIconUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onBoost;

  bool get _isOwner => currentUid == publisherUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('apps')
          .doc(appId)
          .snapshots(),
      builder: (context, snap) {
        final data            = snap.data?.data() as Map<String, dynamic>?;
        final current         = (data?['currentTesterCount'] as num?)?.toInt() ?? 0;
        final max             = (data?['maxTesters']         as num?)?.toInt() ?? 1;
        final isBoosted       = (data?['isBoosted']          as bool?) ?? false;
        final isFull          = (data?['isFull']             as bool?) ?? false;
        final status          = (data?['status']             as String?) ?? 'active';
        final createdAt       = data?['createdAt']           as Timestamp?;
        final durationEnabled = (data?['testingDurationEnabled'] as bool?) ?? false;
        final durationType    = (data?['testingDuration']    as String?) ?? 'days14';
        final testingPhase    = (data?['testingPhase']       as String?) ?? 'open';
        final appType         = (data?['appType']            as String?) ?? 'App';
        final specialLogin    = (data?['specialLogin']       as bool?)   ?? false;

        final isActive       = status == 'active' && !isFull;
        final progress       = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
        final publishedDate  = _formatDate(createdAt);
        final remainingLabel = _remainingLabel(
          createdAt:       createdAt,
          durationEnabled: durationEnabled,
          durationType:    durationType,
        );

        return _AppInfoCardContent(
          appName:        appName,
          developerName:  developerName,
          packageName:    packageName,
          appIconUrl:     appIconUrl,
          current:        current,
          max:            max,
          progress:       progress,
          isActive:       isActive,
          isBoosted:      isBoosted,
          publishedDate:  publishedDate,
          remainingLabel: remainingLabel,
          isOwner:        _isOwner,
          testingPhase:   testingPhase,
          appType:        appType,
          specialLogin:   specialLogin,
          onEdit:         onEdit,
          onBoost:        onBoost,
        );
      },
    );
  }

  static String _formatDate(Timestamp? ts) {
    if (ts == null) return '—';
    final dt     = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _remainingLabel({
    required Timestamp? createdAt,
    required bool       durationEnabled,
    required String     durationType,
  }) {
    if (!durationEnabled || durationType != 'days14') return 'Unlimited';
    if (createdAt == null) return '—';
    final expiry    = createdAt.toDate().add(const Duration(days: 14));
    final remaining = expiry.difference(DateTime.now()).inDays;
    if (remaining <= 0) return 'Expired';
    return '$remaining ${remaining == 1 ? 'Day' : 'Days'}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppInfoCard content (stateless, pure display)
// ─────────────────────────────────────────────────────────────────────────────

class _AppInfoCardContent extends StatelessWidget {
  const _AppInfoCardContent({
    required this.appName,
    required this.developerName,
    required this.packageName,
    required this.appIconUrl,
    required this.current,
    required this.max,
    required this.progress,
    required this.isActive,
    required this.isBoosted,
    required this.publishedDate,
    required this.remainingLabel,
    required this.isOwner,
    required this.testingPhase,
    required this.appType,
    required this.specialLogin,
    this.onEdit,
    this.onBoost,
  });

  final String        appName, developerName, packageName;
  final String?       appIconUrl;
  final int           current, max;
  final double        progress;
  final bool          isActive, isBoosted, isOwner, specialLogin;
  final String        publishedDate, remainingLabel;
  final String        testingPhase, appType;
  final VoidCallback? onEdit;
  final VoidCallback? onBoost;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final rows = <_InfoRow>[
      _InfoRow(
        icon:  Icons.code_rounded,
        label: 'Developer',
        value: developerName,
      ),
      _InfoRow(
        icon:  Icons.inventory_2_outlined,
        label: 'Package',
        value: packageName,
        mono:  true,
      ),
      _InfoRow(
        icon:  Icons.science_outlined,
        label: 'Testing phase',
        value: _formatPhase(testingPhase),
      ),
      _InfoRow(
        icon:  Icons.grid_view_rounded,
        label: 'Category',
        value: appType,
      ),
      _InfoRow(
        icon:  Icons.people_outline_rounded,
        label: 'Max testers',
        value: '$max',
      ),
      _InfoRow(
        icon:       Icons.people_rounded,
        label:      'Testers',
        value:      '$current / $max',
        valueColor: Colors.blueAccent,
      ),
      _InfoRow(
        icon:  Icons.lock_outline_rounded,
        label: 'Login required',
        value: specialLogin ? 'Yes' : 'No',
      ),
      _InfoRow(
        icon:       Icons.timer_outlined,
        label:      'Remaining',
        value:      remainingLabel,
        valueColor: Colors.blue,
      ),
      _InfoRow(
        icon:  Icons.calendar_today_rounded,
        label: 'Published',
        value: publishedDate,
      ),
      _InfoRow(
        icon:       Icons.circle_rounded,
        label:      'Status',
        value:      isActive ? 'Active' : 'Completed',
        valueColor: isActive ? Colors.green : Colors.blueAccent,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color:        cs.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(baseBorderRadius),
        border:       Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          ...rows.asMap().entries.map((e) {
            final isLast = !isOwner && e.key == rows.length - 1;
            return Column(
              children: [
                _InfoRowTile(row: e.value),
                if (!isLast)
                  Divider(thickness: 1, color: cs.outline),
              ],
            );
          }),

          // ── Owner actions inside the card ────────────────────────────
          if (isOwner) ...[
            Divider(thickness: 1, color: cs.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: CustomOutlineBtn(
                      label:       'Edit',
                      prefixIcon:  Icons.edit_rounded,
                      size:        BtnSize.small,
                      isFullWidth: true,
                      onPressed:   onEdit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomElevatedBtn(
                      label:           isBoosted ? 'Boosted' : 'Boost',
                      prefixIcon:      isBoosted
                          ? Icons.bolt_rounded
                          : Icons.rocket_launch_rounded,
                      size:            BtnSize.small,
                      isFullWidth:     true,
                      backgroundColor: isBoosted ? Colors.green : Colors.amber,
                      foregroundColor: isBoosted ? Colors.white : Colors.black87,
                      enabled:         !isBoosted,
                      onPressed:       isBoosted ? null : onBoost,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatPhase(String raw) {
    switch (raw) {
      case 'closed':     return 'Closed testing';
      case 'open':       return 'Open testing';
      case 'production': return 'Production';
      default:           return raw;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Info row model
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  final IconData icon;
  final String   label, value;
  final Color?   valueColor;
  final bool     mono;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Info row tile
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRowTile extends StatelessWidget {
  const _InfoRowTile({required this.row});
  final _InfoRow row;

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final tt         = Theme.of(context).textTheme;
    final valueColor = row.valueColor ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(row.icon, size: 17, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.label,
              style: tt.bodyMedium?.copyWith(color: cs.onPrimary),
            ),
          ),
          Text(
            row.value,
            textAlign: TextAlign.start,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color:      valueColor,
              fontFamily: row.mono ? 'monospace' : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}