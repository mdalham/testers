import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/screen/installizer/animated_drawer.dart';
import 'package:testers/screen/setting/bottom_sheet/data_privacy_sheet.dart';
import 'package:testers/screen/setting/bottom_sheet/privacy_policy_sheet.dart';
import 'package:testers/screen/setting/bottom_sheet/terms_of_service_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/app_routes.dart';
import '../../controllers/height_width.dart';
import '../../controllers/info.dart';
import '../../service/provider/auth_provider.dart';
import '../../theme/theme_provider.dart';
import '../../widget/dialog/confirm_dialog.dart';
import '../../widget/snackbar/custom_snackbar.dart';
import '../installizer/dialog/auth_dialogs.dart';
import 'bottom_sheet/group_join_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;

  Future<void> _handleLogout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your account?',
      confirmLabel: 'Sign Out',
      icon: Icons.logout_rounded,
      iconColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return AnimatedDrawer(
      currentRoute: AppRoutes.settings,
      title: 'Settings',
      child: ListView(
        children: [
          // ── Account ────────────────────────────────────────────────
          _SectionHeader(icon: Icons.person, label: 'Account'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.join_full,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => AuthDialogs.showForgotPassword(context),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Join Group',
                subtitle: 'Join google group',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const GroupJoiningSheet(
                      groupEmail: 'testers_community@googlegroups.com',
                      groupLink:
                          'https://groups.google.com/u/2/g/testers_community',
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: bottomPadding),

          // ── Appearance ─────────────────────────────────────────────
          _SectionHeader(icon: Icons.palette_outlined, label: 'Appearance'),
          _SettingsCard(
            children: [
              _SettingsTileSwitch(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                subtitle: isDark ? 'Using dark theme' : 'Using light theme',
                value: isDark,
                onChanged: (v) => themeProvider.toggleTheme(v),
              ),
              _Divider(),
              _SettingsTileSwitch(
                icon: Icons.notifications_outlined,
                title: 'Enable Notifications',
                subtitle: 'Receive all notifications',
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
            ],
          ),

          SizedBox(height: bottomPadding),

          // ── Privacy & Security ─────────────────────────────────────
          _SectionHeader(
            icon: Icons.security_outlined,
            label: 'Privacy & Security',
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () => PrivacyPolicySheet.show(context),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                onTap: () => TermsOfServiceSheet.show(context),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Data & Privacy',
                subtitle: 'Manage your data',
                onTap: () => DataPrivacySheet.show(context),
              ),
            ],
          ),

          SizedBox(height: bottomPadding),

          // ── Support ────────────────────────────────────────────────
          _SectionHeader(icon: Icons.help_outline_rounded, label: 'Support'),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Feedback or Report',
                subtitle: 'Share your thoughts',
                onTap: () => _sendFeedbackEmail(context),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: PublishConstants.fallbackVersion,
                onTap: () {},
              ),
            ],
          ),

          SizedBox(height: bottomPadding),

          // ── Danger Zone ────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.warning_amber_rounded,
            label: 'Danger Zone',
            color: Colors.red,
          ),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: Colors.orange,
                title: 'Sign out',
                subtitle: 'Sign out of your account',
                onTap: () => _handleLogout(),
              ),
            ],
          ),
          SizedBox(height: bottomPadding + 10),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final tint = color ?? cs.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: 8),
          Text(
            label,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(baseBorderRadius),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Theme.of(context).colorScheme.outline);
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.showChevron = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.displaySmall?.copyWith(
                      color: cs.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurface),
          ],
        ),
      ),
    );
  }
}

class _SettingsTileSwitch extends StatelessWidget {
  const _SettingsTileSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }
}

Future<void> _sendFeedbackEmail(BuildContext context) async {
  const email = 'info.thardstudio@gmail.com';
  final Uri emailUri = Uri(scheme: 'mailto', path: email, queryParameters: {});
  try {
    final bool launched = await launchUrl(
      emailUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      CustomSnackbar.show(
        context,
        message: 'Could not open email app',
        type: SnackBarType.error,
      );
    }
  } catch (e) {
    if (context.mounted) {
      CustomSnackbar.show(
        context,
        message: 'Error opening email',
        type: SnackBarType.error,
      );
      debugPrint('Error opening email: $e');
    }
  }
}
