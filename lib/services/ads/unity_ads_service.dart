import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';




const String _kGameId           = '6015405'; 
const String _kPlacementPrimary = 'Rewarded_Ads_Primary';
const String _kPlacementSec     = 'Rewarded_Ads_Sec';
const String _kPlacementAndroid = 'Rewarded_Android';

const bool _kTestMode = kDebugMode; 





class UnityAdsService {
  
  UnityAdsService._internal();
  static final UnityAdsService instance = UnityAdsService._internal();
  factory UnityAdsService() => instance;

  
  bool _initialized = false;

  
  final Map<String, bool> _loadedPlacements = {
    _kPlacementPrimary: false,
    _kPlacementSec:     false,
    _kPlacementAndroid: false,
  };

  
  static const List<String> _fallbackOrder = [
    _kPlacementPrimary,
    _kPlacementSec,
    _kPlacementAndroid,
  ];

  

  
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      await UnityAds.init(
        gameId:   _kGameId,
        testMode: false,
        onComplete: () {
          _initialized = true;
          _loadAllPlacements();
        },
        onFailed: (error, message) {
        },
      );
    } catch (e) {
      debugPrint('[UnityAds] ❌ Exception during init: $e');
    }
  }

  

  void _loadAllPlacements() {
    for (final placement in _fallbackOrder) {
      _loadPlacement(placement);
    }
  }

  void _loadPlacement(String placementId) {
    debugPrint('[UnityAds] 🔄 Loading placement: $placementId');

    UnityAds.load(
      placementId: placementId,
      onComplete: (id) {
        debugPrint('[UnityAds] ✅ Loaded: $id');
        _loadedPlacements[id] = true;
      },
      onFailed: (id, error, message) {
        debugPrint('[UnityAds] ⚠️ Load failed [$id] — $error: $message');
        _loadedPlacements[id] = false;
      },
    );
  }

  

  
  
  
  
  Future<void> showRewardedAd({
    required Function() onCompleted,
    Function()? onFailed,
  }) async {
    if (!_initialized) {
      debugPrint('[UnityAds] ⚠️ SDK not yet initialized.');
      onFailed?.call();
      return;
    }

    
    final String? placement = _firstReadyPlacement();

    if (placement == null) {
      onFailed?.call();
      
      _loadAllPlacements();
      return;
    }


    
    _loadedPlacements[placement] = false;

    UnityAds.showVideoAd(
      placementId: placement,

      
      onStart: (id) {
      },

      onClick: (id) {
      },

      onSkipped: (id) {
        
        _loadPlacement(id);
      },

      onComplete: (id) {
        onCompleted();
        
        _loadPlacement(id);
      },

      onFailed: (id, error, message) {
        
        _tryNextPlacement(
          failedPlacement: id,
          onCompleted:     onCompleted,
          onFailed:        onFailed,
        );
        
        _loadPlacement(id);
      },
    );
  }

  

  void _tryNextPlacement({
    required String failedPlacement,
    required Function() onCompleted,
    Function()? onFailed,
  }) {
    final int failedIndex = _fallbackOrder.indexOf(failedPlacement);

    
    for (int i = failedIndex + 1; i < _fallbackOrder.length; i++) {
      final String next = _fallbackOrder[i];
      if (_loadedPlacements[next] == true) {
        _loadedPlacements[next] = false;

        UnityAds.showVideoAd(
          placementId: next,
          onStart:    (id) => debugPrint('[UnityAds] ▶️ Fallback ad started: $id'),
          onClick:    (id) => debugPrint('[UnityAds] 👆 Fallback ad clicked: $id'),
          onSkipped:  (id) {
            _loadPlacement(id);
          },
          onComplete: (id) {
            onCompleted();
            _loadPlacement(id);
          },
          onFailed: (id, error, message) {
            _loadPlacement(id);
            
            _tryNextPlacement(
              failedPlacement: id,
              onCompleted:     onCompleted,
              onFailed:        onFailed,
            );
          },
        );
        return; 
      }
    }

    
    onFailed?.call();
    _loadAllPlacements(); 
  }

  

  
  String? _firstReadyPlacement() {
    for (final placement in _fallbackOrder) {
      if (_loadedPlacements[placement] == true) return placement;
    }
    return null;
  }

  
  bool get isAdReady => _loadedPlacements.values.any((loaded) => loaded);

  
  bool get isInitialized => _initialized;

  
  void reloadAds() {
    if (_initialized) _loadAllPlacements();
  }
}