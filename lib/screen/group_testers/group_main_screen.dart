import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/provider/auth_provider.dart';
import '../../controllers/app_routes.dart';
import '../installizer/animated_drawer.dart';
import 'service/group_logic_provider.dart';
import 'service/group_model.dart';
import 'service/group_service.dart';
import 'inactive_group_screen.dart';
import 'active_group_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GroupMainScreen
// ─────────────────────────────────────────────────────────────────────────────

class GroupMainScreen extends StatefulWidget {
  const GroupMainScreen({super.key});

  @override
  State<GroupMainScreen> createState() => _GroupMainScreenState();
}

class _GroupMainScreenState extends State<GroupMainScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ChangeNotifierProvider(
      create: (_) => GroupLogicProvider(auth.uid),
      child: const _GroupRouter(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GroupRouter  —  listens to live group changes and rebuilds automatically
// ─────────────────────────────────────────────────────────────────────────────

class _GroupRouter extends StatefulWidget {
  const _GroupRouter();

  @override
  State<_GroupRouter> createState() => _GroupRouterState();
}

class _GroupRouterState extends State<_GroupRouter> {

  // Streams that drive auto-rebuild
  StreamSubscription<ActiveGroupState>? _statsSub;
  StreamSubscription<GroupModel?>?      _groupSub;

  // Last known group so we can detect status transitions
  GroupStatus? _lastStatus;
  String?      _watchedGroupId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GroupService.instance.checkAndStartGroups();
      _startListening();
    });
  }

  // ── Subscribe to meta/groupStats + current group doc ─────────────────────
  void _startListening() {
    // 1. Watch aggregate stats — fires whenever any group is created,
    //    activated, or completed, so the router re-evaluates immediately.
    _statsSub = GroupService.instance.watchGroupStats().listen((state) {
      if (mounted) setState(() {});
    });

    // 2. Watch the specific group the user is in (if any).
    //    Re-hooks whenever the provider delivers a new group id.
    _hookGroupStream();
  }

  void _hookGroupStream() {
    final provider = context.read<GroupLogicProvider>();
    final groupId  = provider.currentGroup?.id;
    if (groupId == null || groupId == _watchedGroupId) return;

    _watchedGroupId = groupId;
    _groupSub?.cancel();

    _groupSub = GroupService.instance.watchGroup(groupId).listen((group) {
      if (!mounted) return;

      final newStatus = group?.status;

      // Rebuild on any status change:
      //   forming  → active   (group started)
      //   active   → completed (group closed)
      //   null     → anything  (user just joined)
      if (newStatus != _lastStatus) {
        _lastStatus = newStatus;
        setState(() {});

        // If the group the user is in changed id or the user left,
        // re-hook to the new group stream.
        _hookGroupStream();
      }
    });
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    _groupSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupLogicProvider>();
    final auth     = context.watch<AuthProvider>();

    // Re-hook the group stream whenever provider delivers a new group
    WidgetsBinding.instance.addPostFrameCallback((_) => _hookGroupStream());

    // ── Loading ──────────────────────────────────────────────────────────────
    if (provider.loading) {
      return _shell(child: const Center(child: CircularProgressIndicator()));
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (provider.error != null) {
      return _shell(
        child: Center(
          child: Text(
            'Failed to load group data.\n${provider.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final group = provider.currentGroup;

    // ── Active group → full testing cycle screen ─────────────────────────────
    if (provider.isInGroup && group?.status == GroupStatus.active) {
      return ActiveGroupScreen(
        group:    group!,
        uid:      auth.uid,
        username: auth.username,
        photoURL: auth.photoURL,
      );
    }

    // ── Not in any group, or in a forming group → inactive screen ────────────
    return InactiveGroupScreen(
      uid:      auth.uid,
      username: auth.username,
      photoURL: auth.photoURL,
    );
  }

  Widget _shell({required Widget child}) {
    return AnimatedDrawer(
      currentRoute:          AppRoutes.groupTesters,
      title:                 'Tester Groups',
      showCoinBadge:         true,
      showNotificationBadge: true,
      child: child,
    );
  }
}