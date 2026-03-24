import 'dart:async';
import 'package:flutter/material.dart';
import 'package:testers/screen/room/widget/inactive_groups_section.dart';
import 'package:testers/constants/app_routes.dart';
import 'package:testers/widgets/internet/internet_banner.dart';
import 'package:testers/screen/auth/animated_drawer.dart';
import 'package:testers/screen/room/widget/room_members_grid.dart';
import 'package:testers/screen/room/widget/pending_install_tile.dart';

import '../../models/room_model.dart';
import '../../services/room_service.dart';

const _deepBlue = Color(0xFF1A237E);
const _orange = Color(0xFFFF9800);





class InactiveRoomScreen extends StatefulWidget {
  const InactiveRoomScreen({
    super.key,
    required this.uid,
    required this.username,
    required this.photoURL,
  });

  final String uid;
  final String username;
  final String photoURL;

  @override
  State<InactiveRoomScreen> createState() => _InactiveRoomScreenState();
}

class _InactiveRoomScreenState extends State<InactiveRoomScreen> {
  StreamSubscription<ActiveRoomState>? _statsSub;
  StreamSubscription<RoomModel?>? _formingSub;

  RoomModel? _formingGroup;

  @override
  void initState() {
    super.initState();
    _formingSub = RoomService.instance.watchOpenFormingGroup().listen((group) {
      if (mounted) setState(() => _formingGroup = group);
    });

    _statsSub = RoomService.instance.watchGroupStats().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _formingSub?.cancel();
    _statsSub?.cancel();
    super.dispose();
  }

  List<PendingInstallItem> _buildPendingItems(RoomModel group) {
    return group.members.where((m) => group.apps.containsKey(m.uid)).map((m) {
      final app = group.apps[m.uid]!;
      return PendingInstallItem(
        appName: app.appName,
        developerName: m.username,
        packageName: app.packageName,
        isOwner: m.uid == widget.uid,
        iconUrl: app.iconUrl,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final group = _formingGroup;
    final hasJoined = group?.hasJoined(widget.uid) ?? false;
    final pendingItems = group != null
        ? _buildPendingItems(group)
        : <PendingInstallItem>[];

    return AnimatedDrawer(
      currentRoute: AppRoutes.room,
      title: 'Room',
      showCoinBadge: true,
      showNotificationBadge: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        children: [
          const InternetBanner(),
          const _Header(),
          const SizedBox(height: 10),

          RoomMembersGrid(
            groupUniqueId: group?.uniqueId ?? '—',
            members: group?.members ?? const [],
            apps: group?.apps ?? const {},
            currentUid: widget.uid,
            username: widget.username,
            photoURL: widget.photoURL,
            group: group,
          ),

          
          if (hasJoined && pendingItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            PendingInstallSection(items: pendingItems),
          ],

          
          if (!hasJoined) ...[
            const SizedBox(height: 10),
            InactiveGroupsSection(),
          ],
        ],
      ),
    );
  }
}





class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join a Testing Group',
          style: tt.titleMedium
        ),
        const SizedBox(height: 4),
        Text(
          'Fill 15 slots together and run the 14-day closed-testing cycle '
          'to meet Google Play\'s tester requirement.',
          style: tt.bodyMedium?.copyWith(color: cs.onPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatChip(
              icon: Icons.people_rounded,
              label: '15 members',
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.timer_rounded,
              label: '14 days',
              color: _orange,
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.verified_rounded,
              label: 'Mutual test',
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
