import 'dart:async';
import 'package:flutter/material.dart';
import 'group_model.dart';
import 'group_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GroupLogicProvider
// ─────────────────────────────────────────────────────────────────────────────

class GroupLogicProvider extends ChangeNotifier {
  GroupLogicProvider(String uid) : _uid = uid {
    _init();
  }

  final String _uid;

  GroupModel? _currentGroup;
  bool        _loading = true;
  String?     _error;

  GroupModel? get currentGroup => _currentGroup;
  bool        get loading      => _loading;
  String?     get error        => _error;
  bool        get isInGroup    => _currentGroup != null;

  StreamSubscription<List<GroupModel>>? _sub;

  void _init() {
    _sub = GroupService.instance.watchAllGroups().listen(
          (groups) {
        _currentGroup = groups
            .where((g) =>
        g.hasJoined(_uid) && g.status != GroupStatus.completed)
            .toList()
            .firstOrNull;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error   = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}