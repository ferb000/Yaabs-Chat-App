import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../users/data/users_api.dart';
import '../../users/ui/people_page.dart'
    show usersApiProvider; // reuse provider
// import '../data/chat_api.dart';
import '../state/conversations_controller.dart';
import 'chat_room_page.dart';

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
      appBar: AppBar(title: const Text('Start chat')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    decoration: const InputDecoration(
                      hintText: 'Search users (email/username)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final u = _items[i];
                  final name = (u['username'] as String?)?.isNotEmpty == true
                      ? u['username'] as String
                      : (u['email'] as String);

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.grey.withOpacity(0.08),
                    title: Text(name),
                    subtitle: Text(u['email'] as String),
                    trailing: ElevatedButton(
                      onPressed: () => _startDirect(u),
                      child: const Text('Chat'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
