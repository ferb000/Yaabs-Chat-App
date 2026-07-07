import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../users/data/users_api.dart';
import '../../users/ui/people_page.dart'
    show usersApiProvider; // reuse provider
// import '../data/chat_api.dart';
import '../state/conversations_controller.dart';
import 'chat_room_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../users/ui/widgets/profile_avatar.dart';

class StartChatPage extends ConsumerStatefulWidget {
  const StartChatPage({super.key});

  @override
  ConsumerState<StartChatPage> createState() => _StartChatPageState();
}

class _StartChatPageState extends ConsumerState<StartChatPage> {
  final _q = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final usersApi = ref.read(usersApiProvider);
      final raw = await usersApi.search(q);
      _items = raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
      setState(() {});
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _startDirect(Map<String, dynamic> user) async {
    try {
      final api = ref.read(chatApiProvider);
      final res = await api.createDirect(user['id'] as String);

      final convo = (res['conversation'] as Map).cast<String, dynamic>();
      final id = convo['id'] as String;

      await ref.read(conversationsControllerProvider.notifier).load();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              conversationId: id,
              title: user['username'] ?? user['email'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Start chat')),
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
                      const Text(
                        'Find someone quickly and open a clean direct conversation.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _q,
                              onSubmitted: (_) => _search(),
                              decoration: const InputDecoration(
                                hintText: 'Search users (email or username)',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _loading ? null : _search,
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Search'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: buildGlassCardDecoration(radius: 28),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.forum_rounded,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Search to start a direct chat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Results will appear here with a cleaner, WhatsApp-inspired layout.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _items.length,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final u = _items[i];
                          final name =
                              (u['username'] as String?)?.isNotEmpty == true
                              ? u['username'] as String
                              : (u['email'] as String);
                          final avatarUrl =
                              (u['avatarUrl'] as String?) ??
                              (u['avatar_url'] as String?);

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: buildGlassCardDecoration(radius: 28),
                            child: Row(
                              children: [
                                ProfileAvatar(
                                  name: name,
                                  avatarUrl: avatarUrl,
                                  size: 54,
                                  radius: 18,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        u['email'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  onPressed: () => _startDirect(u),
                                  child: const Text('Chat'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
