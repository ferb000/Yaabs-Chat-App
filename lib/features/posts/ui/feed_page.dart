import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../users/ui/people_page.dart';
import '../../auth/state/auth_controller.dart';
import '../state/feed_controller.dart';
import '../data/models.dart';
import 'comments_page.dart';
import '../../chat/ui/conversations_page.dart';
import 'create_post_page.dart';
import 'edit_post_caption_page.dart';
import 'post_detail_page.dart';
import '../../users/ui/profile_page.dart';
import '../../users/data/profile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/providers.dart';
import '../utils/post_links.dart';
import '../../users/ui/widgets/profile_avatar.dart';
import 'widgets/post_media_view.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(feedControllerProvider('following').notifier).load();
      await ref.read(feedControllerProvider('all').notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followingFeed = ref.watch(feedControllerProvider('following'));
    final allFeed = ref.watch(feedControllerProvider('all'));
    final me = ref.watch(authControllerProvider.select((s) => s.user));
    final name = me?.username?.isNotEmpty == true
        ? me!.username!
        : me?.email ?? 'You';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Feed'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: _FeedSegmentedControl(
              controller: _tabController,
              labels: const ['Following', 'All'],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'People',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PeoplePage()),
            ),
            icon: const Icon(Icons.people_alt_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _FeedDrawer(
        userName: name,
        userEmail: me?.email ?? '',
        avatarUrl: me?.avatarUrl,
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      floatingActionButton: _FeedFabCluster(
        onCreatePost: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostPage()),
        ),
        onOpenChats: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConversationsPage()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          top: false,
          child: TabBarView(
            controller: _tabController,
            children: [
              _FeedList(
                state: followingFeed,
                onRefresh: () => ref
                    .read(feedControllerProvider('following').notifier)
                    .load(),
                onLoadMore: () => ref
                    .read(feedControllerProvider('following').notifier)
                    .loadMore(),
              ),
              _FeedList(
                state: allFeed,
                onRefresh: () =>
                    ref.read(feedControllerProvider('all').notifier).load(),
                onLoadMore: () =>
                    ref.read(feedControllerProvider('all').notifier).loadMore(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedSegmentedControl extends StatelessWidget {
  const _FeedSegmentedControl({required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = controller.index.toDouble();

        return Container(
          height: 50,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: Alignment(-1 + index * 2, 0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.floatingAction,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = controller.index == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.animateTo(i),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFamily: 'Manrope',
                        ),
                        child: Center(child: Text(labels[i])),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final AsyncValue<FeedState> state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (value) {
        if (value.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: buildGlassCardDecoration(radius: 28),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppGradients.header,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.dynamic_feed_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Be the first to share something fresh with your people.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              onLoadMore();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
              itemCount: value.items.length + (value.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index >= value.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return _PostCard(post: value.items[index]);
              },
            ),
          ),
        );
      },
    );
  }
}

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(dioProvider)),
);

class _FeedDrawer extends StatelessWidget {
  const _FeedDrawer({
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,
    required this.onLogout,
  });

  final String userName;
  final String userEmail;
  final String? avatarUrl;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppGradients.header,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: userName,
                    avatarUrl: avatarUrl,
                    size: 56,
                    radius: 18,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_rounded),
              title: const Text('Chats'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConversationsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded),
              title: const Text('People'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeoplePage()),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
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
    final me = ref.watch(authControllerProvider.select((s) => s.user));
    final isAuthor = me?.id == post.author.id;

    return Container(
      decoration: buildGlassCardDecoration(radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: post.author.id),
                    ),
                  ),
                  child: ProfileAvatar(
                    name: authorName,
                    avatarUrl: post.author.avatarUrl?.trim().isNotEmpty == true
                        ? post.author.avatarUrl
                        : null,
                    size: 46,
                    radius: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _formatPostedAt(post.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                          if (!isAuthor)
                            _FollowFeedButton(
                              userId: post.author.id,
                              authorName: authorName,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _showPostActionsSheet(context, ref, isAuthor: isAuthor),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            if (post.caption.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ExpandableText(
                text: post.caption,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.35),
              ),
            ],
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 1,
                child: PostMediaView(
                  media: post.media.first,
                  compact: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailPage(post: post),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _ActionPill(
                  icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likeCount}',
                  active: post.likedByMe,
                  onTap: () => ref
                      .read(feedControllerProvider('following').notifier)
                      .toggleLike(post),
                ),
                const SizedBox(width: 10),
                _ActionPill(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentCount}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsPage(postId: post.id),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostActionsSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool isAuthor,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                _PostActionTile(
                  icon: Icons.open_in_new_rounded,
                  title: 'View post',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(post: post),
                      ),
                    );
                  },
                ),
                _PostActionTile(
                  icon: Icons.share_outlined,
                  title: 'Share',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final url = PostLinks.postUrl(post.id);
                    Share.share(
                      '${post.caption.isNotEmpty ? post.caption : "Check out this post"}\n$url',
                    );
                  },
                ),
                _PostActionTile(
                  icon: Icons.link_rounded,
                  title: 'Copy link',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final url = PostLinks.postUrl(post.id);
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                    }
                  },
                ),
                if (isAuthor)
                  _PostActionTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit caption',
                    onTap: () async {
                      Navigator.pop(sheetContext);
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
                        await ref
                            .read(feedControllerProvider('following').notifier)
                            .load();
                        await ref
                            .read(feedControllerProvider('all').notifier)
                            .load();
                      }
                    },
                  ),
                if (isAuthor)
                  _PostActionTile(
                    icon: Icons.delete_outline,
                    title: 'Delete post',
                    destructive: true,
                    onTap: () async {
                      Navigator.pop(sheetContext);
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
          ),
        );
      },
    );
  }

  String _formatPostedAt(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }
}

class _FollowFeedButton extends ConsumerStatefulWidget {
  const _FollowFeedButton({required this.userId, required this.authorName});

  final String userId;
  final String authorName;

  @override
  ConsumerState<_FollowFeedButton> createState() => _FollowFeedButtonState();
}

class _FollowFeedButtonState extends ConsumerState<_FollowFeedButton> {
  bool _loading = true;
  bool _isFollowing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final api = ref.read(profileApiProvider);
      final res = await api.getProfile(widget.userId);
      final user = (res['user'] as Map).cast<String, dynamic>();
      _isFollowing = user['isFollowing'] as bool? ?? false;
    } catch (_) {
      _isFollowing = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final api = ref.read(profileApiProvider);
      if (_isFollowing) {
        await api.unfollow(widget.userId);
      } else {
        await api.follow(widget.userId);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Follow action failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: 74,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return InkWell(
      onTap: _busy ? null : _toggle,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isFollowing ? AppColors.outgoing : AppColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: _busy
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _PostActionTile extends StatelessWidget {
  const _PostActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : AppColors.text;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 4,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final overflow = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : 4,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (overflow) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FeedFabCluster extends StatefulWidget {
  const _FeedFabCluster({
    required this.onCreatePost,
    required this.onOpenChats,
  });

  final VoidCallback onCreatePost;
  final VoidCallback onOpenChats;

  @override
  State<_FeedFabCluster> createState() => _FeedFabClusterState();
}

class _FeedFabClusterState extends State<_FeedFabCluster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_controller.isDismissed) {
      await _controller.forward();
    } else {
      await _controller.reverse();
    }
  }

  Future<void> _runAction(VoidCallback action) async {
    if (_controller.value > 0) {
      await _controller.reverse();
    }
    if (!mounted) return;
    action();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _FabClusterAction(
            animation: _curve,
            label: 'Chat',
            icon: Icons.chat_bubble_rounded,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primaryDark,
            onPressed: () => _runAction(widget.onOpenChats),
          ),
          const SizedBox(height: 12),
          _FabClusterAction(
            animation: _curve,
            label: 'Post',
            icon: Icons.edit_rounded,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => _runAction(widget.onCreatePost),
          ),
          const SizedBox(height: 14),
          FloatingActionButton(
            heroTag: 'feedMainFab',
            onPressed: _toggle,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: AnimatedBuilder(
              animation: _curve,
              builder: (context, _) {
                return AnimatedRotation(
                  turns: 0.125 * _curve.value,
                  duration: const Duration(milliseconds: 120),
                  child: Icon(
                    _controller.value > 0.5
                        ? Icons.close_rounded
                        : Icons.add_rounded,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FabClusterAction extends StatelessWidget {
  const _FabClusterAction({
    required this.animation,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final Animation<double> animation;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final visible = animation.value > 0.01;
        return IgnorePointer(
          ignoring: !visible,
          child: Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - animation.value)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.small(
                    heroTag: 'fab_$label',
                    onPressed: onPressed,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    child: Icon(icon),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.outgoing : AppColors.chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primaryDark : AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
