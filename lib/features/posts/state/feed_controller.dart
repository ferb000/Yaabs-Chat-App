import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../reactions/data/reaction_models.dart';
import '../../reactions/state/reactions_provider.dart';
import '../data/posts_api.dart';
import '../data/models.dart';

final postsApiProvider = Provider<PostsApi>(
  (ref) => PostsApi(ref.watch(dioProvider)),
);

class FeedState {
  final List<Post> items;
  final String? nextCursor;
  final bool isLoadingMore;

  FeedState({required this.items, this.nextCursor, this.isLoadingMore = false});

  FeedState copyWith({
    List<Post>? items,
    String? nextCursor,
    bool? isLoadingMore,
  }) => FeedState(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

final feedControllerProvider =
    StateNotifierProvider.family<FeedController, AsyncValue<FeedState>, String>(
      (ref, scope) {
        return FeedController(ref, scope);
      },
    );

class FeedController extends StateNotifier<AsyncValue<FeedState>> {
  FeedController(this.ref, this.scope) : super(const AsyncValue.loading());

  final Ref ref;
  final String scope;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final api = ref.read(postsApiProvider);
    try {
      final res = await api.feed(limit: 15, scope: scope);
      final posts = (res['items'] as List)
          .map((e) => Post.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      state = AsyncValue.data(
        FeedState(items: posts, nextCursor: res['nextCursor'] as String?),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    if (current.isLoadingMore) return;
    final cursor = current.nextCursor;
    if (cursor == null) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    final api = ref.read(postsApiProvider);

    try {
      final res = await api.feed(cursor: cursor, limit: 15, scope: scope);
      final more = (res['items'] as List)
          .map((e) => Post.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      state = AsyncValue.data(
        current.copyWith(
          isLoadingMore: false,
          items: [...current.items, ...more],
          nextCursor: res['nextCursor'] as String?,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLike(Post post) async {
    final api = ref.read(postsApiProvider);
    final current = state.value;
    if (current == null) return;

    // optimistic update
    final updated = current.items.map((p) {
      if (p.id != post.id) return p;
      final liked = !p.likedByMe;
      return p.copyWith(
        likeCount: liked
            ? p.likeCount + 1
            : (p.likeCount - 1).clamp(0, 1 << 30),
        likedByMe: liked,
      );
    }).toList();

    state = AsyncValue.data(current.copyWith(items: updated));

    try {
      if (post.likedByMe) {
        await api.unlike(post.id);
      } else {
        await api.like(post.id);
      }
    } catch (_) {
      // revert on failure
      state = AsyncValue.data(current);
    }
  }

  void applyCommentCount(String postId, int commentCount) {
    final current = state.value;
    if (current == null) return;

    final updated = current.items.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(commentCount: commentCount);
    }).toList();

    state = AsyncValue.data(current.copyWith(items: updated));
  }

  Future<void> toggleReaction(Post post, String reaction) async {
    final current = state.value;
    if (current == null) return;

    final previousReaction = post.myReaction;
    final optimisticSummary = post.reactionSummary.applyToggle(
      previousReaction: previousReaction,
      reaction: reaction,
    );
    final optimisticMyReaction = previousReaction == reaction ? null : reaction;

    final optimisticItems = current.items.map((p) {
      if (p.id != post.id) return p;
      return p.copyWith(
        reactionCount: optimisticSummary.total,
        myReaction: optimisticMyReaction,
        reactionSummary: optimisticSummary,
      );
    }).toList();

    state = AsyncValue.data(current.copyWith(items: optimisticItems));

    try {
      final res = await ref.read(reactionsApiProvider).toggle(
        targetType: 'post',
        targetId: post.id,
        reaction: reaction,
      );
      final summary = ReactionSummary.fromJson(res['reactionSummary']);
      final myReaction = res['myReaction'] as String?;
      ref
          .read(feedControllerProvider('following').notifier)
          .applyReactionSummary(post.id, summary, myReaction);
      ref
          .read(feedControllerProvider('all').notifier)
          .applyReactionSummary(post.id, summary, myReaction);
    } catch (_) {
      state = AsyncValue.data(current);
    }
  }

  void applyReactionSummary(
    String postId,
    ReactionSummary summary,
    String? myReaction,
  ) {
    final current = state.value;
    if (current == null) return;

    final updated = current.items.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(
        reactionCount: summary.total,
        myReaction: myReaction,
        reactionSummary: summary,
      );
    }).toList();

    state = AsyncValue.data(current.copyWith(items: updated));
  }
}
