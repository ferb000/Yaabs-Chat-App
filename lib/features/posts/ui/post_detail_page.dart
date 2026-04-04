import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:full_node_chat_app/features/auth/state/auth_controller.dart';
import '../data/models.dart';
import '../state/feed_controller.dart';
import 'edit_post_caption_page.dart';
import 'post_image_viewer_page.dart';
import 'comments_page.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/post_links.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final url = PostLinks.postUrl(post.id);
              Share.share(
                '${post.caption.isNotEmpty ? post.caption : "Check out this post"}\n$url',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () async {
              final url = PostLinks.postUrl(post.id);
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied')));
              }
            },
          ),
          if (me?.id == post.author.id)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPostCaptionPage(
                          postId: post.id,
                          initialCaption: post.caption,
                        ),
                      ),
                    );
                    if (changed == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete post?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (ok != true) return;

                    try {
                      await ref.read(postsApiProvider).deletePost(post.id);
                      await ref.read(feedControllerProvider.notifier).load();
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete failed: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            post.author.username?.isNotEmpty == true
                ? post.author.username!
                : post.author.email,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (post.caption.isNotEmpty) Text(post.caption),
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: PageView.builder(
                itemCount: post.media.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    final urls = post.media.map((e) => e.url).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PostImageViewerPage(images: urls, initialIndex: i),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(post.media[i].url, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${post.likeCount} likes'),
              const SizedBox(width: 16),
              Text('${post.commentCount} comments'),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommentsPage(postId: post.id)),
            ),
            child: const Text('View comments'),
          ),
        ],
      ),
    );
  }
}
