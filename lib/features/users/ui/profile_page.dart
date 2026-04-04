import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:full_node_chat_app/features/posts/state/feed_controller.dart';
import '../../../core/di/providers.dart';
import '../data/profile_api.dart';
import 'package:full_node_chat_app/features/auth/state/auth_controller.dart';
import '../../posts/data/models.dart';
import '../../posts/ui/post_detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('User not found'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    (_user!['username'] as String?)?.isNotEmpty == true
                        ? _user!['username'] as String
                        : _user!['email'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_user!['email'] as String),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Followers: ${_user!['followersCount']}'),
                      const SizedBox(width: 16),
                      Text('Following: ${_user!['followingCount']}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (me?.id != widget.userId)
                    ElevatedButton(
                      onPressed: _busy ? null : _toggleFollow,
                      child: Text(
                        (_user!['isFollowing'] as bool? ?? false)
                            ? 'Unfollow'
                            : 'Follow',
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Posts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_posts.isEmpty)
                    const Text('No posts yet')
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _posts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (_, i) {
                        final p = _posts[i];
                        final img = p.media.isNotEmpty
                            ? p.media.first.url
                            : null;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailPage(post: p),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: img == null
                                ? Container(
                                    color: Colors.grey.withOpacity(0.2),
                                    child: const Center(
                                      child: Icon(Icons.text_fields),
                                    ),
                                  )
                                : Image.network(img, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
