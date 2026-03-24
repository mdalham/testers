import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/constants/app_routes.dart';
import 'package:testers/models/notification_model.dart';
import 'package:testers/screen/notifications/service/notification_provider.dart';
import 'package:testers/screen/notifications/sheet/notification_detail_sheet.dart';
import 'package:testers/screen/auth/animated_drawer.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/widgets/dialog/confirm_dialog.dart';





class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    final uid = context.read<AuthProvider>().uid;
    return ChangeNotifierProvider(
      create: (_) => NotificationProvider(uid),
      child: const _NotificationDrawerShell(),
    );
  }
}





class _NotificationDrawerShell extends StatelessWidget {
  const _NotificationDrawerShell();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<NotificationProvider>();
    final cs          = Theme.of(context).colorScheme;
    final tt          = Theme.of(context).textTheme;
    final isSelecting = provider.isSelectionMode;

    final Widget? leading = isSelecting
        ? IconButton(
      icon:      const Icon(Icons.close_rounded),
      onPressed: provider.clearSelection,
      tooltip:   'Cancel selection',
    )
        : null;

    final String title = isSelecting
        ? '${provider.selectionCount} selected'
        : 'Notifications';

    final List<Widget> actions = isSelecting
        ? [
      TextButton(
        onPressed: provider.selectAll,
        child: Text('All',
            style: tt.labelLarge?.copyWith(color: cs.primary)),
      ),
      IconButton(
        icon:    Icon(Icons.delete_outline_rounded, color: cs.error),
        tooltip: 'Delete selected',
        onPressed: provider.hasSelections
            ? () {
          ConfirmDialog.show(
            context,
            title: 'Delete notification?',
            message:
            'This action cannot be undone. Once you delete '
                'this notification it will be permanently removed.',
            confirmLabel: 'Delete',
            icon:      Icons.delete_outline_rounded,
            iconColor: Colors.red,
            onConfirm: () => provider.deleteSelected(),
          );
        }
            : null,
      ),
      const SizedBox(width: 4),
    ]
        : [
      if (provider.unreadCount > 0)
        IconButton(
          icon:    const Icon(Icons.done_all_rounded),
          tooltip: 'Mark all as read',
          onPressed: provider.markAllRead,
        ),
      const SizedBox(width: 4),
    ];

    return AnimatedDrawer(
      currentRoute: AppRoutes.notification,
      title:        title,
      actions:      actions,
      leadingWidget: leading,
      child: _NotificationBody(provider: provider),
    );
  }
}





class _NotificationBody extends StatelessWidget {
  const _NotificationBody({required this.provider});
  final NotificationProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return _ErrorState(message: provider.error!);
    }
    if (provider.notifications.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      itemCount:        provider.notifications.length,
      padding:          EdgeInsets.zero,
      separatorBuilder: (_, __) => Divider(
        height:    1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
      ),
      itemBuilder: (context, index) {
        final notif = provider.notifications[index];
        return _NotificationTile(
          key:          ValueKey(notif.id),
          notification: notif,
          provider:     provider,
        );
      },
    );
  }
}





class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.provider,
  });

  final AppNotification     notification;
  final NotificationProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final tt         = Theme.of(context).textTheme;
    final isSelected = provider.isSelected(notification.id);

    return Dismissible(
      key:       ValueKey('dismiss_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: _SwipeDeleteBackground(cs: cs),
      confirmDismiss: (_) async {
        if (provider.isSelectionMode) {
          provider.toggleSelection(notification.id);
          return false;
        }
        final confirmed = await ConfirmDialog.show(
          context,
          title:        'Delete notification?',
          message:      'This action cannot be undone.',
          confirmLabel: 'Delete',
          icon:         Icons.delete_outline_rounded,
          iconColor:    Colors.red,
        );
        return confirmed == true;
      },
      onDismissed: (_) => provider.deleteOne(notification.id),
      child: InkWell(
        onTap: () {
          if (provider.isSelectionMode) {
            provider.toggleSelection(notification.id);
          } else {
            if (!notification.isRead) {
              provider.markRead(notification.id);
            }
            NotificationDetailSheet.show(
              context,
              notification: notification,
              provider:     provider,
            );
          }
        },
        onLongPress: () {
          if (!provider.isSelectionMode) {
            provider.enterSelectionMode(notification.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: isSelected
              ? cs.primaryContainer.withOpacity(0.5)
              : !notification.isRead
              ? cs.primaryContainer.withOpacity(0.25)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Stack(
                children: [
                  _NotifIconWidget(
                    iconUrl: notification.appIconUrl,
                    type:    notification.type,
                  ),
                  if (provider.isSelectionMode)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity:  1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? cs.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? cs.surface : cs.outline,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                              color: Colors.blue, size: 20)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        
                        _TypeChip(type: notification.type),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style:    tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeago.format(notification.createdAt),
                      style: tt.labelSmall?.copyWith(
                        color:    cs.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              
              if (!notification.isRead && !provider.isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width:  8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
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





class _NotifIconWidget extends StatelessWidget {
  const _NotifIconWidget({required this.iconUrl, required this.type});
  final String? iconUrl;
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final hasIcon = iconUrl != null && iconUrl!.isNotEmpty;

    return SizedBox(
      width:  46,
      height: 46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: hasIcon
            ? Image.network(
          iconUrl!,
          fit:          BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackIcon(type: type),
        )
            : _FallbackIcon(type: type),
      ),
    );
  }

  Color _typeColor(NotificationType t) => switch (t) {
    NotificationType.publish         => const Color(0xFF1565C0),
    NotificationType.maxTester       => const Color(0xFF2E7D32),
    NotificationType.userJoined      => const Color(0xFF6A1B9A),
    NotificationType.testerCompleted => const Color(0xFF2E7D32),
    NotificationType.groupStarted    => const Color(0xFF1565C0),
    NotificationType.groupCompleted  => const Color(0xFF2E7D32),
    NotificationType.groupClosed     => const Color(0xFFC62828),
    NotificationType.userRemoved     => const Color(0xFFC62828),
    NotificationType.dailyReminder   => const Color(0xFFFF9800),
    NotificationType.unknown         => const Color(0xFF607D8B),
  };
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.type});
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _iconFor(type),
      size:  22,
      color: _colorFor(type),
    );
  }

  IconData _iconFor(NotificationType t) => switch (t) {
    NotificationType.publish         => Icons.rocket_launch_rounded,
    NotificationType.maxTester       => Icons.people_alt_rounded,
    NotificationType.userJoined      => Icons.person_add_rounded,
    NotificationType.testerCompleted => Icons.task_alt_rounded,
    NotificationType.groupStarted    => Icons.play_circle_rounded,
    NotificationType.groupCompleted  => Icons.check_circle_rounded,
    NotificationType.groupClosed     => Icons.lock_rounded,
    NotificationType.userRemoved     => Icons.person_remove_rounded,
    NotificationType.dailyReminder   => Icons.alarm_rounded,
    NotificationType.unknown         => Icons.notifications_rounded,
  };

  Color _colorFor(NotificationType t) => switch (t) {
    NotificationType.publish         => const Color(0xFF1565C0),
    NotificationType.maxTester       => const Color(0xFF2E7D32),
    NotificationType.userJoined      => const Color(0xFF6A1B9A),
    NotificationType.testerCompleted => const Color(0xFF2E7D32),
    NotificationType.groupStarted    => const Color(0xFF1565C0),
    NotificationType.groupCompleted  => const Color(0xFF2E7D32),
    NotificationType.groupClosed     => const Color(0xFFC62828),
    NotificationType.userRemoved     => const Color(0xFFC62828),
    NotificationType.dailyReminder   => const Color(0xFFFF9800),
    NotificationType.unknown         => const Color(0xFF607D8B),
  };
}





class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      NotificationType.publish         => 'App',
      NotificationType.maxTester       => 'App',
      NotificationType.userJoined      => 'Group',
      NotificationType.testerCompleted => 'Group',
      NotificationType.groupStarted    => 'Group',
      NotificationType.groupCompleted  => 'Group',
      NotificationType.groupClosed     => 'Group',
      NotificationType.userRemoved     => 'Group',
      NotificationType.dailyReminder   => 'Reminder',
      NotificationType.unknown         => '',
    };

    if (label.isEmpty) return const SizedBox.shrink();

    final color = label == 'Group'
        ? const Color(0xFF1565C0)
        : label == 'Reminder'
        ? const Color(0xFFFF9800)
        : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   9,
          color:      color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}





class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding:   const EdgeInsets.only(right: 20),
    color:     cs.error.withOpacity(0.12),
    child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 24),
  );
}





class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 60, color: cs.onSurfaceVariant.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            'Activity about your apps and groups will appear here',
            style: tt.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}





class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text('Something went wrong', style: tt.titleMedium),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}