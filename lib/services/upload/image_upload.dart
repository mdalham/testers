import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:testers/constants/api.dart';

abstract class _ApiConfig {
  
  static final String imgbbApiKey    = Api.imgbbApiKey;
  static const String imgbbEndpoint  = 'https://api.imgbb.com/1/upload';

  
  
  static final String cloudinaryCloudName    = Api.cloudinaryCloudName;
  static final String cloudinaryUploadPreset = Api.cloudinaryUploadPreset;
  static String get cloudinaryEndpoint =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  
  static const Duration requestTimeout = Duration(seconds: 30);
}




class UploadResult {
  const UploadResult._({
    required this.success,
    this.imageUrl,
    this.errorMessage,
    this.provider,
  });

  
  final bool success;

  
  final String? imageUrl;

  
  final String? errorMessage;

  
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




class ImageUploadService {
  ImageUploadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  
  
  

  
  
  
  Future<UploadResult> uploadImage(File imageFile) async {
    
    if (!imageFile.existsSync()) {
      return UploadResult.failure('Image file not found at: ${imageFile.path}');
    }

    
    try {
      final url = await _uploadToImgbb(imageFile);
      return UploadResult.success(imageUrl: url, provider: 'imgbb');
    } on _UploadException catch (e) {
      
      _log('ImgBB upload failed: ${e.message}. Trying Cloudinary...');
    } catch (e) {
      _log('ImgBB unexpected error: $e. Trying Cloudinary...');
    }

    
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

  
  
  

  Future<String> _uploadToImgbb(File imageFile) async {
    try {
      
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
    
  }

  
  
  

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

  
  
  

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _log(String message) {
    
    assert(() {
      
      print('[ImageUploadService] $message');
      return true;
    }());
  }

  
  void dispose() => _client.close();
}




class _UploadException implements Exception {
  const _UploadException(this.message);
  final String message;

  @override
  String toString() => '_UploadException: $message';
}