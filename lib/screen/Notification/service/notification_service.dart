import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../screen/group_testers/service/group_model.dart';
import 'notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Future<void> _send(String uid, AppNotification notification,
      {String? docId}) async {
    try {
      final ref = docId != null ? _col.doc(docId) : _col.doc();
      await ref.set({...notification.toMap(), 'userId': uid});
    } catch (e) {
      debugPrint('[NotificationService] _send error: $e');
    }
  }

  Future<void> _sendToMany(
      List<String> uids,
      AppNotification Function() builder, {
        String? docId,
      }) async {
    for (final uid in uids) {
      await _send(uid, builder(), docId: docId);
    }
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(AppNotification.fromDoc).toList());
  }

  Stream<int> watchUnreadCount(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((qs) => qs.docs
        .where((d) => (d.data()['isRead'] as bool?) != true)
        .length)
        .handleError((e) {
      debugPrint('[NotificationService] watchUnreadCount error: $e');
      return 0;
    });
  }

  Future<void> markRead(String uid, String notificationId) async {
    try {
      await _col.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('[NotificationService] markRead error: $e');
    }
  }

  Future<void> markAllRead(String uid) async {
    try {
      final unread = await _col
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();
      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[NotificationService] markAllRead error: $e');
    }
  }

  Future<void> deleteNotification(String uid, String notificationId) async {
    try {
      await _col.doc(notificationId).delete();
    } catch (e) {
      debugPrint('[NotificationService] deleteNotification error: $e');
    }
  }

  Future<void> deleteMultiple(String uid, List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final id in ids) {
        batch.delete(_col.doc(id));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[NotificationService] deleteMultiple error: $e');
    }
  }

  Future<void> onAppPublished({
    required String  uid,
    required String  username,
    required String  appName,
    required String  packageName,
    required String? appIconUrl,
  }) async {
    await _send(
      uid,
      AppNotification(
        id:          '',
        title:       'App Published',
        message:     'Your app "$appName" has been published and is now open for testers.',
        type:        NotificationType.publish,
        appName:     appName,
        packageName: packageName,
        appIconUrl:  appIconUrl,
        createdAt:   DateTime.now(),
        isRead:      false,
        extraData:   {'publishedAt': DateTime.now().toIso8601String()},
      ),
    );
  }

  Future<void> onMaxTestersReached({
    required String  ownerUid,
    required String  ownerUsername,
    required String  appName,
    required String  packageName,
    required String? appIconUrl,
    required int     totalTesters,
  }) async {
    await _send(
      ownerUid,
      AppNotification(
        id:          '',
        title:       'Testing Completed',
        message:     '"$appName" testing is complete. $totalTesters testers joined. '
            'You can republish if you need more.',
        type:        NotificationType.maxTester,
        appName:     appName,
        packageName: packageName,
        appIconUrl:  appIconUrl,
        createdAt:   DateTime.now(),
        isRead:      false,
        extraData: {
          'totalTesters': totalTesters,
          'completedAt':  DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  Future<void> onUserJoinedGroup({
    required List<GroupMember> existingMembers,
    required String            joinerUid,
    required String            joinerUsername,
    required String            groupId,
  }) async {
    final recipientUids = existingMembers
        .map((m) => m.uid)
        .where((uid) => uid != joinerUid)
        .toList();

    await _sendToMany(
      recipientUids,
          () => AppNotification(
        id:        '',
        title:     'New Member Joined',
        message:   '$joinerUsername joined the testing group.',
        type:      NotificationType.userJoined,
        groupId:   groupId,
        createdAt: DateTime.now(),
        isRead:    false,
        extraData: {'joinerUid': joinerUid, 'joinerUsername': joinerUsername},
      ),
    );
  }

  Future<void> onTesterCompletedTest({
    required String  targetUserId,
    required String  testerUsername,
    required String  appName,
    required String? appIconUrl,
    required String  groupId,
  }) async {
    await _send(
      targetUserId,
      AppNotification(
        id:         '',
        title:      'Test Submitted',
        message:    '$testerUsername completed testing for "$appName".',
        type:       NotificationType.testerCompleted,
        appName:    appName,
        appIconUrl: appIconUrl,
        groupId:    groupId,
        createdAt:  DateTime.now(),
        isRead:     false,
        extraData:  {'testerUsername': testerUsername},
      ),
    );
  }

  Future<void> onGroupStarted({
    required List<GroupMember> members,
    required String            groupId,
  }) async {
    await _sendToMany(
      members.map((m) => m.uid).toList(),
          () => AppNotification(
        id:        '',
        title:     'Group Testing Started',
        message:   'Group testing has started. You can begin testing now.',
        type:      NotificationType.groupStarted,
        groupId:   groupId,
        createdAt: DateTime.now(),
        isRead:    false,
      ),
    );
  }

  Future<void> onGroupCompleted({
    required List<GroupMember> members,
    required String            groupId,
  }) async {
    await _sendToMany(
      members.map((m) => m.uid).toList(),
          () => AppNotification(
        id:        '',
        title:     'Group Completed',
        message:   'Group testing has been completed. Great work!',
        type:      NotificationType.groupCompleted,
        groupId:   groupId,
        createdAt: DateTime.now(),
        isRead:    false,
      ),
      docId: 'group_completed_$groupId',
    );
  }

  Future<void> onGroupClosed({
    required List<GroupMember> members,
    required String            groupId,
  }) async {
    await _sendToMany(
      members.map((m) => m.uid).toList(),
          () => AppNotification(
        id:        '',
        title:     'Group Closed',
        message:   'This testing group has been closed.',
        type:      NotificationType.groupClosed,
        groupId:   groupId,
        createdAt: DateTime.now(),
        isRead:    false,
      ),
    );
  }

  Future<void> onUserRemovedFromGroup({
    required String removedUid,
    required String groupId,
  }) async {
    await _send(
      removedUid,
      AppNotification(
        id:        '',
        title:     'Removed from Group',
        message:   'You have been removed from the testing group.',
        type:      NotificationType.userRemoved,
        groupId:   groupId,
        createdAt: DateTime.now(),
        isRead:    false,
      ),
    );
  }

  Future<void> onDailyReminder({
    required String receiverUid,
    required String groupId,
  }) async {
    await _send(
      receiverUid,
      AppNotification(
        id:        '',
        title:     'Daily Testing Reminder',
        message:   'Reminder: Please complete today\'s testing task.',
        type:      NotificationType.dailyReminder,
        groupId:   groupId,
        createdAt: DateTime.now(),
        isRead:    false,
      ),
    );
  }
}