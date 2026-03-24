import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CoinService
//
// Handles all coin balance mutations in Firestore.
// Uses FieldValue.increment so concurrent writes never race.
// ─────────────────────────────────────────────────────────────────────────────

class CoinService {
  CoinService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Collection / field names ───────────────────────────────────────────────
  static const String _usersCollection = 'users';
  static const String _coinsField = 'coins'; // adjust if your field differs

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the Firestore document ref for the currently signed-in user.
  /// Throws [StateError] if no user is authenticated.
  static DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('CoinService: no authenticated user');
    return _db.collection(_usersCollection).doc(uid);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Atomically adds [amount] coins to the current user's balance.
  ///
  /// Uses [FieldValue.increment] so the operation is safe even if the app
  /// is offline — Firestore will sync the delta when connectivity resumes.
  ///
  /// Returns the new balance, or `null` if the read-back fails.
  static Future<int?> addCoins(int amount) async {
    assert(amount > 0, 'addCoins: amount must be positive');

    final ref = _userDoc();

    // Atomic increment — no read-modify-write race condition
    await ref.update({
      _coinsField: FieldValue.increment(amount),
      'lastCoinEarnedAt': FieldValue.serverTimestamp(),
    });

    // Read back the new balance for the caller
    final snap = await ref.get();
    final data = snap.data();
    return data?[_coinsField] as int?;
  }

  /// Fetches the current coin balance for the signed-in user.
  static Future<int> fetchCoins() async {
    final snap = await _userDoc().get();
    return (snap.data()?[_coinsField] as int?) ?? 0;
  }
}