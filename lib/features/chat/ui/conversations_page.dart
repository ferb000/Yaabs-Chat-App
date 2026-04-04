import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/conversations_controller.dart';
import 'chat_room_page.dart';
import 'start_chat_page.dart';
import 'create_group_page.dart';

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
      appBar: AppBar(
        title: const Text('Chats'),

        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StartChatPage()),
            ),
            icon: const Icon(Icons.chat_outlined),
          ),
          IconButton(
            tooltip: 'New group',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupPage()),
            ),
            icon: const Icon(Icons.group_add_outlined),
          ),
        ],
      ),
      body: convosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No conversations'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = items[i];
              final title = (c.type == 'group')
                  ? (c.title ?? 'Group')
                  : 'Direct chat';

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.grey.withOpacity(0.08),
                title: Text(title),
                subtitle: Text(c.type),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatRoomPage(conversationId: c.id, title: title),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
