import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ad Placement IDs
// ─────────────────────────────────────────────────────────────────────────────
const String _kGameId           = '6015405'; // ← replace
const String _kPlacementPrimary = 'Rewarded_Ads_Primary';
const String _kPlacementSec     = 'Rewarded_Ads_Sec';
const String _kPlacementAndroid = 'Rewarded_Android';

const bool _kTestMode = kDebugMode; // auto test-mode in debug builds

// ─────────────────────────────────────────────────────────────────────────────
// UnityAdsService — Singleton
// ─────────────────────────────────────────────────────────────────────────────

class UnityAdsService {
  // ── Singleton boilerplate ─────────────────────────────────────────────────
  UnityAdsService._internal();
  static final UnityAdsService instance = UnityAdsService._internal();
  factory UnityAdsService() => instance;

  // ── Internal state ────────────────────────────────────────────────────────
  bool _initialized = false;

  /// Tracks which placements are currently loaded and ready.
  final Map<String, bool> _loadedPlacements = {
    _kPlacementPrimary: false,
    _kPlacementSec:     false,
    _kPlacementAndroid: false,
  };

  // ── Priority order for fallback ───────────────────────────────────────────
  static const List<String> _fallbackOrder = [
    _kPlacementPrimary,
    _kPlacementSec,
    _kPlacementAndroid,
  ];

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Call once from `main()` or your root widget's `initState`.
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

  // ── Load all placements ───────────────────────────────────────────────────

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

  // ── Public: show rewarded ad with fallback ────────────────────────────────

  /// Shows a rewarded ad using a three-placement fallback chain.
  ///
  /// [onCompleted] — called when the user watches the ad fully.
  /// [onFailed]    — optional; called when no placement is available.
  Future<void> showRewardedAd({
    required Function() onCompleted,
    Function()? onFailed,
  }) async {
    if (!_initialized) {
      debugPrint('[UnityAds] ⚠️ SDK not yet initialized.');
      onFailed?.call();
      return;
    }

    // Find the first loaded placement in fallback order
    final String? placement = _firstReadyPlacement();

    if (placement == null) {
      onFailed?.call();
      // Reload all so they're ready for next attempt
      _loadAllPlacements();
      return;
    }


    // Mark as not loaded immediately (Unity requires reload after each show)
    _loadedPlacements[placement] = false;

    UnityAds.showVideoAd(
      placementId: placement,

      // ── Ad lifecycle callbacks ──────────────────────────────────────────
      onStart: (id) {
      },

      onClick: (id) {
      },

      onSkipped: (id) {
        // Reload this slot for next time
        _loadPlacement(id);
      },

      onComplete: (id) {
        onCompleted();
        // Reload this slot immediately for next use
        _loadPlacement(id);
      },

      onFailed: (id, error, message) {
        // Try the next available placement in the fallback chain
        _tryNextPlacement(
          failedPlacement: id,
          onCompleted:     onCompleted,
          onFailed:        onFailed,
        );
        // Reload the failed slot in background
        _loadPlacement(id);
      },
    );
  }

  // ── Internal: fallback on show failure ───────────────────────────────────

  void _tryNextPlacement({
    required String failedPlacement,
    required Function() onCompleted,
    Function()? onFailed,
  }) {
    final int failedIndex = _fallbackOrder.indexOf(failedPlacement);

    // Look for the next ready placement after the failed one
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
            // Continue down the chain recursively
            _tryNextPlacement(
              failedPlacement: id,
              onCompleted:     onCompleted,
              onFailed:        onFailed,
            );
          },
        );
        return; // handed off — stop here
      }
    }

    // Exhausted all fallbacks
    onFailed?.call();
    _loadAllPlacements(); // reload everything for the next attempt
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the first placement that is currently loaded, in priority order.
  String? _firstReadyPlacement() {
    for (final placement in _fallbackOrder) {
      if (_loadedPlacements[placement] == true) return placement;
    }
    return null;
  }

  /// Returns true if at least one placement is ready to show.
  bool get isAdReady => _loadedPlacements.values.any((loaded) => loaded);

  /// Returns true if the SDK has been initialized.
  bool get isInitialized => _initialized;

  /// Force-reload all placements (e.g. call after returning to a screen).
  void reloadAds() {
    if (_initialized) _loadAllPlacements();
  }
}