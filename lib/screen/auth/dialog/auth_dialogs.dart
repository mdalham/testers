import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


import 'package:testers/utils/height_width.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart' as app;
import 'package:testers/widgets/button/custom_buttons.dart';
import 'package:testers/widgets/snackbar/custom_snackbar.dart';
import 'package:testers/widgets/test field/custom_text_formField.dart';





class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      CustomSnackbar.show(
        context,
        title: 'Email Sent',
        message: 'Reset link sent to ${_emailCtrl.text.trim()}',
        type: SnackBarType.success,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      CustomSnackbar.show(
        context,
        message: 'Failed to send reset email.',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogIcon(icon: Icons.lock_reset_rounded, color: cs.primary),
              SizedBox(height: bottomPadding),
              Text('Reset Password', style: tt.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Enter your email to receive a reset link.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onPrimary),
              ),
              SizedBox(height: bottomPadding),
              CustomTextFormField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validators: [FieldValidator.required(), FieldValidator.email()],
              ),
              SizedBox(height: bottomPadding + 10),
              Row(
                children: [
                  Expanded(
                    child: CustomOutlineBtn(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      isFullWidth: true,
                      size: BtnSize.medium,
                    ),
                  ),
                  SizedBox(width: bottomPadding),
                  Expanded(
                    child: CustomElevatedBtn(
                      label: 'Send Link',
                      isLoading: _sending,
                      isFullWidth: true,
                      size: BtnSize.medium,
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}





class SetUsernameDialog extends StatefulWidget {
  const SetUsernameDialog({super.key, required this.auth});

  
  final app.AuthProvider auth;

  @override
  State<SetUsernameDialog> createState() => _SetUsernameDialogState();
}

class _SetUsernameDialogState extends State<SetUsernameDialog> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorText = null;
    });

    final ok = await widget.auth.updateUsername(_ctrl.text.trim());
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _errorText = widget.auth.errorMessage ?? 'Failed to save username.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogIcon(icon: Icons.person_outline_rounded, color: cs.primary),
              SizedBox(height: bottomPadding),
              Text('Set Your Username', style: tt.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Choose a username so others can find you.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onPrimary),
              ),
              SizedBox(height: bottomPadding),
              CustomTextFormField(
                controller: _ctrl,
                label: 'Username',
                hint: 'e.g. john_doe',
                prefixIcon: Icons.alternate_email_rounded,
                autofocus: true,
                validators: [
                  FieldValidator.required('Username cannot be empty'),
                  FieldValidator.minLength(3, 'At least 3 characters'),
                  FieldValidator.maxLength(20, 'Max 20 characters'),
                  FieldValidator.pattern(
                    RegExp(r'^[a-zA-Z0-9_]+$'),
                    'Only letters, numbers, and underscores',
                  ),
                ],
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorText!,
                  style: tt.bodySmall?.copyWith(color: cs.error),
                ),
              ],
              SizedBox(height: bottomPadding + 10),
              CustomElevatedBtn(
                label: 'Save',
                onPressed: _saving ? null : _save,
                isLoading: _saving,
                isFullWidth: true,
                size: BtnSize.medium,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}




abstract class AuthDialogs {
  static Future<void> showForgotPassword(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ForgotPasswordDialog(),
    );
  }

  static Future<void> showSetUsername(
    BuildContext context, {
    required app.AuthProvider auth,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SetUsernameDialog(auth: auth),
    );
  }
}





class DialogIcon extends StatelessWidget {
  const DialogIcon({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 30, color: color),
  );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: color.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: color.outline)),
      ],
    );
  }
}

class AuthSectionLabel extends StatelessWidget {
  const AuthSectionLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}
