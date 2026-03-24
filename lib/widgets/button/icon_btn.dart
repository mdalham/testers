import 'package:flutter/material.dart';

class IconBtn extends StatelessWidget {
  const IconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.size = 42,
    this.iconSize = 18,
    this.borderRadius = 12,
    this.borderWidth = 1.3,
    this.padding = const EdgeInsets.all(6),
    this.tooltip,
    this.isLoading = false,
  });

  final IconData     icon;
  final VoidCallback onTap;
  final Color?       color;
  final double       size;
  final double       iconSize;
  final double       borderRadius;
  final double       borderWidth;
  final EdgeInsets   padding;
  final String?      tooltip;
  final bool         isLoading;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final tint   = color ?? cs.primary;
    final radius = BorderRadius.circular(borderRadius);

    final child = Material(
      color:        Colors.transparent,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          color:        tint.withOpacity(0.06),
          borderRadius: radius,
          border: Border.all(
            color: isLoading
                ? tint.withOpacity(0.25)
                : tint.withOpacity(0.45),
            width: borderWidth,
          ),
        ),
        child: InkWell(
          onTap:          isLoading ? null : onTap,
          borderRadius:   radius,
          splashColor:    tint.withOpacity(0.12),
          highlightColor: tint.withOpacity(0.08),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:  size,
              minHeight: size,
            ),
            child: Padding(
              padding: padding,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                    key:    const ValueKey('loader'),
                    width:  iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       tint.withOpacity(0.7),
                    ),
                  )
                      : Icon(
                    icon,
                    key:   const ValueKey('icon'),
                    size:  iconSize,
                    color: tint,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && !isLoading) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}