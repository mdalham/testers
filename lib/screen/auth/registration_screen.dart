import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/utils/height_width.dart';
import 'package:testers/constants/icons.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/theme/colors.dart';
import 'package:testers/widgets/button/custom_buttons.dart';
import 'package:testers/widgets/snackbar/custom_snackbar.dart';
import 'package:testers/widgets/test field/custom_text_formField.dart';
import 'package:testers/screen/discovery/discovery.dart';

import '../settings/privacy_policy_sheet.dart';
import '../settings/terms_of_service_sheet.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController(); 
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _agreedToTerms = false;
  bool _termsError = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _fullNameCtrl.dispose(); 
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _openTerms() {
    
  }

  void _openPrivacy() {
    
  }

  
  Future<void> _register() async {
    final formValid = _formKey.currentState!.validate();

    if (!_agreedToTerms) {
      
      setState(() => _termsError = true);
      CustomSnackbar.show(
        context,
        title: 'Terms Required',
        message:
            'You must agree to the Terms & Conditions and Privacy Policy to continue.',
        type: SnackBarType.error,
      );
    }

    if (!formValid || !_agreedToTerms) return;

    final auth = context.read<AuthProvider>();

    
    auth.setErrorCallback((title, message) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: title,
        message: message,
        type: SnackBarType.error,
      );
    });

    final success = await auth.registerWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      username: _usernameCtrl.text.trim(),
      displayName: _fullNameCtrl.text.trim(),
    );

    if (!mounted) return;
    auth.clearErrorCallback();

    if (success) {
      CustomSnackbar.show(
        context,
        title: 'Account Created!',
        message: 'Welcome aboard! Your account is ready.',
        type: SnackBarType.success,
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Discovery()),
        (_) => false,
      );
    }
  }

  
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(baseScreenPadding),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        Center(
                          child: Image.asset(appIcon, width: 50, height: 50),
                        ),
                        SizedBox(height: bottomPadding),

                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: tt.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill in the details below to get started',
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(color: cs.onPrimary),
                        ),

                        SizedBox(height: bottomPadding),

                        
                        CustomTextFormField(
                          label: 'Full Name',
                          hint: 'John Doe',
                          controller: _fullNameCtrl,
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validators: [
                            FieldValidator.required('Full name is required'),
                            FieldValidator.minLength(
                              2,
                              'At least 2 characters',
                            ),
                            FieldValidator.maxLength(50, 'Max 50 characters'),
                          ],
                        ),
                        SizedBox(height: bottomPadding),

                        
                        CustomTextFormField(
                          label: 'Username',
                          hint: 'john_doe',
                          controller: _usernameCtrl,
                          prefixIcon: Icons.alternate_email_rounded,
                          textInputAction: TextInputAction.next,
                          validators: [
                            FieldValidator.required('Username is required'),
                            FieldValidator.minLength(
                              3,
                              'At least 3 characters',
                            ),
                            FieldValidator.maxLength(20, 'Max 20 characters'),
                            FieldValidator.pattern(
                              RegExp(r'^[a-zA-Z0-9_]+$'),
                              'Only letters, numbers, and underscores',
                            ),
                          ],
                        ),
                        SizedBox(height: bottomPadding),

                        
                        CustomTextFormField(
                          label: 'Email',
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validators: [
                            FieldValidator.required('Email is required'),
                            FieldValidator.email(),
                          ],
                        ),
                        SizedBox(height: bottomPadding),

                        
                        CustomTextFormField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passCtrl,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          validators: [
                            FieldValidator.required('Password is required'),
                            FieldValidator.minLength(
                              8,
                              'At least 8 characters',
                            ),
                            FieldValidator.custom((v) {
                              if (v == null || v.isEmpty) return null;
                              if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) {
                                return 'Must contain an uppercase letter';
                              }
                              if (!RegExp(r'(?=.*[a-z])').hasMatch(v)) {
                                return 'Must contain a lowercase letter';
                              }
                              if (!RegExp(r'(?=.*\d)').hasMatch(v)) {
                                return 'Must contain a number';
                              }
                              return null;
                            }),
                          ],
                        ),
                        SizedBox(height: bottomPadding),

                        
                        CustomTextFormField(
                          label: 'Confirm Password',
                          hint: '••••••••',
                          controller: _confirmCtrl,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validators: [
                            FieldValidator.required(
                              'Please confirm your password',
                            ),
                            FieldValidator.custom((v) {
                              if (v != _passCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            }),
                          ],
                        ),
                        SizedBox(height: bottomPadding),

                        
                        _TermsCheckbox(
                          value: _agreedToTerms,
                          hasError: _termsError,
                          onChanged: (v) => setState(() {
                            _agreedToTerms = v ?? false;
                            if (_agreedToTerms) _termsError = false;
                          }),
                          onTermsTap: _openTerms,
                          onPrivacyTap: _openPrivacy,
                        ),

                        SizedBox(height: bottomPadding + 10),

                        
                        CustomElevatedBtn(
                          label: 'Create Account',
                          onPressed: isLoading ? null : _register,
                          isFullWidth: true,
                          isLoading: isLoading,
                          size: BtnSize.large,
                          borderRadius: textFromFieldBorderRadius,
                          suffixIcon: Icons.arrow_forward_rounded,
                        ),

                        SizedBox(height: bottomPadding + 10),

                        
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onPrimary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Sign In',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.hasError,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final bool hasError;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = hasError ? cs.error : (isDark ? subFontDark : subFontLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: green,
              checkColor: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              side: BorderSide(
                color: hasError ? cs.error : cs.outline,
                width: 1.5,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: tt.bodySmall?.copyWith(color: color),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: cs.primary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => TermsOfServiceSheet.show(context),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: cs.primary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => PrivacyPolicySheet.show(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
