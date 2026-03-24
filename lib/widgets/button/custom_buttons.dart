import 'package:flutter/material.dart';
import 'package:testers/theme/colors.dart';


enum BtnSize { small, medium, large }

extension _BtnSizeX on BtnSize {
  EdgeInsets get padding => switch (this) {
    BtnSize.small  => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    BtnSize.medium => const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    BtnSize.large  => const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  };

  double get fontSize => switch (this) {
    BtnSize.small  => 13,
    BtnSize.medium => 15,
    BtnSize.large  => 16,
  };

  double get iconSize => switch (this) {
    BtnSize.small  => 16,
    BtnSize.medium => 18,
    BtnSize.large  => 20,
  };

  double get loaderSize => switch (this) {
    BtnSize.small  => 14,
    BtnSize.medium => 18,
    BtnSize.large  => 20,
  };
}





class CustomElevatedBtn extends StatelessWidget {
  const CustomElevatedBtn({
    super.key,
    required this.label,
    required this.onPressed,

    
    this.size            = BtnSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius    = 8,
    this.isFullWidth     = false,
    this.elevation       = 0,

    
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,

    
    this.enabled = true,

    
    this.padding,
  });

  final String           label;
  final VoidCallback?    onPressed;

  final BtnSize          size;
  final Color?           backgroundColor;
  final Color?           foregroundColor;
  final double           borderRadius;
  final bool             isFullWidth;
  final double           elevation;

  final IconData?        prefixIcon;
  final IconData?        suffixIcon;
  final bool             isLoading;

  final bool             enabled;

  
  final EdgeInsetsGeometry? padding;

  bool get _isDisabled => !enabled || isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bgColor        = backgroundColor ?? blue;
    final fgColor        = foregroundColor ?? Colors.white;
    final effectivePad   = padding ?? size.padding;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: _isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:         bgColor,
          foregroundColor:         fgColor,
          disabledBackgroundColor: bgColor.withOpacity(0.2),
          disabledForegroundColor: cs.onPrimary.withOpacity(0.4),
          elevation:               elevation,
          shadowColor:             bgColor.withOpacity(0.3),
          padding:                 effectivePad,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          overlayColor: Colors.white.withOpacity(0.12),
        ),
        child: _buildChild(tt, fgColor),
      ),
    );
  }

  Widget _buildChild(TextTheme tt, Color fgColor) {
    if (isLoading) {
      return SizedBox(
        width:  size.loaderSize,
        height: size.loaderSize,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: fgColor),
      );
    }

    return Row(
      mainAxisSize:      MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: size.iconSize, color: fgColor),
          const SizedBox(width: 8),
        ],
        Text(label, style: tt.titleMedium!.copyWith(color: Colors.white)),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: size.iconSize, color: fgColor),
        ],
      ],
    );
  }
}





class CustomOutlineBtn extends StatelessWidget {
  const CustomOutlineBtn({
    super.key,
    required this.label,
    required this.onPressed,

    
    this.size             = BtnSize.medium,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth      = 1.5,
    this.borderRadius     = 8,
    this.isFullWidth      = false,
    this.backgroundColor  = Colors.transparent,

    
    this.prefixIcon,
    this.suffixIcon,
    this.suffixAssentIcon,
    this.isLoading = false,

    
    this.enabled = true,

    
    this.padding,
  });

  final String           label;
  final VoidCallback?    onPressed;

  final BtnSize          size;
  final Color?           foregroundColor;
  final Color?           borderColor;
  final double           borderWidth;
  final double           borderRadius;
  final bool             isFullWidth;
  final Color            backgroundColor;

  final IconData?        prefixIcon;
  final IconData?        suffixIcon;
  final String?          suffixAssentIcon;
  final bool             isLoading;

  final bool             enabled;

  
  final EdgeInsetsGeometry? padding;

  bool get _isDisabled => !enabled || isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final tt           = Theme.of(context).textTheme;
    final fgColor      = foregroundColor ?? cs.primary;
    final strokeColor  = borderColor     ?? cs.outline;
    final effectivePad = padding         ?? size.padding;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: _isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:         fgColor,
          backgroundColor:         backgroundColor,
          disabledForegroundColor: cs.onPrimary.withOpacity(0.2),
          padding:                 effectivePad,
          side: BorderSide(
            color: _isDisabled
                ? cs.outlineVariant.withOpacity(0.4)
                : strokeColor,
            width: borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          overlayColor: fgColor.withOpacity(0.08),
        ),
        child: _buildChild(tt, fgColor, cs),
      ),
    );
  }

  Widget _buildChild(TextTheme tt, Color fgColor, ColorScheme cs) {
    if (isLoading) {
      return SizedBox(
        width:  size.loaderSize,
        height: size.loaderSize,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: fgColor),
      );
    }

    return Row(
      mainAxisSize:      MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: size.iconSize, color: cs.onSurface),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: tt.titleMedium!.copyWith(
              color: cs.primary.withOpacity(0.6)),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: size.iconSize, color: cs.onSurface),
        ],
      ],
    );
  }
}