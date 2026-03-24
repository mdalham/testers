import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controllers/height_width.dart';
import '../../setting/bottom_sheet/group_join_sheet.dart';
import '../provider/publish_provider.dart';

class Step2TermsAvailability extends StatelessWidget {
  const Step2TermsAvailability({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PublishProvider>();
    final isClosedPhase = p.testingPhase == TestingPhase.closed;

    return SingleChildScrollView(
      padding: EdgeInsets.all(baseScreenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Publisher Agreement ────────────────────────────────────────────
          _SectionLabel(
            icon: Icons.gavel_rounded,
            title: 'Publisher Agreement',
          ),
          const SizedBox(height: 12),
          _AgreementCard(
            isChecked: p.agreementChecked,
            onChanged: p.setAgreementChecked,
          ),

          SizedBox(height: bottomPadding),

          // ── Required Setup ─────────────────────────────────────────────────
          _SectionLabel(icon: Icons.settings_rounded, title: 'Required Setup'),
          const SizedBox(height: 12),

          // Card 1 — BetaCircle tester (closed testing only)
          if (isClosedPhase) ...[
            _WarningBanner(),
            SizedBox(height: 10),
            _SetupCard(
              icon: Icons.person_add_alt_1_rounded,
              iconColor: Colors.tealAccent,
              title: 'Add Group as Tester',
              badge: 'Mandatory',
              badgeColor: Colors.teal,
              index: '1 of 2',
              isCompleted: p.testerStepDone,
              children: [
                _NumberedStep(
                  number: 1,
                  title: 'Join the Testers Google Group',
                  description:
                      'Open the Google Group page and join it. You only need to do this once.',
                  extra: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _JoinGroupButton(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const GroupJoiningSheet(
                          groupEmail: 'testers_community@googlegroups.com',
                          groupLink:
                              'https://groups.google.com/u/2/g/testers_community',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _NumberedStep(
                  number: 2,
                  title: 'Add the Google Group as a tester',
                  description:
                      'To let other users test your app, you need to add the BetaCircle Google Group email as tester in Google Play Console.',
                  extra: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Copy and paste it in the testers field:',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CopyEmailField(
                        email: 'testers_community@googlegroups.com',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _NumberedStep(
                  number: 3,
                  title: 'Save changes',
                  isMandatory: true,
                  description:
                      'Remember to save and publish the changes after completing the steps above.',
                ),
                const SizedBox(height: 14),
                _ConfirmCheckbox(
                  isChecked: p.testerStepDone,
                  onChanged: p.setTesterStepDone,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Card 2 — Worldwide Availability (always shown, index adapts)
          _SetupCard(
            icon: Icons.public_rounded,
            iconColor: Colors.blueAccent,
            title: 'Worldwide Availability',
            badge: 'Recommended',
            badgeColor: Colors.blueAccent,
            index: isClosedPhase ? '2 of 2' : '1 of 1',
            isCompleted: p.worldwideStepDone,
            children: [
              _NumberedStep(
                number: 1,
                title: 'Enable all countries in Play Console',
                description:
                    'Go to Release → Countries/regions and select all available countries so BetaCircle users everywhere can find your app.',
              ),
              const SizedBox(height: 14),
              _NumberedStep(
                number: 2,
                title: 'Save changes',
                isMandatory: true,
                description:
                    'Remember to save and publish the changes after completing the steps above.',
              ),
              const SizedBox(height: 14),
              _ConfirmCheckbox(
                isChecked: p.worldwideStepDone,
                onChanged: p.setWorldwideStepDone,
              ),
            ],
          ),

          SizedBox(height: bottomPadding + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Warning Banner
// ─────────────────────────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete all steps — your app won\'t be visible until you do.',
              style: tt.bodySmall?.copyWith(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Setup Card
// ─────────────────────────────────────────────────────────────────────────────

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.index,
    required this.isCompleted,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String badge;
  final Color badgeColor;
  final String index;
  final bool isCompleted;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.06)
            : cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : cs.outlineVariant.withOpacity(0.4),
          width: isCompleted ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isCompleted ? Colors.green : iconColor).withOpacity(
                      0.15,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : icon,
                    size: 22,
                    color: isCompleted ? Colors.green : iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _BadgeChip(label: badge, color: badgeColor),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    index,
                    style: tt.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: cs.outlineVariant.withOpacity(0.3),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Numbered Step
// ─────────────────────────────────────────────────────────────────────────────

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({
    required this.number,
    required this.title,
    required this.description,
    this.isMandatory = false,
    this.extra,
  });

  final int number;
  final String title;
  final String description;
  final bool isMandatory;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isMandatory) ...[
                    const SizedBox(width: 8),
                    _BadgeChip(label: 'Important', color: Colors.orange),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              if (extra != null) extra!,
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Copy Email Field
// ─────────────────────────────────────────────────────────────────────────────

class _CopyEmailField extends StatefulWidget {
  const _CopyEmailField({required this.email});
  final String email;

  @override
  State<_CopyEmailField> createState() => _CopyEmailFieldState();
}

class _CopyEmailFieldState extends State<_CopyEmailField> {
  bool _copied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.email));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _copy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _copied
              ? Colors.green.withOpacity(0.08)
              : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _copied
                ? Colors.green.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                key: ValueKey(_copied),
                size: 16,
                color: _copied ? Colors.green : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.email,
                style: tt.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: _copied ? Colors.green : cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_copied)
              Text(
                'Copied!',
                style: tt.labelSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Confirm Checkbox
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmCheckbox extends StatelessWidget {
  const _ConfirmCheckbox({required this.isChecked, required this.onChanged});
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!isChecked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isChecked
              ? Colors.green.withOpacity(0.1)
              : cs.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked
                ? Colors.green.withOpacity(0.6)
                : cs.outlineVariant.withOpacity(0.4),
            width: isChecked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isChecked ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? Colors.green : cs.outline,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'I\'ve completed all the steps above, before uploading the app',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isChecked ? Colors.green : cs.onSurface,
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
//  Join Group Button
// ─────────────────────────────────────────────────────────────────────────────

class _JoinGroupButton extends StatelessWidget {
  const _JoinGroupButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_add_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Join Google Group',
              style: tt.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Badge Chip
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Agreement Card
// ─────────────────────────────────────────────────────────────────────────────

class _AgreementCard extends StatelessWidget {
  const _AgreementCard({required this.isChecked, required this.onChanged});
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChecked
            ? Colors.green.withOpacity(0.06)
            : cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked
              ? Colors.green.withOpacity(0.5)
              : cs.outlineVariant.withOpacity(0.5),
          width: isChecked ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TermItem(
            icon: Icons.verified_user_outlined,
            text: 'I own this app and have the rights to publish it.',
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 10),
          _TermItem(
            icon: Icons.block_rounded,
            text:
                'This app does not contain illegal, harmful, or prohibited content.',
            color: Colors.redAccent,
          ),
          const SizedBox(height: 10),
          _TermItem(
            icon: Icons.security_rounded,
            text:
                'I agree to comply with the platform\'s publisher guidelines.',
            color: Colors.purpleAccent,
          ),
          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(!isChecked),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isChecked ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked ? Colors.green : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I confirm all of the above statements.',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isChecked ? Colors.green : cs.onSurface,
                    ),
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

class _TermItem extends StatelessWidget {
  const _TermItem({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
