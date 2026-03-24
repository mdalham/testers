import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/height_width.dart';
import '../../../theme/colors.dart';
import '../../../widget/test field/custom_text_formField.dart';
import '../provider/publish_provider.dart';

/// Step 1 — App Setup
class Step1AppSetup extends StatefulWidget {
  const Step1AppSetup({super.key});

  @override
  State<Step1AppSetup> createState() => _Step1AppSetupState();
}

class _Step1AppSetupState extends State<Step1AppSetup> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<PublishProvider>();
    _usernameCtrl = TextEditingController(text: p.loginUsername);
    _passwordCtrl = TextEditingController(text: p.loginPassword);

    _usernameCtrl.addListener(
          () => context.read<PublishProvider>().setLoginUsername(_usernameCtrl.text),
    );
    _passwordCtrl.addListener(
          () => context.read<PublishProvider>().setLoginPassword(_passwordCtrl.text),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

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
          _SectionHeader(
            title:    'Testing Phase',
            infoText: 'Choose how your app will be distributed to testers.',
          ),
          SizedBox(height: bottomPadding),

          ...TestingPhase.values.map((phase) => _RadioOptionTile<TestingPhase>(
            value:      phase,
            groupValue: p.testingPhase,
            label:      phase.label,
            subtitle:   phase.description,
            onChanged:  (v) => p.setTestingPhase(v!),
            icon: switch (phase) {
              TestingPhase.closed     => Icons.lock_outline_rounded,
              TestingPhase.open       => Icons.public_rounded,
              TestingPhase.production => Icons.rocket_launch_rounded,
            },
          )),

          if (p.testingPhase == TestingPhase.closed) ...[
            const SizedBox(height: 8),
            _InfoBanner(
              icon:  Icons.info_outline_rounded,
              color: Colors.orangeAccent,
              text:  'Testers may need to join a testing group before they can access your app.',
            ),
          ],


          // ── App Type ───────────────────────────────────────────────────
          SizedBox(height: bottomPadding),
          _SectionHeader(
            title:    'App Type',
            infoText: 'Is this an app or a game?',
          ),
          SizedBox(height: bottomPadding),

          Row(
            children: AppTypeOption.values.map((t) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: t == AppTypeOption.app ? 8 : 0),
                child: _SelectChip(
                  label:      t.label,
                  icon:       t == AppTypeOption.app
                      ? Icons.grid_view_rounded
                      : Icons.sports_esports_rounded,
                  isSelected: p.appType == t,
                  onTap:      () => p.setAppType(t),
                ),
              ),
            )).toList(),
          ),

          // ── Price Type ─────────────────────────────────────────────────
          SizedBox(height: bottomPadding),
          _SectionHeader(
            title:    'Price Type',
            infoText: 'How will users obtain your app?',
          ),
          SizedBox(height: bottomPadding),

          Row(
            children: PriceTypeOption.values.map((pt) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: pt == PriceTypeOption.free ? 8 : 0),
                child: _SelectChip(
                  label:      pt.label,
                  icon:       pt == PriceTypeOption.free
                      ? Icons.money_off_rounded
                      : Icons.attach_money_rounded,
                  isSelected: p.priceType == pt,
                  onTap:      () => p.setPriceType(pt),
                ),
              ),
            )).toList(),
          ),

          // ── Special Login ──────────────────────────────────────────────
          SizedBox(height: bottomPadding),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize:       MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Special Login',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    _InfoIcon(
                      infoText: 'Provide test account credentials if your app '
                          'requires login to access features.',
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value:       p.specialLoginEnabled,
                onChanged:   p.setSpecialLoginEnabled,
                activeColor: blue,
              ),
            ],
          ),

          if (!p.specialLoginEnabled) ...[
            const SizedBox(height: 6),
            Text(
              'Enable if your app requires login to access features.',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],

          if (p.specialLoginEnabled) ...[
            const SizedBox(height: 16),
            CustomTextFormField(
              controller:      _usernameCtrl,
              label:           'Username / Email / ID',
              hint:            'Enter test account username or email',
              prefixIcon:      Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: bottomPadding),
            CustomTextFormField(
              controller:      _passwordCtrl,
              label:           'Password / Security Key',
              hint:            'Enter test account password',
              prefixIcon:      Icons.key_rounded,
              obscureText:     true,
              textInputAction: TextInputAction.done,
            ),
          ],

          SizedBox(height: bottomPadding + 8),
        ],
      ),
    );
  }
}


class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.infoText});
  final String infoText;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message:      infoText,
      triggerMode:  TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      padding:      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: .symmetric(horizontal: 10),
      decoration:   BoxDecoration(
        color:        cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: tt.bodySmall?.copyWith(
          color: cs.primary, height: 1.4),
      child: Icon(Icons.help_outline_rounded,
          size: 16, color: cs.onSurface),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.infoText});
  final String  title;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize:       MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (infoText != null) ...[
          const SizedBox(width: 4),
          _InfoIcon(infoText: infoText!),
        ],
      ],
    );
  }
}

class _RadioOptionTile<T> extends StatelessWidget {
  const _RadioOptionTile({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.subtitle,
    required this.onChanged,
    required this.icon,
  });

  final T                value;
  final T                groupValue;
  final String           label, subtitle;
  final ValueChanged<T?> onChanged;
  final IconData         icon;

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;
    final selected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:  const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? blue.withOpacity(0.55) : cs.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: tt.titleSmall
                  ),
                  Text(subtitle,
                      style: tt.labelSmall?.copyWith(color: cs.onPrimary)),
                ],
              ),
            ),
            Radio<T>(
              value:                 value,
              groupValue:            groupValue,
              onChanged:             onChanged,
              activeColor:           blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  final IconData?    icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? blue.withOpacity(0.55) : cs.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16,
                  color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cs.primary : cs.onSurface,
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color    color;
  final String   text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: tt.labelSmall
                    ?.copyWith(color: color.withOpacity(0.9), height: 1.4)),
          ),
        ],
      ),
    );
  }
}