import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_model.dart';

enum TaskApproval { waitingApproval, retestRequired }


class TodayTask {
  TodayTask({
    required this.taskId,
    required this.testerUid,
    required this.testerName,
    required this.appDetails,
    required this.approval,
    required this.submittedAt,
    this.screenshotUrl,
    this.issueType,
    this.reportText,
  });

  final String       taskId;
  final String       testerUid;
  final String       testerName;
  final AppDetails   appDetails;
  final TaskApproval approval;
  final DateTime     submittedAt;
  final String?      screenshotUrl;
  final String?      issueType;
  final String?      reportText;

  factory TodayTask.fromMap(
      String taskId,
      Map<String, dynamic> map,
      AppDetails appDetails,
      ) {
    final raw = map['approvalStatus'] as String? ?? 'waitingApproval';
    return TodayTask(
      taskId:        taskId,
      testerUid:     map['uid']           as String? ?? '',
      testerName:    map['userName']      as String? ?? 'Unknown',
      appDetails:    appDetails,
      approval:      raw == 'retestRequired'
          ? TaskApproval.retestRequired
          : TaskApproval.waitingApproval,
      submittedAt:   (map['submittedAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
      screenshotUrl: map['screenshotUrl'] as String?,
      issueType:     map['issueType']     as String?,
      reportText:    map['reportText']    as String?,
    );
  }
}