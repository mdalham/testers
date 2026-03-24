import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  publish,
  maxTester,
  userJoined,
  testerCompleted,
  groupStarted,
  groupCompleted,
  groupClosed,
  userRemoved,
  dailyReminder,
  unknown;

  static NotificationType fromString(String? v) => switch (v) {
    'publish'         => publish,
    'maxTester'       => maxTester,
    'userJoined'      => userJoined,
    'testerCompleted' => testerCompleted,
    'groupStarted'    => groupStarted,
    'groupCompleted'  => groupCompleted,
    'groupClosed'     => groupClosed,
    'userRemoved'     => userRemoved,
    'dailyReminder'   => dailyReminder,
    _                 => unknown,
  };

  String get firestoreId => switch (this) {
    publish         => 'publish',
    maxTester       => 'maxTester',
    userJoined      => 'userJoined',
    testerCompleted => 'testerCompleted',
    groupStarted    => 'groupStarted',
    groupCompleted  => 'groupCompleted',
    groupClosed     => 'groupClosed',
    userRemoved     => 'userRemoved',
    dailyReminder   => 'dailyReminder',
    unknown         => 'unknown',
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.appName,
    this.packageName,
    this.appIconUrl,
    this.groupId,
    this.extraData,
  });

  final String           id;
  final String           title;
  final String           message;
  final NotificationType type;
  final DateTime         createdAt;
  final bool             isRead;
  final String?          appName;
  final String?          packageName;
  final String?          appIconUrl;
  final String?          groupId;
  final Map<String, dynamic>? extraData;

  static String collectionPath() => 'notifications';

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final d  = doc.data() as Map<String, dynamic>;
    final ts = d['createdAt'];

    return AppNotification(
      id:          doc.id,
      title:       d['title']       as String? ?? '',
      message:     d['message']     as String? ?? '',
      type:        NotificationType.fromString(d['type'] as String?),
      appName:     d['appName']     as String?,
      packageName: d['packageName'] as String?,
      appIconUrl:  d['appIcon']     as String?,
      groupId:     d['groupId']     as String?,
      createdAt:   ts is Timestamp ? ts.toDate() : DateTime.now(),
      isRead:      d['isRead']      as bool? ?? false,
      extraData:   d['extraData']   as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title':     title,
    'message':   message,
    'type':      type.firestoreId,
    'createdAt': FieldValue.serverTimestamp(),
    'isRead':    isRead,
    if (appName     != null) 'appName':     appName,
    if (packageName != null) 'packageName': packageName,
    if (appIconUrl  != null) 'appIcon':     appIconUrl,
    if (groupId     != null) 'groupId':     groupId,
    if (extraData   != null) 'extraData':   extraData,
  };

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id:          id,
    title:       title,
    message:     message,
    type:        type,
    appName:     appName,
    packageName: packageName,
    appIconUrl:  appIconUrl,
    groupId:     groupId,
    createdAt:   createdAt,
    isRead:      isRead ?? this.isRead,
    extraData:   extraData,
  );
}