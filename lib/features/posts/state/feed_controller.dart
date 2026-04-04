import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
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
    StateNotifierProvider<FeedController, AsyncValue<FeedState>>((ref) {
      return FeedController(ref);
    });

class FeedController extends StateNotifier<AsyncValue<FeedState>> {
  FeedController(this.ref) : super(const AsyncValue.loading());

  final Ref ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final api = ref.read(postsApiProvider);
    try {
      final res = await api.feed(limit: 15);
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
      final res = await api.feed(cursor: cursor, limit: 15);
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
      return Post(
        id: p.id,
        caption: p.caption,
        createdAt: p.createdAt,
        author: p.author,
        media: p.media,
        likeCount: liked
            ? p.likeCount + 1
            : (p.likeCount - 1).clamp(0, 1 << 30),
        commentCount: p.commentCount,
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
      return Post(
        id: p.id,
        caption: p.caption,
        createdAt: p.createdAt,
        author: p.author,
        media: p.media,
        likeCount: p.likeCount,
        commentCount: commentCount,
        likedByMe: p.likedByMe,
      );
    }).toList();

    state = AsyncValue.data(current.copyWith(items: updated));
  }
}
