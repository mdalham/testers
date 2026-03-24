import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupStatus { forming, starting, active, completed }

class AppDetails {
  final String  appName;
  final String  developerName;
  final String  packageName;
  final String  iconUrl;
  final String  description;
  final String  appType;
  final String  priceType;
  final String? redeemCode;

  const AppDetails({
    required this.appName,
    required this.developerName,
    required this.packageName,
    required this.iconUrl,
    required this.description,
    this.appType    = 'App',
    this.priceType  = 'Free',
    this.redeemCode,
  });

  factory AppDetails.fromMap(Map<String, dynamic> m) => AppDetails(
    appName:       m['appName']       as String? ?? '',
    developerName: m['developerName'] as String? ?? '',
    packageName:   m['packageName']   as String? ?? '',
    iconUrl:       m['iconUrl']       as String? ?? '',
    description:   m['description']   as String? ?? '',
    appType:       m['appType']       as String? ?? 'App',
    priceType:     m['priceType']     as String? ?? 'Free',
    redeemCode:    m['redeemCode']    as String?,
  );

  Map<String, dynamic> toMap() => {
    'appName':       appName,
    'developerName': developerName,
    'packageName':   packageName,
    'iconUrl':       iconUrl,
    'description':   description,
    'appType':       appType,
    'priceType':     priceType,
    if (redeemCode != null && redeemCode!.isNotEmpty) 'redeemCode': redeemCode,
  };
}

class GroupMember {
  final String uid;
  final String username;

  const GroupMember({
    required this.uid,
    required this.username,
  });

  factory GroupMember.fromMap(Map<String, dynamic> m) => GroupMember(
    uid:      m['uid']      as String? ?? '',
    username: m['username'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'uid':      uid,
    'username': username,
  };
}

class DailyProof {
  final String   uid;
  final String   targetUserId;
  final String   screenshotUrl;
  final DateTime uploadedAt;

  const DailyProof({
    required this.uid,
    required this.targetUserId,
    required this.screenshotUrl,
    required this.uploadedAt,
  });

  factory DailyProof.fromMap(Map<String, dynamic> m) => DailyProof(
    uid:           m['uid']           as String? ?? '',
    targetUserId:  m['targetUserId']  as String? ?? '',
    screenshotUrl: m['screenshotUrl'] as String? ?? '',
    uploadedAt:    (m['uploadedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'uid':           uid,
    'targetUserId':  targetUserId,
    'screenshotUrl': screenshotUrl,
    'uploadedAt':    Timestamp.fromDate(uploadedAt),
  };
}

class GroupModel {
  final String                  id;
  final String                  uniqueId;
  final GroupStatus             status;
  final List<GroupMember>       members;
  final Map<String, AppDetails> apps;
  final DateTime?               taskStartDate;
  final DateTime                createdAt;
  final int                     maxMembers;

  const GroupModel({
    required this.id,
    required this.uniqueId,
    required this.status,
    required this.members,
    required this.apps,
    this.taskStartDate,
    required this.createdAt,
    this.maxMembers = 15,
  });

  bool hasJoined(String uid) => members.any((m) => m.uid == uid);

  int get slotsRemaining => maxMembers - members.length;

  int get currentDay {
    if (taskStartDate == null) return 0;
    return DateTime.now().difference(taskStartDate!).inDays + 1;
  }

  int get daysRemaining {
    if (taskStartDate == null) return 14;
    final elapsed = DateTime.now().difference(taskStartDate!).inDays;
    return (14 - elapsed).clamp(0, 14);
  }

  double get fillProgress => members.length / maxMembers;

  factory GroupModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final members = (d['members'] as List<dynamic>? ?? [])
        .map((m) => GroupMember.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();

    final apps = (d['apps'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
          k, AppDetails.fromMap(Map<String, dynamic>.from(v as Map))),
    );

    return GroupModel(
      id:       doc.id,
      uniqueId: d['uniqueId'] as String? ?? '',
      status:   _parseStatus(d['status'] as String?),
      members:  members,
      apps:     apps,
      taskStartDate: d['taskStartDate'] != null
          ? (d['taskStartDate'] as Timestamp).toDate()
          : null,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      maxMembers: (d['maxMembers'] as num?)?.toInt() ?? 15,
    );
  }

  Map<String, dynamic> toMap() => {
    'uniqueId':      uniqueId,
    'status':        status.name,
    'members':       members.map((m) => m.toMap()).toList(),
    'apps':          apps.map((k, v) => MapEntry(k, v.toMap())),
    'taskStartDate': taskStartDate != null
        ? Timestamp.fromDate(taskStartDate!)
        : null,
    'createdAt':  Timestamp.fromDate(createdAt),
    'maxMembers': maxMembers,
  };

  static GroupStatus _parseStatus(String? s) => switch (s) {
    'forming'   => GroupStatus.forming,
    'starting'  => GroupStatus.starting,
    'active'    => GroupStatus.active,
    'completed' => GroupStatus.completed,
    _           => GroupStatus.forming,
  };
}