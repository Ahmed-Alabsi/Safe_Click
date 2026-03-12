import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// مفاتيح التخزين الآمن
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

class ApiClient {
  static String? _baseUrlOverride;
  
  static String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride!;
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  }

  String? _cachedToken;
  String? _cachedRefreshToken;
  
  static final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final Dio dio;
  
  // Stream للتنبيه عند انتهاء التوكن
  final _tokenExpiredController = StreamController<bool>.broadcast();
  Stream<bool> get onTokenExpired => _tokenExpiredController.stream;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    // تحميل التوكنات عند إنشاء الكلاس
    _loadTokens();

    // Token injection interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        dio.options.baseUrl = baseUrl;
        
        // استخدام التوكن المخزن مؤقتاً
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
          debugPrint('🔑 [ApiClient] إضافة توكن للطلب: ${_cachedToken!.substring(0, _cachedToken!.length > 20 ? 20 : _cachedToken!.length)}...');
        } else {
          debugPrint('🔑 [ApiClient] لا يوجد توكن للطلب');
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        // إذا كان الخطأ 401 (Unauthorized) - التوكن منتهي
        if (error.response?.statusCode == 401) {
          debugPrint('🔄 [ApiClient] توكن منتهي، محاولة التحديث...');
          
          // محاولة تحديث التوكن
          final newToken = await _refreshAccessToken();
          
          if (newToken != null) {
            // إعادة المحاولة بالتوكن الجديد
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';
            
            try {
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              debugPrint('❌ [ApiClient] فشل إعادة المحاولة بعد تحديث التوكن: $e');
            }
          }
          
          // إذا فشل التحديث، أرسل إشارة بانتهاء التوكن
          _tokenExpiredController.add(true);
        }
        
        return handler.next(error);
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

  // تحميل التوكنات من التخزين الآمن
  Future<void> _loadTokens() async {
    try {
      _cachedToken = await _secureStorage.read(key: _kAccessToken);
      _cachedRefreshToken = await _secureStorage.read(key: _kRefreshToken);
      
      if (_cachedToken != null) {
        debugPrint('✅ [ApiClient] تم تحميل التوكن من التخزين الآمن');
      }
    } catch (e) {
      debugPrint('❌ [ApiClient] خطأ في تحميل التوكنات: $e');
    }
  }

  // حفظ التوكنات في التخزين الآمن والذاكرة المؤقتة
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      // حفظ في الذاكرة المؤقتة
      _cachedToken = accessToken;
      _cachedRefreshToken = refreshToken;
      
      // حفظ في التخزين الآمن
      await _secureStorage.write(key: _kAccessToken, value: accessToken);
      await _secureStorage.write(key: _kRefreshToken, value: refreshToken);
      
      debugPrint('✅ [ApiClient] تم حفظ التوكنات بنجاح');
    } catch (e) {
      debugPrint('❌ [ApiClient] خطأ في حفظ التوكنات: $e');
    }
  }

  // تحديث التوكن
  Future<String?> _refreshAccessToken() async {
    if (_cachedRefreshToken == null) {
      debugPrint('❌ [ApiClient] لا يوجد refresh token');
      return null;
    }
    
    try {
      debugPrint('🔄 [ApiClient] محاولة تحديث التوكن...');
      
      final response = await dio.post(
        '/auth/token/refresh/',
        data: {'refresh': _cachedRefreshToken},
      );
      
      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        
        // حفظ التوكن الجديد
        _cachedToken = newAccessToken;
        await _secureStorage.write(key: _kAccessToken, value: newAccessToken);
        
        debugPrint('✅ [ApiClient] تم تحديث التوكن بنجاح');
        return newAccessToken;
      }
    } catch (e) {
      debugPrint('❌ [ApiClient] فشل تحديث التوكن: $e');
    }
    
    return null;
  }

  // مسح التوكنات (تسجيل الخروج)
  Future<void> clearTokens() async {
    try {
      _cachedToken = null;
      _cachedRefreshToken = null;
      
      await _secureStorage.delete(key: _kAccessToken);
      await _secureStorage.delete(key: _kRefreshToken);
      
      debugPrint('🗑️ [ApiClient] تم مسح التوكنات');
    } catch (e) {
      debugPrint('❌ [ApiClient] خطأ في مسح التوكنات: $e');
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

  void cacheToken(String? token) {
    _cachedToken = token;
    if (token != null) {
      debugPrint('🔑 [ApiClient] تحديث التوكن في الذاكرة المؤقتة');
    }
  }

  // التحقق من حالة التوكن
  bool get hasValidToken => _cachedToken != null && _cachedToken!.isNotEmpty;

  Map<String, dynamic> handleDioError(dynamic e) {
    if (e is DioException) {
      if (e.response?.statusCode == 401) {
        return {
          'success': false, 
          'message': 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'
        };
      }
      
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout) {
        return {
          'success': false, 
          'message': 'انتهت مهلة الاتصال بالخادم. يرجى التأكد من جودة الإنترنت وحالة السيرفر.'
        };
      }
      
      if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'success': false, 
          'message': 'استغرق الخادم وقتاً أطول من المعتاد للرد. يرجى المحاولة لاحقاً.'
        };
      }
      
      if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
        return {
          'success': false, 
          'message': 'تعذر الاتصال بالخادم. يرجى التأكد من أنك متصل بالإنترنت وأن الخادم قيد التشغيل.'
        };
      }

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        // Common Status Codes
        if (statusCode == 404) {
          return {'success': false, 'message': 'الرابط أو الخدمة المطلوبة غير متوفرة حالياً.'};
        }
        if (statusCode == 500) {
          return {'success': false, 'message': 'حدث عطل فني في السيرفر. فريقنا يعمل على إصلاحه.'};
        }
        if (statusCode == 403) {
          return {'success': false, 'message': 'ليس لديك صلاحية للقيام بهذا الإجراء.'};
        }
        if (statusCode == 429) {
          return {'success': false, 'message': 'لقد قمت بالكثير من المحاولات. يرجى الانتظار قليلاً ثم المحاولة مرة أخرى.'};
        }

        if (data is Map<String, dynamic>) {
          // Check for specific backend error messages
          if (data.containsKey('message')) {
            return {'success': false, 'message': data['message']};
          }
          if (data.containsKey('detail')) {
            return {'success': false, 'message': data['detail']};
          }
          if (data.containsKey('errors')) {
            final errors = data['errors'];
            if (errors is Map) return {'success': false, 'message': errors.values.expand((v) => v is List ? v : [v]).join('\n')};
            if (errors is List) return {'success': false, 'message': errors.join('\n')};
            return {'success': false, 'message': errors.toString()};
          }
          
          // Fallback for Field Errors (Validation)
          final fieldErrors = data.entries.where((e) => e.value is List).map((e) => e.value.join(', ')).join('\n');
          if (fieldErrors.isNotEmpty) return {'success': false, 'message': fieldErrors};
        }
      }
    }
    return {'success': false, 'message': 'حدث خطأ غير متوقع. يرجى التأكد من الاتصال والمحاولة مرة أخرى.'};
  }
}