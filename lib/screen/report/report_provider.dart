import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testers/services/upload/image_upload.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider._();
  static final ReportProvider instance = ReportProvider._();

  
  String?  _selectedProblemType;
  String   _descriptionText  = '';
  String?  _screenshotUrl;
  bool     _isLoading        = false;
  String?  _submitError;

  
  File?    _screenshotFile;
  bool     _uploadingShot    = false;
  String?  _uploadError;

  final _uploadService = ImageUploadService();

  
  String?  get selectedProblemType => _selectedProblemType;
  String   get descriptionText     => _descriptionText;
  String?  get screenshotUrl       => _screenshotUrl;
  bool     get isLoading           => _isLoading;
  File?    get screenshotFile      => _screenshotFile;
  bool     get uploadingShot       => _uploadingShot;
  String?  get submitError         => _submitError;
  String?  get uploadError         => _uploadError;

  bool get isFormValid =>
      _selectedProblemType != null &&
          _screenshotUrl != null &&
          _descriptionText.trim().length >= 10;

  

  void setProblemType(String? type) {
    _selectedProblemType = type;
    notifyListeners();
  }

  void setDescription(String text) {
    _descriptionText = text;
    notifyListeners();
  }

  

  Future<void> pickAndUploadScreenshot() async {
    try {
      final picked = await ImagePicker().pickImage(
        source:       ImageSource.gallery,
        imageQuality: 85,
        maxWidth:     1080,
      );
      if (picked == null) return;

      _screenshotFile = File(picked.path);
      _uploadingShot  = true;
      _screenshotUrl  = null;
      _uploadError    = null;
      notifyListeners();

      final result = await _uploadService.uploadImage(_screenshotFile!);

      if (result.success) {
        _screenshotUrl = result.imageUrl;
        _uploadingShot = false;
      } else {
        _screenshotFile = null;
        _uploadingShot  = false;
        _uploadError    = result.errorMessage ?? 'Upload failed. Tap to retry.';
      }
    } catch (_) {
      _screenshotFile = null;
      _uploadingShot  = false;
      _uploadError    = 'Something went wrong. Tap to retry.';
    }
    notifyListeners();
  }

  
  
  
  
  
  
  

  Future<String?> findRecentReport(String appId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );

    try {
      final snap = await FirebaseFirestore.instance
          .collection('report')
          .where('userId',    isEqualTo: uid)
          .where('appId',     isEqualTo: appId)
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty ? snap.docs.first.id : null;
    } on FirebaseException catch (e) {
      
      
      debugPrint('findRecentReport: index missing or Firebase error — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('findRecentReport: unexpected error — $e');
      return null;
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  String _buildDateKey(DateTime now) {
    final yy  = (now.year % 100).toString().padLeft(2, '0');
    final ddd = (now.difference(DateTime(now.year, 1, 1)).inDays + 1)
        .toString()
        .padLeft(3, '0');
    return '$yy-$ddd';
  }

  Future<String> _nextReportId(
      Transaction       txn,
      DocumentReference counterRef,
      ) async {
    final dateKey = _buildDateKey(DateTime.now());
    final snap    = await txn.get(counterRef);

    
    final data = snap.data() as Map<String, dynamic>?;

    int seq = 1;
    if (snap.exists && data != null) {
      final storedDate = data['date'] as String?;
      final storedSeq  = (data['seq']  as num?)?.toInt() ?? 0;
      seq = (storedDate == dateKey) ? storedSeq + 1 : 1;
    }

    txn.set(counterRef, {'date': dateKey, 'seq': seq});

    return '$dateKey-${seq.toString().padLeft(3, '0')}';
  }

  

  Future<bool> submitReport({
    required String appId,
    required String appName,
    required String developerName,
    required String sourceType,   
  }) async {
    if (!isFormValid) return false;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    _isLoading = true;
    notifyListeners();

    final db         = FirebaseFirestore.instance;
    final counterRef = db.collection('meta').doc('report_counter');

    try {
      await db.runTransaction((txn) async {
        final reportId = await _nextReportId(txn, counterRef);

        txn.set(db.collection('report').doc(reportId), {
          'reportId':      reportId,
          'userId':        uid,
          'appId':         appId,
          'appName':       appName,
          'developerName': developerName,
          'problemType':   _selectedProblemType,
          'description':   _descriptionText.trim(),
          'screenshotUrl': _screenshotUrl,
          'sourceType':    sourceType,
          'createdAt':     Timestamp.now(),
        });
      });

      _reset();
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
          'ReportProvider.submitReport FirebaseException: ${e.code} - ${e.message}');
      _submitError = e.message ?? 'Firebase error (${e.code})';
      _isLoading   = false;
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint('ReportProvider.submitReport ERROR: $e\n$st');
      _submitError = e.toString();
      _isLoading   = false;
      notifyListeners();
      return false;
    }
  }

  

  void _reset() {
    _selectedProblemType = null;
    _descriptionText     = '';
    _screenshotUrl       = null;
    _screenshotFile      = null;
    _uploadingShot       = false;
    _uploadError         = null;
    _submitError         = null;
    _isLoading           = false;
    notifyListeners();
  }

  void resetState() => _reset();

  @override
  void dispose() {
    _uploadService.dispose();
    super.dispose();
  }
}