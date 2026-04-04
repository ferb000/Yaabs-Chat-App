import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../data/posts_api.dart';
import '../data/models.dart';
import 'feed_controller.dart';

class CommentsState {
  final List<Comment> items;
  final String? nextCursor;
  final bool isLoadingMore;

  CommentsState({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  CommentsState copyWith({
    List<Comment>? items,
    String? nextCursor,
    bool? isLoadingMore,
  }) => CommentsState(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
    final current = state.value;
    if (current == null) return;

    final res = await api.createComment(postId, text);
    final comment = Comment.fromJson(
      (res['comment'] as Map).cast<String, dynamic>(),
    );
    final commentCount = (res['commentCount'] as num).toInt();

    state = AsyncValue.data(
      current.copyWith(items: [comment, ...current.items]),
    );
    ref
        .read(feedControllerProvider.notifier)
        .applyCommentCount(postId, commentCount);
  }

  Future<void> delete(String commentId) async {
    final api = ref.read(postsApiProvider);
    final current = state.value;
    if (current == null) return;

    // optimistic remove
    final updated = current.items.where((c) => c.id != commentId).toList();
    state = AsyncValue.data(current.copyWith(items: updated));

    try {
      final res = await api.deleteComment(commentId);
      final commentCount = (res['commentCount'] as num).toInt();
      ref
          .read(feedControllerProvider.notifier)
          .applyCommentCount(postId, commentCount);
    } catch (_) {
      // revert
      state = AsyncValue.data(current);
    }
  }
}
