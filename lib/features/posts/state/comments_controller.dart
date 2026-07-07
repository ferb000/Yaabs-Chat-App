import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/models.dart';
import 'feed_controller.dart';

class CommentsState {
  final List<Comment> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool isCreating;

  CommentsState({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
    this.isCreating = false,
  });

  CommentsState copyWith({
    List<Comment>? items,
    String? nextCursor,
    bool? isLoadingMore,
    bool? isCreating,
  }) => CommentsState(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isCreating: isCreating ?? this.isCreating,
  );
}

final commentsControllerProvider =
    StateNotifierProvider.family<
      CommentsController,
      AsyncValue<CommentsState>,
      String
    >((ref, postId) => CommentsController(ref, postId));

class CommentsController extends StateNotifier<AsyncValue<CommentsState>> {
  CommentsController(this.ref, this.postId)
    : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;
  final String postId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final api = ref.read(postsApiProvider);
    try {
      final res = await api.listComments(postId, limit: 20);
      final items = (res['items'] as List)
          .map((e) => Comment.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      state = AsyncValue.data(
        CommentsState(items: items, nextCursor: res['nextCursor'] as String?),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(String text) async {
    final api = ref.read(postsApiProvider);
    final current = state.value ?? CommentsState(items: []);
    final me = ref.read(authControllerProvider).user;

    final optimisticId = 'tmp-${DateTime.now().microsecondsSinceEpoch}';
    final optimisticAuthor = PostAuthor(
      id: me?.id ?? '',
      email: me?.email ?? 'me',
      username: me?.username,
      avatarUrl: me?.avatarUrl,
    );
    final optimistic = Comment(
      id: optimisticId,
      text: text,
      createdAt: DateTime.now(),
      author: optimisticAuthor,
    );

    state = AsyncValue.data(
      current.copyWith(isCreating: true, items: [optimistic, ...current.items]),
    );

    try {
      final res = await api.createComment(postId, text);
      final rawComment = res['comment'];
      final commentCount = (res['commentCount'] as num?)?.toInt();

      final updated = current.items
          .where((c) => c.id != optimisticId)
          .toList(growable: true);

      if (rawComment is Map) {
        final created = Comment.fromJson(rawComment.cast<String, dynamic>());
        updated.insert(0, created);
      } else {
        final latest = await api.listComments(postId, limit: 20);
        updated
          ..clear()
          ..addAll(
            (latest['items'] as List)
                .map(
                  (e) => Comment.fromJson((e as Map).cast<String, dynamic>()),
                )
                .toList(),
          );
      }

      state = AsyncValue.data(
        current.copyWith(items: updated, isCreating: false),
      );

      if (commentCount != null) {
        ref
            .read(feedControllerProvider.notifier)
            .applyCommentCount(postId, commentCount);
      }
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(
          isCreating: false,
          items: current.items.where((c) => c.id != optimisticId).toList(),
        ),
      );
      rethrow;
    }
  }

  Future<void> delete(String commentId) async {
    final api = ref.read(postsApiProvider);
    final current = state.value;
    if (current == null) return;

    final updated = current.items.where((c) => c.id != commentId).toList();
    state = AsyncValue.data(current.copyWith(items: updated));

    try {
      final res = await api.deleteComment(commentId);
      final commentCount = (res['commentCount'] as num).toInt();
      ref
          .read(feedControllerProvider.notifier)
          .applyCommentCount(postId, commentCount);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }
}
