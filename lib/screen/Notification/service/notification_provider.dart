import 'dart:async';
import 'package:flutter/foundation.dart';

import '../service/notification_model.dart';
import '../service/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationProvider
//
// Manages:
//  • Real-time list of notifications (newest first)
//  • Multi-select state
//  • Unread count badge
// ─────────────────────────────────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._uid) {
    _listenToNotifications();
  }

  final String _uid;
  final _service = NotificationService.instance;

  // ── State ─────────────────────────────────────────────────────────────────

  List<AppNotification> _notifications = [];
  bool    _isLoading = true;
  String? _error;

  // Multi-select
  bool           _isSelectionMode = false;
  final Set<String> _selectedIds  = {};

  StreamSubscription<List<AppNotification>>? _notifSub;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<AppNotification> get notifications    => _notifications;
  bool    get isLoading       => _isLoading;
  String? get error           => _error;
  int     get unreadCount     => _notifications.where((n) => !n.isRead).length;
  bool    get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool    get hasSelections   => _selectedIds.isNotEmpty;
  int     get selectionCount  => _selectedIds.length;

  // ── Stream subscription ───────────────────────────────────────────────────

  void _listenToNotifications() {
    _notifSub = _service.watchNotifications(_uid).listen(
          (list) {
        _notifications = list;
        _isLoading     = false;
        _error         = null;
        notifyListeners();
      },
      onError: (e) {
        _error     = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> markRead(String notificationId) async {
    await _service.markRead(_uid, notificationId);
  }

  Future<void> markAllRead() async {
    await _service.markAllRead(_uid);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteOne(String notificationId) async {
    await _service.deleteNotification(_uid, notificationId);
    _selectedIds.remove(notificationId);
    if (_selectedIds.isEmpty) _isSelectionMode = false;
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    final ids = List<String>.from(_selectedIds);
    await _service.deleteMultiple(_uid, ids);
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // ── Multi-select ──────────────────────────────────────────────────────────

  void enterSelectionMode(String firstId) {
    _isSelectionMode = true;
    _selectedIds.add(firstId);
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_notifications.map((n) => n.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  bool isSelected(String id) => _selectedIds.contains(id);

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }
}