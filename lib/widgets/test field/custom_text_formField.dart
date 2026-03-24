import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:testers/utils/height_width.dart';
import 'package:testers/theme/colors.dart';





enum ValidateMode { onSubmit, onChange }




class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,

    
    this.label,
    this.hint,
    this.helperText,
    this.initialValue,
    this.controller,

    
    this.validate = true,
    this.validators = const [],
    this.validateMode = ValidateMode.onSubmit,

    
    this.prefixIcon,
    this.suffixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.prefixText,
    this.filled,
    this.fillColor,

    
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.focusNode,
    this.textAlign = TextAlign.start,

    
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onSaved,
  });

  
  final String? label;
  final String? hint;
  final String? helperText;
  final String? initialValue;
  final TextEditingController? controller;

  
  final bool validate;
  final List<FieldValidator> validators;
  final ValidateMode validateMode;

  
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final String? prefixText;
  final bool? filled;
  final Color? fillColor;

  
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final GestureTapCallback? onTap;
  final FormFieldSetter<String>? onSaved;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  
  String? _runValidators(String? value) {
    if (!widget.validate) return null;
    for (final v in widget.validators) {
      final err = v.call(value);
      if (err != null) return err;
    }
    return null;
  }

  
  Widget? _buildSuffix({required ColorScheme cs, required bool isDark}) {
    if (widget.suffixWidget != null) return widget.suffixWidget;

    
    if (widget.obscureText) {
      return GestureDetector(
        onTap: () => setState(() => _obscure = !_obscure),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: isDark ? cs.onSurfaceVariant : cs.onSurfaceVariant,
          ),
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(widget.suffixIcon, size: 20, color: cs.onSurfaceVariant),
      );
    }

    return null;
  }

  
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color resolvedFill =
        widget.fillColor ??
        (isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest);

    final Color borderColor = cs.outline;
    final Color focusColor = blue;
    final Color iconColor = cs.onSurface;
    final Color labelColor = cs.onSurfaceVariant;
    final Color textColor = cs.onSurface;

    OutlineInputBorder border(Color color, {double width = 1.5}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(textFromFieldBorderRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      
      controller: widget.controller,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,

      
      style: tt.titleSmall,
      cursorColor: focusColor.withOpacity(.5),

      
      validator: _runValidators,
      autovalidateMode: widget.validateMode == ValidateMode.onChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,

      
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onSaved: widget.onSaved,

      
      decoration: InputDecoration(
        
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,

        labelStyle: tt.bodyMedium,
        floatingLabelStyle: tt.bodySmall,
        hintStyle: tt.bodyMedium,
        helperStyle: tt.labelSmall?.copyWith(color: labelColor),
        errorStyle: tt.labelSmall?.copyWith(color: cs.error, height: 1.4),

        
        filled: widget.filled ?? true,
        fillColor: cs.primaryContainer,

        
        counterText: '',

        
        prefixIcon:
            widget.prefixWidget ??
            (widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(widget.prefixIcon, size: 20, color: iconColor),
                  )
                : null),
        prefixText: widget.prefixText,
        prefixStyle: tt.bodyLarge?.copyWith(color: textColor),

        
        suffixIcon: _buildSuffix(cs: cs, isDark: isDark),

        
        border: border(borderColor),

        enabledBorder: border(borderColor),

        focusedBorder: border(focusColor, width: 2),

        errorBorder: border(cs.error),

        focusedErrorBorder: border(cs.error, width: 2),

        disabledBorder: border(cs.outlineVariant.withOpacity(0.4)),

        
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        isDense: true,
      ),
    );
  }
}




class FieldValidator {
  const FieldValidator._(this._fn);

  final String? Function(String? value) _fn;

  String? call(String? value) => _fn(value);

  
  factory FieldValidator.required([String? message]) => FieldValidator._(
    (v) => (v == null || v.trim().isEmpty)
        ? (message ?? 'This field is required')
        : null,
  );

  
  factory FieldValidator.email([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());
    return ok ? null : (message ?? 'Enter a valid email address');
  });

  
  factory FieldValidator.url([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^https?://[^\s/$.?#].[^\s]*$').hasMatch(v.trim());
    return ok ? null : (message ?? 'Enter a valid URL');
  });

  
  factory FieldValidator.minLength(int min, [String? message]) =>
      FieldValidator._(
        (v) => (v != null && v.length >= min)
            ? null
            : (message ?? 'Minimum $min characters required'),
      );

  
  factory FieldValidator.maxLength(int max, [String? message]) =>
      FieldValidator._(
        (v) => (v == null || v.length <= max)
            ? null
            : (message ?? 'Maximum $max characters allowed'),
      );

  
  factory FieldValidator.numeric([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    return RegExp(r'^\d+$').hasMatch(v)
        ? null
        : (message ?? 'Only numbers are allowed');
  });

  
  factory FieldValidator.phone([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^\+?\d{7,15}$').hasMatch(v.replaceAll(' ', ''));
    return ok ? null : (message ?? 'Enter a valid phone number');
  });

  
  factory FieldValidator.minValue(num min, [String? message]) =>
      FieldValidator._((v) {
        if (v == null || v.trim().isEmpty) return null;
        final n = num.tryParse(v);
        if (n == null) return 'Enter a valid number';
        return n >= min ? null : (message ?? 'Minimum value is $min');
      });

  
  factory FieldValidator.maxValue(num max, [String? message]) =>
      FieldValidator._((v) {
        if (v == null || v.trim().isEmpty) return null;
        final n = num.tryParse(v);
        if (n == null) return 'Enter a valid number';
        return n <= max ? null : (message ?? 'Maximum value is $max');
      });

  
  factory FieldValidator.pattern(RegExp regex, [String? message]) =>
      FieldValidator._((v) {
        if (v == null || v.trim().isEmpty) return null;
        return regex.hasMatch(v) ? null : (message ?? 'Invalid format');
      });

  
  factory FieldValidator.custom(String? Function(String? value) fn) =>
      FieldValidator._(fn);
}
