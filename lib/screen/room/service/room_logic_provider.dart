import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/room_model.dart';
import '../../../services/room_service.dart';

class RoomLogicProvider extends ChangeNotifier {
  RoomLogicProvider(String uid) : _uid = uid {
    _init();
  }

  final String _uid;

  RoomModel? _currentGroup;
  bool _loading = true;
  String? _error;

  RoomModel? get currentGroup => _currentGroup;
  bool get loading => _loading;
  String? get error => _error;
  bool get isInGroup => _currentGroup != null;

  StreamSubscription<List<RoomModel>>? _sub;

  void _init() {
    _sub = RoomService.instance.watchAllGroups().listen(
      (groups) {
        _currentGroup = groups
            .where((g) => g.hasJoined(_uid) && g.status != RoomStatus.completed)
            .toList()
            .firstOrNull;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
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
