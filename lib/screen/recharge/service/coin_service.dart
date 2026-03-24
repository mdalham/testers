import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';








class CoinService {
  CoinService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  
  static const String _usersCollection = 'users';
  static const String _coinsField = 'coins'; 

  

  
  
  static DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('CoinService: no authenticated user');
    return _db.collection(_usersCollection).doc(uid);
  }

  

  
  
  
  
  
  
  static Future<int?> addCoins(int amount) async {
    assert(amount > 0, 'addCoins: amount must be positive');

    final ref = _userDoc();

    
    await ref.update({
      _coinsField: FieldValue.increment(amount),
      'lastCoinEarnedAt': FieldValue.serverTimestamp(),
    });

    
    final snap = await ref.get();
    final data = snap.data();
    return data?[_coinsField] as int?;
  }

  
  static Future<int> fetchCoins() async {
    final snap = await _userDoc().get();
    return (snap.data()?[_coinsField] as int?) ?? 0;
  }
}