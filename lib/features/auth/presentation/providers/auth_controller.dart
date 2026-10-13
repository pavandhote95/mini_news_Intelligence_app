import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/user.dart';

@immutable
class AuthState {
  const AuthState({this.user, this.isLoading = false, this.failure});

  final User? user;
  final bool isLoading;
  final Failure? failure;

  bool get isAuthenticated => user != null;
}

/// Owns the session. The router listens to [AuthState.isAuthenticated]
/// to redirect between the login screen and the app.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState(user: ref.read(getCurrentUserProvider)());

  Future<bool> login({required String email, required String password}) async {
    if (state.isLoading) return false;
    state = AuthState(user: state.user, isLoading: true);

    final result = await ref.read(loginProvider)(email: email, password: password);
    return result.fold<bool>(
      onSuccess: (user) {
        state = AuthState(user: user);
        return true;
      },
      onFailure: (failure) {
        state = AuthState(failure: failure);
        return false;
      },
    );
  }

  Future<void> logout() async {
    final result = await ref.read(logoutProvider)();
    result.fold<void>(
      onSuccess: (_) => state = const AuthState(),
      onFailure: (failure) => state = AuthState(user: state.user, failure: failure),
    );
  }

  void clearError() {
    if (state.failure != null) state = AuthState(user: state.user);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
