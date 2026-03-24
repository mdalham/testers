import 'package:flutter/material.dart';

import '../../../widget/button/icon_btn.dart';
import '../../../widget/list tile/app_icon.dart';
import '../service/group_model.dart';
import '../service/group_service.dart';
import '../service/todaytask_model.dart';
import '../sheet/test_detail_sheet.dart';
import '../sheet/testing_bottom_sheet.dart';
import 'mandatory_task_card.dart';


const _orange = Color(0xFFFF9800);
const _blue   = Color(0xFF1565C0);
const _green  = Color(0xFF2E7D32);

class UnifiedTaskList extends StatefulWidget {
  const UnifiedTaskList({super.key,
    required this.todayTasks,
    required this.others,
    required this.live,
    required this.uid,
    required this.username,
    required this.dayKey,
    required this.taskStartDate,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, TodayTask>   todayTasks;
  final List<GroupMember>        others;
  final GroupModel               live;
  final String                   uid;
  final String                   username;
  final int                      dayKey;
  final DateTime?                taskStartDate;
  final void Function(TodayTask) onApprove;
  final void Function(TodayTask) onReject;

  @override
  State<UnifiedTaskList> createState() => _UnifiedTaskListState();
}

class _UnifiedTaskListState extends State<UnifiedTaskList> {
  final _listKey = GlobalKey<AnimatedListState>();
  final List<_TaskItem> _items = [];

  final Set<String> _approvedUids = {};

  static const _insertDuration = Duration(milliseconds: 300);
  static const _removeDuration = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    _items.addAll(_buildDesired());
  }

  @override
  void didUpdateWidget(UnifiedTaskList old) {
    super.didUpdateWidget(old);
    _syncItems();
  }


  // ── Diffing ────────────────────────────────────────────────────────────────

  List<_TaskItem> _buildDesired() {
    final today = widget.todayTasks.entries
        .map((e) => _TodayItem(taskId: e.key, task: e.value))
        .toList();

    final mandatory = widget.others
        .where((m) => widget.live.apps[m.uid] != null)
        .map((m) => _MandatoryItem(
      member:     m,
      appDetails: widget.live.apps[m.uid]!,
      dayKey:     widget.dayKey,
    ))
        .toList();

    mandatory.sort((a, b) {
      final aIsApproved = _approvedUids.contains(a.member.uid) ? 1 : 0;
      final bIsApproved = _approvedUids.contains(b.member.uid) ? 1 : 0;
      return aIsApproved.compareTo(bIsApproved);
    });

    return [...today, ...mandatory];
  }

  bool _sameKey(_TaskItem a, _TaskItem b) {
    if (a is _TodayItem     && b is _TodayItem)     return a.taskId == b.taskId;
    if (a is _MandatoryItem && b is _MandatoryItem) {
      return a.member.uid == b.member.uid && a.dayKey == b.dayKey;
    }
    return false;
  }

  void _syncItems() {
    final desired = _buildDesired();

    // 1. Remove items that are no longer in the desired list
    for (int i = _items.length - 1; i >= 0; i--) {
      final currentItem = _items[i];
      if (!desired.any((d) => _sameKey(d, currentItem))) {
        _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
              (ctx, anim) => _buildAnimatedTile(currentItem, anim, isLast: false),
          duration: _removeDuration,
        );
      }
    }

    // 2. Insert or Move items to match the desired order
    for (int i = 0; i < desired.length; i++) {
      final targetItem = desired[i];

      // If the item at current index doesn't match the desired item
      if (i >= _items.length || !_sameKey(_items[i], targetItem)) {

        // Check if this item exists elsewhere in the list (needs moving)
        final oldIndex = _items.indexWhere((item) => _sameKey(item, targetItem));

        if (oldIndex != -1) {
          // Item exists, remove from old and insert at new to simulate "moving"
          final movedItem = _items.removeAt(oldIndex);
          _listKey.currentState?.removeItem(
            oldIndex,
                (ctx, anim) => const SizedBox.shrink(), // Silent remove for move
            duration: Duration.zero,
          );

          _items.insert(i, movedItem);
          _listKey.currentState?.insertItem(i, duration: _insertDuration);
        } else {
          // Item is genuinely new
          _items.insert(i, targetItem);
          _listKey.currentState?.insertItem(i, duration: _insertDuration);
        }
      }
    }
  }

  // ── Tile builders ──────────────────────────────────────────────────────────

  /// [isLast] controls whether a Divider is rendered below the card.
  Widget _buildAnimatedTile(
      _TaskItem item,
      Animation<double> animation, {
        required bool isLast,
      }) {
    final cs    = _listKey.currentContext != null
        ? Theme.of(_listKey.currentContext!).colorScheme
        : null;

    final slide = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCard(item),
            if (!isLast)
              Padding(
                padding: .only(top: 10),
                child: Divider(
                  height:    1,
                  thickness: 1,
                  //indent:    16,
                  //endIndent: 16,
                  color: cs?.outline,
                ),
              ),
            // Spacing: below divider for non-last, below card for last.
            SizedBox(height: isLast ? 0 : 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_TaskItem item) => switch (item) {
    _TodayItem(:final task) => _TodayTaskCard(
      task:      task,
      onApprove: () => widget.onApprove(task),
      onReject:  () => widget.onReject(task),
    ),
    _MandatoryItem(:final member, :final appDetails, :final dayKey) =>
        MandatoryTaskCard(
          key:             ValueKey('mandatory_${member.uid}_$dayKey'),
          groupId:         widget.live.id,
          currentUid:      widget.uid,
          currentUsername: widget.username,
          member:          member,
          appDetails:      appDetails,
          taskStartDate:   widget.taskStartDate!,
          // Listen for status changes to trigger a re-sort
          onStatusChanged: (status) {
            final isApproved = status == ProofStatus.approved;
            final wasAlreadyApproved = _approvedUids.contains(member.uid);

            if (isApproved != wasAlreadyApproved) {
              // Wrap in a post-frame callback to avoid state collisions during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  if (isApproved) {
                    _approvedUids.add(member.uid);
                  } else {
                    _approvedUids.remove(member.uid);
                  }
                });
                _syncItems();
              });
            }
          },
        ),
  };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const _EmptyTasksPlaceholder();

    return AnimatedList(
      key:              _listKey,
      shrinkWrap:       true,
      physics:          const NeverScrollableScrollPhysics(),
      initialItemCount: _items.length,
      itemBuilder: (ctx, i, anim) => _buildAnimatedTile(
        _items[i],
        anim,
        isLast: i == _items.length - 1,   // ← live length, always accurate
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyTasksPlaceholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTasksPlaceholder extends StatelessWidget {
  const _EmptyTasksPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color:        cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add_check_circle_rounded,
              size: 40, color: _green.withOpacity(0.45)),
          const SizedBox(height: 12),
          Text('No tasks available',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Check back once the group is active and tasks have been assigned.',
            style:     tt.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TodayTaskCard
// ─────────────────────────────────────────────────────────────────────────────

class _TodayTaskCard extends StatelessWidget {
  const _TodayTaskCard({
    required this.task,
    required this.onApprove,
    required this.onReject,
  });

  final TodayTask    task;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color get _accent => task.approval == TaskApproval.retestRequired
      ? Colors.deepOrange
      : _orange;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => showTestDetailSheet(
        context,
        testerUid:     task.testerUid,
        testerName:    task.testerName,
        screenshotUrl: task.screenshotUrl!,
        submittedAt:   task.submittedAt,
        appDetails:    task.appDetails,
        issueType:     task.issueType,
        reportText:    task.reportText,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(
                imageUrl:     task.appDetails.iconUrl,
                size:         48,
                borderRadius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.appDetails.appName,
                      style:    tt.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '@${task.testerName}',
                            style: tt.bodySmall
                                ?.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (task.approval == TaskApproval.waitingApproval) ...[
                IconBtn(
                  icon:         Icons.check_rounded,
                  onTap:        onApprove,
                  color:        _green,
                  size:         36,
                  iconSize:     16,
                  borderRadius: 10,
                  tooltip:      'Approve',
                ),
                const SizedBox(width: 8),
                IconBtn(
                  icon:         Icons.close_rounded,
                  onTap:        onReject,
                  color:        Colors.red,
                  size:         36,
                  iconSize:     16,
                  borderRadius: 10,
                  tooltip:      'Request Retest',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}


sealed class _TaskItem { const _TaskItem(); }

final class _TodayItem extends _TaskItem {
  const _TodayItem({required this.taskId, required this.task});
  final String    taskId;
  final TodayTask task;
}

final class _MandatoryItem extends _TaskItem {
  const _MandatoryItem({
    required this.member,
    required this.appDetails,
    required this.dayKey,
  });
  final GroupMember member;
  final AppDetails  appDetails;
  /// Part of equality — a day rollover forces remove + re-insert, which
  /// disposes MandatoryTaskCard and triggers a fresh stream subscription.
  final int dayKey;
}
