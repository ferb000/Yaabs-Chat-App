import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../users/ui/people_page.dart' show usersApiProvider;
import '../state/conversations_controller.dart';
// import '../data/chat_api.dart';
import 'chat_room_page.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final _q = TextEditingController();
  final _title = TextEditingController();

  bool _loading = false;
  bool _creating = false;

  List<Map<String, dynamic>> _results = [];
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _q.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final usersApi = ref.read(usersApiProvider);
      final raw = await usersApi.search(q);
      _results = raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
      setState(() {});
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createGroup() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group name required')));
      return;
    }
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick at least 2 members')));
      return;
    }

    setState(() => _creating = true);
    try {
      final api = ref.read(chatApiProvider);
      final res = await api.createGroup(
        title: title,
        memberIds: _selectedIds.toList(),
      );

      final convo = (res['conversation'] as Map).cast<String, dynamic>();
      final id = convo['id'] as String;

      await ref.read(conversationsControllerProvider.notifier).load();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(conversationId: id, title: title),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create group'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _createGroup,
            child: _creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Group name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    decoration: const InputDecoration(
                      hintText: 'Search users',
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Selected: ${_selectedIds.length}'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final u = _results[i];
                  final id = u['id'] as String;
                  final name = (u['username'] as String?)?.isNotEmpty == true
                      ? u['username'] as String
                      : (u['email'] as String);

                  final selected = _selectedIds.contains(id);

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.grey.withOpacity(0.08),
                    title: Text(name),
                    subtitle: Text(u['email'] as String),
                    trailing: Checkbox(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedIds.add(id);
                          } else {
                            _selectedIds.remove(id);
                          }
                        });
                      },
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
