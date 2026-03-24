import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testers/controllers/height_width.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widget/button/custom_buttons.dart';
import '../../../widget/snackbar/custom_snackbar.dart';


class GroupJoiningSheet extends StatelessWidget {
  const GroupJoiningSheet({
    super.key,
    required this.groupEmail,
    required this.groupLink,
  });

  final String groupEmail;
  final String groupLink;

  static const List<String> _steps = [
    'Join the provided Google Group link.',
    'Use the same Google account on Play Store.',
    'Add this group inside Google Play Console → Closed Testing → Testers.',
    'Wait a few minutes after joining and retry.',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.74,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.75, 0.95],
      builder: (sheetCtx, scrollController) {
        final cs = Theme.of(sheetCtx).colorScheme;
        final tt = Theme.of(sheetCtx).textTheme;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: cs.outline, width: 1.5)),
          ),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const SizedBox(width: 40, height: 4),
                  ),
                ),
              ),

              // ── Scrollable area ────────────────────────────────────
              // ListView is wired to scrollController so dragging down
              // from the top of the list collapses the sheet
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Header icon
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outline),
                      ),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: cs.onSurface,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      'Closed Testing Access Required',
                      style: tt.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      'If you are not added to the Google Testing Group, '
                      'tester or you will not be able to find or install this app in '
                      'Closed Testing. Please make sure you join the correct '
                      'group before trying again.',
                      style: tt.bodyMedium?.copyWith(color: cs.onPrimary),
                    ),
                    SizedBox(height: bottomPadding),

                    // ── How to join card ───────────────────────────
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 17,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('How to Join?', style: tt.titleSmall),
                              ],
                            ),
                            const SizedBox(height: 14),
                            for (int i = 0; i < _steps.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == _steps.length - 1 ? 0 : 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: cs.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: tt.labelSmall?.copyWith(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _steps[i],
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          height: 1.45,
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
                    const SizedBox(height: 20),

                    // ── Email section ──────────────────────────────
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 15,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Testing Group Email',
                          style: tt.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                        child: Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(
                                  Icons.email_outlined,
                                  size: 17,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                groupEmail,
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: groupEmail),
                                );
                                if (!sheetCtx.mounted) return;
                                CustomSnackbar.show(
                                  context,
                                  message: 'Copied to clipboard',
                                  type: SnackBarType.success,
                                );
                              },
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: cs.onSurface,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: cs.primary.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── Bottom buttons — pinned, never scrolls away ────────
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(top: BorderSide(color: cs.outline)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(sheetCtx).padding.bottom + 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomOutlineBtn(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(sheetCtx),
                          isFullWidth: true,
                          size: BtnSize.large,
                          borderRadius: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: CustomElevatedBtn(
                          label: 'Open Group',
                          isFullWidth: true,
                          size: BtnSize.large,
                          borderRadius: 14,
                          suffixIcon: Icons.open_in_new_rounded,
                          onPressed: () async {
                            try {
                              final launched = await launchUrl(
                                Uri.parse(groupLink),
                                mode: LaunchMode.externalApplication,
                              );
                              if (!launched && sheetCtx.mounted) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open link.'),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (sheetCtx.mounted) {
                                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open link.'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
