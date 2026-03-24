import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../controllers/api.dart';

abstract class _ApiConfig {
  // ── ImgBB ──────────────────────────────────────────────────────────────────
  static final String imgbbApiKey    = Api.imgbbApiKey;
  static const String imgbbEndpoint  = 'https://api.imgbb.com/1/upload';

  // ── Cloudinary ─────────────────────────────────────────────────────────────
  // Upload preset must be set to "unsigned" in your Cloudinary dashboard.
  static final String cloudinaryCloudName    = Api.cloudinaryCloudName;
  static final String cloudinaryUploadPreset = Api.cloudinaryUploadPreset;
  static String get cloudinaryEndpoint =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 30);
}

// ══════════════════════════════════════════════════════════════════════════════
//  UploadResult
// ══════════════════════════════════════════════════════════════════════════════
class UploadResult {
  const UploadResult._({
    required this.success,
    this.imageUrl,
    this.errorMessage,
    this.provider,
  });

  /// True when at least one provider returned a valid URL.
  final bool success;

  /// The publicly accessible image URL. Null on failure.
  final String? imageUrl;

  /// Human-readable error message. Null on success.
  final String? errorMessage;

  /// Which provider ultimately succeeded ('imgbb' | 'cloudinary'). Null on failure.
  final String? provider;

  factory UploadResult.success({
    required String imageUrl,
    required String provider,
  }) =>
      UploadResult._(success: true, imageUrl: imageUrl, provider: provider);

  factory UploadResult.failure(String errorMessage) =>
      UploadResult._(success: false, errorMessage: errorMessage);

  @override
  String toString() => success
      ? 'UploadResult(success, url: $imageUrl, via: $provider)'
      : 'UploadResult(failed, error: $errorMessage)';
}

// ══════════════════════════════════════════════════════════════════════════════
//  ImageUploadService
// ══════════════════════════════════════════════════════════════════════════════
class ImageUploadService {
  ImageUploadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ─────────────────────────────────────────────────────────────────────────
  //  Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Uploads [imageFile] to ImgBB first.
  /// Falls back to Cloudinary automatically if ImgBB fails.
  /// Always returns an [UploadResult] — never throws.
  Future<UploadResult> uploadImage(File imageFile) async {
    // ── Validate file exists ───────────────────────────────────────────────
    if (!imageFile.existsSync()) {
      return UploadResult.failure('Image file not found at: ${imageFile.path}');
    }

    // ── Attempt 1: ImgBB ──────────────────────────────────────────────────
    try {
      final url = await _uploadToImgbb(imageFile);
      return UploadResult.success(imageUrl: url, provider: 'imgbb');
    } on _UploadException catch (e) {
      // ImgBB failed — log and fall through to Cloudinary
      _log('ImgBB upload failed: ${e.message}. Trying Cloudinary...');
    } catch (e) {
      _log('ImgBB unexpected error: $e. Trying Cloudinary...');
    }

    // ── Attempt 2: Cloudinary ─────────────────────────────────────────────
    try {
      final url = await _uploadToCloudinary(imageFile);
      return UploadResult.success(imageUrl: url, provider: 'cloudinary');
    } on _UploadException catch (e) {
      _log('Cloudinary upload failed: ${e.message}');
      return UploadResult.failure(
        'Both upload providers failed. Last error: ${e.message}',
      );
    } catch (e) {
      _log('Cloudinary unexpected error: $e');
      return UploadResult.failure(
        'Both upload providers failed. Unexpected error: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ImgBB Upload
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _uploadToImgbb(File imageFile) async {
    try {
      // ImgBB accepts base64-encoded image data
      final bytes      = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_ApiConfig.imgbbEndpoint}?key=${_ApiConfig.imgbbApiKey}'),
      )..fields['image'] = base64Image;

      final streamedResponse = await request
          .send()
          .timeout(_ApiConfig.requestTimeout);

      final response = await http.Response.fromStream(streamedResponse);

      // ── Handle HTTP errors ────────────────────────────────────────────
      if (response.statusCode == 400) {
        throw _UploadException('ImgBB: Bad request — check API key or image format');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw _UploadException('ImgBB: Invalid or unauthorised API key');
      }
      if (response.statusCode != 200) {
        throw _UploadException(
          'ImgBB: Server error (HTTP ${response.statusCode})',
        );
      }

      // ── Parse response ────────────────────────────────────────────────
      final Map<String, dynamic> json =
      jsonDecode(response.body) as Map<String, dynamic>;

      final bool? apiSuccess = json['success'] as bool?;
      if (apiSuccess != true) {
        final errMsg = (json['error'] as Map?)?['message'] as String?;
        throw _UploadException('ImgBB: API returned failure — ${errMsg ?? 'unknown reason'}');
      }

      final url = (json['data'] as Map?)?['url'] as String?;
      if (url == null || url.isEmpty) {
        throw _UploadException('ImgBB: Response did not contain an image URL');
      }

      return url;
    } on SocketException {
      throw _UploadException('ImgBB: No internet connection');
    } on http.ClientException catch (e) {
      throw _UploadException('ImgBB: Network error — ${e.message}');
    } on FormatException {
      throw _UploadException('ImgBB: Could not parse server response');
    }
    // TimeoutException and _UploadException bubble up naturally
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Cloudinary Upload
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _uploadToCloudinary(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_ApiConfig.cloudinaryEndpoint),
      );

      request.fields['upload_preset'] = _ApiConfig.cloudinaryUploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request
          .send()
          .timeout(_ApiConfig.requestTimeout);

      final response = await http.Response.fromStream(streamedResponse);

      // ── Handle HTTP errors ────────────────────────────────────────────
      if (response.statusCode == 400) {
        final json = _tryParseJson(response.body);
        final errMsg = json?['error']?['message'] as String?;
        throw _UploadException(
          'Cloudinary: Bad request — ${errMsg ?? 'check upload preset'}',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw _UploadException(
          'Cloudinary: Unauthorised — check cloud name and upload preset',
        );
      }
      if (response.statusCode != 200) {
        throw _UploadException(
          'Cloudinary: Server error (HTTP ${response.statusCode})',
        );
      }

      // ── Parse response ────────────────────────────────────────────────
      final Map<String, dynamic>? json = _tryParseJson(response.body);
      if (json == null) {
        throw _UploadException('Cloudinary: Could not parse server response');
      }

      final url = json['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw _UploadException('Cloudinary: Response did not contain secure_url');
      }

      return url;
    } on SocketException {
      throw _UploadException('Cloudinary: No internet connection');
    } on http.ClientException catch (e) {
      throw _UploadException('Cloudinary: Network error — ${e.message}');
    } on FormatException {
      throw _UploadException('Cloudinary: Could not parse server response');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _log(String message) {
    // Replace with your preferred logger in production (e.g. logger package)
    assert(() {
      // ignore: avoid_print
      print('[ImageUploadService] $message');
      return true;
    }());
  }

  /// Call this when the service is no longer needed to free HTTP resources.
  void dispose() => _client.close();
}

// ══════════════════════════════════════════════════════════════════════════════
//  Internal exception — never exposed to UI
// ══════════════════════════════════════════════════════════════════════════════
class _UploadException implements Exception {
  const _UploadException(this.message);
  final String message;

  @override
  String toString() => '_UploadException: $message';
}