import 'package:flutter/material.dart';

import '../../controllers/height_width.dart';

class AnimatedExpandableCard extends StatefulWidget {
  const AnimatedExpandableCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor,
    this.accentColor,
    this.collapsedTrailing = const [],
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 320),
    this.onExpansionChanged,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Color? iconColor;
  final Color? accentColor;
  final List<Widget> collapsedTrailing;
  final bool initiallyExpanded;
  final Duration animationDuration;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<AnimatedExpandableCard> createState() => _AnimatedExpandableCardState();
}

class _AnimatedExpandableCardState extends State<AnimatedExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;
  late Animation<double> _chevronAnim;
  late Animation<double> _borderAnim;
  late Animation<double> _fadeAnim;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _ctrl = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: _isExpanded ? 1.0 : 0.0,
    );

    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);

    _chevronAnim = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));

    _borderAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = widget.accentColor ?? widget.iconColor ?? cs.primary;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final borderColor = Color.lerp(cs.outline, accent, _borderAnim.value)!;
        return Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(baseBorderRadius),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(baseBorderRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, cs, tt, accent),
                _buildBody(cs, accent),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Color accent,
  ) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(15),
      splashColor: accent.withOpacity(0.08),
      child: Padding(
        padding: const .all(10),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _borderAnim,
              builder: (_, __) => Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    // Add '?? Colors.transparent' or a default color here
                    color:
                        Color.lerp(cs.outline, accent, _borderAnim.value) ??
                        cs.outline,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  // Add '?? cs.onSurface' here
                  color:
                      Color.lerp(cs.onSurface, accent, _borderAnim.value) ??
                      cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _borderAnim,
              builder: (_, __) => Text(
                widget.title,
                style: tt.titleMedium?.copyWith(
                  color: Color.lerp(cs.primary, accent, _borderAnim.value),
                ),
              ),
            ),
            const Spacer(),
            // Collapsed trailing chips — fade out when expanding
            if (widget.collapsedTrailing.isNotEmpty)
              FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: _ctrl,
                    curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...widget.collapsedTrailing
                        .expand((w) => [w, const SizedBox(width: 6)])
                        .toList()
                      ..removeLast(),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            // Chevron
            RotationTransition(
              turns: _chevronAnim,
              child: AnimatedBuilder(
                animation: _borderAnim,
                builder: (_, __) => Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color.lerp(cs.onSurface, accent, _borderAnim.value),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, Color accent) {
    return SizeTransition(
      sizeFactor: _expandAnim,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color:
                  Color.lerp(cs.outline, accent, _borderAnim.value) ??
                  cs.outline,
            ),
            ...widget.children,
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CardInfoRow  —  label on left, value / trailing widget on right
// ══════════════════════════════════════════════════════════════════════════════
class CardInfoRow extends StatelessWidget {
  const CardInfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueColor,
    this.trailing,
    this.showDivider = true,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: tt.bodyMedium
              ),
              if (trailing != null)
                trailing!
              else if (value != null)
                Text(
                  value!,
                  style: tt.bodyMedium?.copyWith(
                    color: valueColor ?? cs.primary,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12,
            color: cs.outline,
          ),
      ],
    );
  }
}

//  CardChip  —  small pill badge used in headers and rows
class CardChip extends StatelessWidget {
  const CardChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chipColor = color ?? Colors.orange;
    final chipBg = backgroundColor ?? chipColor.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


//  CardActionRow  —  centered tappable link row at the bottom of a card
class CardActionRow extends StatelessWidget {
  const CardActionRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final linkColor = color ?? cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: linkColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: linkColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
