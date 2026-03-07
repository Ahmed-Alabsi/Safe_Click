import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safeclik/features/auth/data/models/user_model.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_state.dart';
import 'package:safeclik/core/network/api_service.dart';
import 'package:safeclik/core/di/di.dart';

export 'auth_state.dart';

// ── Secure token storage keys ─────────────────────────────────────────────
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

final _secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = sl<ApiService>();

  AuthNotifier() : super(const AuthState(isInitializing: true)) {
    _loadSavedUser();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _loadSavedUser() async {
    try {
      final token = await _secureStorage.read(key: _kAccessToken);
      if (token != null) {
        final response = await _apiService.getProfile();
        if (response['success'] == true && response.containsKey('user')) {
          state = state.copyWith(
            isInitializing: false,
            user: UserModel.fromJson(response['user']),
          );
          return;
        }
        // Invalid / expired token — purge
        await _clearTokens();
      }
    } catch (e) {
      debugPrint('AuthNotifier._loadSavedUser error: $e');
    }
    state = state.copyWith(isInitializing: false);
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: _kAccessToken);
    await _secureStorage.delete(key: _kRefreshToken);
    state = state.copyWith(clearUser: true, clearError: true, isInitializing: false);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    // Only block if we are actually initializing
    if (state.isInitializing && state.user == null && state.error == null) return false;
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiService.login(email: email, password: password);
      if (response['success'] == true) {
        // Persist tokens in secure storage
        final tokens = response['tokens'];
        if (tokens != null) {
          await _secureStorage.write(key: _kAccessToken, value: tokens['access']);
          await _secureStorage.write(key: _kRefreshToken, value: tokens['refresh']);
          // Also push to ApiService in-memory cache
          sl<ApiService>().cacheToken(tokens['access']);
        }
        final user = UserModel.fromJson(response['user']);
        state = AuthState(isInitializing: false, isLoading: false, user: user);
        return true;
      } else {
        state = AuthState(
          isInitializing: false,
          isLoading: false,
          error: response['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        );
        return false;
      }
    } on SocketException {
      state = AuthState(isInitializing: false, isLoading: false, error: 'تعذر الاتصال بالخادم');
    } on TimeoutException {
      state = AuthState(isInitializing: false, isLoading: false, error: 'انتهت مهلة الاتصال بالخادم');
    } catch (e) {
      debugPrint('Login exception: $e');
      state = AuthState(isInitializing: false, isLoading: false, error: 'تعذر الاتصال بالخادم');
    }
    return false;
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    required bool agreeToTerms,
  }) async {
    if (state.isInitializing) return false;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (!agreeToTerms) {
        state = AuthState(isInitializing: false, isLoading: false, error: 'يجب الموافقة على الشروط والأحكام');
        return false;
      }
      if (password.length < 6) {
        state = AuthState(isInitializing: false, isLoading: false, error: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
        return false;
      }

      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirm: password,
      );

      if (response['success'] == true) {
        if (response.containsKey('user')) {
          final user = UserModel.fromJson(response['user']);
          state = AuthState(isInitializing: false, isLoading: false, user: user);
          return true;
        } else {
          state = state.copyWith(isLoading: false);
          return await login(email, password);
        }
      } else {
        state = AuthState(
          isInitializing: false,
          isLoading: false,
          error: response['message'] ?? 'فشل إنشاء الحساب',
        );
        return false;
      }
    } on SocketException {
      state = AuthState(isInitializing: false, isLoading: false, error: 'تعذر الاتصال بالخادم');
    } on TimeoutException {
      state = AuthState(isInitializing: false, isLoading: false, error: 'انتهت مهلة الاتصال بالخادم');
    } catch (_) {
      state = AuthState(isInitializing: false, isLoading: false, error: 'حدث خطأ غير متوقع');
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await _apiService.logout().catchError((_) => <String, dynamic>{});
    } finally {
      await _clearTokens();
      sl<ApiService>().cacheToken(null);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      final response = await _apiService.forgotPassword(email);
      state = state.copyWith(isInitializing: false);
      return response['success'] == true;
    } catch (_) {
      state = AuthState(isInitializing: false, error: 'حدث خطأ في الاتصال بالخادم');
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      final response = await _apiService.updateProfile(name: name, email: email);
      if (response['success'] == true && response.containsKey('user')) {
        state = AuthState(
          isInitializing: false,
          user: UserModel.fromJson(response['user']),
        );
        return true;
      }
      state = AuthState(
        isInitializing: false,
        error: response['message'] ?? 'فشل تحديث البيانات',
      );
      return false;
    } catch (_) {
      state = AuthState(isInitializing: false, error: 'حدث خطأ في الاتصال');
      return false;
    }
  }

  Future<bool> updateProfileImage(String imagePath) async {
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      final response = await _apiService.updateProfileImage(imagePath);
      if (response['success'] == true && response.containsKey('user')) {
        state = AuthState(
          isInitializing: false,
          user: UserModel.fromJson(response['user']),
        );
        return true;
      }
      state = AuthState(isInitializing: false, error: 'فشل تحديث الصورة');
      return false;
    } catch (_) {
      state = AuthState(isInitializing: false, error: 'حدث خطأ في الاتصال');
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      final response = await _apiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );
      state = state.copyWith(isInitializing: false);
      if (response['success'] == true) return true;
      state = state.copyWith(error: response['message'] ?? 'فشل تغيير كلمة المرور');
      return false;
    } catch (_) {
      state = AuthState(isInitializing: false, error: 'حدث خطأ في الاتصال بالخادم');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Convenience getters (computed from state) ─────────────────────────────
  bool get isAuthenticated => state.isAuthenticated;
  bool get isInitializing => state.isInitializing;
  String? get error => state.error;
  String? get userProfileImage => state.user?.profileImage;
  String get userName => state.user?.name ?? '';
  String get userEmail => state.user?.email ?? '';
  int get userScansCount => state.user?.scannedLinks ?? 0;
  int get userThreatsCount => state.user?.detectedThreats ?? 0;
  double get userAccuracyRate => state.user?.accuracyRate ?? 0.0;
  bool get isEmailVerified => state.user?.isEmailVerified ?? false;
  String get welcomeMessage =>
      isAuthenticated ? 'مرحباً، ${state.user?.name ?? ''}' : 'مرحباً بك';
}