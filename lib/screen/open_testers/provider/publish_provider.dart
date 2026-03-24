import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../controllers/info.dart';
import '../../Notification/service/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Enums
// ─────────────────────────────────────────────────────────────────────────────

// PublishType kept as enum in case future types are added,
// but maxTesters / republishCost are now dynamic — no extension needed.
enum PublishType { normal }

enum PublishState { idle, uploading, publishing, boosting, success, error }

enum TestingPhase { closed, open, production }

extension TestingPhaseX on TestingPhase {
  String get label {
    switch (this) {
      case TestingPhase.closed:
        return 'Closed Testing';
      case TestingPhase.open:
        return 'Open Testing';
      case TestingPhase.production:
        return 'Production';
    }
  }

  String get description {
    switch (this) {
      case TestingPhase.closed:
        return 'Testers may need to join a testing group.';
      case TestingPhase.open:
        return 'Anyone can test your app.';
      case TestingPhase.production:
        return 'App is ready for production testers.';
    }
  }
}

enum AppTypeOption { app, game }

extension AppTypeOptionX on AppTypeOption {
  String get label => this == AppTypeOption.app ? 'App' : 'Game';
}

enum PriceTypeOption { free, paid }

extension PriceTypeOptionX on PriceTypeOption {
  String get label => this == PriceTypeOption.free ? 'Free' : 'Paid';
}

enum TestingDuration { days14, remaining }

extension TestingDurationX on TestingDuration {
  String get label {
    switch (this) {
      case TestingDuration.days14:
        return '14 Days';
      case TestingDuration.remaining:
        return 'Remaining Days';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────

const List<int> kTesterOptions = [12, 25, 50, 100];
const int kCoinsPerTester = 10;

// ─────────────────────────────────────────────────────────────────────────────
//  PublishProvider
// ─────────────────────────────────────────────────────────────────────────────

class PublishProvider extends ChangeNotifier {
  PublishProvider({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // ── Core state ─────────────────────────────────────────────────────────────
  PublishState _state = PublishState.idle;
  String? _error;
  String? _uploadedIconUrl;
  String? _lastPublishedDocId;

  PublishState get state => _state;
  String? get error => _error;
  String? get uploadedIconUrl => _uploadedIconUrl;
  String? get lastPublishedDocId => _lastPublishedDocId;
  bool get isLoading =>
      _state == PublishState.uploading ||
      _state == PublishState.publishing ||
      _state == PublishState.boosting;

  void setIconUrl(String url) {
    _uploadedIconUrl = url;
    notifyListeners();
  }

  void clearIconUrl() {
    _uploadedIconUrl = null;
    notifyListeners();
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────
  TestingPhase _testingPhase = TestingPhase.open;
  TestingDuration _testingDuration = TestingDuration.days14;
  int _testingDurationDays = 7;
  bool _testingDurationEnabled = false;
  AppTypeOption _appType = AppTypeOption.app;
  PriceTypeOption _priceType = PriceTypeOption.free;
  bool _specialLoginEnabled = false;
  String _loginUsername = '';
  String _loginPassword = '';

  TestingPhase get testingPhase => _testingPhase;
  TestingDuration get testingDuration => _testingDuration;
  int get testingDurationDays => _testingDurationDays;
  bool get testingDurationEnabled => _testingDurationEnabled;
  AppTypeOption get appType => _appType;
  PriceTypeOption get priceType => _priceType;
  bool get specialLoginEnabled => _specialLoginEnabled;
  String get loginUsername => _loginUsername;
  String get loginPassword => _loginPassword;

  void setTestingPhase(TestingPhase v) {
    _testingPhase = v;
    notifyListeners();
  }

  void setTestingDuration(TestingDuration v) {
    _testingDuration = v;
    notifyListeners();
  }

  void setTestingDurationDays(int v) {
    _testingDurationDays = v;
    notifyListeners();
  }

  void setTestingDurationEnabled(bool v) {
    _testingDurationEnabled = v;
    notifyListeners();
  }

  void setAppType(AppTypeOption v) {
    _appType = v;
    notifyListeners();
  }

  void setPriceType(PriceTypeOption v) {
    _priceType = v;
    notifyListeners();
  }

  void setSpecialLoginEnabled(bool v) {
    _specialLoginEnabled = v;
    notifyListeners();
  }

  void setLoginUsername(String v) {
    _loginUsername = v;
    notifyListeners();
  }

  void setLoginPassword(String v) {
    _loginPassword = v;
    notifyListeners();
  }

  bool get isStep1Valid {
    if (_specialLoginEnabled) {
      return _loginUsername.trim().isNotEmpty &&
          _loginPassword.trim().isNotEmpty;
    }
    return true;
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────────
  bool _agreementChecked = false;
  int _joinedTesterCount = 0;
  bool _testerStepDone = false;
  bool _worldwideStepDone = false;

  bool get agreementChecked => _agreementChecked;
  int get joinedTesterCount => _joinedTesterCount;
  bool get testerStepDone => _testerStepDone;
  bool get worldwideStepDone => _worldwideStepDone;

  void setAgreementChecked(bool v) {
    _agreementChecked = v;
    notifyListeners();
  }

  void setTesterStepDone(bool v) {
    _testerStepDone = v;
    notifyListeners();
  }

  void setWorldwideStepDone(bool v) {
    _worldwideStepDone = v;
    notifyListeners();
  }

  bool get isStep2Valid {
    if (!_agreementChecked) return false;
    if (_testingPhase == TestingPhase.closed && !_testerStepDone) return false;
    return _worldwideStepDone;
  }

  Future<void> loadJoinedTesterCount(String groupId) async {
    try {
      final snap = await _db.collection('testing_groups').doc(groupId).get();
      _joinedTesterCount = (snap.data()?['memberCount'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[PublishProvider] loadJoinedTesterCount error: $e');
    }
  }

  // ── Step 3 ─────────────────────────────────────────────────────────────────
  String _step3AppName = '';
  String _step3Developer = '';
  String _step3PackageName = '';
  String _step3Description = '';
  File? _step3PickedIconFile;

  String get step3AppName => _step3AppName;
  String get step3Developer => _step3Developer;
  String get step3PackageName => _step3PackageName;
  String get step3Description => _step3Description;
  File? get step3PickedIcon => _step3PickedIconFile;

  void setStep3AppName(String v) {
    _step3AppName = v;
    notifyListeners();
  }

  void setStep3Developer(String v) {
    _step3Developer = v;
    notifyListeners();
  }

  void setStep3PackageName(String v) {
    _step3PackageName = v;
    notifyListeners();
  }

  void setStep3Description(String v) {
    _step3Description = v;
    notifyListeners();
  }

  void setStep3PickedIcon(File? f) {
    _step3PickedIconFile = f;
    notifyListeners();
  }

  bool get isStep3Valid =>
      _step3AppName.trim().isNotEmpty &&
      _step3Developer.trim().isNotEmpty &&
      _step3PackageName.trim().isNotEmpty &&
      (_uploadedIconUrl != null && _uploadedIconUrl!.isNotEmpty);

  // ── Step 4 ─────────────────────────────────────────────────────────────────
  int _selectedTesterCount = kTesterOptions.first;

  int get selectedTesterCount => _selectedTesterCount;
  int get rewardPerTester => kCoinsPerTester;
  int get totalCoinsRequired => _selectedTesterCount * kCoinsPerTester;
  bool get isStep4Valid => true;

  void setSelectedTesterCount(int v) {
    assert(kTesterOptions.contains(v), 'Invalid tester count: $v');
    _selectedTesterCount = v;
    notifyListeners();
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return isStep1Valid;
      case 1:
        return isStep2Valid;
      case 2:
        return isStep3Valid;
      case 3:
        return isStep4Valid;
      default:
        return true;
    }
  }

  // ── Duration reward fields ─────────────────────────────────────────────────
  Map<String, dynamic> get _durationRewardFields => {
    'testingDurationEnabled': _testingDurationEnabled,
    'testingDuration': _testingDuration == TestingDuration.days14
        ? 'days14'
        : 'remaining',
    'testingDurationDays':
        _testingDurationEnabled && _testingDuration == TestingDuration.days14
        ? _testingDurationDays
        : null,
  };

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  Future<String> _generateAppDocId() async {
    final now = DateTime.now();
    final prefix =
        'app'
        '${_twoDigit(now.year % 100)}'
        '${_twoDigit(now.month)}'
        '${_twoDigit(now.day)}';
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    try {
      final countSnap = await _db
          .collection('apps')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .count()
          .get();
      final sequence = (countSnap.count ?? 0) + 1;
      return '$prefix${sequence.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('[PublishProvider] _generateAppDocId error: $e');
      return '$prefix${now.millisecondsSinceEpoch % 1000000}';
    }
  }

  Future<String?> _getUsernameForUid(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['username'] as String?;
    } catch (e) {
      debugPrint('[PublishProvider] _getUsernameForUid error: $e');
      return null;
    }
  }

  /// Fetches the stored maxTesters for an existing app doc.
  /// Used by the UI to compute republish cost before calling updateApp().
  Future<int?> fetchStoredMaxTesters(String docId) async {
    try {
      final doc = await _db.collection('apps').doc(docId).get();
      return (doc.data()?['maxTesters'] as num?)?.toInt();
    } catch (e) {
      debugPrint('[PublishProvider] fetchStoredMaxTesters error: $e');
      return null;
    }
  }

  // ── Publish ────────────────────────────────────────────────────────────────

  Future<bool> publishApp({
    required String appName,
    required String developerName,
    required String packageName,
    required String iconUrl,
    required int coinCost,
    String? description,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _setError('User not authenticated');
      return false;
    }
    _setState(PublishState.publishing);
    try {
      final existing = await _db
          .collection('apps')
          .where('packageName', isEqualTo: packageName)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        final existingData = existing.docs.first.data();
        final isOwner = existingData['ownerUid'] == uid;
        throw _DuplicatePackageException(
          isOwner
              ? 'You already have an active listing with package "$packageName". '
                    'Wait for it to expire or deactivate it first.'
              : 'An active listing with package "$packageName" already exists.',
        );
      }

      final userRef = _db.collection('users').doc(uid);
      final appId = await _generateAppDocId();
      final appRef = _db.collection('apps').doc(appId);

      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(userRef);
        if (!userSnap.exists) throw Exception('User document not found');
        final currentCoins = (userSnap.data()?['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < coinCost) {
          throw _InsufficientCoinsException(
            'You need $coinCost coins but only have $currentCoins',
          );
        }
        txn.update(userRef, {'coins': FieldValue.increment(-coinCost)});
        txn.set(appRef, {
          'appId': appId,
          'appName': appName,
          'developerName': developerName,
          'packageName': packageName,
          'description': description ?? '',
          'iconUrl': iconUrl,
          'ownerUid': uid,
          'publishType': 'normal',
          'coinsUsed': coinCost,
          'createdAt': FieldValue.serverTimestamp(),
          'maxTesters': _selectedTesterCount,
          'currentTesterCount': 0,
          'isFull': false,
          'isBoosted': false,
          'boostTimestamp': null,
          'status': 'active',
          'testerReward': PublishConstants.normalTesterReward,

          // ── Step 1 — App Setup ─────────────────────────────────────────────────
          'testingPhase':
              _testingPhase.name, // 'open' | 'closed' | 'production'
          'appType': _appType.label, // 'App' | 'Game'
          'priceType': _priceType.label, // 'Free' | 'Paid'
          'specialLogin': _specialLoginEnabled,
          'loginUsername': _specialLoginEnabled ? _loginUsername.trim() : null,
          'loginPassword': _specialLoginEnabled ? _loginPassword.trim() : null,

          // ── Step 1 — Testing Duration ──────────────────────────────────────────
          ..._durationRewardFields,

          // ── Step 2 — Terms & Availability ─────────────────────────────────────
          'agreementChecked': _agreementChecked,
          'testerStepDone': _testingPhase == TestingPhase.closed
              ? _testerStepDone
              : null, // null if not closed phase
          'worldwideStepDone': _worldwideStepDone,
        });
      });

      _lastPublishedDocId = appId;
      notifyListeners();

      final username = await _getUsernameForUid(uid);
      if (username != null && username.isNotEmpty) {
        await NotificationService.instance.onAppPublished(
          uid: uid,
          username: username,
          appName: appName,
          packageName: packageName,
          appIconUrl: iconUrl,
        );
      }
      _setState(PublishState.success);
      return true;
    } on _DuplicatePackageException catch (e) {
      _setError(e.message);
      return false;
    } on _InsufficientCoinsException catch (e) {
      _setError(e.message);
      return false;
    } on FirebaseException catch (e) {
      _setError('Firestore error: ${e.message ?? e.code}');
      return false;
    } catch (e) {
      _setError('Unexpected error: $e');
      return false;
    }
  }

  // ── Boost ──────────────────────────────────────────────────────────────────

  Future<BoostResult> boostApp(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return BoostResult.failure('User not authenticated');
    _setState(PublishState.boosting);
    try {
      final userRef = _db.collection('users').doc(uid);
      final appRef = _db.collection('apps').doc(docId);
      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(userRef);
        final appSnap = await txn.get(appRef);
        if (!userSnap.exists) throw Exception('User document not found');
        if (!appSnap.exists) throw Exception('App not found');
        final currentCoins = (userSnap.data()?['coins'] as num?)?.toInt() ?? 0;
        final cost = PublishConstants.boostCoinCost; // ✅ cost defined here
        if (currentCoins < cost) {
          throw _InsufficientCoinsException(
            'You need $cost coins to boost but only have $currentCoins.',
          );
        }
        txn.update(userRef, {'coins': FieldValue.increment(-cost)});
        txn.update(appRef, {
          'isBoosted': true,
          'boostTimestamp': FieldValue.serverTimestamp(),
          'testerReward': PublishConstants.boostedTesterReward, // ✅ 30 coins
        });
      });
      _setState(PublishState.success);
      return BoostResult.success();
    } on _InsufficientCoinsException catch (e) {
      _setState(PublishState.idle);
      return BoostResult.insufficientCoins(e.message);
    } on FirebaseException catch (e) {
      _setError('Firestore error: ${e.message ?? e.code}');
      return BoostResult.failure('Firestore error: ${e.message ?? e.code}');
    } catch (e) {
      _setError('Unexpected error: $e');
      return BoostResult.failure('Unexpected error: $e');
    }
  }

  // ── Update / Republish ─────────────────────────────────────────────────────
  //
  // coinCost is always passed in from the UI layer (which has DiscountProvider).
  // For edit:      coinCost = PublishConstants.editCoinCost
  // For republish: coinCost = discount.discountedCost(storedMaxTesters * kCoinsPerTester)

  Future<bool> updateApp({
    required String docId,
    required String appName,
    required String developerName,
    required String packageName,
    required String iconUrl,
    String? description,
    required bool isRepublish,
    required int coinCost, // ✅ always provided by caller
    int? newMaxTesters, // ✅ only used when isRepublish = true
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _setError('User not authenticated');
      return false;
    }
    _setState(PublishState.publishing);
    try {
      final userRef = _db.collection('users').doc(uid);
      final appRef = _db.collection('apps').doc(docId);
      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(userRef);
        if (!userSnap.exists) throw Exception('User document not found');
        final currentCoins = (userSnap.data()?['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < coinCost) {
          throw _InsufficientCoinsException(
            'You need $coinCost coins but only have $currentCoins.',
          );
        }
        txn.update(userRef, {'coins': FieldValue.increment(-coinCost)});
        final updates = <String, dynamic>{
          'appName': appName,
          'developerName': developerName,
          'packageName': packageName,
          'description': description ?? '',
          'iconUrl': iconUrl,
          'updatedAt': FieldValue.serverTimestamp(),

          // ── Step 1 fields updated on edit ─────────────────────────────────────
          'testingPhase': _testingPhase.name,
          'appType': _appType.label,
          'priceType': _priceType.label,
          'specialLogin': _specialLoginEnabled,
          'loginUsername': _specialLoginEnabled ? _loginUsername.trim() : null,
          'loginPassword': _specialLoginEnabled ? _loginPassword.trim() : null,

          ..._durationRewardFields,
        };

        if (isRepublish) {
          updates['currentTesterCount'] = 0;
          if (newMaxTesters != null) updates['maxTesters'] = newMaxTesters;
          updates['isFull'] = false;
          updates['isBoosted'] = false;
          updates['boostTimestamp'] = null;
          updates['testerReward'] = PublishConstants.normalTesterReward;
          updates['relistedAt'] = FieldValue.serverTimestamp();
          // ── re-save step 2 state on republish ─────────────────────────────────
          updates['agreementChecked'] = _agreementChecked;
          updates['worldwideStepDone'] = _worldwideStepDone;
          updates['testerStepDone'] = _testingPhase == TestingPhase.closed
              ? _testerStepDone
              : null;
        }
        txn.update(appRef, updates);
      });
      _setState(PublishState.success);
      return true;
    } on _InsufficientCoinsException catch (e) {
      _setError(e.message);
      return false;
    } on FirebaseException catch (e) {
      _setError('Firestore error: ${e.message ?? e.code}');
      return false;
    } catch (e) {
      _setError('Unexpected error: $e');
      return false;
    }
  }

  Future<JoinResult> joinAppAsTester(String appId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return JoinResult.failure('User not authenticated');
    String? ownerUid0;
    String? appName;
    String? packageName;
    String? appIconUrl;
    int? totalTesters;
    bool maxTestersReached = false;
    try {
      final appRef = _db.collection('apps').doc(appId);
      final testerRef = appRef.collection('testers').doc(uid);
      final userTestedRef = _db.collection('user_tested_apps').doc(uid);
      await _db.runTransaction((txn) async {
        final appSnap = await txn.get(appRef);
        final testerSnap = await txn.get(testerRef);
        if (!appSnap.exists) throw Exception('App not found');
        final data = appSnap.data()!;
        final ownerUid = data['ownerUid'] as String?;
        final maxTesters = (data['maxTesters'] as num?)?.toInt() ?? 0;
        final current = (data['currentTesterCount'] as num?)?.toInt() ?? 0;
        final status = data['status'] as String? ?? 'active';
        final publishType = data['publishType'] as String? ?? 'normal';
        final relistedAt = data['relistedAt'] as Timestamp?;
        final isFull = data['isFull'] as bool? ?? false;

        if (!isFull && current >= maxTesters) {
          txn.update(appRef, {'isFull': true});
          throw _JoinException('Tester limit reached ($current/$maxTesters)');
        }

        if (ownerUid == uid) {
          throw _JoinException('You cannot test your own app');
        }
        if (status != 'active') {
          throw _JoinException('This app is no longer active');
        }
        if (testerSnap.exists) {
          final joinedAt = testerSnap.data()?['joinedAt'] as Timestamp?;
          final canRetry =
              relistedAt != null &&
              joinedAt != null &&
              relistedAt.compareTo(joinedAt) > 0;
          if (!canRetry) {
            throw _JoinException('You are already testing this app');
          }
        } else {
          if (current >= maxTesters) {
            final isFull = data['isFull'] as bool? ?? false;
            if (!isFull) {
              txn.update(appRef, {'isFull': true});
            }
            throw _JoinException('Tester limit reached ($current/$maxTesters)');
          }
        }
        final now = Timestamp.now();
        final newCount = testerSnap.exists ? current : current + 1;
        final willBeFull = newCount >= maxTesters;
        txn.set(testerRef, {'testerUid': uid, 'joinedAt': now});
        if (!testerSnap.exists) {
          txn.update(appRef, {
            'currentTesterCount': FieldValue.increment(1),
            'isFull': willBeFull,
          });
        }
        txn.set(userTestedRef, {
          'userUid': uid,
          'testedApps': FieldValue.arrayUnion([
            {
              'appId':        appId,
              'joinedAt':     now,
              'publishType':  publishType,
              'appName':      data['appName']      as String? ?? '',
              'appIconUrl':   data['iconUrl']      as String?,
              'coinsEarned':  (data['testerReward'] as num?)?.toInt() ?? 0,
            }
          ]),
        }, SetOptions(merge: true));
        if (willBeFull) {
          ownerUid0 = ownerUid;
          appName = data['appName'] as String?;
          packageName = data['packageName'] as String?;
          appIconUrl = data['iconUrl'] as String?;
          totalTesters = newCount;
          maxTestersReached = true;
        }
      });
      if (maxTestersReached && ownerUid0 != null) {
        final ownerUsername = await _getUsernameForUid(ownerUid0!);
        if (ownerUsername != null && ownerUsername.isNotEmpty) {
          await NotificationService.instance.onMaxTestersReached(
            ownerUid: ownerUid0!,
            ownerUsername: ownerUsername,
            appName: appName ?? 'Your App',
            packageName: packageName ?? '',
            appIconUrl: appIconUrl,
            totalTesters: totalTesters ?? 0,
          );
        }
      }
      return JoinResult.success();
    } on _JoinException catch (e) {
      return JoinResult.failure(e.message);
    } on FirebaseException catch (e) {
      return JoinResult.failure('Firestore error: ${e.message ?? e.code}');
    } catch (e) {
      return JoinResult.failure('Unexpected error: $e');
    }
  }

  void _setState(PublishState s) {
    _state = s;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _state = PublishState.error;
    _error = msg;
    notifyListeners();
  }

  void reset() {
    _state = PublishState.idle;
    _error = null;
    _uploadedIconUrl = null;
    _lastPublishedDocId = null;
    _testingPhase = TestingPhase.open;
    _testingDuration = TestingDuration.days14;
    _testingDurationDays = 7;
    _testingDurationEnabled = false;
    _appType = AppTypeOption.app;
    _priceType = PriceTypeOption.free;
    _specialLoginEnabled = false;
    _loginUsername = '';
    _loginPassword = '';
    _agreementChecked = false;
    _joinedTesterCount = 0;
    _testerStepDone = false;
    _worldwideStepDone = false;
    _step3AppName = '';
    _step3Developer = '';
    _step3PackageName = '';
    _step3Description = '';
    _step3PickedIconFile = null;
    _selectedTesterCount = kTesterOptions.first;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Result types
// ─────────────────────────────────────────────────────────────────────────────

class JoinResult {
  const JoinResult._({required this.success, this.errorMessage});
  final bool success;
  final String? errorMessage;
  factory JoinResult.success() => const JoinResult._(success: true);
  factory JoinResult.failure(String msg) =>
      JoinResult._(success: false, errorMessage: msg);
}

enum BoostResultType { success, insufficientCoins, failure }

class BoostResult {
  const BoostResult._({required this.type, this.errorMessage});
  final BoostResultType type;
  final String? errorMessage;

  bool get isSuccess => type == BoostResultType.success;
  bool get isInsufficientCoins => type == BoostResultType.insufficientCoins;

  factory BoostResult.success() =>
      const BoostResult._(type: BoostResultType.success);
  factory BoostResult.insufficientCoins(String msg) =>
      BoostResult._(type: BoostResultType.insufficientCoins, errorMessage: msg);
  factory BoostResult.failure(String msg) =>
      BoostResult._(type: BoostResultType.failure, errorMessage: msg);
}

class _InsufficientCoinsException implements Exception {
  const _InsufficientCoinsException(this.message);
  final String message;
}

class _DuplicatePackageException implements Exception {
  const _DuplicatePackageException(this.message);
  final String message;
}

class _JoinException implements Exception {
  const _JoinException(this.message);
  final String message;
}
