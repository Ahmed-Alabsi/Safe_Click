import 'package:safeclik/features/auth/data/models/user_model.dart';

class AuthState {
  final bool isInitializing;
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool hasToken;
  final bool isGuest; // ✅ للزائر
  final int guestScansCount; // ✅ عدد فحوصات الزائر

  const AuthState({
    this.isInitializing = true,
    this.isLoading = false,
    this.user,
    this.error,
    this.hasToken = false,
    this.isGuest = false,
    this.guestScansCount = 0,
  });

  bool get isAuthenticated => user != null || hasToken;
  
  // ✅ Getter للفحوصات المتبقية
  int get remainingGuestScans {
    if (!isGuest) return 0;
    return 3 - guestScansCount;
  }
  
  // ✅ التحقق من إمكانية الفحص
  bool get canGuestScan {
    if (!isGuest) return false;
    return guestScansCount < 3;
  }

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? hasToken,
    bool? isGuest,
    int? guestScansCount,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      hasToken: hasToken ?? this.hasToken,
      isGuest: isGuest ?? this.isGuest,
      guestScansCount: guestScansCount ?? this.guestScansCount,
    );
  }

  @override
  String toString() =>
      'AuthState(init=$isInitializing, user=${user?.email}, error=$error, isGuest=$isGuest, scans=$guestScansCount/3)';
}