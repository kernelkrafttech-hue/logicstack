import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/property_repository.dart';
import '../domain/property.dart';

final Provider<PropertyRepository> propertyRepositoryProvider =
    Provider<PropertyRepository>(
  (ProviderRef<PropertyRepository> ref) => PropertyRepository(),
);

/// Live list of properties for the signed-in landlord.
///
/// Emits an empty list when nobody is signed in so list screens can render a
/// stable empty state during sign-out transitions instead of throwing.
final StreamProvider<List<Property>> myPropertiesProvider =
    StreamProvider<List<Property>>(
  (StreamProviderRef<List<Property>> ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Stream<List<Property>>.value(<Property>[]);
    }
    return ref
        .watch(propertyRepositoryProvider)
        .watchPropertiesForOwner(user.uid);
  },
);

final StreamProviderFamily<Property?, String> propertyByIdProvider =
    StreamProvider.family<Property?, String>(
  (StreamProviderRef<Property?> ref, String id) {
    return ref.watch(propertyRepositoryProvider).watchProperty(id);
  },
);

class AddPropertyController extends StateNotifier<AsyncValue<void>> {
  AddPropertyController(this._repo) : super(const AsyncValue<void>.data(null));

  final PropertyRepository _repo;

  /// Persists a new property. Returns the saved [Property] on success and
  /// `null` on failure (after publishing an error into [state]).
  Future<Property?> submit({
    required String ownerId,
    required String name,
    required String address,
    required String unit,
    required String city,
    required String state,
    required String zipCode,
  }) async {
    this.state = const AsyncValue<void>.loading();
    try {
      final Property property = await _repo.createProperty(
        ownerId: ownerId,
        name: name,
        address: address,
        unit: unit,
        city: city,
        state: state,
        zipCode: zipCode,
      );
      this.state = const AsyncValue<void>.data(null);
      return property;
    } on PropertyException catch (e, st) {
      this.state = AsyncValue<void>.error(e, st);
      return null;
    } catch (e, st) {
      this.state = AsyncValue<void>.error(
        PropertyException('Something went wrong. Please try again.'),
        st,
      );
      return null;
    }
  }
}

final StateNotifierProvider<AddPropertyController, AsyncValue<void>>
    addPropertyControllerProvider =
    StateNotifierProvider<AddPropertyController, AsyncValue<void>>(
  (StateNotifierProviderRef<AddPropertyController, AsyncValue<void>> ref) {
    return AddPropertyController(ref.watch(propertyRepositoryProvider));
  },
);
