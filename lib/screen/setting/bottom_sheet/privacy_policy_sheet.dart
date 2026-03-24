import 'package:flutter/material.dart';

import '../widget/last_updated.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PrivacyPolicySheet
//
// Usage:
//   PrivacyPolicySheet.show(context);
// ─────────────────────────────────────────────────────────────────────────────

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: cs.outline, width: 1.5)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────
              _DragHandle(cs: cs),

              // ── Header (fixed, not scrollable) ───────────────────
              _SheetHeader(cs: cs),

              // ── Scrollable body ──────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: const [
                    _IntroBlock(),
                    _PolicySection(
                      icon: Icons.info_outline_rounded,
                      title: '1. Information We Collect',
                      body:
                          'We collect information you provide directly to us when you create an account, such as your name, email address, and username.\n\n'
                          //'We also collect usage data automatically, including device information, log data, and interaction data within the app to improve your experience.',
                    ),
                    _PolicySection(
                      icon: Icons.storage_outlined,
                      title: '2. How We Use Your Information',
                      body:
                          '• To provide, maintain, and improve our services.\n'
                          '• To send you notifications about your app listings and testing activity.\n'
                          '• To process transactions and manage your coin balance.\n'
                          '• To communicate with you about updates, support, and promotions.\n'
                          '• To detect, prevent, and address technical issues or abuse.',
                    ),
                    _PolicySection(
                      icon: Icons.share_outlined,
                      title: '3. Sharing of Information',
                      body:
                          'We do not sell, trade, or rent your personal information to third parties.\n\n'
                          'We may share your information with trusted service providers who assist us in operating the app (e.g. Firebase, Google), subject to strict confidentiality agreements.\n\n'
                          'We may disclose information if required by law or to protect the rights and safety of our users.',
                    ),
                    _PolicySection(
                      icon: Icons.lock_outline_rounded,
                      title: '4. Data Security',
                      body:
                          'We implement industry-standard security measures including Firebase Authentication and Firestore security rules to protect your data.\n\n'
                          'However, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security but are committed to protecting your information.',
                    ),
                    _PolicySection(
                      icon: Icons.person_outline_rounded,
                      title: '5. Your Rights',
                      body:
                          'You have the right to:\n'
                          '• Access the personal information we hold about you.\n'
                          '• Request correction of inaccurate data.\n'
                          '• Request deletion of your account and associated data.\n'
                          '• Opt out of non-essential communications at any time.\n\n'
                          'To exercise these rights, contact us at the email provided below.',
                    ),
                    _PolicySection(
                      icon: Icons.child_care_outlined,
                      title: '6. Children\'s Privacy',
                      body:
                          'Our service is not directed to children under the age of 13.\n\n'//We do not knowingly collect personal information from children.
                          'If you believe we have inadvertently collected such information, please contact us immediately and we will take steps to delete it.',
                    ),
                    _PolicySection(
                      icon: Icons.cookie_outlined,
                      title: '7. Cookies & Tracking',
                      body:
                          'We use Firebase Analytics and Crashlytics to understand app usage patterns and improve stability. These tools may collect anonymised usage data.\n\n'
                          'You may opt out of analytics collection through your device settings at any time.',
                    ),
                    _PolicySection(
                      icon: Icons.update_rounded,
                      title: '8. Changes to This Policy',
                      body:
                          'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or via email.\n\n'
                          'Continued use of the app after changes constitutes your acceptance of the revised policy. We encourage you to review this policy periodically.',
                    ),
                    _PolicySection(
                      icon: Icons.mail_outline_rounded,
                      title: '9. Contact Us',
                      body:
                          'If you have any questions, concerns, or requests regarding this Privacy Policy, please contact us at:\n\n'
                          'info.thardstudio@gmail.com\n\n'
                          'We will respond to your inquiry within 5 business days.',
                    ),
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
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant.withOpacity(0.5),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.privacy_tip_outlined,
              color: cs.onSurface,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Policy', style: tt.titleLarge),
                Text(
                  'Open Testers App',
                  style: tt.bodySmall?.copyWith(color: cs.onPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: cs.onSurface),
            tooltip: 'Close',
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your privacy matters to us. This policy explains how Testers '
              'collects, uses, and protects your personal information.',
              style: tt.bodySmall?.copyWith(color: cs.onPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Policy Section ────────────────────────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: tt.titleSmall)),
            ],
          ),
          const SizedBox(height: 10),
          // Body text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Text(
              body,
              style: tt.bodySmall?.copyWith(color: cs.onPrimary, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Last Updated ──────────────────────────────────────────────────────────────


