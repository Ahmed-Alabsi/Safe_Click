// lib/features/auth/presentation/providers/auth_state.dart
//
// Reactive AuthState for Riverpod StateNotifier.
// All fields — including initialization status and error — are part of
// the state object, ensuring the UI rebuilds correctly on every change.

import 'package:safeclik/features/auth/data/models/user_model.dart';

class AuthState {
  final bool isInitializing;
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isInitializing = true,
    this.isLoading = false,
    this.user,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    UserModel? user,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() =>
      'AuthState(init=$isInitializing, user=${user?.email}, error=$error)';
}
