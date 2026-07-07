import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../users/ui/people_page.dart' show usersApiProvider;
import '../state/conversations_controller.dart';
// import '../data/chat_api.dart';
import 'chat_room_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../users/ui/widgets/profile_avatar.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Create group')),
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
                          Expanded(
                            child: Text(
                              'Create group',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          FilledButton(
                            onPressed: _creating ? null : _createGroup,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                            ),
                            child: _creating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Create'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build a polished group space with selected members and a custom title.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Group name',
                          prefixIcon: Icon(
                            Icons.group_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _q,
                              onSubmitted: (_) => _search(),
                              decoration: const InputDecoration(
                                hintText: 'Search users',
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
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                            ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Text(
                      'Selected ${_selectedIds.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _selectedIds.length < 2 ? 'Need 2+' : 'Ready to create',
                      style: TextStyle(
                        color: _selectedIds.length < 2
                            ? AppColors.muted
                            : AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _results.isEmpty
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
                                  Icons.group_work_rounded,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Search and pick members',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Selected people will appear here with a cleaner group-creation flow.',
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
                        itemCount: _results.length,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final u = _results[i];
                          final id = u['id'] as String;
                          final name =
                              (u['username'] as String?)?.isNotEmpty == true
                              ? u['username'] as String
                              : (u['email'] as String);
                          final avatarUrl =
                              (u['avatarUrl'] as String?) ??
                              (u['avatar_url'] as String?);

                          final selected = _selectedIds.contains(id);

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
                                Switch.adaptive(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v) {
                                        _selectedIds.add(id);
                                      } else {
                                        _selectedIds.remove(id);
                                      }
                                    });
                                  },
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
