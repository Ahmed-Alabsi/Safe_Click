import 'package:safeclik/features/auth/data/models/user_model.dart';

class AuthState {
  final bool isInitializing;
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool hasToken;

  const AuthState({
    this.isInitializing = true,
    this.isLoading = false,
    this.user,
    this.error,
    this.hasToken = false,
  });

  bool get isAuthenticated => user != null || hasToken;

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? hasToken,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      hasToken: hasToken ?? this.hasToken,
    );
  }

  @override
  String toString() =>
      'AuthState(init=$isInitializing, user=${user?.email}, error=$error)';
}