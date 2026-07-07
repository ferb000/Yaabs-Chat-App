import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_controller.dart';
import '../../posts/state/feed_controller.dart';
import 'profile_page.dart';
import '../data/users_api.dart';
import 'widgets/profile_avatar.dart';

final usersApiProvider = Provider<UsersApi>(
  (ref) => UsersApi(ref.watch(dioProvider)),
);

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );
  final _q = TextEditingController();
  final Set<String> _busyIds = {};

  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDirectory);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _q.dispose();
    super.dispose();
  }

  String _displayName(Map<String, dynamic> u) {
    final username = (u['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    return (u['email'] as String?) ?? 'Unknown user';
  }

  Map<String, dynamic> _normalize(dynamic value) {
    return (value as Map).cast<String, dynamic>();
  }

  List<Map<String, dynamic>> _suggestedUsers(
    FeedState? feedState,
    String meId,
  ) {
    final seen = <String>{};
    final followingIds = _following.map((e) => e['id'] as String).toSet();
    final followerIds = _followers.map((e) => e['id'] as String).toSet();

    final suggested = <Map<String, dynamic>>[];
    for (final post in feedState?.items ?? const <dynamic>[]) {
      final author = post.author;
      final id = author.id as String;
      if (id == meId || followingIds.contains(id) || followerIds.contains(id)) {
        continue;
      }
      if (!seen.add(id)) continue;

      suggested.add({
        'id': id,
        'email': author.email,
        'username': author.username,
        'avatarUrl': author.avatarUrl,
      });
    }
    return suggested;
  }

  Future<void> _loadDirectory({String? query}) async {
    final me = ref.read(authControllerProvider).user;
    if (me == null) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(usersApiProvider);
      final results = await Future.wait([
        api.followers(me.id, q: query),
        api.following(me.id, q: query),
      ]);

      if (!mounted) return;
      setState(() {
        _followers = results[0].map(_normalize).toList();
        _following = results[1].map(_normalize).toList();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    await _loadDirectory(query: _q.text.trim().isEmpty ? null : _q.text.trim());
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final me = ref.read(authControllerProvider).user;
    if (me == null) return;

    final id = user['id'] as String;
    if (_busyIds.contains(id)) return;

    final isFollowing = user['isFollowing'] as bool? ?? false;
    setState(() => _busyIds.add(id));

    try {
      final api = ref.read(usersApiProvider);
      if (isFollowing) {
        await api.unfollow(id);
      } else {
        await api.follow(id);
      }

      if (!mounted) return;
      await _loadDirectory(
        query: _q.text.trim().isEmpty ? null : _q.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider.select((s) => s.user));
    final feedState = ref.watch(feedControllerProvider).value;

    final q = _q.text.trim().toLowerCase();
    final followers = _followers.where((u) {
      if (q.isEmpty) return true;
      return _displayName(u).toLowerCase().contains(q) ||
          ((u['email'] as String?) ?? '').toLowerCase().contains(q);
    }).toList();

    final following = _following.where((u) {
      if (q.isEmpty) return true;
      return _displayName(u).toLowerCase().contains(q) ||
          ((u['email'] as String?) ?? '').toLowerCase().contains(q);
    }).toList();

    final suggested = _suggestedUsers(feedState, me?.id ?? '').where((u) {
      if (q.isEmpty) return true;
      return _displayName(u).toLowerCase().contains(q) ||
          ((u['email'] as String?) ?? '').toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('People'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Followers (${followers.length})'),
            Tab(text: 'Following (${following.length})'),
            Tab(text: 'Suggested (${suggested.length})'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _q.clear();
              _loadDirectory();
              setState(() {});
            },
            icon: const Icon(Icons.clear_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: buildGlassCardDecoration(radius: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppGradients.header,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Discover your network',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Check who follows you, who you follow, and suggested people from your recent feed.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _q,
                        onSubmitted: (_) => _search(),
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search these tabs',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _q.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _q.clear();
                                    setState(() {});
                                    _loadDirectory();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _search,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.manage_search_rounded),
                              label: const Text('Search'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              _q.clear();
                              _loadDirectory();
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PeopleList(
                      emptyTitle: 'No followers yet',
                      emptySubtitle:
                          'When people follow you, they will show up here.',
                      loading: _loading,
                      people: followers,
                      meId: me?.id,
                      busyIds: _busyIds,
                      onOpenProfile: _openProfile,
                      onToggleFollow: _toggleFollow,
                    ),
                    _PeopleList(
                      emptyTitle: 'You are not following anyone yet',
                      emptySubtitle:
                          'Follow people from search or suggested users to build your feed.',
                      loading: _loading,
                      people: following,
                      meId: me?.id,
                      busyIds: _busyIds,
                      onOpenProfile: _openProfile,
                      onToggleFollow: _toggleFollow,
                    ),
                    _PeopleList(
                      emptyTitle: 'Nothing to suggest right now',
                      emptySubtitle:
                          'Once your feed has active posters, you’ll see suggested people here.',
                      loading: _loading,
                      people: suggested,
                      meId: me?.id,
                      busyIds: _busyIds,
                      onOpenProfile: _openProfile,
                      onToggleFollow: _toggleFollow,
                      suggested: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.loading,
    required this.people,
    required this.meId,
    required this.busyIds,
    required this.onOpenProfile,
    required this.onToggleFollow,
    this.suggested = false,
  });

  final String emptyTitle;
  final String emptySubtitle;
  final bool loading;
  final List<Map<String, dynamic>> people;
  final String? meId;
  final Set<String> busyIds;
  final void Function(String userId) onOpenProfile;
  final Future<void> Function(Map<String, dynamic> user) onToggleFollow;
  final bool suggested;

  String _displayName(Map<String, dynamic> u) {
    final username = (u['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    return (u['email'] as String?) ?? 'Unknown user';
  }

  String? _avatarUrl(Map<String, dynamic> u) {
    final raw = u['avatarUrl'] ?? u['avatar_url'];
    final avatar = raw is String ? raw.trim() : '';
    return avatar.isEmpty ? null : avatar;
  }

  @override
  Widget build(BuildContext context) {
    if (loading && people.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (people.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: buildGlassCardDecoration(radius: 28),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: AppGradients.header,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      itemCount: people.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = people[index];
        final id = u['id'] as String;
        final name = _displayName(u);
        final email = (u['email'] as String?) ?? '';
        final isFollowing = u['isFollowing'] as bool? ?? false;
        final isMe = meId == id;

        return InkWell(
          onTap: () => onOpenProfile(id),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: buildGlassCardDecoration(radius: 28),
            child: Row(
              children: [
                ProfileAvatar(
                  name: name,
                  avatarUrl: _avatarUrl(u),
                  size: 58,
                  radius: 18,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFollowing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.outgoing,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Following',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      if (suggested) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Suggested from recent posters',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!isMe)
                  FilledButton.tonalIcon(
                    onPressed: busyIds.contains(id)
                        ? null
                        : () => onToggleFollow(u),
                    icon: busyIds.contains(id)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isFollowing
                                ? Icons.check_rounded
                                : Icons.person_add_alt_1_rounded,
                          ),
                    label: Text(isFollowing ? 'Following' : 'Follow'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
