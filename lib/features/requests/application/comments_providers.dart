import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../data/comments_repository.dart';
import '../domain/activity_event.dart';
import '../domain/request_comment.dart';

final Provider<CommentsRepository> commentsRepositoryProvider =
    Provider<CommentsRepository>(
  (ProviderRef<CommentsRepository> ref) => CommentsRepository(),
);

final StreamProviderFamily<List<RequestComment>, String>
    requestCommentsProvider =
    StreamProvider.family<List<RequestComment>, String>(
  (StreamProviderRef<List<RequestComment>> ref, String requestId) {
    return ref.watch(commentsRepositoryProvider).watchComments(requestId);
  },
);

final StreamProviderFamily<List<ActivityEvent>, String>
    requestActivityProvider =
    StreamProvider.family<List<ActivityEvent>, String>(
  (StreamProviderRef<List<ActivityEvent>> ref, String requestId) {
    return ref.watch(commentsRepositoryProvider).watchActivity(requestId);
  },
);

/// Per-request controller for the "Add comment" composer. Keyed by request
/// id so two open detail screens don't clobber each other's loading state.
class AddCommentController
    extends StateNotifier<Map<String, AsyncValue<void>>> {
  AddCommentController(this._repo, this._ref)
      : super(const <String, AsyncValue<void>>{});

  final CommentsRepository _repo;
  final Ref _ref;

  AsyncValue<void> stateFor(String requestId) =>
      state[requestId] ?? const AsyncValue<void>.data(null);

  Future<bool> submit({
    required String requestId,
    required String text,
  }) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final AppUser? user = _ref.read(appUserProvider).valueOrNull;
    if (user == null) {
      state = <String, AsyncValue<void>>{
        ...state,
        requestId: AsyncValue<void>.error(
          CommentsException('You must be signed in to comment.'),
          StackTrace.current,
        ),
      };
      return false;
    }

    state = <String, AsyncValue<void>>{
      ...state,
      requestId: const AsyncValue<void>.loading(),
    };
    try {
      await _repo.addComment(
        requestId: requestId,
        senderId: user.uid,
        senderName: user.displayName,
        senderRole: user.role,
        text: trimmed,
      );
      state = <String, AsyncValue<void>>{
        ...state,
        requestId: const AsyncValue<void>.data(null),
      };
      return true;
    } on CommentsException catch (e, st) {
      state = <String, AsyncValue<void>>{
        ...state,
        requestId: AsyncValue<void>.error(e, st),
      };
      return false;
    } catch (e, st) {
      state = <String, AsyncValue<void>>{
        ...state,
        requestId: AsyncValue<void>.error(
          CommentsException('Could not post comment.'),
          st,
        ),
      };
      return false;
    }
  }
}

final StateNotifierProvider<AddCommentController,
        Map<String, AsyncValue<void>>> addCommentControllerProvider =
    StateNotifierProvider<AddCommentController,
        Map<String, AsyncValue<void>>>(
  (StateNotifierProviderRef<AddCommentController,
          Map<String, AsyncValue<void>>>
      ref) {
    return AddCommentController(ref.watch(commentsRepositoryProvider), ref);
  },
);
