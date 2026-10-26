import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/user_role.dart';
import 'auth_providers.dart';

/// Drives the login/signup screens.
///
/// Holds an [AsyncValue] so screens can show progress and surface
/// [AuthException] messages without each screen wiring its own try/catch.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncValue<void>.data(null));

  final AuthRepository _repo;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => _repo.signIn(email: email, password: password),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => _repo.signUp(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      ),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(() => _repo.sendPasswordReset(email));
  }

  Future<void> signOut() async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(_repo.signOut);
  }
}

final StateNotifierProvider<AuthController, AsyncValue<void>>
    authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
  (StateNotifierProviderRef<AuthController, AsyncValue<void>> ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);
