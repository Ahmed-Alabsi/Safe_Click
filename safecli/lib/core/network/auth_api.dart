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
      final response = await _client.dio.post('/auth/register/', data: {
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
          _client.cacheToken(data['tokens']['access']);
        }
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['message'] ?? 'فشل التسجيل'};
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/auth/login/', data: {
        'email': email,
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
        final status = e.response!.statusCode;
        if (status == 401 || status == 400 || status == 403) {
          return {'success': false, 'message': 'البريد الإلكتروني أو كلمة المرور غير صحيحة'};
        }
      }
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      await _client.dio.post('/auth/logout/', data: {'refresh_token': refreshToken});
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
      final response = await _client.dio.put('/auth/profile/', data: body);
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
      final response = await _client.dio.put('/auth/profile/', data: formData);
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
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await _client.dio.post('/auth/reset-password/', data: {
        'token': token,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      });
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await _client.dio.get('/auth/verify-email/', queryParameters: {'token': token});
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }
}
