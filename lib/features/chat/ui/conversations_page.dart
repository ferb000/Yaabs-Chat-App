import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/conversations_controller.dart';
import 'chat_room_page.dart';
import 'start_chat_page.dart';
import 'create_group_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../users/ui/widgets/profile_avatar.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(conversationsControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final convosAsync = ref.watch(conversationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StartChatPage()),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          IconButton(
            tooltip: 'New group',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupPage()),
            ),
            icon: const Icon(Icons.group_add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          top: false,
          child: convosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(conversationsControllerProvider.notifier).load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(18),
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
                                Icons.forum_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No conversations yet',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Start a direct chat or create a group to begin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StartChatPage(),
                                ),
                              ),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('Start chatting'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(conversationsControllerProvider.notifier).load(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    final title = c.resolvedTitle;
                    final subtitle =
                        c.displaySubtitle ??
                        (c.type == 'group'
                            ? 'Group conversation'
                            : 'Direct message');
                    final avatarUrl = c.type == 'group' ? null : c.avatarUrl;
                    final displayAvatarName = c.type == 'group'
                        ? (c.title ?? 'Group')
                        : c.resolvedTitle;

                    return InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatRoomPage(conversationId: c.id, title: title),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: buildGlassCardDecoration(radius: 28),
                        child: Row(
                          children: [
                            ProfileAvatar(
                              name: displayAvatarName,
                              avatarUrl: avatarUrl,
                              size: 54,
                              radius: 18,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StartChatPage()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.chat_rounded),
        label: const Text('New chat'),
      ),
    );
  }
}
