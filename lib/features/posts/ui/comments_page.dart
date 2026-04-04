import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:full_node_chat_app/features/auth/state/auth_controller.dart';
import '../state/comments_controller.dart';

class CommentsPage extends ConsumerStatefulWidget {
  const CommentsPage({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsControllerProvider(widget.postId));
    final me = ref.watch(authControllerProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (state) {
                if (state.items.isEmpty) {
                  return const Center(child: Text('No comments yet'));
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
                      ref
                          .read(
                            commentsControllerProvider(widget.postId).notifier,
                          )
                          .load();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = state.items[i];
                      final author = c.author.username?.isNotEmpty == true
                          ? c.author.username!
                          : c.author.email;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Colors.grey.withOpacity(0.08),
                        title: Text(
                          author,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(c.text),
                        trailing: me?.id == c.author.id
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => ref
                                    .read(
                                      commentsControllerProvider(
                                        widget.postId,
                                      ).notifier,
                                    )
                                    .delete(c.id),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final v = _text.text.trim();
                      if (v.isEmpty) return;
                      await ref
                          .read(
                            commentsControllerProvider(widget.postId).notifier,
                          )
                          .create(v);
                      _text.clear();
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
