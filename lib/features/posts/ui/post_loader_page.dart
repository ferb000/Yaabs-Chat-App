import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:full_node_chat_app/features/posts/state/feed_controller.dart';
import '../data/models.dart';
import 'post_detail_page.dart';

class PostLoaderPage extends ConsumerStatefulWidget {
  const PostLoaderPage({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostLoaderPage> createState() => _PostLoaderPageState();
}

class _PostLoaderPageState extends ConsumerState<PostLoaderPage> {
  Post? _post;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(postsApiProvider).getPost(widget.postId);
      final json = (res['post'] as Map).cast<String, dynamic>();
      _post = Post.fromJson(json);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: Center(child: Text(_error ?? 'Post not found')),
      );
    }

    return PostDetailPage(post: _post!);
  }
}
