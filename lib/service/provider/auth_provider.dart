import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../controllers/info.dart';
import '../../controllers/info.dart';

enum AuthState { idle, loading, authenticated, unauthenticated, error }

enum UsernameStatus { available, taken, invalid }

typedef SnackbarCallback = void Function(String title, String message);

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth      _auth         = FirebaseAuth.instance;
  final FirebaseFirestore _firestore    = FirebaseFirestore.instance;
  final GoogleSignIn      _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;
  bool _isRegistering     = false;

  SnackbarCallback? _errorCallback;

  void setErrorCallback(SnackbarCallback cb) => _errorCallback = cb;
  void clearErrorCallback()                  => _errorCallback = null;

  AuthState             _state        = AuthState.idle;
  User?                 _firebaseUser;
  Map<String, dynamic>? _userData;
  String?               _errorMessage;

  AuthState             get state           => _state;
  User?                 get firebaseUser    => _firebaseUser;
  Map<String, dynamic>? get userData        => _userData;
  String?               get errorMessage    => _errorMessage;
  bool                  get isAuthenticated => _state == AuthState.authenticated;
  bool                  get isLoading       => _state == AuthState.loading;

  String get displayName => _userData?['displayName'] ?? _firebaseUser?.displayName ?? '';
  String get email       => _userData?['email']       ?? _firebaseUser?.email       ?? '';
  String get username    => _userData?['username']    ?? '';
  String get photoURL    => _userData?['photoURL']    ?? _firebaseUser?.photoURL    ?? '';
  int    get coins       => (_userData?['coins'] ?? 0) as int;
  String get uid         => _firebaseUser?.uid ?? '';

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _initGoogle();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DEVICE ID
  // ══════════════════════════════════════════════════════════════════════════

  Future<String> _getDeviceId() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) return '';
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = await info.androidInfo;
        return android.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor ?? '';
      }
    } catch (e) {
      debugPrint('AuthProvider._getDeviceId ERROR: $e');
    }
    return '';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DEVICE ACCOUNT SLOT CHECK
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> _checkDeviceAccountSlot(String signingInUid) async {
    final deviceId = await _getDeviceId();
    if (deviceId.isEmpty) return true;

    try {
      final query = await _firestore
          .collection(_usersCol)
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await _firestore
            .collection(_usersCol)
            .doc(signingInUid)
            .set({'deviceId': deviceId}, SetOptions(merge: true));
        return true;
      }

      final boundUid = query.docs.first.id;
      if (boundUid == signingInUid) return true;

      _setError(
        'Device Already Has an Account',
        'This device is already linked to another account. Only one account is allowed per device.',
      );
      return false;
    } catch (e) {
      debugPrint('AuthProvider._checkDeviceAccountSlot ERROR: $e');
      return true;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GOOGLE INIT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _initGoogle() async {
    if (_googleInitialized) return;
    try {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    } catch (e) {
      debugPrint('AuthProvider._initGoogle ERROR: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  AUTH STATE LISTENER
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _userData = null;
      _setState(AuthState.unauthenticated);
      return;
    }

    if (_isRegistering) return;

    await _fetchUserData(user.uid);

    if (_userData == null) {
      try {
        await _createUserDocument(user: user);
        await _fetchUserData(user.uid);
      } catch (e) {
        debugPrint('AuthProvider._onAuthStateChanged: recovery FAILED: $e');
      }
    }

    _setState(AuthState.authenticated);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FIRESTORE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static const _usersCol     = 'users';
  static const _usernamesCol = 'usernames';
  static const _emailsCol    = 'emails';

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCol).doc(uid).get();
      _userData = doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('AuthProvider._fetchUserData ERROR: $e');
    }
  }

  /// Normalised email key — lowercased, dots replaced so Firestore accepts it
  /// as a document ID.  e.g. "User.Name@Gmail.com" → "user_name@gmail_com"
  String _emailDocId(String email) =>
      email.trim().toLowerCase().replaceAll('.', '_');

  /// Reserves [email] in the `emails` collection (doc ID = normalised email).
  /// If [oldEmail] is supplied and different, the old entry is deleted.
  Future<void> _reserveEmail({
    required String uid,
    required String email,
    String?         oldEmail,
  }) async {
    final docId = _emailDocId(email);
    try {
      await _firestore
          .collection(_emailsCol)
          .doc(docId)
          .set({'uid': uid, 'email': email.trim().toLowerCase(), 'createdAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('AuthProvider._reserveEmail: set FAILED (non-fatal): $e');
    }

    if (oldEmail != null && _emailDocId(oldEmail) != docId) {
      try {
        await _firestore.collection(_emailsCol).doc(_emailDocId(oldEmail)).delete();
      } catch (e) {
        debugPrint('AuthProvider._reserveEmail: old delete FAILED (non-fatal): $e');
      }
    }
  }

  /// Returns `true` if [email] is not yet taken by another account.
  Future<bool> _isEmailAvailable(String email, {String? excludeUid}) async {
    try {
      final doc = await _firestore
          .collection(_emailsCol)
          .doc(_emailDocId(email))
          .get();
      if (!doc.exists) return true;
      if (excludeUid != null && doc.data()?['uid'] == excludeUid) return true;
      return false;
    } catch (e) {
      debugPrint('AuthProvider._isEmailAvailable ERROR: $e');
      return true;
    }
  }

  Future<void> _createUserDocument({
    required User user,
    String?       username,
    String?       displayName,
    String?       deviceId,
  }) async {
    final now            = FieldValue.serverTimestamp();
    final resolvedDevice = deviceId ?? await _getDeviceId();

    await _firestore.collection(_usersCol).doc(user.uid).set({
      'uid':           user.uid,
      'email':         user.email        ?? '',
      'displayName':   displayName       ?? user.displayName ?? '',
      'photoURL':      user.photoURL     ?? '',
      'emailVerified': user.emailVerified,
      'username':      username          ?? '',
      'coins':         PublishConstants.accountCreatingCoins,
      'deviceId':      resolvedDevice,
      'createdAt':     now,
      'lastLoginAt':   now,
    });

    if (user.email != null && user.email!.isNotEmpty) {
      await _reserveEmail(uid: user.uid, email: user.email!);
    }

    if (username != null && username.trim().isNotEmpty) {
      try {
        await _firestore
            .collection(_usernamesCol)
            .doc(username.trim().toLowerCase())
            .set({'uid': user.uid, 'createdAt': now});
      } catch (e) {
        debugPrint('AuthProvider._createUserDocument: username reservation FAILED (non-fatal): $e');
      }
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore
          .collection(_usersCol)
          .doc(uid)
          .set({'lastLoginAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthProvider._updateLastLogin ERROR: $e');
    }
  }

  Future<String?> _resolveEmailFromUsername(String username) async {
    try {
      final usernameDoc = await _firestore
          .collection(_usernamesCol)
          .doc(username.trim().toLowerCase())
          .get();

      if (!usernameDoc.exists) return null;

      final uid = usernameDoc.data()?['uid'] as String?;
      if (uid == null || uid.isEmpty) return null;

      final userDoc = await _firestore.collection(_usersCol).doc(uid).get();
      return userDoc.data()?['email'] as String?;
    } catch (e) {
      debugPrint('AuthProvider._resolveEmailFromUsername ERROR: $e');
      return null;
    }
  }

  bool _isEmail(String input) => input.contains('@');

  // ══════════════════════════════════════════════════════════════════════════
  //  USERNAME UNIQUENESS
  // ══════════════════════════════════════════════════════════════════════════

  Future<UsernameStatus> checkUsernameAvailable(
      String username, {
        String? excludeUid,
      }) async {
    final clean = username.trim().toLowerCase();

    if (clean.length < 3 || clean.length > 20)        return UsernameStatus.invalid;
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(clean))     return UsernameStatus.invalid;
    if (clean.startsWith('_') || clean.endsWith('_')) return UsernameStatus.invalid;
    if (clean.contains('__'))                         return UsernameStatus.invalid;

    try {
      final doc = await _firestore.collection(_usernamesCol).doc(clean).get();
      if (!doc.exists) return UsernameStatus.available;
      if (excludeUid != null && doc.data()?['uid'] == excludeUid) {
        return UsernameStatus.available;
      }
      return UsernameStatus.taken;
    } catch (e) {
      return UsernameStatus.available;
    }
  }

  Future<void> _reserveUsername({
    required String uid,
    required String newUsername,
    String?         oldUsername,
  }) async {
    final newClean = newUsername.trim().toLowerCase();

    await _firestore
        .collection(_usernamesCol)
        .doc(newClean)
        .set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

    if (oldUsername != null && oldUsername.trim().isNotEmpty) {
      final oldClean = oldUsername.trim().toLowerCase();
      if (oldClean != newClean) {
        try {
          await _firestore.collection(_usernamesCol).doc(oldClean).delete();
        } catch (e) {
          debugPrint('AuthProvider._reserveUsername: old slug delete FAILED (non-fatal): $e');
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REGISTER WITH EMAIL
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    if (isLoading) return false;
    _setState(AuthState.loading);
    _clearError();

    final trimmedName  = displayName.trim();
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      _setError('Full Name Required', 'Please enter your full name.');
      return false;
    }

    final usernameStatus = await checkUsernameAvailable(username);
    if (usernameStatus == UsernameStatus.invalid) {
      _setError(
        'Invalid Username',
        'Username must be 3–20 characters, letters/numbers/underscores only, '
            'and cannot start or end with an underscore.',
      );
      return false;
    }
    if (usernameStatus == UsernameStatus.taken) {
      _setError('Username Taken', 'That username is already taken. Please choose another.');
      return false;
    }

    final emailFree = await _isEmailAvailable(trimmedEmail);
    if (!emailFree) {
      _setError('Email Already Registered', 'An account with this email already exists.');
      return false;
    }

    final deviceId = await _getDeviceId();
    if (deviceId.isNotEmpty) {
      try {
        final query = await _firestore
            .collection(_usersCol)
            .where('deviceId', isEqualTo: deviceId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          _setError(
            'Device Already Has an Account',
            'This device is already linked to another account. Only one account is allowed per device.',
          );
          return false;
        }
      } catch (e) {
        debugPrint('AuthProvider.registerWithEmail: device pre-check ERROR (non-fatal): $e');
      }
    }

    _isRegistering = true;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email:    trimmedEmail,
        password: password,
      );
      final user = credential.user!;

      await user.updateDisplayName(trimmedName);
      await user.reload();
      _firebaseUser = _auth.currentUser;

      await _createUserDocument(
        user:        _auth.currentUser ?? user,
        username:    username.trim(),
        displayName: trimmedName,
        deviceId:    deviceId,
      );

      await _fetchUserData(user.uid);

      _isRegistering = false;
      _setState(AuthState.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _isRegistering = false;
      _setError('Registration Failed', _friendlyAuthError(e.code));
      return false;
    } catch (e) {
      _isRegistering = false;
      _setError('Registration Failed', 'An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGIN WITH EMAIL
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (isLoading) return false;
    _setState(AuthState.loading);
    _clearError();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim().toLowerCase(),
        password: password,
      );
      final uid = credential.user!.uid;

      final deviceAllowed = await _checkDeviceAccountSlot(uid);
      if (!deviceAllowed) {
        await _auth.signOut();
        return false;
      }

      await _updateLastLogin(uid);
      await _fetchUserData(uid);

      _setState(AuthState.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError('Login Failed', _friendlyAuthError(e.code));
      return false;
    } catch (e) {
      _setError('Login Failed', 'An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGIN WITH EMAIL OR USERNAME
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> loginWithEmailOrUsername({
    required String emailOrUsername,
    required String password,
  }) async {
    if (isLoading) return false;
    _setState(AuthState.loading);
    _clearError();

    String resolvedEmail = emailOrUsername.trim();

    if (!_isEmail(resolvedEmail)) {
      final found = await _resolveEmailFromUsername(resolvedEmail);
      if (found == null || found.isEmpty) {
        _setError('Not Found', 'No account found with that username.');
        return false;
      }
      resolvedEmail = found;
    }

    return loginWithEmail(email: resolvedEmail, password: password);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GOOGLE SIGN-IN
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> signInWithGoogle() async {
    if (isLoading) return false;
    _setState(AuthState.loading);
    _clearError();
    if (!_googleInitialized) await _initGoogle();

    try {
      late final GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          _setState(AuthState.unauthenticated);
          return false;
        }
        rethrow;
      }

      final String? idToken = googleUser.authentication.idToken;

      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient
            .authorizeScopes(['email', 'profile', 'openid']);
        accessToken = authz.accessToken;
      } catch (e) {
        debugPrint('AuthProvider.signInWithGoogle: accessToken ERROR: $e');
      }

      if (idToken == null && accessToken == null) {
        _setError('Google Sign-In Failed', 'Could not obtain credentials. Please try again.');
        return false;
      }

      final deviceId = await _getDeviceId();

      _isRegistering = true;

      late final User user;
      try {
        final oauthCred = GoogleAuthProvider.credential(
          idToken:     idToken,
          accessToken: accessToken,
        );
        final userCredential = await _auth.signInWithCredential(oauthCred);
        user = userCredential.user!;
      } catch (e) {
        _isRegistering = false;
        rethrow;
      }

      try {
        final docSnap = await _firestore.collection(_usersCol).doc(user.uid).get();

        if (!docSnap.exists) {
          final userEmail = user.email ?? '';

          if (userEmail.isNotEmpty) {
            final emailFree = await _isEmailAvailable(userEmail);
            if (!emailFree) {
              _isRegistering = false;
              await _auth.signOut();
              _setError('Email Already Registered',
                  'An account with this Google email already exists.');
              return false;
            }
          }

          if (deviceId.isNotEmpty) {
            final query = await _firestore
                .collection(_usersCol)
                .where('deviceId', isEqualTo: deviceId)
                .limit(1)
                .get();

            if (query.docs.isNotEmpty && query.docs.first.id != user.uid) {
              _isRegistering = false;
              await _auth.signOut();
              _setError(
                'Device Already Has an Account',
                'This device is already linked to another account. Only one account is allowed per device.',
              );
              return false;
            }
          }

          await _createUserDocument(user: user, deviceId: deviceId);
        } else {
          final deviceAllowed = await _checkDeviceAccountSlot(user.uid);
          if (!deviceAllowed) {
            _isRegistering = false;
            await _auth.signOut();
            return false;
          }
          await _updateLastLogin(user.uid);
        }
      } catch (e) {
        debugPrint('AuthProvider.signInWithGoogle: Firestore ERROR (non-fatal): $e');
      } finally {
        _isRegistering = false;
      }

      await _fetchUserData(user.uid);
      _setState(AuthState.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError('Google Sign-In Failed', _friendlyAuthError(e.code));
      return false;
    } on GoogleSignInException catch (e) {
      _setError('Google Sign-In Failed', e.description ?? e.code.name);
      return false;
    } catch (e) {
      _setError('Google Sign-In Failed', 'Please try again.');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UPDATE USERNAME
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> updateUsername(String newUsername) async {
    if (uid.isEmpty) return false;
    final trimmed = newUsername.trim();

    final status = await checkUsernameAvailable(trimmed, excludeUid: uid);
    if (status == UsernameStatus.invalid) {
      _setError('Invalid Username',
          'Username must be 3–20 characters, letters/numbers/underscores only.');
      return false;
    }
    if (status == UsernameStatus.taken) {
      _setError('Username Taken', 'That username is already taken. Please choose another.');
      return false;
    }

    _userData ??= {};
    _userData!['username'] = trimmed;
    notifyListeners();

    try {
      await _firestore
          .collection(_usersCol)
          .doc(uid)
          .set({'username': trimmed}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthProvider.updateUsername: write FAILED (non-fatal): $e');
    }

    try {
      await _reserveUsername(
        uid:         uid,
        newUsername: trimmed,
        oldUsername: (username != trimmed && username.isNotEmpty) ? username : null,
      );
    } catch (e) {
      debugPrint('AuthProvider.updateUsername: reservation FAILED (non-fatal): $e');
    }

    return true;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  UPDATE DISPLAY NAME
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> updateDisplayName(String name) async {
    if (uid.isEmpty) return false;
    try {
      await _firebaseUser?.updateDisplayName(name.trim());
      await _firestore.collection(_usersCol).doc(uid).update({'displayName': name.trim()});
      _userData?['displayName'] = name.trim();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.updateDisplayName ERROR: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REFRESH USER DATA
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> refreshUserData() async {
    if (uid.isNotEmpty) {
      await _fetchUserData(uid);
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGOUT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> logout() async {
    _setState(AuthState.loading);
    try {
      await Future.wait([
        _auth.signOut(),
        if (_googleInitialized) _googleSignIn.signOut(),
      ]);
      _userData = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      debugPrint('AuthProvider.logout ERROR: $e');
      _setState(AuthState.unauthenticated);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  bool checkIsLoggedIn() => _auth.currentUser != null;

  void _setState(AuthState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String title, String message) {
    _errorMessage = message;
    _state        = AuthState.error;
    notifyListeners();
    _errorCallback?.call(title, message);
  }

  void _clearError() => _errorMessage = null;

  String _friendlyAuthError(String code) => switch (code) {
    'user-not-found'                           => 'No account found with this email.',
    'wrong-password'                           => 'Incorrect password. Please try again.',
    'invalid-credential'                       => 'Invalid credentials. Please try again.',
    'email-already-in-use'                     => 'This email is already registered.',
    'invalid-email'                            => 'Please enter a valid email address.',
    'weak-password'                            => 'Password must be at least 6 characters.',
    'user-disabled'                            => 'This account has been disabled.',
    'too-many-requests'                        => 'Too many attempts. Please try again later.',
    'network-request-failed'                   => 'Network error. Check your connection.',
    'account-exists-with-different-credential' => 'An account exists with a different sign-in method.',
    _                                          => 'Authentication failed. Please try again.',
  };
}