
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:testers/screen/open_testers/update/update_bottom_sheet.dart';
import 'package:testers/screen/open_testers/update/update_model.dart';

import '../../../controllers/info.dart';

//remove comment
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const _collection = 'app_config';
  static const _document   = 'update';

  static const String _kFallbackVersion = PublishConstants.fallbackVersion;



  Future<void> checkForUpdate(BuildContext context) async {
    try {

      final model = await _fetchUpdateModel();
      if (model == null) {
          return;
      }

      final currentVersion = await _currentVersion();

      final needsUpdate = _isUpdateAvailable(currentVersion, model.latestVersion);

      if (!needsUpdate) {
         return;
      }

      if (!context.mounted) {
        return;
      }

      showUpdateBottomSheet(
        context:        context,
        model:          model,
        currentVersion: currentVersion,
      );
    } catch (e, st) {
      debugPrint('[UpdateService] ✗ error: $e\n$st');
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<UpdateModel?> _fetchUpdateModel() async {
    final snap = await FirebaseFirestore.instance
        .collection(_collection)
        .doc(_document)
        .get();

    if (!snap.exists || snap.data() == null) return null;
    return UpdateModel.fromMap(snap.data()!);
  }


  Future<String> _currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
        return _kFallbackVersion;
    }
  }

  /// Compares two semver strings.
  /// Returns true when [latest] is strictly greater than [current].
  bool _isUpdateAvailable(String current, String latest) {
    if (current == latest) return false;

    final c = _toInts(current);
    final l = _toInts(latest);

    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  List<int> _toInts(String version) {
    // Clean up any build metadata e.g. "1.0.1+4" → "1.0.1"
    final clean = version.split('+').first.trim();
    final parts = clean.split('.');
    return List.generate(
      3,
          (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    );
  }
}