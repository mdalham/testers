import 'package:flutter/material.dart';

import '../widget/last_updated.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TermsOfServiceSheet
//
// Usage:
//   TermsOfServiceSheet.show(context);
// ─────────────────────────────────────────────────────────────────────────────

class TermsOfServiceSheet extends StatelessWidget {
  const TermsOfServiceSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      useRootNavigator:   true,
      backgroundColor:    Colors.transparent,
      builder:            (_) => const TermsOfServiceSheet(),
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
            border: Border(top: BorderSide(color: cs.outline, width: 1.5)),

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
                    _TermsSection(
                      icon:  Icons.check_circle_outline_rounded,
                      title: '1. Acceptance of Terms',
                      body:
                      'By downloading, installing, or using Testers, you agree to be bound by these Terms of Service. '
                          'If you do not agree to these terms, please do not use the app.\n\n'
                          'We reserve the right to update these terms at any time. Continued use of the app after changes '
                          'constitutes acceptance of the revised terms.',
                    ),
                    _TermsSection(
                      icon:  Icons.person_outline_rounded,
                      title: '2. Eligibility & Accounts',
                      body:
                      'You must be at least 13 years old to use Testers. By creating an account, you confirm that:\n\n'
                          '• All information you provide is accurate and complete.\n'
                          '• You will keep your account credentials secure.\n'
                          '• You are responsible for all activity that occurs under your account.\n'
                          '• You will notify us immediately of any unauthorised use of your account.',
                    ),
                    _TermsSection(
                      icon:  Icons.apps_rounded,
                      title: '3. App Listings & Publishing',
                      body:
                      'When publishing an app on Testers, you agree that:\n\n'
                          '• You own or have the rights to publish the app.\n'
                          '• The app does not contain malware, harmful code, or illegal content.\n'
                          '• The app information (name, package, description) is accurate.\n'
                          '• You will not attempt to manipulate tester counts or reviews.\n\n'
                          'We reserve the right to remove any listing that violates these terms without notice.',
                    ),
                    _TermsSection(
                      icon:  Icons.science_outlined,
                      title: '4. Testing Responsibilities',
                      body:
                      'As a tester on Testers, you agree to:\n\n'
                          '• Only test apps you have legitimately joined.\n'
                          '• Not attempt to reverse engineer or clone any listed app.\n'
                          '• Provide honest feedback where applicable.\n'
                          '• Not abuse the coin reward system through fraudulent testing.\n\n'
                          'Any abuse of the testing system may result in permanent account suspension.',
                    ),
                    _TermsSection(
                      icon:  Icons.monetization_on_outlined,
                      title: '5. Coins & Transactions',
                      body:
                      'Open Testers uses an in-app coin system. By participating, you acknowledge that:\n\n'
                          '• Coins have no real-world monetary value and cannot be exchanged for cash.\n'
                          '• Coins are non-transferable between accounts.\n'
                          '• We reserve the right to adjust coin balances in cases of fraud or abuse.\n'
                          '• Coin costs for publishing and featuring apps may change at any time.',
                    ),
                    _TermsSection(
                      icon:  Icons.block_outlined,
                      title: '6. Prohibited Conduct',
                      body:
                      'You agree NOT to:\n\n'
                          '• Use the app for any unlawful purpose.\n'
                          '• Attempt to gain unauthorised access to any part of the service.\n'
                          '• Upload, post, or share harmful, offensive, or misleading content.\n'
                          '• Interfere with or disrupt the integrity of the service.\n'
                          '• Create multiple accounts to exploit the coin system.\n'
                          '• Scrape or harvest data from the platform.',
                    ),
                    _TermsSection(
                      icon:  Icons.copyright_outlined,
                      title: '7. Intellectual Property',
                      body:
                      'All content, design, and code within Testers is the property of thardstudio '
                          'and is protected by applicable intellectual property laws.\n\n'
                          'App icons and names submitted by users remain the property of their respective owners. '
                          'By submitting content, you grant us a limited licence to display it within the platform.',
                    ),
                    _TermsSection(
                      icon:  Icons.warning_amber_rounded,
                      title: '8. Disclaimers & Limitation of Liability',
                      body:
                      'Open Testers is provided "as is" without warranties of any kind.\n\n'
                          'We are not responsible for:\n'
                          '• The quality, safety, or legality of listed apps.\n'
                          '• Any loss of coins or data due to technical failures.\n'
                          '• Third-party content or services linked within the app.\n\n'
                          'To the maximum extent permitted by law, our liability is limited to the amount '
                          //'you have paid us in the past 12 months, if any.',
                    ),
                    _TermsSection(
                      icon:  Icons.gavel_outlined,
                      title: '9. Termination',
                      body:
                      'We reserve the right to suspend or terminate your account at any time if you violate these terms.\n\n'
                          'You may delete your account at any time through the contact us. Upon termination, '
                          'your coin balance and listings will be permanently removed and cannot be recovered.',
                    ),
                    _TermsSection(
                      icon:  Icons.mail_outline_rounded,
                      title: '10. Contact',
                      body:
                      'For any questions about these Terms of Service, please contact us at:\n\n'
                          'info.thardstudio@gmail.com\n\n'
                          'We aim to respond to all inquiries within 5 business days.',
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
            child: Icon(Icons.description_outlined, color: cs.onSurface, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms of Service',
                  style: tt.titleLarge,
                ),
                Text(
                  'Open Testers App',
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
        border:       Border.all(color: cs.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Please read these Terms of Service carefully before using Testers. '
                  'By using the app, you agree to be bound by these terms.',
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

// ── Terms Section ─────────────────────────────────────────────────────────────

class _TermsSection extends StatelessWidget {
  const _TermsSection({
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
