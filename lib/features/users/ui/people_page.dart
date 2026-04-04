import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
// import 'package:dio/dio.dart';
import '../data/users_api.dart';

final usersApiProvider = Provider<UsersApi>(
  (ref) => UsersApi(ref.watch(dioProvider)),
);

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  final _q = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

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
      final api = ref.read(usersApiProvider);
      final raw = await api.search(q);
      setState(() {
        _items = raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.read(usersApiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("People")),
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
                      hintText: "Search by email/username",
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
                      : const Text("Search"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await api.follow(u['id'] as String);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Followed")),
                              );
                            }
                          },
                          child: const Text("Follow"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await api.unfollow(u['id'] as String);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Unfollowed")),
                              );
                            }
                          },
                          child: const Text("Unfollow"),
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
    );
  }
}
