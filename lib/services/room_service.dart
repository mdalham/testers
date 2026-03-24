import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../constants/info.dart';
import '../models/room_model.dart';
import 'notification_service.dart';

enum ProofStatus { none, waitingApproval, approved, retestRequired }

class ActiveRoomState {
  const ActiveRoomState({
    required this.activeCount,
    required this.completedCount,
    required this.formingCount,
    required this.totalCount,
    required this.hasActive,
    required this.hasCompleted,
    required this.hasForming,
    required this.isEmpty,
    required this.lastUpdated,
  });

  final int activeCount;
  final int completedCount;
  final int formingCount;
  final int totalCount;
  final bool hasActive;
  final bool hasCompleted;
  final bool hasForming;
  final bool isEmpty;
  final DateTime lastUpdated;

  bool get hasBoth => hasActive && hasCompleted;

  factory ActiveRoomState.fromMap(Map<String, dynamic> map) {
    final active = (map['activeCount'] as int?) ?? 0;
    final completed = (map['completedCount'] as int?) ?? 0;
    final forming = (map['formingCount'] as int?) ?? 0;

    return ActiveRoomState(
      activeCount: active,
      completedCount: completed,
      formingCount: forming,
      totalCount: (map['totalCount'] as int?) ?? 0,
      hasActive: active > 0,
      hasCompleted: completed > 0,
      hasForming: forming > 0,
      isEmpty: active == 0 && completed == 0,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'activeCount': activeCount,
    'completedCount': completedCount,
    'formingCount': formingCount,
    'totalCount': totalCount,
    'hasActive': hasActive,
    'hasCompleted': hasCompleted,
    'hasForming': hasForming,
    'isEmpty': isEmpty,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
  };

  static final empty = ActiveRoomState(
    activeCount: 0,
    completedCount: 0,
    formingCount: 0,
    totalCount: 0,
    hasActive: false,
    hasCompleted: false,
    hasForming: false,
    isEmpty: true,
    lastUpdated: DateTime(0),
  );
}

class RoomService {
  RoomService._();
  static final instance = RoomService._();

  final _db = FirebaseFirestore.instance;
  final _notif = NotificationService.instance;

  CollectionReference get _col => _db.collection('groups');
  CollectionReference get _testedCol => _db.collection('group_tested');
  DocumentReference get _statsDoc => _db.collection('meta').doc('groupStats');

  Stream<List<RoomModel>> watchAllGroups() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RoomModel.fromDoc).toList());

  Stream<ActiveRoomState> watchGroupStats() => _statsDoc.snapshots().map(
    (doc) => doc.exists
        ? ActiveRoomState.fromMap(doc.data() as Map<String, dynamic>)
        : ActiveRoomState.empty,
  );

  Stream<List<RoomModel>> watchActiveGroups() => _col
      .where('status', isEqualTo: RoomStatus.active.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RoomModel.fromDoc).toList());

  Stream<List<RoomModel>> watchCompletedGroups() => _col
      .where('status', isEqualTo: RoomStatus.completed.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RoomModel.fromDoc).toList());

  Stream<RoomModel?> watchGroup(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? RoomModel.fromDoc(d) : null);

  Stream<RoomModel?> watchOpenFormingGroup() => _col
      .where('status', isEqualTo: 'forming')
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isNotEmpty ? RoomModel.fromDoc(s.docs.first) : null);

  Future<void> _syncGroupStats() async {
    try {
      final snap = await _col.get();
      final all = snap.docs.map(RoomModel.fromDoc).toList();
      final active = all.where((g) => g.status == RoomStatus.active).length;
      final completed = all
          .where((g) => g.status == RoomStatus.completed)
          .length;
      final forming = all.where((g) => g.status == RoomStatus.forming).length;

      await _statsDoc.set(
        ActiveRoomState(
          activeCount: active,
          completedCount: completed,
          formingCount: forming,
          totalCount: all.length,
          hasActive: active > 0,
          hasCompleted: completed > 0,
          hasForming: forming > 0,
          isEmpty: active == 0 && completed == 0,
          lastUpdated: DateTime.now(),
        ).toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[RoomService] _syncGroupStats ERROR: $e');
    }
  }

  Future<String> _generateUniqueId() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snap = await _col
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    final today = DateFormat('yyMMdd').format(now);
    final seq = (snap.docs.length + 1).toString().padLeft(2, '0');
    return '$today-$seq';
  }

  Future<void> checkAndStartGroups() async {
    try {
      final snap = await _col.where('status', isEqualTo: 'forming').get();
      for (final doc in snap.docs) {
        final group = RoomModel.fromDoc(doc);
        if (_meetsStartCondition(group)) {
          await _activateGroup(doc.id);
          await _ensureFormingGroupExists();
        }
      }
      await _ensureFormingGroupExists();
      await _syncGroupStats();
    } catch (e) {
      debugPrint('[RoomService] checkAndStartGroups ERROR: $e');
    }
  }

  bool _meetsStartCondition(RoomModel group) {
    if (group.members.length >= group.maxMembers) return true;
    final enoughMembers =
        group.members.length >= PublishConstants.miniGroupMembers;
    final age = DateTime.now().difference(group.createdAt);
    final enoughTime = age.inHours >= PublishConstants.groupStartHours;
    return enoughMembers && enoughTime;
  }

  Future<void> _activateGroup(String groupId) async {
    List<RoomMember> membersSnapshot = [];

    await _db.runTransaction((tx) async {
      final ref = _col.doc(groupId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final group = RoomModel.fromDoc(snap);
      if (group.status != RoomStatus.forming) return;

      membersSnapshot = List.from(group.members);

      tx.update(ref, {
        'status': RoomStatus.active.name,
        'taskStartDate': Timestamp.fromDate(DateTime.now()),
        'startedAt': Timestamp.fromDate(DateTime.now()),
      });
    });

    if (membersSnapshot.isNotEmpty) {
      await _notif.onGroupStarted(members: membersSnapshot, groupId: groupId);
    }
  }

  Future<void> _ensureFormingGroupExists() async {
    final snap = await _col
        .where('status', isEqualTo: 'forming')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return;
    await _createBlankFormingGroup();
  }

  Future<void> _createBlankFormingGroup() async {
    try {
      final uniqueId = await _generateUniqueId();
      await _col.doc(uniqueId).set({
        'uniqueId': uniqueId,
        'status': RoomStatus.forming.name,
        'members': [],
        'apps': {},
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'startedAt': null,
        'taskStartDate': null,
        'maxMembers': PublishConstants.maxGroupMembers,
        'membersCount': 0,
      });
    } catch (e) {
      debugPrint('[RoomService] _createBlankFormingGroup ERROR: $e');
      rethrow;
    }
  }

  Future<String?> joinGroup({
    required String groupId,
    required String uid,
    required String username,
    required AppDetails appDetails,
  }) async {
    try {
      final ref = _col.doc(groupId);
      List<RoomMember> existingMembersSnapshot = [];
      bool groupActivated = false;

      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw 'Group not found.';
        final group = RoomModel.fromDoc(snap);

        if (group.hasJoined(uid)) throw 'You are already in this group.';
        if (group.members.length >= group.maxMembers) throw 'Group is full.';
        if (group.status != RoomStatus.forming)
          throw 'This group is no longer accepting members.';

        existingMembersSnapshot = List.from(group.members);

        final newMember = RoomMember(uid: uid, username: username);
        final updatedMembers = [
          ...group.members.map((m) => m.toMap()),
          newMember.toMap(),
        ];
        final updatedApps = {
          ...group.apps.map((k, v) => MapEntry(k, v.toMap())),
          uid: appDetails.toMap(),
        };
        final newCount = updatedMembers.length;

        final updates = <String, dynamic>{
          'members': updatedMembers,
          'apps': updatedApps,
          'membersCount': newCount,
        };

        if (newCount >= group.maxMembers) {
          updates['status'] = RoomStatus.active.name;
          updates['taskStartDate'] = Timestamp.fromDate(DateTime.now());
          updates['startedAt'] = Timestamp.fromDate(DateTime.now());
          groupActivated = true;
        }

        tx.update(ref, updates);
      });

      if (existingMembersSnapshot.isNotEmpty) {
        await _notif.onUserJoinedGroup(
          existingMembers: existingMembersSnapshot,
          joinerUid: uid,
          joinerUsername: username,
          groupId: groupId,
        );
      }

      if (groupActivated) {
        await _notif.onGroupStarted(
          members: [
            ...existingMembersSnapshot,
            RoomMember(uid: uid, username: username),
          ],
          groupId: groupId,
        );
      }

      await checkAndStartGroups();
      return null;
    } catch (e) {
      debugPrint('[RoomService.joinGroup] $e');
      return e.toString();
    }
  }

  Future<String?> createGroup({
    required String uid,
    required String username,
    required AppDetails appDetails,
  }) async {
    try {
      final existing = await _col
          .where('status', isEqualTo: 'forming')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return joinGroup(
          groupId: existing.docs.first.id,
          uid: uid,
          username: username,
          appDetails: appDetails,
        );
      }

      final uniqueId = await _generateUniqueId();
      final member = RoomMember(uid: uid, username: username);
      await _col.doc(uniqueId).set({
        'uniqueId': uniqueId,
        'status': RoomStatus.forming.name,
        'members': [member.toMap()],
        'apps': {uid: appDetails.toMap()},
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'startedAt': null,
        'taskStartDate': null,
        'maxMembers': PublishConstants.maxGroupMembers,
        'membersCount': 1,
      });

      await _syncGroupStats();
      return null;
    } catch (e, stack) {
      debugPrint('[RoomService] createGroup ERROR: $e\n$stack');
      return e.toString();
    }
  }

  Future<String?> uploadProof({
    required String groupId,
    required String uid,
    required String username,
    required String targetUserId,
    required String screenshotUrl,
    required DateTime taskStartDate,
    String? issueType,
    String? reportText,
    String? appName,
    String? appIconUrl,
  }) async {
    try {
      final now = DateTime.now();
      final dayNumber = (now.difference(taskStartDate).inHours ~/ 24 + 1).clamp(
        1,
        14,
      );
      final dayKey = 'day-$dayNumber';

      final dayWindowEnd = taskStartDate.add(Duration(days: dayNumber));
      final representativeDate = DateTime(
        dayWindowEnd.year,
        dayWindowEnd.month,
        dayWindowEnd.day,
      );

      final proofData = {
        'uid': uid,
        'userName': username,
        'targetUserId': targetUserId,
        'screenshotUrl': screenshotUrl,
        'submittedAt': Timestamp.fromDate(now),
        'windowDate': Timestamp.fromDate(representativeDate),
        'approvalStatus': 'waitingApproval',
        if (issueType != null && issueType.isNotEmpty) 'issueType': issueType,
        if (reportText != null && reportText.isNotEmpty)
          'reportText': reportText.trim(),
      };

      await _testedCol.doc(groupId).set({
        'groupId': groupId,
        dayKey: {'${uid}_$targetUserId': proofData},
      }, SetOptions(merge: true));

      String resolvedAppName = appName ?? '';
      String? resolvedIcon = appIconUrl;
      if (resolvedAppName.isEmpty) {
        try {
          final groupDoc = await _col.doc(groupId).get();
          if (groupDoc.exists) {
            final g = RoomModel.fromDoc(groupDoc);
            final details = g.apps[targetUserId];
            resolvedAppName = details?.appName ?? '';
            resolvedIcon = details?.iconUrl;
          }
        } catch (_) {}
      }

      await _notif.onTesterCompletedTest(
        targetUserId: targetUserId,
        testerUsername: username,
        appName: resolvedAppName,
        appIconUrl: resolvedIcon,
        groupId: groupId,
      );

      return null;
    } catch (e) {
      debugPrint('[RoomService] uploadProof ERROR: $e');
      return e.toString();
    }
  }

  Future<ProofStatus> getTodayProofStatus({
    required String groupId,
    required String uid,
    required String targetUserId,
    required DateTime taskStartDate,
  }) async {
    try {
      final now = DateTime.now();
      final dayNumber = (now.difference(taskStartDate).inHours ~/ 24 + 1).clamp(
        1,
        14,
      );
      final dayKey = 'day-$dayNumber';
      final entryKey = '${uid}_$targetUserId';

      final doc = await _testedCol.doc(groupId).get();
      if (!doc.exists) return ProofStatus.none;

      final data = doc.data() as Map<String, dynamic>?;
      final dayMap = data?[dayKey] as Map<String, dynamic>?;
      if (dayMap == null || !dayMap.containsKey(entryKey))
        return ProofStatus.none;

      final entry = dayMap[entryKey] as Map<String, dynamic>?;
      final status = entry?['approvalStatus'] as String?;

      return switch (status) {
        'approved' => ProofStatus.approved,
        'retestRequired' => ProofStatus.retestRequired,
        _ => ProofStatus.waitingApproval,
      };
    } catch (e) {
      debugPrint('[RoomService] getTodayProofStatus ERROR: $e');
      return ProofStatus.none;
    }
  }

  Future<bool> hasSubmittedTodayProof({
    required String groupId,
    required String uid,
    required String targetUserId,
    required DateTime taskStartDate,
  }) async {
    final status = await getTodayProofStatus(
      groupId: groupId,
      uid: uid,
      targetUserId: targetUserId,
      taskStartDate: taskStartDate,
    );
    return status != ProofStatus.none;
  }

  Future<String?> approveTask({
    required String groupId,
    required String taskId,
    required String reviewerUid,
    required DateTime taskStartDate,
  }) async {
    try {
      final dayNumber =
          (DateTime.now().difference(taskStartDate).inHours ~/ 24 + 1).clamp(
            1,
            14,
          );
      final dayKey = 'day-$dayNumber';

      await _testedCol.doc(groupId).update({
        '$dayKey.$taskId.approvalStatus': 'approved',
        '$dayKey.$taskId.reviewedAt': Timestamp.fromDate(DateTime.now()),
        '$dayKey.$taskId.reviewedBy': reviewerUid,
      });

      return null;
    } catch (e) {
      debugPrint('[RoomService] approveTask ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> rejectTask({
    required String groupId,
    required String taskId,
    required String reviewerUid,
    required DateTime taskStartDate,
  }) async {
    try {
      final dayNumber =
          (DateTime.now().difference(taskStartDate).inHours ~/ 24 + 1).clamp(
            1,
            14,
          );
      final dayKey = 'day-$dayNumber';

      await _testedCol.doc(groupId).update({
        '$dayKey.$taskId.approvalStatus': 'retestRequired',
        '$dayKey.$taskId.reviewedAt': Timestamp.fromDate(DateTime.now()),
        '$dayKey.$taskId.reviewedBy': reviewerUid,
      });

      return null;
    } catch (e) {
      debugPrint('[RoomService] rejectTask ERROR: $e');
      return e.toString();
    }
  }

  Future<void> checkAndCompleteGroups() async {
    try {
      final activeSnap = await _col
          .where('status', isEqualTo: RoomStatus.active.name)
          .get();

      for (final doc in activeSnap.docs) {
        final group = RoomModel.fromDoc(doc);
        if (_isGroupExpired(group)) {
          await _markGroupCompleted(doc.id, members: group.members);
        }
      }
      await _syncGroupStats();
    } catch (e) {
      debugPrint('[RoomService] checkAndCompleteGroups ERROR: $e');
    }
  }

  Future<void> checkAndCompleteGroup(String groupId) async {
    try {
      final doc = await _col.doc(groupId).get();
      if (!doc.exists) return;

      final group = RoomModel.fromDoc(doc);
      if (group.status != RoomStatus.active) return;
      if (!_isGroupExpired(group)) return;

      await _markGroupCompleted(groupId, members: group.members);
      await _syncGroupStats();
    } catch (e) {
      debugPrint('[RoomService] checkAndCompleteGroup ERROR: $e');
    }
  }

  Future<String?> completeGroup(String groupId) async {
    try {
      final doc = await _col.doc(groupId).get();
      if (!doc.exists) return 'Group not found.';

      final group = RoomModel.fromDoc(doc);
      if (group.status == RoomStatus.completed) return null;

      await _markGroupCompleted(
        groupId,
        members: group.members,
        isManuallyClosed: true,
      );
      await _syncGroupStats();
      return null;
    } catch (e) {
      debugPrint('[RoomService] completeGroup ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> removeMember({
    required String groupId,
    required String memberUid,
  }) async {
    try {
      final ref = _col.doc(groupId);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw 'Group not found.';

        final group = RoomModel.fromDoc(snap);
        final updatedMembers = group.members
            .where((m) => m.uid != memberUid)
            .map((m) => m.toMap())
            .toList();
        final updatedApps = Map<String, dynamic>.from(
          group.apps.map((k, v) => MapEntry(k, v.toMap())),
        )..remove(memberUid);

        tx.update(ref, {
          'members': updatedMembers,
          'apps': updatedApps,
          'membersCount': updatedMembers.length,
        });
      });

      await _notif.onUserRemovedFromGroup(
        removedUid: memberUid,
        groupId: groupId,
      );
      return null;
    } catch (e) {
      debugPrint('[RoomService] removeMember ERROR: $e');
      return e.toString();
    }
  }

  Future<void> sendDailyReminders({
    required String groupId,
    required DateTime taskStartDate,
  }) async {
    try {
      final groupDoc = await _col.doc(groupId).get();
      if (!groupDoc.exists) return;
      final group = RoomModel.fromDoc(groupDoc);
      if (group.status != RoomStatus.active) return;

      final now = DateTime.now();
      final dayNumber = (now.difference(taskStartDate).inHours ~/ 24 + 1).clamp(
        1,
        14,
      );
      final dayKey = 'day-$dayNumber';

      final testedDoc = await _testedCol.doc(groupId).get();
      final data = testedDoc.exists
          ? (testedDoc.data() as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};
      final dayMap = data[dayKey] as Map<String, dynamic>? ?? {};

      final submittedUids = dayMap.entries
          .map(
            (e) => (e.value as Map<String, dynamic>?)?['uid'] as String? ?? '',
          )
          .toSet();

      final pendingUids = group.members
          .map((m) => m.uid)
          .where((uid) => !submittedUids.contains(uid))
          .toList();

      for (final uid in pendingUids) {
        await _notif.onDailyReminder(receiverUid: uid, groupId: groupId);
      }
    } catch (e) {
      debugPrint('[RoomService] sendDailyReminders ERROR: $e');
    }
  }

  bool _isGroupExpired(RoomModel group) {
    final taskStart = group.taskStartDate;
    if (taskStart == null) return false;
    return DateTime.now().difference(taskStart).inDays >= 14;
  }

  Future<void> _markGroupCompleted(
    String groupId, {
    required List<RoomMember> members,
    bool isManuallyClosed = false,
  }) async {
    try {
      await _col.doc(groupId).update({
        'status': RoomStatus.completed.name,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (isManuallyClosed) {
        await _notif.onGroupClosed(members: members, groupId: groupId);
      } else {
        await _notif.onGroupCompleted(members: members, groupId: groupId);
      }
    } catch (e) {
      debugPrint('[RoomService] _markGroupCompleted ERROR: $e');
    }
  }

  Future<void> autoApproveStaleTasks({
    required String groupId,
    required DateTime taskStartDate,
  }) async {
    try {
      final now = DateTime.now();
      final currentDay = (now.difference(taskStartDate).inHours ~/ 24 + 1)
          .clamp(1, 14);
      final prevDay = currentDay - 1;
      if (prevDay < 1) return;

      final prevDayKey = 'day-$prevDay';
      final doc = await _testedCol.doc(groupId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>?;
      final dayMap = data?[prevDayKey] as Map<String, dynamic>?;
      if (dayMap == null || dayMap.isEmpty) return;

      final staleKeys = dayMap.entries
          .where((e) {
            final entry = e.value as Map<String, dynamic>?;
            final status = entry?['approvalStatus'] as String?;
            return status == 'waitingApproval';
          })
          .map((e) => e.key)
          .toList();

      if (staleKeys.isEmpty) return;

      final batch = _db.batch();
      final ref = _testedCol.doc(groupId);
      final ts = Timestamp.fromDate(now);

      for (final key in staleKeys) {
        batch.update(ref, {
          '$prevDayKey.$key.approvalStatus': 'approved',
          '$prevDayKey.$key.autoApprovedAt': ts,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[RoomService] autoApproveStaleTasks ERROR: $e');
    }
  }
}
