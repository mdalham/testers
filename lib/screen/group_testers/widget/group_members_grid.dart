import 'package:flutter/material.dart';
import 'package:testers/screen/group_testers/group_join_screen.dart';
import '../../../controllers/info.dart';
import '../../../controllers/icons.dart';
import '../../../widget/button/custom_buttons.dart';
import '../service/group_model.dart';


// ─────────────────────────────────────────────────────────────────────────────
// GroupMembersGrid  —  3 columns × 5 rows = 15 slots
// ─────────────────────────────────────────────────────────────────────────────

class GroupMembersGrid extends StatelessWidget {
  const GroupMembersGrid({
    super.key,
    required this.groupUniqueId,
    required this.members,
    required this.apps,
    required this.currentUid,
    required this.username,
    required this.photoURL,
    this.group,
  });

  final String groupUniqueId;
  final List<GroupMember> members;
  final Map<String, AppDetails> apps;
  final String currentUid;
  final String username;
  final String photoURL;
  final GroupModel? group;

  static const int _totalSlots = 15; // 3 × 5
  static const int _columns = 5; // 3 columns → 5 rows

  bool get _alreadyIn => group?.hasJoined(currentUid) ?? false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Group ID pill ──────────────────────────────────────────────────
          _GroupIdHeader(uniqueId: groupUniqueId),
          const SizedBox(height: 14),

          // ── 3 × 5 grid ────────────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _totalSlots,
            itemBuilder: (context, i) {
              if (i < members.length) {
                final member = members[i];
                final iconUrl = apps[member.uid]?.iconUrl ?? '';
                return _AppIcon(
                  appIconUrl: iconUrl,
                  isMe: member.uid == currentUid,
                );
              }
              return const _EmptySlot();
            },
          ),

          // ── Member count ───────────────────────────────────────────────────
          const SizedBox(height: 10),

          // ── Action buttons / waiting message ───────────────────────────────
          if (_alreadyIn) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Text(
                'Members joined: ${members.length} / $_totalSlots\nWaiting for other members to join…',
                style: tt.bodySmall!.copyWith(
                  color: Colors.amber,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFB800).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(coinIcon, width: 12, height: 12),
                  const SizedBox(width: 5),
                  Text(
                    '${PublishConstants.groupJoinCoinCost} coins required to join',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFFFB800),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: CustomOutlineBtn(
                    label: 'View Apps',
                    prefixIcon: Icons.grid_view_rounded,
                    isFullWidth: true,
                    size: BtnSize.small,
                    onPressed: members.isEmpty
                        ? null
                        : () => _showAppsSheet(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomElevatedBtn(
                    label: 'Join Group',
                    prefixIcon: Icons.group_add_rounded,
                    isFullWidth: true,
                    size: BtnSize.small,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupJoinScreen(
                          existingGroupId: group?.id,
                          uid: currentUid,
                          username: username,
                          photoURL: photoURL,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAppsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AppsListSheet(members: members, apps: apps),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GroupIdHeader
// ─────────────────────────────────────────────────────────────────────────────

class _GroupIdHeader extends StatelessWidget {
  const _GroupIdHeader({required this.uniqueId});
  final String uniqueId;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.tag_rounded, size: 15, color: Colors.amber),
        const SizedBox(width: 5),
        Text(uniqueId, style: tt.titleSmall),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppIcon
// ─────────────────────────────────────────────────────────────────────────────

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.appIconUrl, required this.isMe});

  final String appIconUrl;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: appIconUrl.isNotEmpty
          ? Image.network(
              appIconUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _fallback(context),
            )
          : _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.apps_rounded,
        size: 22,
        color: cs.onPrimaryContainer.withOpacity(0.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptySlot
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline, width: 1.2),
      ),
      child: Center(
        child: Icon(Icons.add_rounded, size: 22, color: cs.outline),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppsListSheet
// ─────────────────────────────────────────────────────────────────────────────

class _AppsListSheet extends StatelessWidget {
  const _AppsListSheet({required this.members, required this.apps});

  final List<GroupMember> members;
  final Map<String, AppDetails> apps;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final joined = members.where((m) => apps.containsKey(m.uid)).toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Apps in this Group',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (joined.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No apps submitted yet.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: joined.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = joined[i];
                final app = apps[m.uid]!;
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: app.iconUrl.isNotEmpty
                          ? Image.network(
                              app.iconUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: cs.primaryContainer,
                              child: Icon(
                                Icons.apps_rounded,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.appName,
                            style: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            app.packageName,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
