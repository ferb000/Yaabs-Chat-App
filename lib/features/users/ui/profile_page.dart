import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:full_node_chat_app/features/posts/state/feed_controller.dart';
import '../../../core/di/providers.dart';
import '../../auth/data/models.dart';
import '../data/profile_api.dart';
import 'package:full_node_chat_app/features/auth/state/auth_controller.dart';
import '../../posts/data/models.dart';
import '../../posts/ui/post_detail_page.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/profile_avatar.dart';
import '../../media/data/media_api.dart';
import '../../posts/utils/media_url.dart' show isVideoMediaUrl, resolveMediaUrl;

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(dioProvider)),
);

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _user;
  List<Post> _posts = [];
  bool _loading = true;
  bool _busy = false;
  bool _avatarBusy = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profileApi = ref.read(profileApiProvider);
      final postsApi = ref.read(postsApiProvider);

      final profile = await profileApi.getProfile(widget.userId);
      final posts = await postsApi.userPosts(widget.userId);

      _user = (profile['user'] as Map).cast<String, dynamic>();
      _posts = (posts['items'] as List)
          .map((e) => Post.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null || _busy) return;
    setState(() => _busy = true);

    try {
      final api = ref.read(profileApiProvider);
      final isFollowing = _user!['isFollowing'] as bool? ?? false;

      if (isFollowing) {
        await api.unfollow(widget.userId);
      } else {
        await api.follow(widget.userId);
      }

      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeAvatar() async {
    final me = ref.read(authControllerProvider).user;
    if (me == null || me.id != widget.userId || _avatarBusy) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _avatarBusy = true);
    try {
      final mediaApi = MediaApi(ref.read(dioProvider));
      final profileApi = ref.read(profileApiProvider);

      final media = await mediaApi.uploadXFile(image);
      final res = await profileApi.updateAvatar(media['url'] as String);
      final updatedUser = (res['user'] as Map).cast<String, dynamic>();

      ref
          .read(authControllerProvider.notifier)
          .updateUser(AppUser.fromJson(updatedUser));
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Avatar update failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider.select((s) => s.user));
    final isMe = me?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isMe)
            IconButton(
              tooltip: 'Change photo',
              onPressed: _avatarBusy ? null : _changeAvatar,
              icon: _avatarBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
              ? const Center(child: Text('User not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppGradients.header,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: isMe && !_avatarBusy
                                      ? _changeAvatar
                                      : null,
                                  child: Stack(
                                    children: [
                                      ProfileAvatar(
                                        name:
                                            (_user!['username'] as String?)
                                                    ?.isNotEmpty ==
                                                true
                                            ? _user!['username'] as String
                                            : _user!['email'] as String,
                                        avatarUrl:
                                            (_user!['avatarUrl'] as String?) ??
                                            (_user!['avatar_url'] as String?),
                                        size: 64,
                                        radius: 20,
                                      ),
                                      if (isMe)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: AppColors.primaryDark,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.photo_camera_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (!isMe)
                                  FilledButton(
                                    onPressed: _busy ? null : _toggleFollow,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primaryDark,
                                    ),
                                    child: Text(
                                      (_user!['isFollowing'] as bool? ?? false)
                                          ? 'Unfollow'
                                          : 'Follow',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              (_user!['username'] as String?)?.isNotEmpty ==
                                      true
                                  ? _user!['username'] as String
                                  : _user!['email'] as String,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _user!['email'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _ProfileStat(
                                  label: 'Followers',
                                  value: '${_user!['followersCount']}',
                                ),
                                _ProfileStat(
                                  label: 'Following',
                                  value: '${_user!['followingCount']}',
                                ),
                                _ProfileStat(
                                  label: 'Posts',
                                  value: '${_posts.length}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            'Posts',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.grid_view_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_posts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: buildGlassCardDecoration(radius: 28),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 44,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _posts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemBuilder: (_, i) {
                            final p = _posts[i];
                            final firstImage = p.media
                                .where(
                                  (m) => !isVideoMediaUrl(m.url, mime: m.mime),
                                )
                                .toList();
                            final img = firstImage.isNotEmpty
                                ? firstImage.first.url
                                : null;
                            final isVideoPost =
                                p.media.isNotEmpty &&
                                p.media.every(
                                  (m) => isVideoMediaUrl(m.url, mime: m.mime),
                                );

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailPage(post: p),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: img == null
                                    ? Container(
                                        decoration: BoxDecoration(
                                          gradient: isVideoPost
                                              ? AppGradients.header
                                              : null,
                                          color: isVideoPost
                                              ? null
                                              : AppColors.chip,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isVideoPost
                                                ? Icons.videocam_rounded
                                                : Icons.text_fields_rounded,
                                            color: isVideoPost
                                                ? Colors.white
                                                : AppColors.muted,
                                          ),
                                        ),
                                      )
                                    : Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            resolveMediaUrl(img),
                                            fit: BoxFit.cover,
                                          ),
                                          if (isVideoPost)
                                            Container(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons
                                                      .play_circle_fill_rounded,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
