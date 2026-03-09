import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safeclik/core/network/api_client.dart';

class AuthApi {
  final ApiClient _client;
  static final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthApi(this._client);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await _client.dio.post('/auth/send-otp/', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
        'purpose': 'register',
      });
      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'تم إرسال رمز التحقق'};
      }
      return {'success': false, 'message': data['message'] ?? 'فشل إرسال رمز التحقق'};
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.dio.post('/auth/verify-otp/', data: {
        'email': email,
        'otp': otp,
      });
      final data = response.data;
      if (data['success'] == true) {
        // If tokens are returned (direct login after registration)
        if (data['tokens'] != null) {
          final access = data['tokens']['access'] as String?;
          final refresh = data['tokens']['refresh'] as String?;
          if (access != null) {
            await _secureStorage.write(key: 'access_token', value: access);
            _client.cacheToken(access);
          }
          if (refresh != null) await _secureStorage.write(key: 'refresh_token', value: refresh);
        }
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'رمز غير صحيح'};
    } catch (e) {
      if (e is DioException && e.response != null) {
         final errorData = e.response!.data;
         return {'success': false, 'message': errorData['message'] ?? 'رمز غير صحيح'};
      }
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final response = await _client.dio.post('/auth/resend-otp/', data: {'email': email});
      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'تم إعادة إرسال الرمز'};
      }
      return {'success': false, 'message': data['message'] ?? 'فشل إعادة الإرسال'};
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/auth/login/', data: {
        'username': username,
        'password': password,
      });
      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        final access = data['tokens']['access'] as String?;
        final refresh = data['tokens']['refresh'] as String?;
        if (access != null) {
          await _secureStorage.write(key: 'access_token', value: access);
          _client.cacheToken(access);
        }
        if (refresh != null) await _secureStorage.write(key: 'refresh_token', value: refresh);
        return data;
      }
      return data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response!.data;
        return {'success': false, 'message': errorData['message'] ?? 'اسم المستخدم أو كلمة المرور غير صحيحة'};
      }
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      await _client.dio.post('/auth/logout/', data: {'refresh': refreshToken});
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _client.cacheToken(null);
      return {'success': true};
    } catch (e) {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _client.cacheToken(null);
      return {'success': true, 'message': 'تم تسجيل الخروج محلياً'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.dio.get('/auth/profile/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({String? name, String? email}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      final response = await _client.dio.patch('/auth/profile/', data: body);
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfileImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _client.dio.patch('/auth/profile/', data: formData);
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _client.dio.post('/auth/change-password/', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      });
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _client.dio.post('/auth/forgot-password/', data: {'email': email});
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        return e.response!.data;
      }
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.dio.post('/auth/verify-reset-otp/', data: {
        'email': email,
        'otp': otp,
      });
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        return e.response!.data;
      }
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/auth/reset-password/', data: {
        'email': email,
        'otp': otp,
        'password': password,
      });
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        return e.response!.data;
      }
      return _client.handleDioError(e);
    }
  }
}
