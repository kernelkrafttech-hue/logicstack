import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/avatar_repository.dart';

final Provider<AvatarRepository> avatarRepositoryProvider =
    Provider<AvatarRepository>(
  (ProviderRef<AvatarRepository> ref) => AvatarRepository(),
);

/// Drives the profile edit form. Emits an [AsyncValue] so the screen can
/// show inline progress on save and surface error messages.
class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this._auth, this._avatars)
      : super(const AsyncValue<void>.data(null));

  final AuthRepository _auth;
  final AvatarRepository _avatars;

  /// Saves profile fields. When [photoFile] is non-null it's uploaded to
  /// Storage first and the returned URL is persisted alongside the rest.
  Future<bool> save({
    required AppUser user,
    required String displayName,
    required String phone,
    required String companyName,
    File? photoFile,
  }) async {
    state = const AsyncValue<void>.loading();
    try {
      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _avatars.uploadAvatar(
          uid: user.uid,
          file: photoFile,
        );
      }
      await _auth.updateProfile(
        uid: user.uid,
        displayName: displayName,
        phone: phone,
        companyName: companyName,
        photoUrl: photoUrl,
      );
      state = const AsyncValue<void>.data(null);
      return true;
    } on AuthException catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return false;
    } on AvatarException catch (e, st) {
      state = AsyncValue<void>.error(AuthException(e.message), st);
      return false;
    } catch (e, st) {
      state = AsyncValue<void>.error(
        AuthException('Could not save your profile.'),
        st,
      );
      return false;
    }
  }
}

final StateNotifierProvider<ProfileController, AsyncValue<void>>
    profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>(
  (StateNotifierProviderRef<ProfileController, AsyncValue<void>> ref) {
    return ProfileController(
      ref.watch(authRepositoryProvider),
      ref.watch(avatarRepositoryProvider),
    );
  },
);
