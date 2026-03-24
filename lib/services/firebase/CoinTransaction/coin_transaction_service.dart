import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum CoinTxType {
  publishNormal,
  publishFeatured,
  editApp,
  republishNormal,
  republishFeatured,
  joinGroup,
  accountCreated,
  testingReward,
  adReward,
  boost,
}

extension CoinTxTypeX on CoinTxType {
  String get label => switch (this) {
    CoinTxType.publishNormal     => 'Published App (Normal)',
    CoinTxType.publishFeatured   => 'Published App (Featured)',
    CoinTxType.editApp           => 'Edited App',
    CoinTxType.republishNormal   => 'Republished App (Normal)',
    CoinTxType.republishFeatured => 'Republished App (Featured)',
    CoinTxType.joinGroup         => 'Joined Testing Group',
    CoinTxType.accountCreated    => 'Account Created Bonus',
    CoinTxType.testingReward     => 'Testing Reward',
    CoinTxType.adReward          => 'Ad Reward',
    CoinTxType.boost             => 'App Boosted',
  };

  bool get isExpense => switch (this) {
    CoinTxType.publishNormal     => true,
    CoinTxType.publishFeatured   => true,
    CoinTxType.editApp           => true,
    CoinTxType.republishNormal   => true,
    CoinTxType.republishFeatured => true,
    CoinTxType.joinGroup         => true,
    CoinTxType.boost             => true,
    _                            => false,
  };
}

class CoinTransaction {
  final String     userId;
  final String     username;
  final int        amount;
  final CoinTxType type;
  final String?    appId;
  final String?    note;
  final DateTime   createdAt;

  const CoinTransaction({
    required this.userId,
    required this.username,
    required this.amount,
    required this.type,
    this.appId,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId':    userId,
    'username':  username,
    'amount':    type.isExpense ? -amount : amount,
    'type':      type.name,
    'label':     type.label,
    'appId':     appId,
    'note':      note,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class CoinTransactionService {
  CoinTransactionService._();
  static final CoinTransactionService instance = CoinTransactionService._();

  static const _txCollection    = 'coin_transactions';
  static const _usersCollection = 'users';

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  Future<String> _generateDocId() async {
    final now    = DateTime.now();
    final prefix = '${_twoDigit(now.year % 100)}'
        '${_twoDigit(now.month)}'
        '${_twoDigit(now.day)}';

    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay   = startOfDay.add(const Duration(days: 1));

    try {
      final countSnap = await FirebaseFirestore.instance
          .collection(_txCollection)
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .count()
          .get();

      final sequence = (countSnap.count ?? 0) + 1;
      return '$prefix${sequence.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('[CoinTransactionService] _generateDocId error: $e');
      return '$prefix${now.millisecondsSinceEpoch % 1000000}';
    }
  }

  Future<String?> spendCoins({
    required String     userId,
    required String     username,
    required int        amount,
    required CoinTxType type,
    String? appId,
    String? note,
  }) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(userId);

      final txRef = FirebaseFirestore.instance
          .collection(_txCollection)
          .doc(await _generateDocId());

      final error = await FirebaseFirestore.instance
          .runTransaction<String?>((tx) async {
        final snap    = await tx.get(userRef);
        final current = (snap.data()?['coins'] as num?)?.toInt() ?? 0;

        if (current < amount) {
          return 'Not enough coins. You have $current but need $amount.';
        }

        tx.update(userRef, {'coins': FieldValue.increment(-amount)});
        tx.set(txRef, CoinTransaction(
          userId:    userId,
          username:  username,
          amount:    amount,
          type:      type,
          appId:     appId,
          note:      note,
          createdAt: DateTime.now(),
        ).toMap()
          ..['balanceBefore'] = current
          ..['balanceAfter']  = current - amount);

        return null;
      });

      return error;
    } catch (e) {
      debugPrint('[CoinTransactionService] spendCoins error: $e');
      return 'Failed to process coins. Please try again.';
    }
  }

  Future<void> earnCoins({
    required String     userId,
    required String     username,
    required int        amount,
    required CoinTxType type,
    String? appId,
    String? note,
  }) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(userId);

      final txRef = FirebaseFirestore.instance
          .collection(_txCollection)
          .doc(await _generateDocId());

      final snap    = await FirebaseFirestore.instance.collection(_usersCollection).doc(userId).get();
      final current = (snap.data()?['coins'] as num?)?.toInt() ?? 0;

      final batch = FirebaseFirestore.instance.batch();
      batch.update(userRef, {'coins': FieldValue.increment(amount)});
      batch.set(txRef, CoinTransaction(
        userId:    userId,
        username:  username,
        amount:    amount,
        type:      type,
        appId:     appId,
        note:      note,
        createdAt: DateTime.now(),
      ).toMap()
        ..['balanceBefore'] = current
        ..['balanceAfter']  = current + amount);

      await batch.commit();
    } catch (e) {
      debugPrint('[CoinTransactionService] earnCoins error: $e');
    }
  }

  Future<void> logTransaction({
    required String     userId,
    required String     username,
    required int        amount,
    required CoinTxType type,
    String? appId,
    String? note,
  }) async {
    try {
      final docId   = await _generateDocId();
      final snap    = await FirebaseFirestore.instance.collection(_usersCollection).doc(userId).get();
      final current = (snap.data()?['coins'] as num?)?.toInt() ?? 0;

      await FirebaseFirestore.instance
          .collection(_txCollection)
          .doc(docId)
          .set(CoinTransaction(
        userId:    userId,
        username:  username,
        amount:    amount.abs(),
        type:      type,
        appId:     appId,
        note:      note,
        createdAt: DateTime.now(),
      ).toMap()
        ..['amount']        = amount
        ..['balanceBefore'] = current
        ..['balanceAfter']  = current);
    } catch (e) {
      debugPrint('[CoinTransactionService] logTransaction error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> watchHistory({
    required String userId,
    int limit = 30,
  }) {
    return FirebaseFirestore.instance
        .collection(_txCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}