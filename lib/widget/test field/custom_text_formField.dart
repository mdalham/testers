import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/height_width.dart';
import '../../theme/colors.dart';

// ─────────────────────────────────────────────
//  ValidateMode
// ─────────────────────────────────────────────
/// Controls when the field validates its input.
enum ValidateMode { onSubmit, onChange }

// ─────────────────────────────────────────────
//  CustomTextFormField
// ─────────────────────────────────────────────
class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,

    // ── Content ──────────────────────────────
    this.label,
    this.hint,
    this.helperText,
    this.initialValue,
    this.controller,

    // ── Validation ───────────────────────────
    this.validate = true,
    this.validators = const [],
    this.validateMode = ValidateMode.onSubmit,

    // ── Appearance ───────────────────────────
    this.prefixIcon,
    this.suffixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.prefixText,
    this.filled,
    this.fillColor,

    // ── Behaviour ────────────────────────────
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

    // ── Callbacks ────────────────────────────
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onSaved,
  });

  // ── Content ────────────────────────────────
  final String? label;
  final String? hint;
  final String? helperText;
  final String? initialValue;
  final TextEditingController? controller;

  // ── Validation ─────────────────────────────
  final bool validate;
  final List<FieldValidator> validators;
  final ValidateMode validateMode;

  // ── Appearance ─────────────────────────────
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final String? prefixText;
  final bool? filled;
  final Color? fillColor;

  // ── Behaviour ──────────────────────────────
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

  // ── Callbacks ──────────────────────────────
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

  // ── Run validators in sequence ─────────────
  String? _runValidators(String? value) {
    if (!widget.validate) return null;
    for (final v in widget.validators) {
      final err = v.call(value);
      if (err != null) return err;
    }
    return null;
  }

  // ── Suffix widget ──────────────────────────
  Widget? _buildSuffix({required ColorScheme cs, required bool isDark}) {
    if (widget.suffixWidget != null) return widget.suffixWidget;

    // Password eye toggle
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

  // ── Build ──────────────────────────────────
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
      // ── Core ────────────────────────────────────────────────────────────
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

      // ── Style ───────────────────────────────────────────────────────────
      style: tt.titleSmall,
      cursorColor: focusColor.withOpacity(.5),

      // ── Validation ──────────────────────────────────────────────────────
      validator: _runValidators,
      autovalidateMode: widget.validateMode == ValidateMode.onChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,

      // ── Callbacks ───────────────────────────────────────────────────────
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onSaved: widget.onSaved,

      // ── Decoration ──────────────────────────────────────────────────────
      decoration: InputDecoration(
        // Labels
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,

        labelStyle: tt.bodyMedium,
        floatingLabelStyle: tt.bodySmall,
        hintStyle: tt.bodyMedium,
        helperStyle: tt.labelSmall?.copyWith(color: labelColor),
        errorStyle: tt.labelSmall?.copyWith(color: cs.error, height: 1.4),

        // Fill
        filled: widget.filled ?? true,
        fillColor: cs.primaryContainer,

        // Hide counter
        counterText: '',

        // Prefix
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

        // Suffix
        suffixIcon: _buildSuffix(cs: cs, isDark: isDark),

        // ── Borders ───────────────────────────────────────────────────────
        border: border(borderColor),

        enabledBorder: border(borderColor),

        focusedBorder: border(focusColor, width: 2),

        errorBorder: border(cs.error),

        focusedErrorBorder: border(cs.error, width: 2),

        disabledBorder: border(cs.outlineVariant.withOpacity(0.4)),

        // Content padding — matches demo screen spacing
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        isDense: true,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FieldValidator
// ══════════════════════════════════════════════════════════════════════════════
class FieldValidator {
  const FieldValidator._(this._fn);

  final String? Function(String? value) _fn;

  String? call(String? value) => _fn(value);

  /// Field must not be empty.
  factory FieldValidator.required([String? message]) => FieldValidator._(
    (v) => (v == null || v.trim().isEmpty)
        ? (message ?? 'This field is required')
        : null,
  );

  /// Value must be a valid email address.
  factory FieldValidator.email([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());
    return ok ? null : (message ?? 'Enter a valid email address');
  });

  /// Value must be a valid URL (http / https).
  factory FieldValidator.url([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^https?://[^\s/$.?#].[^\s]*$').hasMatch(v.trim());
    return ok ? null : (message ?? 'Enter a valid URL');
  });

  /// Value length must be at least [min] characters.
  factory FieldValidator.minLength(int min, [String? message]) =>
      FieldValidator._(
        (v) => (v != null && v.length >= min)
            ? null
            : (message ?? 'Minimum $min characters required'),
      );

  /// Value length must not exceed [max] characters.
  factory FieldValidator.maxLength(int max, [String? message]) =>
      FieldValidator._(
        (v) => (v == null || v.length <= max)
            ? null
            : (message ?? 'Maximum $max characters allowed'),
      );

  /// Value must contain only digits.
  factory FieldValidator.numeric([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    return RegExp(r'^\d+$').hasMatch(v)
        ? null
        : (message ?? 'Only numbers are allowed');
  });

  /// Value must match a phone number pattern (7–15 digits, optional +).
  factory FieldValidator.phone([String? message]) => FieldValidator._((v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^\+?\d{7,15}$').hasMatch(v.replaceAll(' ', ''));
    return ok ? null : (message ?? 'Enter a valid phone number');
  });

  /// Value must be at least [min] when parsed as a number.
  factory FieldValidator.minValue(num min, [String? message]) =>
      FieldValidator._((v) {
        if (v == null || v.trim().isEmpty) return null;
        final n = num.tryParse(v);
        if (n == null) return 'Enter a valid number';
        return n >= min ? null : (message ?? 'Minimum value is $min');
      });

  /// Value must not exceed [max] when parsed as a number.
  factory FieldValidator.maxValue(num max, [String? message]) =>
      FieldValidator._((v) {
        if (v == null || v.trim().isEmpty) return null;
        final n = num.tryParse(v);
        if (n == null) return 'Enter a valid number';
        return n <= max ? null : (message ?? 'Maximum value is $max');
      });

  /// Value must match a custom [RegExp] pattern.
  factory FieldValidator.pattern(RegExp regex, [String? message]) =>
      FieldValidator._((v) {
        if (v == null || v.trim().isEmpty) return null;
        return regex.hasMatch(v) ? null : (message ?? 'Invalid format');
      });

  /// Fully custom rule — pass any function that returns an error or null.
  factory FieldValidator.custom(String? Function(String? value) fn) =>
      FieldValidator._(fn);
}
