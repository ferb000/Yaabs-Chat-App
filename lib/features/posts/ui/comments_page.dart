import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:full_node_chat_app/features/auth/state/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../reactions/ui/reaction_widgets.dart';
import '../state/comments_controller.dart';

class CommentsPage extends ConsumerStatefulWidget {
  const CommentsPage({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  final _text = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _text.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNewest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsControllerProvider(widget.postId));
    final commentsState = commentsAsync.valueOrNull;
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
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = state.items[i];
                      final author = c.author.username?.isNotEmpty == true
                          ? c.author.username!
                          : c.author.email;

                      final isSending = c.id.startsWith('tmp-');

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: AppColors.surface.withValues(alpha: 0.82),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isSending)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Sending...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.text),
                              ReactionStrip(
                                summary: c.reactionSummary,
                                myReaction: c.myReaction,
                              ),
                              const SizedBox(height: 6),
                              ReactionActionButton(
                                myReaction: c.myReaction,
                                onTap: isSending
                                    ? () {}
                                    : () async {
                                        final reaction =
                                            await showReactionPicker(
                                              context,
                                              selectedReaction: c.myReaction,
                                            );
                                        if (reaction == null) return;
                                        await ref
                                            .read(
                                              commentsControllerProvider(
                                                widget.postId,
                                              ).notifier,
                                            )
                                            .toggleReaction(c, reaction);
                                      },
                              ),
                            ],
                          ),
                        ),
                        trailing: me?.id == c.author.id && !isSending
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
                    onPressed: commentsState?.isCreating == true
                        ? null
                        : () async {
                            final v = _text.text.trim();
                            if (v.isEmpty) return;
                            try {
                              await ref
                                  .read(
                                    commentsControllerProvider(
                                      widget.postId,
                                    ).notifier,
                                  )
                                  .create(v);
                              _text.clear();
                              if (context.mounted) {
                                FocusScope.of(context).unfocus();
                              }
                              _scrollToNewest();
                            } catch (_) {}
                          },
                    child: commentsState?.isCreating == true
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send'),
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
