import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../controllers/info.dart';

class AppItem {
  const AppItem({
    required this.id,
    required this.appName,
    required this.developerName,
    this.appIconUrl,
    required this.coins,
    required this.isBoosted,
    this.boostTimestamp,
    required this.currentTesterCount,
    required this.maxTesters,        // ✅ added
    required this.isFull,            // ✅ added
    required this.ownerUid,
    required this.packageName,
    required this.description,
    required this.createdAt,
  });

  final String    id;
  final String    appName;
  final String    developerName;
  final String?   appIconUrl;
  final int       coins;
  final bool      isBoosted;
  final DateTime? boostTimestamp;
  final int       currentTesterCount;
  final int       maxTesters;        // ✅ added
  final bool      isFull;            // ✅ added
  final String    ownerUid;
  final String    packageName;
  final String    description;
  final DateTime  createdAt;

  factory AppItem.fromDoc(DocumentSnapshot doc) {
    final d         = doc.data() as Map<String, dynamic>;
    final isBoosted = d['isBoosted'] as bool? ?? false;

    final coins = (d['testerReward'] as num?)?.toInt()
        ?? (isBoosted
            ? PublishConstants.boostedTesterReward
            : PublishConstants.normalTesterReward);

    final currentTesterCount = (d['currentTesterCount'] as num?)?.toInt() ?? 0;
    final maxTesters         = (d['maxTesters']         as num?)?.toInt() ?? 0;

    return AppItem(
      id:                 doc.id,
      appName:            d['appName']        as String? ?? '',
      developerName:      d['developerName']  as String? ?? '',
      appIconUrl:         d['iconUrl']        as String?,
      coins:              coins,
      isBoosted:          isBoosted,
      boostTimestamp:     (d['boostTimestamp'] as Timestamp?)?.toDate(),
      currentTesterCount: currentTesterCount,
      maxTesters:         maxTesters,                                    // ✅
      isFull:             (d['isFull'] as bool?) ?? (currentTesterCount >= maxTesters), // ✅ fallback for stale flag
      ownerUid:           d['ownerUid']       as String? ?? '',
      packageName:        d['packageName']    as String? ?? '',
      description:        d['description']    as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Repository
// ─────────────────────────────────────────────────────────────────────────────

class AppsRepository {
  AppsRepository._();
  static final instance = AppsRepository._();

  final _db = FirebaseFirestore.instance;

  Stream<List<AppItem>> watchAvailableApps() {
    return _db
        .collection('apps')
        .where('status', isEqualTo: 'active')
        .where('isFull', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map(AppItem.fromDoc).toList());
  }

  Stream<List<AppItem>> watchUserApps(String uid) {
    return _db
        .collection('apps')
        .where('ownerUid', isEqualTo: uid)
        .where('status',   isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs.map(AppItem.fromDoc).toList());
  }
}