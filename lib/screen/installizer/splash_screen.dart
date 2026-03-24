import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/height_width.dart';
import '../../controllers/icons.dart';
import '../../service/provider/auth_provider.dart';
import '../../theme/colors.dart';
import '../open_testers/open_testers.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';


class _PrefKeys {
  static const String onboardingDone = 'onboarding_done';
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _scaleAnim;
  late final Animation<double>   _slideAnim;

  // Cycling status messages shown next to the spinner
  static const List<String> _statusMessages = [
    'Initializing...',
    'Loading your data...',
    'Almost ready...',
  ];
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cycleStatusMessages();
    _navigateAfterDelay();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve:  const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  // Cycles through status messages every 800 ms
  void _cycleStatusMessages() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return false;
      setState(() {
        _statusIndex = (_statusIndex + 1) % _statusMessages.length;
      });
      return true;
    });
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final authProvider   = context.read<AuthProvider>();
    final prefs          = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_PrefKeys.onboardingDone) ?? false;

    if (!mounted) return;

    if (authProvider.checkIsLoggedIn()) {
      _pushReplacement(const OpenTesters());
    } else if (!onboardingDone) {
      _pushReplacement(const OnboardingScreen());
    } else {
      _pushReplacement(const LoginScreen());
    }
  }

  void _pushReplacement(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:        (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child:   child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Logo ────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: _Logo(isDark: isDark),
                  ),
                ),

                SizedBox(height: bottomPadding),

                // ── App Name ────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    'Testers',
                    style: textTheme.headlineSmall,
                  ),
                ),

                const SizedBox(height: 4),

                // ── Tagline ─────────────────────────
                Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                     'Connect, test, and improve apps together',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: bottomPadding + 20),

                // ── Loading indicator + status text ──
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width:  18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end:   Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _statusMessages[_statusIndex],
                          key: ValueKey(_statusIndex),
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark ? subFontDark : subFontLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _Logo Widget
// ─────────────────────────────────────────────
class _Logo extends StatelessWidget {
  const _Logo({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(appIcon,
      width: 65,
      height: 65,
    );
  }
}