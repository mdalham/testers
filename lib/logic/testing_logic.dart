import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../service/firebase/CoinTransaction/coin_transaction_service.dart';
import '../../widget/snackbar/custom_snackbar.dart';
import '../screen/recharge/service/ads/unity/unity_ads_service.dart';

class TestingLogic {
  TestingLogic._();
  static final TestingLogic instance = TestingLogic._();

  Future<void> openPlayStore({required String packageName}) async {
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri    = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> tryOpenApp({
    required BuildContext context,
    required String packageName,
  }) async {
    try {
      final isInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: packageName,
      );
      if (isInstalled) {
        await LaunchApp.openApp(androidPackageName: packageName, openStore: false);
        return true;
      } else {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            title:       'App Not Installed',
            message:     'Please install the app from Play Store first.',
            type:        SnackBarType.error,
            actionLabel: 'Install',
            onAction:    () => openPlayStore(packageName: packageName),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('TestingLogic.tryOpenApp ERROR: $e');
      try {
        final intentUri = Uri.parse('market://details?id=$packageName');
        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        if (context.mounted) {
          CustomSnackbar.show(
            context,
            title:   'Launch Failed',
            message: 'Could not find the app on this device.',
            type:    SnackBarType.error,
          );
        }
      }
      return false;
    }
  }

  Future<void> openPlayStoreReview({required String packageName}) async {
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri    = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Claim — shows rewarded ad then runs the Firestore transaction
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> claimCoins({
    required BuildContext context,
    required String       appId,
    required String       appName,
    required String       packageName,
    required int          rewardCoins,
    required String       username,
    required String       screenshotUrl,   // ← NEW
    String?               issueType,       // ← NEW (optional)
    String?               feedbackNote,    // ← NEW (optional)
    required VoidCallback onClaimed,
    required VoidCallback onLoadingChanged,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await UnityAdsService.instance.showRewardedAd(
      onCompleted: () async {
        await runClaimTransaction(
          context:          context,
          appId:            appId,
          appName:          appName,
          rewardCoins:      rewardCoins,
          username:         username,
          screenshotUrl:    screenshotUrl,
          issueType:        issueType,
          feedbackNote:     feedbackNote,
          onClaimed:        onClaimed,
          onLoadingChanged: onLoadingChanged,
        );
      },
      onFailed: () {
        if (!context.mounted) return;
        onLoadingChanged();
        CustomSnackbar.show(
          context,
          title:   'Ad Unavailable',
          message: 'No ad available right now. Please try again shortly.',
          type:    SnackBarType.error,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core Firestore transaction
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> runClaimTransaction({
    required BuildContext context,
    required String       appId,
    required String       appName,
    required int          rewardCoins,
    required String       username,
    required String       screenshotUrl,   // ← NEW
    String?               issueType,       // ← NEW
    String?               feedbackNote,    // ← NEW
    required VoidCallback onClaimed,
    required VoidCallback onLoadingChanged,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final db            = FirebaseFirestore.instance;
    final userRef       = db.collection('users').doc(uid);
    final userTestedRef = db.collection('user_tested_apps').doc(uid);
    final appRef        = db.collection('apps').doc(appId);

    try {
      await db.runTransaction((txn) async {
        final userTestedSnap = await txn.get(userTestedRef);
        final appSnap        = await txn.get(appRef);

        // ── duplicate-claim guard ──────────────────────────────────────────
        if (userTestedSnap.exists) {
          final testedApps     = (userTestedSnap.data()?['testedApps'] as List<dynamic>?) ?? [];
          final alreadyClaimed = testedApps
              .whereType<Map<String, dynamic>>()
              .any((e) => e['appId'] == appId);
          if (alreadyClaimed) {
            throw _AlreadyClaimedException(
                'You have already claimed coins for this app.');
          }
        }

        // ── credit coins ───────────────────────────────────────────────────
        txn.update(userRef, {'coins': FieldValue.increment(rewardCoins)});

        // ── record tested-app entry (with screenshot + feedback) ───────────
        txn.set(userTestedRef, {
          'username': username,
          'userUid':  uid,
          'testedApps': FieldValue.arrayUnion([
            {
              'appId':        appId,
              'appName':      appName,
              'coinsEarned':  rewardCoins,
              'screenshotUrl': screenshotUrl,                     // ← saved
              if (issueType   != null && issueType.isNotEmpty)
                'issueType':  issueType,                          // ← saved
              if (feedbackNote != null && feedbackNote.isNotEmpty)
                'feedbackNote': feedbackNote,                     // ← saved
              'claimedAt':    Timestamp.now(),
            },
          ]),
        }, SetOptions(merge: true));

        // ── update tester count on the app document ────────────────────────
        final maxTesters = (appSnap.data()?['maxTesters']         as num?)?.toInt() ?? 12;
        final current    = (appSnap.data()?['currentTesterCount'] as num?)?.toInt() ?? 0;
        final newCount   = current + 1;

        txn.update(appRef, {
          'currentTesterCount': FieldValue.increment(1),
          if (newCount >= maxTesters) 'isFull': true,
        });
      });

      if (!context.mounted) return;
      onClaimed();

      await CoinTransactionService.instance.logTransaction(
        userId:   uid,
        username: username,
        amount:   rewardCoins,
        type:     CoinTxType.testingReward,
        appId:    appId,
        note:     'Tested $appName',
      );

      if (context.mounted) {
        Navigator.pop(context);
        CustomSnackbar.show(
          context,
          title:   'Coins Claimed!',
          message: '+$rewardCoins coins added to your wallet.',
          type:    SnackBarType.success,
        );
      }
    } on _AlreadyClaimedException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      CustomSnackbar.show(
        context,
        title:   'Already Claimed',
        message: e.message,
        type:    SnackBarType.error,
      );
    } on FirebaseException catch (_) {
      if (!context.mounted) return;
      CustomSnackbar.show(
        context,
        title:   'Permission Error',
        message: 'Firebase permission denied.',
        type:    SnackBarType.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      CustomSnackbar.show(
        context,
        title:   'Error',
        message: 'An unexpected error occurred.',
        type:    SnackBarType.error,
      );
    } finally {
      onLoadingChanged();
    }
  }
}

class _AlreadyClaimedException implements Exception {
  const _AlreadyClaimedException(this.message);
  final String message;
}