import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/constants/app_routes.dart';
import 'package:testers/screen/auth/animated_drawer.dart';
import 'package:testers/screen/room/service/room_logic_provider.dart';
import 'package:testers/screen/room/inactive_room_screen.dart';
import 'package:testers/screen/room/active_room_screen.dart';

import '../../models/room_model.dart';
import '../../services/room_service.dart';





class RoomMainScreen extends StatefulWidget {
  const RoomMainScreen({super.key});

  @override
  State<RoomMainScreen> createState() => _RoomMainScreenState();
}

class _RoomMainScreenState extends State<RoomMainScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return ChangeNotifierProvider(
      create: (_) => RoomLogicProvider(auth.uid),
      child: const _GroupRouter(),
    );
  }
}





class _GroupRouter extends StatefulWidget {
  const _GroupRouter();

  @override
  State<_GroupRouter> createState() => _GroupRouterState();
}

class _GroupRouterState extends State<_GroupRouter> {

  
  StreamSubscription<ActiveRoomState>? _statsSub;
  StreamSubscription<RoomModel?>?      _groupSub;

  
  RoomStatus? _lastStatus;
  String?      _watchedGroupId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoomService.instance.checkAndStartGroups();
      _startListening();
    });
  }

  
  void _startListening() {
    
    
    _statsSub = RoomService.instance.watchGroupStats().listen((state) {
      if (mounted) setState(() {});
    });

    
    
    _hookGroupStream();
  }

  void _hookGroupStream() {
    final provider = context.read<RoomLogicProvider>();
    final groupId  = provider.currentGroup?.id;
    if (groupId == null || groupId == _watchedGroupId) return;

    _watchedGroupId = groupId;
    _groupSub?.cancel();

    _groupSub = RoomService.instance.watchGroup(groupId).listen((group) {
      if (!mounted) return;

      final newStatus = group?.status;

      
      
      
      
      if (newStatus != _lastStatus) {
        _lastStatus = newStatus;
        setState(() {});

        
        
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
    final provider = context.watch<RoomLogicProvider>();
    final auth     = context.watch<AuthProvider>();

    
    WidgetsBinding.instance.addPostFrameCallback((_) => _hookGroupStream());

    
    if (provider.loading) {
      return _shell(child: const Center(child: CircularProgressIndicator()));
    }

    
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

    
    if (provider.isInGroup && group?.status == RoomStatus.active) {
      return ActiveRoomScreen(
        group:    group!,
        uid:      auth.uid,
        username: auth.username,
        photoURL: auth.photoURL,
      );
    }

    
    return InactiveRoomScreen(
      uid:      auth.uid,
      username: auth.username,
      photoURL: auth.photoURL,
    );
  }

  Widget _shell({required Widget child}) {
    return AnimatedDrawer(
      currentRoute:          AppRoutes.room,
      title:                 'Rooms',
      showCoinBadge:         true,
      showNotificationBadge: true,
      child: child,
    );
  }
}