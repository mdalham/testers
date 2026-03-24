import 'package:flutter/material.dart';
import 'package:testers/screen/discovery/update/update_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:testers/widgets/button/custom_buttons.dart';


void showUpdateBottomSheet({
  required BuildContext context,
  required UpdateModel model,
  required String currentVersion,
  String? appIconPath,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: !model.forceUpdate, 
    enableDrag: !model.forceUpdate,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UpdateBottomSheet(
      model: model,
      currentVersion: currentVersion,
      appIconPath: appIconPath,
    ),
  );
}



class _UpdateBottomSheet extends StatelessWidget {
  const _UpdateBottomSheet({
    required this.model,
    required this.currentVersion,
    this.appIconPath,
  });

  final UpdateModel model;
  final String currentVersion;
  final String? appIconPath;

  

  Future<void> _openStore() async {
    final uri = Uri.parse(model.updateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      
      canPop: !model.forceUpdate,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(forceUpdate: model.forceUpdate),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          model.title,
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        color: cs.outline,
                        thickness: 1,
                        indent: 60,
                        endIndent: 60,
                      ),
                      const SizedBox(height: 10),
                      _VersionPill(
                        current: currentVersion,
                        latest: model.latestVersion,
                        cs: cs,
                        tt: tt,
                      ),
                      const SizedBox(height: 16),
                      _Description(text: model.description, tt: tt, cs: cs),
                      if (model.changelog.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _Changelog(items: model.changelog, tt: tt, cs: cs),
                      ],
                      const SizedBox(height: 28),
                      _Buttons(
                        forceUpdate: model.forceUpdate,
                        onUpdate: _openStore,
                        onLater: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        cs: cs,
                        tt: tt,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.forceUpdate});
  final bool forceUpdate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: forceUpdate
              ? Colors.transparent
              : cs.onSurfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}



class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.current,
    required this.latest,
    required this.cs,
    required this.tt,
  });

  final String current;
  final String latest;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _VersionTag(label: 'Current', version: current, cs: cs, tt: tt),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: cs.onSurface,
            ),
          ),
          _VersionTag(
            label: 'Latest',
            version: latest,
            cs: cs,
            tt: tt,
            isLatest: true,
          ),
        ],
      ),
    );
  }
}

class _VersionTag extends StatelessWidget {
  const _VersionTag({
    required this.label,
    required this.version,
    required this.cs,
    required this.tt,
    this.isLatest = false,
  });

  final String label;
  final String version;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(color: cs.onPrimary, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          'v$version',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isLatest ? cs.primary : cs.onPrimary,
          ),
        ),
      ],
    );
  }
}



class _Description extends StatelessWidget {
  const _Description({required this.text, required this.tt, required this.cs});

  final String text;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: tt.bodyMedium?.copyWith(color: cs.onPrimary, height: 1.5),
    );
  }
}



class _Changelog extends StatelessWidget {
  const _Changelog({required this.items, required this.tt, required this.cs});

  final List<String> items;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's new",
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



class _Buttons extends StatelessWidget {
  const _Buttons({
    required this.forceUpdate,
    required this.onUpdate,
    required this.onLater,
    required this.cs,
    required this.tt,
  });

  final bool         forceUpdate;
  final VoidCallback onUpdate;
  final VoidCallback onLater;
  final ColorScheme  cs;
  final TextTheme    tt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        
        CustomElevatedBtn(
          label:        'Update Now',
          onPressed:    onUpdate,
          prefixIcon:   Icons.system_update_rounded,
          isFullWidth:  true,
          size:         BtnSize.large,
          borderRadius: 14,
        ),

        
        if (!forceUpdate) ...[
          const SizedBox(height: 10),
          CustomOutlineBtn(
            label:        'Later',
            onPressed:    onLater,
            isFullWidth:  true,
            size:         BtnSize.large,
            borderRadius: 14,
          ),
        ],
      ],
    );
  }
}
