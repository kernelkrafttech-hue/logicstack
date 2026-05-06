import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_providers.dart';
import '../data/request_repository.dart';
import '../domain/maintenance_request.dart';

final Provider<RequestRepository> requestRepositoryProvider =
    Provider<RequestRepository>(
  (ProviderRef<RequestRepository> ref) => RequestRepository(),
);

/// Live list of maintenance requests authored by the signed-in tenant.
final StreamProvider<List<MaintenanceRequest>> myRequestsProvider =
    StreamProvider<List<MaintenanceRequest>>(
  (StreamProviderRef<List<MaintenanceRequest>> ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Stream<List<MaintenanceRequest>>.value(<MaintenanceRequest>[]);
    }
    return ref
        .watch(requestRepositoryProvider)
        .watchRequestsForTenant(user.uid);
  },
);

final StreamProviderFamily<MaintenanceRequest?, String> requestByIdProvider =
    StreamProvider.family<MaintenanceRequest?, String>(
  (StreamProviderRef<MaintenanceRequest?> ref, String id) {
    return ref.watch(requestRepositoryProvider).watchRequest(id);
  },
);

class SubmitRequestController extends StateNotifier<AsyncValue<void>> {
  SubmitRequestController(this._repo) : super(const AsyncValue<void>.data(null));

  final RequestRepository _repo;

  /// Uploads any photos and writes the maintenance request document.
  ///
  /// Returns the saved request on success, or `null` after publishing an
  /// error into [state].
  Future<MaintenanceRequest?> submit({
    required String propertyId,
    required String landlordId,
    required String tenantId,
    required String title,
    required String description,
    required RequestCategory category,
    required RequestUrgency urgency,
    required List<XFile> photos,
  }) async {
    state = const AsyncValue<void>.loading();
    try {
      final String requestId = _repo.newRequestId();

      final List<String> photoUrls = <String>[];
      for (int i = 0; i < photos.length; i++) {
        final String url = await _repo.uploadPhoto(
          requestId: requestId,
          index: i,
          file: File(photos[i].path),
        );
        photoUrls.add(url);
      }

      final MaintenanceRequest request = await _repo.createRequest(
        id: requestId,
        propertyId: propertyId,
        landlordId: landlordId,
        tenantId: tenantId,
        title: title,
        description: description,
        category: category,
        urgency: urgency,
        photoUrls: photoUrls,
      );
      state = const AsyncValue<void>.data(null);
      return request;
    } on RequestException catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return null;
    } catch (e, st) {
      state = AsyncValue<void>.error(
        RequestException('Could not submit your request. Please try again.'),
        st,
      );
      return null;
    }
  }
}

final StateNotifierProvider<SubmitRequestController, AsyncValue<void>>
    submitRequestControllerProvider =
    StateNotifierProvider<SubmitRequestController, AsyncValue<void>>(
  (StateNotifierProviderRef<SubmitRequestController, AsyncValue<void>> ref) {
    return SubmitRequestController(ref.watch(requestRepositoryProvider));
  },
);
