import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:full_node_chat_app/features/posts/state/feed_controller.dart';

class EditPostCaptionPage extends ConsumerStatefulWidget {
  const EditPostCaptionPage({
    super.key,
    required this.postId,
    required this.initialCaption,
  });

  final String postId;
  final String initialCaption;

  @override
  ConsumerState<EditPostCaptionPage> createState() =>
      _EditPostCaptionPageState();
}

class _EditPostCaptionPageState extends ConsumerState<EditPostCaptionPage> {
  late final TextEditingController _caption;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(text: widget.initialCaption);
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsApi = ref.read(postsApiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit caption'),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await postsApi.editPostCaption(
                        widget.postId,
                        _caption.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _caption,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit caption',
          ),
        ),
      ),
    );
  }
}
