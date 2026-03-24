import 'package:flutter/material.dart';
import 'package:testers/utils/height_width.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:testers/widgets/button/custom_buttons.dart';
import 'package:testers/widgets/dialog/confirm_dialog.dart';
import 'package:testers/screen/notifications/service/notification_provider.dart';
import '../../../models/notification_model.dart';

class NotificationDetailSheet extends StatelessWidget {
  const NotificationDetailSheet({
    super.key,
    required this.notification,
    required this.provider,
  });

  final AppNotification      notification;
  final NotificationProvider provider;

  static void show(
      BuildContext context, {
        required AppNotification      notification,
        required NotificationProvider provider,
      }) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      useRootNavigator:   true,
      backgroundColor:    Colors.transparent,
      builder: (_) => NotificationDetailSheet(
        notification: notification,
        provider:     provider,
      ),
    );
  }

  String _formatIso(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final extra        = notification.extraData;
    final totalTesters = extra?['totalTesters'];
    final completedAt  = extra?['completedAt'] as String?;

    
    final pkg = notification.packageName;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize:     0.35,
      maxChildSize:     0.85,
      expand:           false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:        cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: cs.outline, width: 1.5)),
          ),
          child: Column(
            children: [
              _DragHandle(cs: cs),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          
                          Expanded(
                            child: Text(
                              notification.title.isNotEmpty
                                  ? notification.title
                                  : '—',
                              style: tt.titleMedium,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: bottomPadding),
                      Divider(color: cs.outline),
                      SizedBox(height: bottomPadding),

                      
                      Text(
                        notification.message.isNotEmpty
                            ? notification.message
                            : '—',
                        style: tt.bodyMedium?.copyWith(
                          color:  cs.onSurfaceVariant,
                          height: 1.55,
                        ),
                      ),

                      SizedBox(height: bottomPadding),

                      
                      if (pkg != null && pkg.isNotEmpty)
                        _MetaRow(
                          icon:  Icons.inventory_2_outlined,
                          label: 'Package',
                          value: pkg,        
                          cs:    cs,
                          tt:    tt,
                        ),

                      
                      if (totalTesters != null)
                        _MetaRow(
                          icon:  Icons.people_alt_outlined,
                          label: 'Total Tested',
                          value: totalTesters.toString(),
                          cs:    cs,
                          tt:    tt,
                        ),

                      
                      if (completedAt != null && completedAt.isNotEmpty)
                        _MetaRow(
                          icon:  Icons.check_circle_outline_rounded,
                          label: 'Completed At',
                          value: _formatIso(completedAt),
                          cs:    cs,
                          tt:    tt,
                        ),

                      SizedBox(height: bottomPadding),

                      
                      _MetaRow(
                        icon:  Icons.access_time_rounded,
                        label: 'Received',
                        value: timeago.format(notification.createdAt),
                        cs:    cs,
                        tt:    tt,
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              _ActionButtons(notification: notification, provider: provider),
            ],
          ),
        );
      },
    );
  }
}



class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });

  final IconData    icon;
  final String      label;
  final String      value;
  final ColorScheme cs;
  final TextTheme   tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant.withOpacity(0.55)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: tt.bodySmall?.copyWith(
              color:      cs.onSurfaceVariant.withOpacity(0.55),
              fontSize:   10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodySmall?.copyWith(
                color:    cs.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width:  40,
          height: 4,
          decoration: BoxDecoration(
            color:        cs.outlineVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}



class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, required this.cs});
  final NotificationType type;
  final ColorScheme      cs;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.publish         => (Icons.rocket_launch_rounded,  const Color(0xFF1565C0)),
      NotificationType.maxTester       => (Icons.people_alt_rounded,     const Color(0xFF2E7D32)),
      NotificationType.userJoined      => (Icons.person_add_rounded,     const Color(0xFF6A1B9A)),
      NotificationType.testerCompleted => (Icons.task_alt_rounded,       const Color(0xFF2E7D32)),
      NotificationType.groupStarted    => (Icons.play_circle_rounded,    const Color(0xFF1565C0)),
      NotificationType.groupCompleted  => (Icons.check_circle_rounded,   const Color(0xFF2E7D32)),
      NotificationType.groupClosed     => (Icons.lock_rounded,           const Color(0xFFC62828)),
      NotificationType.userRemoved     => (Icons.person_remove_rounded,  const Color(0xFFC62828)),
      NotificationType.dailyReminder   => (Icons.alarm_rounded,          const Color(0xFFFF9800)),
      NotificationType.unknown         => (Icons.notifications_rounded,  const Color(0xFF607D8B)),
    };

    return Container(
      padding:    const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}



class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.notification, required this.provider});

  final AppNotification      notification;
  final NotificationProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color:  cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withOpacity(0.25),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomOutlineBtn(
              label:        'Close',
              prefixIcon:   Icons.close_rounded,
              size:         BtnSize.large,
              borderRadius: 14,
              onPressed:    () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomElevatedBtn(
              label:           'Delete',
              prefixIcon:      Icons.delete_outline_rounded,
              size:            BtnSize.large,
              borderRadius:    14,
              backgroundColor: Colors.red,
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title:        'Delete notification?',
                  message:
                  'This action cannot be undone. Once you delete this '
                      'notification, it will be permanently removed and you '
                      'will not be able to recover it.',
                  confirmLabel: 'Delete',
                  icon:         Icons.delete_outline_rounded,
                  iconColor:    Colors.red,
                );
                if (confirmed == true && context.mounted) {
                  Navigator.pop(context);
                  provider.deleteOne(notification.id);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}