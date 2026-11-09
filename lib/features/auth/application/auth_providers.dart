import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (ProviderRef<AuthRepository> ref) => AuthRepository(),
);

/// Stream of the raw Firebase auth user. Used by the router to gate access.
final StreamProvider<User?> authStateProvider = StreamProvider<User?>(
  (StreamProviderRef<User?> ref) {
    return ref.watch(authRepositoryProvider).authStateChanges();
  },
);

/// Stream of the rich [AppUser] profile (auth user + Firestore profile doc).
///
/// Emits `null` when signed out, and emits the populated profile once both the
/// auth user and the Firestore profile document have loaded.
final StreamProvider<AppUser?> appUserProvider = StreamProvider<AppUser?>(
  (StreamProviderRef<AppUser?> ref) async* {
    final AuthRepository repo = ref.watch(authRepositoryProvider);
    final AsyncValue<User?> auth = ref.watch(authStateProvider);

    final User? user = auth.valueOrNull;
    if (user == null) {
      yield null;
      return;
    }
    yield* repo.watchAppUser(user.uid);
  },
);
