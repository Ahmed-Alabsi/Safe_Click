import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String? _baseUrlOverride;
  
  static String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride!;
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  }

  String? _cachedToken;
  static final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    // Token injection interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        dio.options.baseUrl = baseUrl;
        _cachedToken ??= await _secureStorage.read(key: 'access_token');
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        return handler.next(options);
      },
    ));

    // Debug logging
    if (kDebugMode) {
      dio.interceptors.add(
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
      return;
    }

    if (kDebugMode) {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        if (!androidInfo.isPhysicalDevice) {
          _baseUrlOverride = 'http://10.0.2.2:8000/api';
          return;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          _baseUrlOverride = 'http://127.0.0.1:8000/api';
          return;
        }
      }
    }
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
  }

  void cacheToken(String? token) => _cachedToken = token;

  Map<String, dynamic> handleDioError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'message': 'انتهت مهلة الاتصال - تأكد من تشغيل السيرفر وعنوان الـ IP'};
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'message': 'الخادم استغرق وقتاً طويلاً للرد'};
      }
      if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
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
}
