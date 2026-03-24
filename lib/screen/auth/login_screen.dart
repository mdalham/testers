import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/widgets/internet/internet_banner.dart';
import 'package:testers/utils/height_width.dart';
import 'package:testers/constants/icons.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/theme/colors.dart';
import 'package:testers/widgets/button/custom_buttons.dart';
import 'package:testers/widgets/snackbar/custom_snackbar.dart';
import 'package:testers/widgets/test field/custom_text_formField.dart';
import 'package:testers/screen/discovery/discovery.dart';
import 'package:testers/screen/auth/dialog/auth_dialogs.dart';
import 'package:testers/screen/auth/registration_screen.dart';

import '../settings/privacy_policy_sheet.dart';
import '../settings/terms_of_service_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _navigating = false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    try {
      context.read<AuthProvider>().removeListener(_onAuthStateChanged);
    } catch (_) {}
    _animCtrl.dispose();
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && mounted && !_navigating) {
      _navigating = true;
      auth.removeListener(_onAuthStateChanged);
      _handlePostLogin(auth);
    }
  }

  Future<void> _handlePostLogin(AuthProvider auth) async {
    if (!mounted) return;

    if (auth.username.trim().isEmpty) {
      await AuthDialogs.showSetUsername(context, auth: auth);
    }
    if (!mounted) return;

    final name = auth.username.trim().isNotEmpty
        ? auth.username.trim()
        : auth.displayName.trim().isNotEmpty
        ? auth.displayName.trim()
        : 'there';

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => Discovery(welcomeName: name)),
          (_) => false,
    );
  }

  bool _checkTerms() {
    if (!_agreedToTerms) {
      setState(() => _termsError = true);
      CustomSnackbar.show(
        context,
        title: 'Terms Required',
        message:
        'You must agree to the Terms & Conditions and Privacy Policy to continue.',
        type: SnackBarType.error,
      );
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_checkTerms()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithEmailOrUsername(
      emailOrUsername: _identifierCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (!success) {
      CustomSnackbar.show(
        context,
        title: 'Login Failed',
        message: auth.errorMessage ?? 'Something went wrong.',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    if (!_checkTerms()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      CustomSnackbar.show(
        context,
        title: 'Google Sign-In Failed',
        message: auth.errorMessage!,
        type: SnackBarType.error,
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
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            Center(
                              child: Column(
                                children: [
                                  Center(
                                    child: Image.asset(
                                      appIcon,
                                      width: 50,
                                      height: 50,
                                    ),
                                  ),
                                  SizedBox(height: bottomPadding),
                                  Text(
                                    'Welcome back',
                                    style: tt.headlineSmall,
                                  ),
                                  SizedBox(height: bottomPadding - 7),
                                  Text(
                                    'Sign in to continue',
                                    style: tt.bodyMedium!.copyWith(
                                      color: cs.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: bottomPadding + 10),

                            
                            CustomTextFormField(
                              label: 'Email or Username',
                              hint: 'you@example.com or john_doe',
                              controller: _identifierCtrl,
                              prefixIcon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validators: [
                                FieldValidator.required(
                                  'Email or username is required',
                                ),
                              ],
                            ),
                            SizedBox(height: bottomPadding),

                            
                            CustomTextFormField(
                              label: 'Password',
                              hint: '••••••••',
                              controller: _passCtrl,
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validators: [
                                FieldValidator.required(
                                  'Password is required',
                                ),
                                FieldValidator.minLength(6),
                              ],
                            ),
                            SizedBox(height: bottomPadding - 8),

                            
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    AuthDialogs.showForgotPassword(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: tt.titleSmall,
                                ),
                              ),
                            ),
                            SizedBox(height: bottomPadding),

                            
                            _TermsCheckbox(
                              value: _agreedToTerms,
                              hasError: _termsError,
                              onChanged: (v) => setState(() {
                                _agreedToTerms = v ?? false;
                                if (_agreedToTerms) _termsError = false;
                              }),
                              onTermsTap: () {},
                              onPrivacyTap: () {},
                            ),
                            SizedBox(height: bottomPadding),

                            
                            CustomElevatedBtn(
                              label: 'Sign In',
                              onPressed: isLoading ? null : _login,
                              isFullWidth: true,
                              isLoading: isLoading,
                              size: BtnSize.large,
                              borderRadius: textFromFieldBorderRadius,
                              suffixIcon: Icons.arrow_forward_rounded,
                            ),
                            SizedBox(height: bottomPadding + 10),

                            const OrDivider(),
                            SizedBox(height: bottomPadding + 10),

                            
                            CustomOutlineBtn(
                              label: 'Continue with Google',
                              onPressed: isLoading ? null : _loginWithGoogle,
                              isFullWidth: true,
                              isLoading: isLoading,
                              size: BtnSize.large,
                              borderRadius: textFromFieldBorderRadius,
                            ),
                            SizedBox(height: bottomPadding + 10),

                            
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onPrimary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const RegistrationScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      'Sign Up',
                                      style: tt.bodyMedium?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: InternetBanner(),
            ),
          ],
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

    return Row(
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
    );
  }
}