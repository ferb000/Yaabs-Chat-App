import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/ui/people_page.dart';
import '../../auth/state/auth_controller.dart';
import '../state/feed_controller.dart';
import '../data/models.dart';
import 'comments_page.dart';
import '../../chat/ui/conversations_page.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';
import '../../users/ui/profile_page.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(feedControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            tooltip: "Chats",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConversationsPage()),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: "People",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PeoplePage()),
            ),
            icon: const Icon(Icons.people_outline),
          ),

          IconButton(
            tooltip: "Create Post",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostPage()),
            ),
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          if (state.items.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                ref.read(feedControllerProvider.notifier).loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () => ref.read(feedControllerProvider.notifier).load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final post = state.items[index];
                  return _PostCard(post: post);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorName = post.author.username?.isNotEmpty == true
        ? post.author.username!
        : post.author.email;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(userId: post.author.id),
                ),
              ),
              child: Text(
                authorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (post.caption.isNotEmpty) Text(post.caption),
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      post.media.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Text("Image failed")),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(feedControllerProvider.notifier)
                      .toggleLike(post),
                  icon: Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
                Text('${post.likeCount}'),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsPage(postId: post.id),
                    ),
                  ),
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: Text('${post.commentCount}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
