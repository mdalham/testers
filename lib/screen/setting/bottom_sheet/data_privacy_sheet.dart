import 'package:flutter/material.dart';

import '../widget/last_updated.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DataPrivacySheet
//
// Usage:
//   DataPrivacySheet.show(context);
// ─────────────────────────────────────────────────────────────────────────────

class DataPrivacySheet extends StatelessWidget {
  const DataPrivacySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      useRootNavigator:   true,
      backgroundColor:    Colors.transparent,
      builder:            (_) => const DataPrivacySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize:     0.4,
      maxChildSize:     0.95,
      expand:           false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:        cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border:       Border(top : BorderSide(color: cs.outline)),
          ),
          child: Column(
            children: [
              _DragHandle(cs: cs),
              _SheetHeader(cs: cs),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: const [
                    _IntroBlock(),
                    _DataCard(
                      icon:       Icons.storage_outlined,
                      title:      'Data We Store',
                      accentColor: Color(0xFF2196F3),
                      items: [
                        _DataItem(
                          label: 'Account Info',
                          value: 'Name, email, username, profile photo',
                          icon:  Icons.person_outline_rounded,
                        ),
                        _DataItem(
                          label: 'App Listings',
                          value: 'App name, package, icon, description',
                          icon:  Icons.apps_rounded,
                        ),
                        _DataItem(
                          label: 'Testing History',
                          value: 'Apps tested, dates, coins earned',
                          icon:  Icons.history_rounded,
                        ),
                        _DataItem(
                          label: 'Coin Balance',
                          value: 'Current balance and transaction records',
                          icon:  Icons.monetization_on_outlined,
                        ),
                        _DataItem(
                          label: 'Notifications',
                          value: 'In-app notification history',
                          icon:  Icons.notifications_outlined,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _DataCard(
                      icon:        Icons.sync_outlined,
                      title:       'How Your Data Is Used',
                      accentColor: Color(0xFF4CAF50),
                      items: [
                        _DataItem(
                          label: 'Service Delivery',
                          value: 'To provide the core app testing platform',
                          icon:  Icons.rocket_launch_outlined,
                        ),
                        _DataItem(
                          label: 'Notifications',
                          value: 'To alert you about testing and publishing events',
                          icon:  Icons.notifications_active_outlined,
                        ),
                        _DataItem(
                          label: 'Analytics',
                          value: 'To improve app performance and user experience',
                          icon:  Icons.bar_chart_rounded,
                        ),
                        _DataItem(
                          label: 'Security',
                          value: 'To detect and prevent fraudulent activity',
                          icon:  Icons.security_outlined,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _DataCard(
                      icon:        Icons.share_outlined,
                      title:       'Data Sharing',
                      accentColor: Color(0xFFFF9800),
                      items: [
                        _DataItem(
                          label: 'Firebase (Google)',
                          value: 'Authentication, database, and storage',
                          icon:  Icons.cloud_outlined,
                        ),
                        _DataItem(
                          label: 'Never Sold',
                          value: 'We never sell your data to third parties',
                          icon:  Icons.block_outlined,
                        ),
                        _DataItem(
                          label: 'Legal Requests',
                          value: 'Only when required by applicable law',
                          icon:  Icons.gavel_outlined,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _RetentionSection(),
                    SizedBox(height: 20),
                    _YourRightsSection(),
                    SizedBox(height: 20),
                    _ContactSection(),
                    LastUpdated(text: 'Last updated: January 2025',),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Drag Handle ───────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width:  40,
          height: 4,
          decoration: BoxDecoration(
            color:        cs.outlineVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ── Sheet Header ──────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      child: Row(
        children: [
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color:        cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield_outlined, color: cs.onSurface, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data & Privacy',
                  style: tt.titleLarge,
                ),
                Text(
                  'Manage your data',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon:      Icon(Icons.close_rounded, color: cs.onSurface),
            tooltip:   'Close',
          ),
        ],
      ),
    );
  }
}

// ── Intro Block ───────────────────────────────────────────────────────────────

class _IntroBlock extends StatelessWidget {
  const _IntroBlock();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin:  const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        cs.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Here\'s a clear overview of what data we collect, how we use it, '
                  'and the controls you have over your information.',
              style: tt.bodySmall?.copyWith(
                color:  cs.onPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Item model ───────────────────────────────────────────────────────────

class _DataItem {
  const _DataItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String   label;
  final String   value;
  final IconData icon;
}

// ── Data Card ─────────────────────────────────────────────────────────────────

class _DataCard extends StatelessWidget {
  const _DataCard({
    super.key,
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.items,
  });

  final IconData      icon;
  final String        title;
  final Color         accentColor;
  final List<_DataItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Container(
              width:  32,
              height: 32,
              decoration: BoxDecoration(
                color:        accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: tt.titleSmall
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Items container
        Container(
          decoration: BoxDecoration(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: cs.outline),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i    = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width:  34,
                          height: 34,
                          decoration: BoxDecoration(
                            color:        accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon,
                              size: 16, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:      cs.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.value,
                                style: tt.labelSmall?.copyWith(
                                  color:  cs.onPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    Divider(
                      height:    1,
                      indent:    60,
                      color: cs.outline,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Retention Section ─────────────────────────────────────────────────────────

class _RetentionSection extends StatelessWidget {
  const _RetentionSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width:  32,
              height: 32,
              decoration: BoxDecoration(
                color:        const Color(0xFF9C27B0).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.timelapse_rounded,
                  size: 16, color: Color(0xFF9C27B0)),
            ),
            const SizedBox(width: 10),
            Text(
              'Data Retention',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:      cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:       Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: cs.outline),
          ),
          child: Text(
            'We retain your personal data for as long as your account is active or as needed to provide services.\n\n'
                '• Account data is retained until you delete your account.\n'
                '• Testing history and coin transactions are kept for 12 months after account deletion for audit purposes.\n'
                '• App listing data may be retained in anonymised form for analytics.\n\n'
                'You can request full deletion of your data by contacting us.',
            style: tt.bodySmall?.copyWith(
              color:  cs.onPrimary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Your Rights Section ───────────────────────────────────────────────────────

class _YourRightsSection extends StatelessWidget {
  const _YourRightsSection();

  static const _rights = [
    (Icons.visibility_outlined,      'Access',     'Request a copy of all data we hold about you'),
    (Icons.edit_outlined,            'Correct',    'Request correction of inaccurate information'),
    (Icons.delete_outline_rounded,   'Delete',     'Request deletion of your account and data'),
    //(Icons.download_outlined,        'Export',     'Export your data in a portable format'),
    (Icons.notifications_off_outlined,'Opt Out',   'Unsubscribe from non-essential communications'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width:  32,
              height: 32,
              decoration: BoxDecoration(
                color:        const Color(0xFF009688).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.how_to_reg_outlined,
                  size: 16, color: Color(0xFF009688)),
            ),
            const SizedBox(width: 10),
            Text(
              'Your Rights',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color:      cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: cs.outline),
          ),
          child: Column(
            children: _rights.asMap().entries.map((entry) {
              final i              = entry.key;
              final (icon, label, desc) = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width:  34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF009688).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon,
                              size: 16,
                              color: const Color(0xFF009688)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:      cs.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: tt.labelSmall?.copyWith(
                                  color:  cs.onPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < _rights.length - 1)
                    Divider(
                      height: 1,
                      indent: 60,
                      color:  cs.outlineVariant.withOpacity(0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Contact Section ───────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin:  const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mail_outline_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise Your Rights',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To make any request, contact us at:\ninfo.thardstudio@gmail.com\n\nWe respond within 5 business days.',
                  style: tt.bodySmall?.copyWith(
                    color:  cs.onPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}