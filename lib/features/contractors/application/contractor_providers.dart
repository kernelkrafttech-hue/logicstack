import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/contractor_repository.dart';
import '../domain/contractor.dart';

final Provider<ContractorRepository> contractorRepositoryProvider =
    Provider<ContractorRepository>(
  (ProviderRef<ContractorRepository> ref) => ContractorRepository(),
);

/// Live list of contractors in the signed-in landlord's roster.
final StreamProvider<List<Contractor>> myContractorsProvider =
    StreamProvider<List<Contractor>>(
  (StreamProviderRef<List<Contractor>> ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Stream<List<Contractor>>.value(<Contractor>[]);
    }
    return ref
        .watch(contractorRepositoryProvider)
        .watchContractorsForLandlord(user.uid);
  },
);

final StreamProviderFamily<Contractor?, String> contractorByIdProvider =
    StreamProvider.family<Contractor?, String>(
  (StreamProviderRef<Contractor?> ref, String id) {
    return ref.watch(contractorRepositoryProvider).watchContractor(id);
  },
);

/// Drives the add / edit form's loading + error state.
class ContractorFormController extends StateNotifier<AsyncValue<void>> {
  ContractorFormController(this._repo)
      : super(const AsyncValue<void>.data(null));

  final ContractorRepository _repo;

  Future<Contractor?> create({
    required String landlordId,
    required String name,
    required String companyName,
    required String phone,
    required String email,
    required ContractorTrade trade,
  }) async {
    state = const AsyncValue<void>.loading();
    try {
      final Contractor c = await _repo.createContractor(
        landlordId: landlordId,
        name: name,
        companyName: companyName,
        phone: phone,
        email: email,
        trade: trade,
      );
      state = const AsyncValue<void>.data(null);
      return c;
    } on ContractorException catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return null;
    } catch (e, st) {
      state = AsyncValue<void>.error(
        ContractorException('Could not save contractor.'),
        st,
      );
      return null;
    }
  }

  Future<bool> save(Contractor contractor) async {
    state = const AsyncValue<void>.loading();
    try {
      await _repo.updateContractor(contractor);
      state = const AsyncValue<void>.data(null);
      return true;
    } on ContractorException catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue<void>.error(
        ContractorException('Could not save contractor.'),
        st,
      );
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue<void>.loading();
    try {
      await _repo.deleteContractor(id);
      state = const AsyncValue<void>.data(null);
      return true;
    } on ContractorException catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue<void>.error(
        ContractorException('Could not delete contractor.'),
        st,
      );
      return false;
    }
  }
}

final StateNotifierProvider<ContractorFormController, AsyncValue<void>>
    contractorFormControllerProvider =
    StateNotifierProvider<ContractorFormController, AsyncValue<void>>(
  (StateNotifierProviderRef<ContractorFormController, AsyncValue<void>> ref) {
    return ContractorFormController(ref.watch(contractorRepositoryProvider));
  },
);
