import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;
  final int? statusCode;

  ApiResponse.success(this.data, {this.statusCode})
      : isSuccess = true,
        errorMessage = null;

  ApiResponse.error(this.errorMessage, {this.statusCode})
      : isSuccess = false,
        data = null;
}

class ApiClient {
  static const Duration timeoutDuration = Duration(seconds: 25);
  static const Duration uploadTimeoutDuration = Duration(seconds: 90);

  Future<Map<String, String>> _getHeaders() async {
    final token = await AppConfig.getAuthToken();
    return {
      'Authorization': 'Bearer $token',
      'X-API-Key': token,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Sunucu sağlık durumunu test eder
  Future<ApiResponse<bool>> checkHealth() async {
    try {
      final baseUrl = await AppConfig.getServerUrl();
      final uri = Uri.parse('$baseUrl/api/v1/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return ApiResponse.success(true, statusCode: 200);
      } else {
        return ApiResponse.error(
          'Sunucu yanıt verdi ancak durum kodu: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Sunucuya erişilemiyor (Bağlantı reddedildi veya adres hatalı).');
    } on TimeoutException {
      return ApiResponse.error('Sunucu bağlantısı zaman aşımına uğradı.');
    } catch (e) {
      return ApiResponse.error('Bağlantı hatası: $e');
    }
  }

  /// Klasör taslağı oluşturur veya mevcut olanı alır
  Future<ApiResponse<Map<String, dynamic>>> createCollection({
    required String id,
    required String name,
  }) async {
    try {
      final baseUrl = await AppConfig.getServerUrl();
      final uri = Uri.parse('$baseUrl/api/v1/collections');
      final headers = await _getHeaders();

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({'id': id, 'name': name}),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Fotoğraf yükler (Multipart/form-data)
  Future<ApiResponse<Map<String, dynamic>>> uploadPhoto({
    required String collectionId,
    required String filePath,
    required int sequenceNumber,
  }) async {
    try {
      final baseUrl = await AppConfig.getServerUrl();
      final uri = Uri.parse('$baseUrl/api/v1/collections/$collectionId/photos');
      final token = await AppConfig.getAuthToken();

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-API-Key'] = token;

      request.fields['sequence_number'] = sequenceNumber.toString();

      final file = File(filePath);
      if (!await file.exists()) {
        return ApiResponse.error('Yüklenecek fotoğraf dosyası cihazda bulunamadı: $filePath');
      }

      final multipartFile = await http.MultipartFile.fromPath('file', file.path);
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(uploadTimeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Notları kaydeder
  Future<ApiResponse<Map<String, dynamic>>> updateNotes({
    required String collectionId,
    required String content,
    required String format,
  }) async {
    try {
      final baseUrl = await AppConfig.getServerUrl();
      final uri = Uri.parse('$baseUrl/api/v1/collections/$collectionId/notes');
      final headers = await _getHeaders();

      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode({'content': content, 'format': format}),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Klasörü tamamlandı durumuna getirir
  Future<ApiResponse<Map<String, dynamic>>> completeCollection({
    required String collectionId,
  }) async {
    try {
      final baseUrl = await AppConfig.getServerUrl();
      final uri = Uri.parse('$baseUrl/api/v1/collections/$collectionId/complete');
      final headers = await _getHeaders();

      final response = await http
          .post(uri, headers: headers)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return _handleException(e);
    }
  }

  /// Önceki klasörleri listeler
  Future<ApiResponse<List<dynamic>>> listCollections() async {
    try {
      final baseUrl = await AppConfig.getServerUrl();
      final uri = Uri.parse('$baseUrl/api/v1/collections');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return ApiResponse.success(decoded, statusCode: 200);
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      return _handleException(e);
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    try {
      final body = utf8.decode(response.bodyBytes);
      final json = body.isNotEmpty ? jsonDecode(body) : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(json as T?, statusCode: response.statusCode);
      }

      String message = 'Bilinmeyen sunucu yanıtı (${response.statusCode})';
      if (json is Map && json.containsKey('detail')) {
        message = json['detail'].toString();
      }

      if (response.statusCode == 401) {
        message = 'Yetkisiz erişim: Sunucu API anahtarınızı kabul etmedi.';
      } else if (response.statusCode == 413) {
        message = 'Dosya boyutu çok büyük (Sunucu limitini aşıyor).';
      }

      return ApiResponse.error(message, statusCode: response.statusCode);
    } catch (_) {
      return ApiResponse.error(
        'Sunucudan geçersiz yanıt alındı (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  ApiResponse<T> _handleException<T>(dynamic e) {
    if (e is SocketException) {
      return ApiResponse.error('Sunucuya bağlanılamadı. İnternet ve sunucu adresini kontrol edin.');
    } else if (e is TimeoutException) {
      return ApiResponse.error('İşlem zaman aşımına uğradı. Ağ bağlantınızı kontrol edin.');
    } else {
      return ApiResponse.error('Beklenmeyen bir hata oluştu: $e');
    }
  }
}
