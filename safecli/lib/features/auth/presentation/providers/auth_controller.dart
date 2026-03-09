import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safeclik/features/auth/data/models/user_model.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_state.dart';
import 'package:safeclik/core/network/api_client.dart';
import 'package:safeclik/core/network/auth_api.dart';
import 'package:safeclik/core/di/di.dart';

export 'auth_state.dart';

// ── Secure token storage keys ─────────────────────────────────────────────
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

final _secureStorage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(sl<AuthApi>()),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;

  AuthNotifier(this._authApi) : super(const AuthState(isInitializing: true)) {
    _loadSavedUser();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _loadSavedUser() async {
    try {
      final token = await _secureStorage.read(key: _kAccessToken);
      if (token != null) {
        final response = await _authApi.getProfile();
        if (response['success'] == true && response.containsKey('user')) {
          state = state.copyWith(
            isInitializing: false,
            user: UserModel.fromJson(response['user']),
          );
          return;
        }
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
    sl<ApiClient>().cacheToken(null);
    state = state.copyWith(clearUser: true, clearError: true, isInitializing: false);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<bool> login(String username, String password) async {
    if (state.isInitializing && state.user == null && state.error == null) return false;
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authApi.login(username: username, password: password);
      if (response['success'] == true) {
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

      final response = await _authApi.register(
        name: name,
        email: email,
        password: password,
        passwordConfirm: password,
      );

      if (response['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = AuthState(
          isInitializing: false,
          isLoading: false,
          error: response['message'] ?? 'فشل إنشاء الحساب',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Register exception: $e');
      state = AuthState(isInitializing: false, isLoading: false, error: 'حدث خطأ غير متوقع');
    }
    return false;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final response = await _authApi.verifyOtp(email: email, otp: otp);
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        
        // If tokens and user are in response (Direct Login)
        if (data != null && data['tokens'] != null && data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          state = AuthState(isInitializing: false, isLoading: false, user: user);
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response['message'] ?? 'رمز التحقق غير صحيح',
      );
      return false;
      
    } catch (e) {
      debugPrint('VerifyOtp exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال');
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final response = await _authApi.resendOtp(email);
      if (response['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: response['message'] ?? 'فشل إعادة الإرسال',
      );
      return false;
      
    } catch (e) {
      debugPrint('ResendOtp exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authApi.logout().catchError((_) => <String, dynamic>{});
    } finally {
      await _clearTokens();
    }
  }

  Future<bool> verifyResetOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authApi.verifyResetOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      if (response['success'] == true) return true;
      state = state.copyWith(error: response['message'] ?? 'الرمز غير صحيح');
      return false;
    } catch (e) {
      debugPrint('VerifyResetOtp exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال');
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authApi.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      if (response['success'] == true) return true;
      state = state.copyWith(error: response['message'] ?? 'فشل طلب استعادة كلمة المرور');
      return false;
    } catch (e) {
      debugPrint('ForgotPassword exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال بالخادم');
      return false;
    }
  }

  Future<bool> confirmResetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authApi.resetPassword(
        email: email,
        otp: otp,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      if (response['success'] == true) return true;
      state = state.copyWith(error: response['message'] ?? 'فشل إعادة تعيين كلمة المرور');
      return false;
    } catch (e) {
      debugPrint('ConfirmResetPassword exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال بالخادم');
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authApi.updateProfile(name: name, email: email);
      if (response['user'] != null) {
        state = state.copyWith(
          isLoading: false,
          user: UserModel.fromJson(response['user']),
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response['message'] ?? 'فشل تحديث البيانات',
      );
      return false;
    } catch (e) {
      debugPrint('UpdateProfile exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال');
      return false;
    }
  }

  Future<bool> updateProfileImage(String imagePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authApi.updateProfileImage(imagePath);
      if (response['user'] != null) {
        state = state.copyWith(
          isLoading: false,
          user: UserModel.fromJson(response['user']),
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'فشل تحديث الصورة');
      return false;
    } catch (e) {
      debugPrint('UpdateProfileImage exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال');
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _authApi.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );
      state = state.copyWith(isLoading: false);
      if (response['success'] == true) return true;
      state = state.copyWith(error: response['message'] ?? 'فشل تغيير كلمة المرور');
      return false;
    } catch (e) {
      debugPrint('ChangePassword exception: $e');
      state = state.copyWith(isLoading: false, error: 'حدث خطأ في الاتصال بالخادم');
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Convenience getters ───────────────────────────────────────────────────
  bool get isAuthenticated => state.user != null;
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