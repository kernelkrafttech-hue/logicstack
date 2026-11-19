import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_role.dart';
import '../../application/comments_providers.dart';
import '../../data/comments_repository.dart';
import '../../domain/request_comment.dart';

/// Threaded comments for a request: live list on top, composer pinned at the
/// bottom. Visible to anyone who can read the parent request, with the
/// current user's own messages right-aligned.
class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String text = _ctrl.text;
    if (text.trim().isEmpty) return;
    final bool ok = await ref
        .read(addCommentControllerProvider.notifier)
        .submit(requestId: widget.requestId, text: text);
    if (!mounted) return;
    if (ok) {
      _ctrl.clear();
      _focus.unfocus();
      return;
    }
    final AsyncValue<void> state = ref
        .read(addCommentControllerProvider.notifier)
        .stateFor(widget.requestId);
    final Object? error = state.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is CommentsException
              ? error.message
              : 'Could not post comment.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AsyncValue<List<RequestComment>> async =
        ref.watch(requestCommentsProvider(widget.requestId));
    final AppUser? me = ref.watch(appUserProvider).valueOrNull;
    final AsyncValue<void> sendState = ref.watch(
      addCommentControllerProvider.select(
        (Map<String, AsyncValue<void>> map) =>
            map[widget.requestId] ?? const AsyncValue<void>.data(null),
      ),
    );
    final bool sending = sendState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.forum_outlined,
              size: 18,
              color: AppColors.navy,
            ),
            const SizedBox(width: 6),
            Text(
              'Comments',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        async.when(
          loading: () => const _Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (Object error, _) => _Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load comments: $error',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (List<RequestComment> list) {
            if (list.isEmpty) {
              return const _Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No comments yet — start the conversation below.',
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < list.length; i++) ...<Widget>[
                  if (i != 0) const SizedBox(height: 8),
                  _CommentBubble(
                    comment: list[i],
                    mine: me != null && list[i].senderId == me.uid,
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _Composer(
          controller: _ctrl,
          focusNode: _focus,
          sending: sending,
          onSubmit: _submit,
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment, required this.mine});

  final RequestComment comment;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color bg = mine ? AppColors.navy : AppColors.surface;
    final Color fg = mine ? AppColors.white : AppColors.bodyText;
    final Color subFg =
        mine ? AppColors.white.withValues(alpha: 0.75) : AppColors.mutedText;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            border: mine ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    comment.senderName.isEmpty
                        ? comment.senderRole.displayName
                        : comment.senderName,
                    style: text.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _RoleTag(role: comment.senderRole, mine: mine),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.text,
                style: text.bodyMedium?.copyWith(color: fg),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(comment.createdAt),
                style: text.bodySmall?.copyWith(color: subFg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) return 'Just now';
    return DateFormat.MMMd().add_jm().format(date.toLocal());
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.role, required this.mine});
  final UserRole role;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: mine
            ? AppColors.white.withValues(alpha: 0.15)
            : AppColors.lightGray,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: mine ? AppColors.white : AppColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              enabled: !sending,
              decoration: const InputDecoration(
                hintText: 'Add a comment…',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: sending ? null : onSubmit,
            tooltip: 'Send',
            icon: sending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.send_rounded,
                    color: AppColors.greenDark,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
