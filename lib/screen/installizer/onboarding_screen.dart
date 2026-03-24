import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/height_width.dart';
import '../../theme/colors.dart';
import '../../widget/button/custom_buttons.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────
//  Onboarding Data Model
// ─────────────────────────────────────────────
class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    accent;
}

const _pages = [
  _OnboardingPage(
    icon:     Icons.public_outlined,
    title:    'Open Testing for Everyone',
    subtitle: 'Publish your app for open testing and let anyone try it. Get instant feedback, discover bugs, and improve your app faster.',
    accent:   green,
  ),
  _OnboardingPage(
    icon:     Icons.group_outlined,
    title:    'Exclusive Group Testing',
    subtitle: 'Create or join a private testing group with up to 15 testers for 14 days. Collaborate closely and ensure high-quality releases.',
    accent:   green,
  ),
  _OnboardingPage(
    icon:     Icons.monetization_on_outlined,
    title:    'Earn & Use Coins',
    subtitle: 'Earn coins by testing apps and completing tasks. Use coins to join group tests or boost your own app’s visibility.',
    accent:   orange,
  ),
  _OnboardingPage(
    icon:     Icons.security_outlined,
    title:    'Secure & Trusted Platform',
    subtitle: 'All testing activities are monitored and protected. Your apps, data, and feedback remain secure and confidential.',
    accent:   blue,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ─────────────────────────────────────────────
  //  Mark Onboarding Complete & Navigate
  // ─────────────────────────────────────────────
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size   = MediaQuery.of(context).size;
    final tt     = Theme.of(context).textTheme;
    final cs     = Theme.of(context).colorScheme;


    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [

            // ── Skip button ──────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: tt.labelLarge?.copyWith(color: cs.onPrimary),
                  ),
                ),
              ),
            ),

            // ── PageView ─────────────────────────
            Expanded(
              child: PageView.builder(
                controller:   _pageController,
                itemCount:    _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _PageContent(page: _pages[index], size: size),
              ),
            ),

            // ── Dot indicators ───────────────────
            _DotIndicators(
              count:   _pages.length,
              current: _currentPage,
              accent:  _pages[_currentPage].accent,
            ),

            SizedBox(height: bottomPadding),

            // ── Action buttons ───────────────────
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: bottomPadding + 6),
              child: Row(
                children: [

                  // ── Back (hidden on first page) ────────────────────────────────
                  if (_currentPage > 0) ...[
                    CustomOutlineBtn(
                      label:           'Back',
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve:    Curves.easeInOut,
                      ),
                      size:            BtnSize.large,
                      borderRadius:    14,
                      foregroundColor: _pages[_currentPage].accent,
                      borderColor:     _pages[_currentPage].accent,
                      prefixIcon:      Icons.arrow_back_rounded,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // ── Continue / Get Started ─────────────────────────────────────
                  Expanded(
                    child: CustomElevatedBtn(
                      label: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      onPressed:       _nextPage,
                      isFullWidth:     true,
                      size:            BtnSize.large,
                      borderRadius:    14,
                      backgroundColor: _pages[_currentPage].accent,
                      foregroundColor: Colors.white,
                      suffixIcon: _currentPage == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _PageContent
// ─────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  const _PageContent({required this.page, required this.size});

  final _OnboardingPage page;
  final Size            size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt     = Theme.of(context).textTheme;
    final cs     = Theme.of(context).colorScheme;


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // ── Icon card ──────────────────────────
          Container(
            width:  size.width * 0.45,
            height: size.width * 0.45,
            decoration: BoxDecoration(
              color:        page.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: page.accent.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              page.icon,
              size:  size.width * 0.18,
              color: page.accent,
            ),
          ),

          const SizedBox(height: 48),

          // ── Title ─────────────────────────────
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: tt.headlineSmall
          ),

          const SizedBox(height: 10),

          // ── Subtitle ──────────────────────────
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: tt.bodyMedium
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _DotIndicators
// ─────────────────────────────────────────────
class _DotIndicators extends StatelessWidget {
  const _DotIndicators({
    required this.count,
    required this.current,
    required this.accent,
  });

  final int   count;
  final int   current;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width:  isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:        isActive ? accent : accent.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}