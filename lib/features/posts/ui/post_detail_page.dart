import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:full_node_chat_app/features/auth/state/auth_controller.dart';
import '../data/models.dart';
import '../state/feed_controller.dart';
import 'edit_post_caption_page.dart';
import 'post_image_viewer_page.dart';
import 'comments_page.dart';
import 'widgets/post_media_view.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/post_links.dart';
import '../utils/media_url.dart';
import '../../../core/theme/app_theme.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider.select((s) => s.user));
    final displayName = post.author.username?.isNotEmpty == true
        ? post.author.username!
        : post.author.email;

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
                      await ref
                          .read(feedControllerProvider('following').notifier)
                          .load();
                      await ref
                          .read(feedControllerProvider('all').notifier)
                          .load();
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: buildGlassCardDecoration(radius: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.outgoing,
                  child: Text(
                    _initialFor(displayName),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _formatTime(post.createdAt),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.muted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Text(
                            'Public',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.share_outlined),
                        title: Text('Share'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.link_rounded),
                        title: Text('Copy link'),
                      ),
                    ),
                    if (me?.id == post.author.id)
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit caption'),
                        ),
                      ),
                  ],
                  onSelected: (value) async {
                    if (value == 'share') {
                      final url = PostLinks.postUrl(post.id);
                      Share.share(
                        '${post.caption.isNotEmpty ? post.caption : "Check out this post"}\n$url',
                      );
                    } else if (value == 'copy') {
                      final url = PostLinks.postUrl(post.id);
                      await Clipboard.setData(ClipboardData(text: url));
                    } else if (value == 'edit' && me?.id == post.author.id) {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPostCaptionPage(
                            postId: post.id,
                            initialCaption: post.caption,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (post.caption.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: buildGlassCardDecoration(radius: 24),
              child: Text(post.caption),
            ),
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: PageView.builder(
                itemCount: post.media.length,
                itemBuilder: (_, i) {
                  final media = post.media[i];
                  if (isVideoMediaUrl(media.url, mime: media.mime)) {
                    return PostMediaView(media: media);
                  }

                  return GestureDetector(
                    onTap: () {
                      final images = post.media
                          .where((m) => !isVideoMediaUrl(m.url, mime: m.mime))
                          .map((e) => resolveMediaUrl(e.url))
                          .toList();
                      final currentUrl = resolveMediaUrl(media.url);
                      final initialIndex = images.isEmpty
                          ? 0
                          : images
                                .indexOf(currentUrl)
                                .clamp(0, images.length - 1)
                                .toInt();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostImageViewerPage(
                            images: images,
                            initialIndex: initialIndex,
                          ),
                        ),
                      );
                    },
                    child: PostMediaView(media: media),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: buildGlassCardDecoration(radius: 24),
            child: Row(
              children: [
                _MetaChip(
                  label: '${post.likeCount} likes',
                  icon: Icons.favorite,
                ),
                const SizedBox(width: 10),
                _MetaChip(
                  label: '${post.commentCount} comments',
                  icon: Icons.mode_comment_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommentsPage(postId: post.id)),
            ),
            icon: const Icon(Icons.mode_comment_outlined),
            label: const Text('View comments'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${local.month}/${local.day}/${local.year}';
  }

  String _initialFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppGradients.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
