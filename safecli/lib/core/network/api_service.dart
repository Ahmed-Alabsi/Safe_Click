// lib/core/network/api_service.dart
//
// PHASE 1 FIX: baseUrl loaded from .env via flutter_dotenv.
// PHASE 3 FIX: In-memory token cache — eliminates disk I/O per request.
// PHASE 2 FIX: Token storage uses flutter_secure_storage.
// PHASE 4 FIX: Removed duplicate scanUrl() — use scanLink() only.
// PHASE 5 FIX: Migrated from http to dio for better performance and timeout control.
// PHASE 6 FIX: Smart API Discovery — Auto-detects Emulator (10.0.2.2) and allows runtime override.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _baseUrlOverride;
  
  static String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride!;
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  }

  String? _cachedToken;
  static final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    // Token injection interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Dynamically update baseUrl in case override was set after initialization
        _dio.options.baseUrl = baseUrl;
        _cachedToken ??= await _secureStorage.read(key: 'access_token');
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        return handler.next(options);
      },
    ));

    // Debug logging — traces request/response times in the console
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          requestBody: false,
          responseBody: false,
          logPrint: (msg) => debugPrint('🌐 [Dio] $msg'),
        ),
      );
    }
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOverride = prefs.getString('api_base_url_override');
    
    if (savedOverride != null && savedOverride.isNotEmpty) {
      _baseUrlOverride = savedOverride;
      debugPrint('🚀 [API] Using manual override: $_baseUrlOverride');
      return;
    }

    // Smart Detection for Emulators (only in Debug mode)
    if (kDebugMode) {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        if (!androidInfo.isPhysicalDevice) {
          _baseUrlOverride = 'http://10.0.2.2:8000/api';
          debugPrint('📱 [API] Emulator detected. Using: $_baseUrlOverride');
          return;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          _baseUrlOverride = 'http://127.0.0.1:8000/api';
          debugPrint('🍎 [API] iOS Simulator detected. Using: $_baseUrlOverride');
          return;
        }
      }
    }
    
    debugPrint('🌐 [API] Using default baseUrl: $baseUrl');
  }

  static Future<void> updateBaseUrl(String newUrl) async {
    _baseUrlOverride = newUrl;
    final prefs = await SharedPreferences.getInstance();
    if (newUrl.isEmpty) {
      await prefs.remove('api_base_url_override');
      _baseUrlOverride = null;
    } else {
      await prefs.setString('api_base_url_override', newUrl);
    }
    debugPrint('🔄 [API] Base URL updated to: $baseUrl');
  }

  void cacheToken(String? token) => _cachedToken = token;

  // ── Error Handling Helper ──────────────────────────────────────────────────

  Map<String, dynamic> _handleDioError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'message': 'انتهت مهلة الاتصال - تأكد من تشغيل السيرفر وعنوان الـ IP'};
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'message': 'الخادم استغرق وقتاً طويلاً للرد'};
      }
      if (e.error is SocketException) {
        return {
          'success': false, 
          'message': 'تعذر الاتصال بالخادم ($baseUrl).\nتأكد من عنوان الـ IP وصحة الاتصال.'
        };
      }
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          String errorMessage = 'فشل الطلب';
          if (data.containsKey('errors')) {
            final errors = data['errors'];
            if (errors is Map) errorMessage = errors.values.join('\n');
            if (errors is List) errorMessage = errors.join('\n');
          } else if (data.containsKey('message')) {
            errorMessage = data['message'];
          }
          return {'success': false, 'message': errorMessage};
        }
      }
    }
    return {'success': false, 'message': 'حدث خطأ غير متوقع في الاتصال'};
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await _dio.post('/auth/register/', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      });
      final data = response.data;
      if (response.statusCode == 201 && data['success'] == true) {
        if (data.containsKey('tokens')) {
          await _secureStorage.write(key: 'access_token', value: data['tokens']['access']);
          await _secureStorage.write(key: 'refresh_token', value: data['tokens']['refresh']);
          _cachedToken = data['tokens']['access'];
        }
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['message'] ?? 'فشل التسجيل'};
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'email': email,
        'password': password,
      });
      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        final access = data['tokens']['access'] as String?;
        final refresh = data['tokens']['refresh'] as String?;
        if (access != null) {
          await _secureStorage.write(key: 'access_token', value: access);
          _cachedToken = access;
        }
        if (refresh != null) {
          await _secureStorage.write(key: 'refresh_token', value: refresh);
        }
        return data;
      }
      return data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final status = e.response!.statusCode;
        if (status == 401 || status == 400 || status == 403) {
          return {'success': false, 'message': 'البريد الإلكتروني أو كلمة المرور غير صحيحة'};
        }
      }
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      await _dio.post('/auth/logout/', data: {'refresh_token': refreshToken});
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _cachedToken = null;
      return {'success': true};
    } catch (e) {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _cachedToken = null;
      return {'success': true, 'message': 'تم تسجيل الخروج محلياً'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({String? name, String? email}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      final response = await _dio.put('/auth/profile/', data: body);
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfileImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.put('/auth/profile/', data: formData);
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _dio.post('/auth/change-password/', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      });
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/auth/forgot-password/', data: {'email': email});
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _dio.post('/auth/reset-password/', data: {
        'token': token,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      });
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await _dio.get('/auth/verify-email/', queryParameters: {'token': token});
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/auth/settings/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _dio.put('/auth/settings/', data: settings);
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ── Scans ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> scanLink(String link) async {
    try {
      final response = await _dio.post('/scans/scan/', data: {'link': link}, 
      options: Options(receiveTimeout: const Duration(seconds: 30)));
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getScanHistory() async {
    try {
      final response = await _dio.get('/scans/history/');
      return response.data;
    } catch (e) {
      final err = _handleDioError(e);
      err['history'] = [];
      return err;
    }
  }

  Future<Map<String, dynamic>> getScanDetail(String scanId) async {
    try {
      final response = await _dio.get('/scans/history/$scanId/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> deleteScan(String scanId) async {
    try {
      final response = await _dio.delete('/scans/history/$scanId/delete/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> clearHistory() async {
    try {
      final response = await _dio.delete('/scans/history/clear/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getScanStats() async {
    try {
      final response = await _dio.get('/scans/stats/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createReport({
    required String link,
    required String category,
    String? description,
    int severity = 3,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _dio.post('/reports/create/', data: {
        'link': link,
        'category': category,
        'description': description ?? '',
        'severity': severity,
        'is_anonymous': isAnonymous,
      });
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> trackReport(String trackingNumber) async {
    try {
      final response = await _dio.get('/reports/track/$trackingNumber/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMyReports() async {
    try {
      final response = await _dio.get('/reports/my-reports/');
      return response.data;
    } catch (e) {
       final err = _handleDioError(e);
       err['reports'] = [];
       return err;
    }
  }

  Future<Map<String, dynamic>> getReportDetail(String reportId) async {
    try {
      final response = await _dio.get('/reports/$reportId/');
      return response.data;
    } catch (e) {
      return _handleDioError(e);
    }
  }
}
