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

  
  bool get hasDiscount => _enabled && _percentage > 0;

  
  double get multiplier => hasDiscount ? (100 - _percentage) / 100 : 1.0;

  
  int discountedCost(int originalCost) =>
      hasDiscount ? (originalCost * multiplier).ceil() : originalCost;

  
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

  
  Future<void> refresh() => _fetch();
}