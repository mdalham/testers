import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';




const String _kPlacementPrimary  = 'Interstitial_Ads_Primary';
const String _kPlacementSec      = 'Interstitial_Ads';
const String _kPlacementAndroid  = 'Interstitial_Android';





class UnityInterstitialService {
  
  UnityInterstitialService._internal();
  static final UnityInterstitialService instance =
  UnityInterstitialService._internal();
  factory UnityInterstitialService() => instance;

  
  
  final Map<String, bool> _loadedPlacements = {
    _kPlacementPrimary : false,
    _kPlacementSec     : false,
    _kPlacementAndroid : false,
  };

  
  static const List<String> _fallbackOrder = [
    _kPlacementPrimary,
    _kPlacementSec,
    _kPlacementAndroid,
  ];

  

  
  
  void loadAds() {
    for (final placement in _fallbackOrder) {
      _loadPlacement(placement);
    }
  }

  void _loadPlacement(String placementId) {
    debugPrint('[UnityInterstitial] 🔄 Loading: $placementId');

    UnityAds.load(
      placementId: placementId,
      onComplete: (id) {
        debugPrint('[UnityInterstitial] ✅ Loaded: $id');
        _loadedPlacements[id] = true;
      },
      onFailed: (id, error, message) {
        debugPrint('[UnityInterstitial] ⚠️ Load failed [$id] — $error: $message');
        _loadedPlacements[id] = false;
      },
    );
  }

  

  
  
  
  
  void showInterstitialAd({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
  }) {
    final String? placement = _firstReadyPlacement();

    if (placement == null) {
      debugPrint('[UnityInterstitial] ❌ No placements ready — triggering onFailed.');
      onFailed?.call();
      loadAds(); 
      return;
    }

    debugPrint('[UnityInterstitial] ▶️ Showing: $placement');
    _loadedPlacements[placement] = false; 

    UnityAds.showVideoAd(
      placementId: placement,

      onStart: (id) {
        debugPrint('[UnityInterstitial] ▶️ Ad started: $id');
      },

      onClick: (id) {
        debugPrint('[UnityInterstitial] 👆 Ad clicked: $id');
      },

      onSkipped: (id) {
        
        
        debugPrint('[UnityInterstitial] ⏭️ Ad skipped: $id — completing anyway.');
        onCompleted();
        _loadPlacement(id);
      },

      onComplete: (id) {
        debugPrint('[UnityInterstitial] 🎉 Ad completed: $id');
        onCompleted();
        _loadPlacement(id); 
      },

      onFailed: (id, error, message) {
        debugPrint('[UnityInterstitial] ❌ Show failed [$id] — $error: $message');
        _loadPlacement(id); 
        _tryNextPlacement(
          failedPlacement: id,
          onCompleted: onCompleted,
          onFailed: onFailed,
        );
      },
    );
  }

  
  void _tryNextPlacement({
    required String failedPlacement,
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
  }) {
    final int failedIndex = _fallbackOrder.indexOf(failedPlacement);

    for (int i = failedIndex + 1; i < _fallbackOrder.length; i++) {
      final String next = _fallbackOrder[i];
      if (_loadedPlacements[next] == true) {
        debugPrint('[UnityInterstitial] 🔁 Falling back to: $next');
        _loadedPlacements[next] = false;

        UnityAds.showVideoAd(
          placementId: next,
          onStart:    (id) => debugPrint('[UnityInterstitial] ▶️ Fallback started: $id'),
          onClick:    (id) => debugPrint('[UnityInterstitial] 👆 Fallback clicked: $id'),
          onSkipped:  (id) {
            debugPrint('[UnityInterstitial] ⏭️ Fallback skipped: $id — completing.');
            onCompleted();
            _loadPlacement(id);
          },
          onComplete: (id) {
            debugPrint('[UnityInterstitial] 🎉 Fallback completed: $id');
            onCompleted();
            _loadPlacement(id);
          },
          onFailed: (id, error, message) {
            debugPrint('[UnityInterstitial] ❌ Fallback failed [$id] — $error: $message');
            _loadPlacement(id);
            _tryNextPlacement(
              failedPlacement: id,
              onCompleted: onCompleted,
              onFailed: onFailed,
            );
          },
        );
        return;
      }
    }

    
    debugPrint('[UnityInterstitial] ❌ All fallbacks exhausted.');
    onFailed?.call();
    loadAds(); 
  }

  

  
  String? _firstReadyPlacement() {
    for (final p in _fallbackOrder) {
      if (_loadedPlacements[p] == true) return p;
    }
    return null;
  }

  
  bool get isAdReady => _loadedPlacements.values.any((loaded) => loaded);

  
  void reloadAds() => loadAds();
}