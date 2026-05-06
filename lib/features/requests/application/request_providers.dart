import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../contractors/domain/contractor.dart';
import '../data/ai_analysis_service.dart';
import '../data/request_repository.dart';
import '../domain/activity_event.dart';
import '../domain/maintenance_request.dart';

/// Resolves the current [AppUser] into the lightweight [ActivityActor]
/// repositories use when stamping audit events. Returns `null` when the
/// profile hasn't loaded yet so callers can fail closed.
final Provider<ActivityActor?> activityActorProvider =
    Provider<ActivityActor?>(
  (ProviderRef<ActivityActor?> ref) {
    final AppUser? user = ref.watch(appUserProvider).valueOrNull;
    if (user == null) return null;
    return ActivityActor(
      uid: user.uid,
      name: user.displayName,
      role: user.role,
    );
  },
);

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

/// Live list of jobs assigned to the signed-in contractor (matched by email).
final StreamProvider<List<MaintenanceRequest>> contractorJobsProvider =
    StreamProvider<List<MaintenanceRequest>>(
  (StreamProviderRef<List<MaintenanceRequest>> ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    final String? email = user?.email;
    if (email == null || email.isEmpty) {
      return Stream<List<MaintenanceRequest>>.value(<MaintenanceRequest>[]);
    }
    return ref
        .watch(requestRepositoryProvider)
        .watchRequestsForContractorEmail(email);
  },
);

final StreamProviderFamily<MaintenanceRequest?, String> requestByIdProvider =
    StreamProvider.family<MaintenanceRequest?, String>(
  (StreamProviderRef<MaintenanceRequest?> ref, String id) {
    return ref.watch(requestRepositoryProvider).watchRequest(id);
  },
);

class SubmitRequestController extends StateNotifier<AsyncValue<void>> {
  SubmitRequestController(this._repo, this._ai, this._ref)
      : super(const AsyncValue<void>.data(null));

  final RequestRepository _repo;
  final AiAnalysisService _ai;
  final Ref _ref;

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
    final ActivityActor? actor = _ref.read(activityActorProvider);
    if (actor == null) {
      state = AsyncValue<void>.error(
        RequestException('You must be signed in to submit a request.'),
        StackTrace.current,
      );
      return null;
    }

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
        actor: actor,
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
      ref,
    );
  },
);

/// Drives the landlord-side status update on the request detail screen.
class UpdateRequestStatusController extends StateNotifier<AsyncValue<void>> {
  UpdateRequestStatusController(this._repo, this._ref)
      : super(const AsyncValue<void>.data(null));

  final RequestRepository _repo;
  final Ref _ref;

  /// Returns `true` on success; failures are also published into [state] so
  /// the screen can surface a snackbar without hand-rolling a try/catch.
  Future<bool> setStatus({
    required String id,
    required RequestStatus status,
  }) async {
    final ActivityActor? actor = _ref.read(activityActorProvider);
    if (actor == null) {
      state = AsyncValue<void>.error(
        RequestException('You must be signed in to update status.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncValue<void>.loading();
    try {
      await _repo.updateStatus(id: id, status: status, actor: actor);
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
    return UpdateRequestStatusController(
      ref.watch(requestRepositoryProvider),
      ref,
    );
  },
);

/// Drives the assign-contractor bottom sheet on the landlord detail screen.
class AssignContractorController extends StateNotifier<AsyncValue<void>> {
  AssignContractorController(this._repo, this._ref)
      : super(const AsyncValue<void>.data(null));

  final RequestRepository _repo;
  final Ref _ref;

  Future<bool> assign({
    required String requestId,
    required Contractor contractor,
  }) async {
    final ActivityActor? actor = _ref.read(activityActorProvider);
    if (actor == null) {
      state = AsyncValue<void>.error(
        RequestException('You must be signed in to assign a contractor.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncValue<void>.loading();
    try {
      await _repo.assignContractor(
        requestId: requestId,
        contractor: contractor,
        actor: actor,
      );
      state = const AsyncValue<void>.data(null);
      return true;
    } on RequestException catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return false;
    } catch (e, st) {
      state = AsyncValue<void>.error(
        RequestException('Could not assign contractor.'),
        st,
      );
      return false;
    }
  }
}

final StateNotifierProvider<AssignContractorController, AsyncValue<void>>
    assignContractorControllerProvider =
    StateNotifierProvider<AssignContractorController, AsyncValue<void>>(
  (StateNotifierProviderRef<AssignContractorController, AsyncValue<void>>
          ref) {
    return AssignContractorController(
      ref.watch(requestRepositoryProvider),
      ref,
    );
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
