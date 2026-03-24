import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testers/screen/group_testers/service/todaytask_model.dart';
import 'package:testers/screen/group_testers/statistics_screen.dart';
import 'package:testers/screen/group_testers/widget/unified_task_list.dart';
import '../../controllers/app_routes.dart';
import '../../widget/container/animated_expandable_card.dart';
import '../../widget/internet/internet_banner.dart';
import '../installizer/animated_drawer.dart';
import 'service/group_model.dart';
import 'service/group_service.dart';

const _orange = Color(0xFFFF9800);
const _blue = Color(0xFF1565C0);
const _green = Color(0xFF2E7D32);

class ActiveGroupScreen extends StatefulWidget {
  const ActiveGroupScreen({
    super.key,
    required this.group,
    required this.uid,
    required this.username,
    required this.photoURL,
  });

  final GroupModel group;
  final String uid;
  final String username;
  final String photoURL;

  @override
  State<ActiveGroupScreen> createState() => _ActiveGroupScreenState();
}

class _ActiveGroupScreenState extends State<ActiveGroupScreen> {
  // ── Live group — auto-updated from Firestore ───────────────────────────────

  late GroupModel _live;
  StreamSubscription<GroupModel?>? _groupSub;

  // ── Timer for day-flip detection ───────────────────────────────────────────

  Timer? _dayWatchTimer;

  // ── Logic guards ───────────────────────────────────────────────────────────

  int _lastDay = 0;
  bool _completionFired = false;

  // ── Publisher: today's incoming approval cards ─────────────────────────────

  final Map<String, TodayTask> _todayTasks = {};
  StreamSubscription? _taskSub;

  // ── Derived display values ─────────────────────────────────────────────────

  int get _currentDay {
    final start = _live.taskStartDate;
    if (start == null) return 1;
    return (DateTime.now().difference(start).inHours ~/ 24 + 1).clamp(1, 14);
  }

  List<GroupMember> get _others =>
      _live.members.where((m) => m.uid != widget.uid).toList();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _live = widget.group;
    _subscribeToGroup();
    _subscribeToTodayTasks();

    _dayWatchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _handleGroupLogic(_live);
      _checkExpiry();
    });
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    _taskSub?.cancel();
    _dayWatchTimer?.cancel();
    super.dispose();
  }

  // ── Group stream ───────────────────────────────────────────────────────────

  void _subscribeToGroup() {
    _groupSub = GroupService.instance.watchGroup(widget.group.id).listen((
      snapshot,
    ) {
      if (!mounted || snapshot == null) return;
      setState(() => _live = snapshot);
      _handleGroupLogic(snapshot);
    });
  }

  // ── Inlined group logic ────────────────────────────────────────────────────

  void _handleGroupLogic(GroupModel group) {
    if (group.status != GroupStatus.active) return;
    final taskStart = group.taskStartDate;
    if (taskStart == null) return;

    final day = (DateTime.now().difference(taskStart).inHours ~/ 24 + 1).clamp(
      1,
      14,
    );

    if (_lastDay != 0 && day != _lastDay) {
      debugPrint('[ActiveGroupScreen] day rolled — autoApproveStaleTasks');
      GroupService.instance.autoApproveStaleTasks(
        groupId: group.id,
        taskStartDate: taskStart,
      );
    }
    _lastDay = day;

    if (!_completionFired && day >= 14) {
      if (DateTime.now().difference(taskStart).inDays >= 14) {
        _completionFired = true;
        debugPrint('[ActiveGroupScreen] group expired — triggering completion');
        GroupService.instance.checkAndCompleteGroup(group.id);
      }
    }
  }

  Future<void> _checkExpiry() async {
    final group = _live;
    if (group.status != GroupStatus.active || _completionFired) return;
    final taskStart = group.taskStartDate;
    if (taskStart == null) return;
    if (DateTime.now().difference(taskStart).inDays >= 14) {
      _completionFired = true;
      await GroupService.instance.checkAndCompleteGroup(group.id);
    }
  }

  Future<void> _autoApprove() async {
    final taskStart = _live.taskStartDate;
    if (taskStart == null) return;
    await GroupService.instance.autoApproveStaleTasks(
      groupId: _live.id,
      taskStartDate: taskStart,
    );
  }

  // ── Today-tasks stream ─────────────────────────────────────────────────────

  void _subscribeToTodayTasks() {
    final taskStart = widget.group.taskStartDate;
    if (taskStart == null) return;

    _taskSub = FirebaseFirestore.instance
        .collection('group_tested')
        .doc(widget.group.id)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;

          final now = DateTime.now();
          final dayNumber = (now.difference(taskStart).inHours ~/ 24 + 1).clamp(
            1,
            14,
          );
          final data = snap.data() as Map<String, dynamic>;
          final dayMap = data['day-$dayNumber'] as Map<String, dynamic>? ?? {};

          final updated = <String, TodayTask>{};
          for (final entry in dayMap.entries) {
            final map = entry.value as Map<String, dynamic>? ?? {};
            final targetUid = map['targetUserId'] as String? ?? '';
            if (targetUid != widget.uid) continue;
            // Both approved and retestRequired have been acted on by the publisher
            // and must not reappear after the Firestore stream fires.
            final status = map['approvalStatus'] as String?;
            if (status == 'approved' || status == 'retestRequired') continue;
            final appDetails = _live.apps[widget.uid];
            if (appDetails == null) continue;
            updated[entry.key] = TodayTask.fromMap(entry.key, map, appDetails);
          }

          setState(() {
            _todayTasks
              ..removeWhere((k, _) => !updated.containsKey(k))
              ..addAll(updated);
          });
        });
  }

  // ── Approval actions ───────────────────────────────────────────────────────

  Future<void> _approve(TodayTask task) async {
    setState(() => _todayTasks.remove(task.taskId));
    await GroupService.instance.approveTask(
      groupId: _live.id,
      taskId: task.taskId,
      reviewerUid: widget.uid,
      taskStartDate: _live.taskStartDate!,
    );
  }

  Future<void> _reject(TodayTask task) async {
    setState(() => _todayTasks.remove(task.taskId));
    await GroupService.instance.rejectTask(
      groupId: _live.id,
      taskId: task.taskId,
      reviewerUid: widget.uid,
      taskStartDate: _live.taskStartDate!,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final taskStart = _live.taskStartDate;
    final day = _currentDay;

    return AnimatedDrawer(
      currentRoute: AppRoutes.groupTesters,
      title: 'Group Testers',
      showCoinBadge: true,
      showNotificationBadge: true,
      child: ListView(
        children: [
          const InternetBanner(),

          // ── Group Details ──────────────────────────────────────────────
          AnimatedExpandableCard(
            icon: Icons.hub_rounded,
            title: 'Group Details',
            iconColor: _orange,
            accentColor: _orange,
            collapsedTrailing: [
              if (taskStart != null)
                _DayChip(
                  taskStartDate: taskStart,
                  onDayChanged: () {
                    if (mounted) _autoApprove();
                  },
                ),
            ],
            children: [
              CardInfoRow(label: 'Group ID', value: _live.uniqueId),
              CardInfoRow(
                label: 'Members',
                value: '${_live.members.length} / ${_live.maxMembers}',
                valueColor: _orange,
              ),
              CardInfoRow(
                label: 'Tasks reset in',
                trailing: taskStart != null
                    ? _DayChip(
                        taskStartDate: taskStart,
                        onDayChanged: () {
                          if (mounted) _autoApprove();
                        },
                      )
                    : null,
              ),
              CardInfoRow(
                label: 'Time Remaining',
                showDivider: false,
                trailing: _CountdownTimer(taskStartDate: _live.taskStartDate),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Statistics ─────────────────────────────────────────────────
          _StatisticsCard(live: _live, uid: widget.uid, groupId: _live.id),

          const SizedBox(height: 10),
          Text(
            'Mandatory Tasks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),

          // ── Unified Task List ──────────────────────────────────────────
          if (_live.status == GroupStatus.active)
            Container(
              padding: .all(10),
              width: .infinity,
              height: MediaQuery.of(context).size.height * 0.68,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: .circular(16),
                border: .all(
                  color: Theme.of(context).colorScheme.outline
                )
              ),
              child: SingleChildScrollView(
                child: UnifiedTaskList(
                  todayTasks: _todayTasks,
                  others: _others,
                  live: _live,
                  uid: widget.uid,
                  username: widget.username,
                  dayKey: day,
                  taskStartDate: taskStart,
                  onApprove: _approve,
                  onReject: _reject,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatisticsCard — self-contained Firestore stream for stats counters
// ─────────────────────────────────────────────────────────────────────────────

class _StatisticsCard extends StatefulWidget {
  const _StatisticsCard({
    required this.live,
    required this.uid,
    required this.groupId,
  });

  final GroupModel live;
  final String uid;
  final String groupId;

  @override
  State<_StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<_StatisticsCard> {
  StreamSubscription<DocumentSnapshot>? _sub;
  int _myProofs = 0;
  int _received = 0;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('group_tested')
        .doc(widget.groupId)
        .snapshots()
        .listen(_onSnapshot);
  }

  void _onSnapshot(DocumentSnapshot snap) {
    if (!snap.exists || !mounted) return;
    final data = snap.data() as Map<String, dynamic>;
    int proofs = 0;
    int recv = 0;
    for (int d = 1; d <= 14; d++) {
      final dayMap = data['day-$d'] as Map<String, dynamic>?;
      if (dayMap == null) continue;
      proofs += dayMap.entries
          .where(
            (e) =>
                e.key.startsWith('${widget.uid}_') &&
                (e.value as Map<String, dynamic>?)?['approvalStatus'] ==
                    'approved',
          )
          .length;
      recv += dayMap.entries
          .where(
            (e) =>
                e.key.endsWith('_${widget.uid}') &&
                (e.value as Map<String, dynamic>?)?['approvalStatus'] ==
                    'approved',
          )
          .length;
    }
    setState(() {
      _myProofs = proofs;
      _received = recv;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testers = widget.live.members.length - 1;

    return AnimatedExpandableCard(
      icon: Icons.bar_chart_rounded,
      title: 'Statistics',
      iconColor: _blue,
      accentColor: _blue,
      collapsedTrailing: [
        CardChip(
          icon: Icons.calendar_today_rounded,
          label: '$_myProofs',
          color: Colors.green,
        ),
        CardChip(icon: Icons.people_rounded, label: '$testers', color: _blue),
        CardChip(icon: Icons.flag_rounded, label: '$_received', color: _orange),
      ],
      children: [
        CardInfoRow(
          label: 'Tested Today',
          value: '$_myProofs',
          valueColor: Colors.green,
        ),
        CardInfoRow(
          label: 'Total Testers',
          value: '$testers',
          valueColor: _blue,
        ),
        CardInfoRow(
          label: 'Reports Received',
          value: '$_received',
          valueColor: _orange,
          showDivider: false,
        ),
        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
        CardActionRow(
          label: 'View Full Statistics',
          icon: Icons.open_in_new_rounded,
          color: _blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatisticsScreen(
                groupId: widget.groupId,
                uid: widget.uid,
                group: widget.live,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DayChip — live "Day X • HH:MM:SS" CardChip that ticks every second
// ─────────────────────────────────────────────────────────────────────────────

class _DayChip extends StatefulWidget {
  const _DayChip({required this.taskStartDate, this.onDayChanged});
  final DateTime taskStartDate;
  final VoidCallback? onDayChanged;

  @override
  State<_DayChip> createState() => _DayChipState();
}

class _DayChipState extends State<_DayChip> {
  late Timer _timer;
  int _day = 1;
  int _prevDay = 0;
  Duration _untilReset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    if (!mounted) return;
    final now = DateTime.now();
    final elapsed = now.difference(widget.taskStartDate);
    final day = (elapsed.inHours ~/ 24 + 1).clamp(1, 14);
    final nextReset = widget.taskStartDate.add(Duration(hours: day * 24));
    final until = nextReset.difference(now);
    setState(() {
      _day = day;
      _untilReset = until.isNegative ? Duration.zero : until;
    });

    if (_prevDay != 0 && day != _prevDay) widget.onDayChanged?.call();
    _prevDay = day;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _label {
    if (_untilReset == Duration.zero) return 'Resetting…';
    final h = _untilReset.inHours.remainder(24).toString().padLeft(2, '0');
    final m = _untilReset.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _untilReset.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Color get _color => _untilReset.inMinutes < 60
      ? Colors.red
      : _untilReset.inHours < 6
      ? _orange
      : _orange;

  @override
  Widget build(BuildContext context) => CardChip(
    label: _label,
    color: _color,
    backgroundColor: Colors.transparent,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountdownTimer  —  live countdown to end of 14-day cycle
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({required this.taskStartDate});
  final DateTime? taskStartDate;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    if (!mounted) return;
    final start = widget.taskStartDate;
    if (start == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final diff = start.add(const Duration(days: 14)).difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.remainder(24);
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${d.inDays}d ${h}h ${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskStartDate == null) {
      return const Text(
        '—',
        style: TextStyle(
          color: _orange,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      );
    }
    return Text(
      _remaining == Duration.zero ? 'Completed' : _fmt(_remaining),
      style: TextStyle(
        color: _remaining == Duration.zero ? Colors.green : _orange,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}
