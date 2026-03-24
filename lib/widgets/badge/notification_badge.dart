import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:testers/constants/app_routes.dart';
import 'package:testers/services/notification_service.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key, required this.uid});

  final String uid;

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  StreamSubscription<int>? _sub;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  
  @override
  void didUpdateWidget(NotificationBadge old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) {
      _sub?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    if (widget.uid.isEmpty) {
      debugPrint('[NotificationBadge] uid is empty — skipping subscribe');
      return;
    }

    debugPrint('[NotificationBadge] subscribing for uid=${widget.uid}');

    _sub = NotificationService.instance
        .watchUnreadCount(widget.uid)
        .listen(
          (count) {
        debugPrint('[NotificationBadge] unread count = $count');
        if (mounted) setState(() => _count = count);
      },
      onError: (e) {
        debugPrint('[NotificationBadge] stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      tooltip:   'Notifications',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.notification),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            _count > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            color: cs.onSurface,
          ),
          if (_count > 0)
            Positioned(
              top:   -2,
              right: -2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  8,
                height: 8,
                decoration: BoxDecoration(
                  color:  cs.error,
                  shape:  BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}