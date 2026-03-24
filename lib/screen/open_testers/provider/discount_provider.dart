import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';


class DiscountProvider extends ChangeNotifier {
  static const _collection = 'app_config';
  static const _document   = 'discount';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool    _enabled    = false;
  int     _percentage = 0;
  String  _label      = '';
  bool    _isLoading  = true;
  String? _error;

  bool    get enabled    => _enabled;
  int     get percentage => _percentage;
  String  get label      => _label;
  bool    get isLoading  => _isLoading;
  String? get error      => _error;

  /// True when discount is active and > 0 %.
  bool get hasDiscount => _enabled && _percentage > 0;

  /// Multiplier to apply to a cost — e.g. 20 % off → 0.80.
  double get multiplier => hasDiscount ? (100 - _percentage) / 100 : 1.0;

  /// Returns [originalCost] after applying the discount (rounded up).
  int discountedCost(int originalCost) =>
      hasDiscount ? (originalCost * multiplier).ceil() : originalCost;

  /// Saved coin amount for a given [originalCost].
  int savedCoins(int originalCost) =>
      originalCost - discountedCost(originalCost);

  DiscountProvider() {
    _fetch();
  }

  Future<void> _fetch() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(_document)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _enabled    = (data['enabled']    as bool?)  ?? false;
        _percentage = (data['percentage'] as num?)?.toInt().clamp(0, 100) ?? 0;
        _label      = (data['label']      as String?) ?? '';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('DiscountProvider._fetch ERROR: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetches the discount from Firestore (call on pull-to-refresh etc.).
  Future<void> refresh() => _fetch();
}