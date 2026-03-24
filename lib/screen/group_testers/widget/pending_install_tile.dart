import 'dart:async';

import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widget/list tile/app_icon.dart';
import '../../../widget/snackbar/custom_snackbar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PendingInstallItem  —  data model for a single pending-install row
// ─────────────────────────────────────────────────────────────────────────────

class PendingInstallItem {
  const PendingInstallItem({
    required this.appName,
    required this.developerName,
    required this.packageName,
    required this.isOwner,
    this.iconUrl,
  });

  final String appName;
  final String developerName;
  final String packageName;
  final bool isOwner;
  final String? iconUrl;
}

// ─────────────────────────────────────────────────────────────────────────────
// PendingInstallSection  —  full section: header + list of tiles
// ─────────────────────────────────────────────────────────────────────────────

class PendingInstallSection extends StatelessWidget {
  const PendingInstallSection({super.key, required this.items});

  final List<PendingInstallItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(
            children: [
              Icon(
                Icons.download_for_offline_rounded,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Pending Install',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),

        // ── Tiles ─────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: cs.outlineVariant,
            ),
            itemBuilder: (context, i) => PendingInstallTile(item: items[i]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PendingInstallTile  —  single row
// ─────────────────────────────────────────────────────────────────────────────

class PendingInstallTile extends StatelessWidget {
  const PendingInstallTile({super.key, required this.item});

  final PendingInstallItem item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // ── App icon ───────────────────────────────────────────────────
          AppIcon(imageUrl: item.iconUrl, size: 46, borderRadius: 12),
          const SizedBox(width: 12),

          // ── App name + developer ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.appName,
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Dev: ${item.developerName}',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Action button ──────────────────────────────────────────────
          item.isOwner
              ? _OpenAppButton(packageName: item.packageName)
              : _InstallButton(packageName: item.packageName),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InstallButton  —  for non-owners: opens Play Store
// ─────────────────────────────────────────────────────────────────────────────

class _InstallButton extends StatefulWidget {
  const _InstallButton({
    super.key,
    required this.packageName,
    this.onInstalled,
  });
  final String packageName;
  final VoidCallback? onInstalled; // Triggered when app is detected

  @override
  State<_InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<_InstallButton>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _isInstalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use a small delay to ensure the plugin is ready
    Future.delayed(Duration.zero, () => _checkStatus());
  }

  // Very Important: This triggers the check when you come back from Play Store
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("Checking install status: App Resumed");
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    try {
      // Standard check using external_app_launcher
      final bool installed = await LaunchApp.isAppInstalled(
        androidPackageName: widget.packageName,
      );

      debugPrint("Checking ${widget.packageName}: Result = $installed");

      if (mounted && installed != _isInstalled) {
        setState(() => _isInstalled = installed);
        if (installed && widget.onInstalled != null) {
          widget.onInstalled!();
        }
      }
    } on MissingPluginException catch (e) {
      debugPrint("Plugin not linked! Stop app and rebuild from scratch. $e");
    } catch (e) {
      debugPrint("Other check error: $e");
    }
  }

  Future<void> _openPlayStore() async {
    final String pkg = widget.packageName;
    final Uri marketUri = Uri.parse('market://details?id=$pkg');
    final Uri webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$pkg',
    );
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        _timer?.cancel();
        _timer = Timer.periodic(
          const Duration(seconds: 4),
          (t) => _checkStatus(),
        );
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch Play Store: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 1. Logic for "Installed" State
    if (_isInstalled) {
      return OutlinedButton.icon(
        onPressed: null, // Disabled because task is done
        icon: const Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: Colors.green,
        ),
        label: const Text('Installed'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          minimumSize: const Size(0, 34),
          side: const BorderSide(color: Colors.green, width: 1.5),
          foregroundColor: Colors.green,
          disabledForegroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // ── Pending Install State (Primary Outline) ────────────────────────
    return OutlinedButton.icon(
      onPressed: _openPlayStore,
      icon: const Icon(Icons.download_rounded, size: 16),
      label: const Text('Install'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: cs.primary),
        foregroundColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _OpenAppButton extends StatefulWidget {
  const _OpenAppButton({
    super.key,
    required this.packageName,
    this.onSuccess, // Callback to trigger _advance(1)
  });

  final String packageName;
  final VoidCallback? onSuccess;

  @override
  State<_OpenAppButton> createState() => _OpenAppButtonState();
}

class _OpenAppButtonState extends State<_OpenAppButton> {
  bool _isLoading = false;

  // Your standardized Open Play Store logic
  Future<void> _openPlayStore() async {
    final marketUri = Uri.parse('market://details?id=${widget.packageName}');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=${widget.packageName}',
    );
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // Your requested _tryOpenApp logic integrated into the handler
  Future<void> _handleOpenApp() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Check if the app is installed
      bool isInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: widget.packageName,
      );

      if (isInstalled) {
        // 2. Open the app (Professional Launcher)
        await LaunchApp.openApp(
          androidPackageName: widget.packageName,
          openStore: false,
        );

        // 3. Success: Advance the step if the callback exists
        if (mounted && widget.onSuccess != null) {
          widget.onSuccess!();
        }
      } else {
        // 4. Not installed: Show Snackbar with your Play Store logic
        if (mounted) {
          CustomSnackbar.show(
            context,
            title: 'App Not Installed',
            message: 'Please install the app from Play Store first.',
            type: SnackBarType.error,
            actionLabel: 'Install',
            onAction: _openPlayStore,
          );
        }
      }
    } catch (e) {
      debugPrint('_tryOpenApp Error: $e');
      // Final fallback: try to force open market intent
      try {
        final intentUri = Uri.parse(
          "market://details?id=${widget.packageName}",
        );
        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        }
      } catch (innerError) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            title: 'Launch Failed',
            message: 'Could not find the app on this device.',
            type: SnackBarType.error,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleOpenApp,
      icon: _isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            )
          : const Icon(Icons.open_in_new_rounded, size: 16),
      label: Text(_isLoading ? 'Opening...' : 'Open'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: _isLoading ? cs.outline : cs.primary),
        foregroundColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
