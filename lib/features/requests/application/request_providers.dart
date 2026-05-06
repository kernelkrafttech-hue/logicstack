import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_providers.dart';
import '../data/ai_analysis_service.dart';
import '../data/request_repository.dart';
import '../domain/maintenance_request.dart';

final Provider<RequestRepository> requestRepositoryProvider =
    Provider<RequestRepository>(
  (ProviderRef<RequestRepository> ref) => RequestRepository(),
);

final Provider<AiAnalysisService> aiAnalysisServiceProvider =
    Provider<AiAnalysisService>(
  (ProviderRef<AiAnalysisService> ref) => AiAnalysisService(),
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

/// Live list of every maintenance request that targets a property owned by
/// the signed-in landlord.
final StreamProvider<List<MaintenanceRequest>> landlordRequestsProvider =
    StreamProvider<List<MaintenanceRequest>>(
  (StreamProviderRef<List<MaintenanceRequest>> ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Stream<List<MaintenanceRequest>>.value(<MaintenanceRequest>[]);
    }
    return ref
        .watch(requestRepositoryProvider)
        .watchRequestsForLandlord(user.uid);
  },
);

final StreamProviderFamily<MaintenanceRequest?, String> requestByIdProvider =
    StreamProvider.family<MaintenanceRequest?, String>(
  (StreamProviderRef<MaintenanceRequest?> ref, String id) {
    return ref.watch(requestRepositoryProvider).watchRequest(id);
  },
);

class SubmitRequestController extends StateNotifier<AsyncValue<void>> {
  SubmitRequestController(this._repo, this._ai)
      : super(const AsyncValue<void>.data(null));

  final RequestRepository _repo;
  final AiAnalysisService _ai;

  /// Uploads photos, writes the request, and runs AI analysis.
  ///
  /// The Firestore document is committed before the AI call. If analysis
  /// fails (network, OpenAI error, …) the request itself is preserved and
  /// the user can hit "Regenerate" later from the landlord detail screen.
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

      // Soft-fail AI: the request is already saved, so we treat analysis
      // failure as a non-blocking warning rather than a submission failure.
      try {
        final AiAnalysis analysis = await _ai.analyze(
          title: request.title,
          description: request.description,
          category: request.category,
          urgency: request.urgency,
        );
        await _repo.applyAiAnalysis(id: request.id, analysis: analysis);
      } catch (_) {
        // Swallow: Phase 5 surfaces the regenerate path on the detail screen.
      }

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
    return SubmitRequestController(
      ref.watch(requestRepositoryProvider),
      ref.watch(aiAnalysisServiceProvider),
    );
  },
);

/// Drives the landlord-side status update on the request detail screen.
class UpdateRequestStatusController extends StateNotifier<AsyncValue<void>> {
  UpdateRequestStatusController(this._repo)
      : super(const AsyncValue<void>.data(null));

  final RequestRepository _repo;

  /// Returns `true` on success; failures are also published into [state] so
  /// the screen can surface a snackbar without hand-rolling a try/catch.
  Future<bool> setStatus({
    required String id,
    required RequestStatus status,
  }) async {
    state = const AsyncValue<void>.loading();
    try {
      await _repo.updateStatus(id: id, status: status);
      state = const AsyncValue<void>.data(null);
      return true;
    } on RequestException catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue<void>.error(
        RequestException('Could not update status. Please try again.'),
        st,
      );
      return false;
    }
  }
}

final StateNotifierProvider<UpdateRequestStatusController, AsyncValue<void>>
    updateRequestStatusControllerProvider =
    StateNotifierProvider<UpdateRequestStatusController, AsyncValue<void>>(
  (StateNotifierProviderRef<UpdateRequestStatusController, AsyncValue<void>>
          ref) {
    return UpdateRequestStatusController(ref.watch(requestRepositoryProvider));
  },
);

/// Drives the "Regenerate AI summary" button on the landlord detail screen.
///
/// Per-request state so two open requests can regenerate independently
/// without their loading indicators colliding.
class RegenerateAiController
    extends StateNotifier<Map<String, AsyncValue<void>>> {
  RegenerateAiController(this._repo, this._ai)
      : super(const <String, AsyncValue<void>>{});

  final RequestRepository _repo;
  final AiAnalysisService _ai;

  AsyncValue<void> stateFor(String requestId) =>
      state[requestId] ?? const AsyncValue<void>.data(null);

  Future<bool> regenerate(MaintenanceRequest request) async {
    state = <String, AsyncValue<void>>{
      ...state,
      request.id: const AsyncValue<void>.loading(),
    };
    try {
      final AiAnalysis analysis = await _ai.analyze(
        title: request.title,
        description: request.description,
        category: request.category,
        urgency: request.urgency,
      );
      await _repo.applyAiAnalysis(id: request.id, analysis: analysis);
      state = <String, AsyncValue<void>>{
        ...state,
        request.id: const AsyncValue<void>.data(null),
      };
      return true;
    } on RequestException catch (e, st) {
      state = <String, AsyncValue<void>>{
        ...state,
        request.id: AsyncValue<void>.error(e, st),
      };
      return false;
    } catch (e, st) {
      state = <String, AsyncValue<void>>{
        ...state,
        request.id: AsyncValue<void>.error(
          RequestException('Could not regenerate analysis.'),
          st,
        ),
      };
      return false;
    }
  }
}

final StateNotifierProvider<RegenerateAiController,
        Map<String, AsyncValue<void>>> regenerateAiControllerProvider =
    StateNotifierProvider<RegenerateAiController,
        Map<String, AsyncValue<void>>>(
  (StateNotifierProviderRef<RegenerateAiController,
          Map<String, AsyncValue<void>>>
      ref) {
    return RegenerateAiController(
      ref.watch(requestRepositoryProvider),
      ref.watch(aiAnalysisServiceProvider),
    );
  },
);
