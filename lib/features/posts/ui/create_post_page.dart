import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/providers.dart';
import '../../media/data/media_api.dart';
// import '../data/posts_api.dart';
import '../state/feed_controller.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _caption = TextEditingController();
  final _picker = ImagePicker();

  bool _submitting = false;
  final List<XFile> _picked = [];

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _picked.addAll(files);
      if (_picked.length > 10) {
        _picked.removeRange(10, _picked.length);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final mediaApi = MediaApi(dio);
      final postsApi = ref.read(postsApiProvider);

      // 1) upload images
      final uploaded = <Map<String, dynamic>>[];
      for (final f in _picked) {
        final media = await mediaApi.uploadXFile(f);
        uploaded.add({'url': media['url'], 'mime': media['mime']});
      }

      // 2) create post
      await postsApi.createPost(
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
        media: uploaded,
      );

      // 3) refresh feed
      await ref.read(feedControllerProvider.notifier).load();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _caption,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Write something...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _pickImages,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add images'),
                ),
                const SizedBox(width: 12),
                Text('${_picked.length}/10'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: _picked.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final f = _picked[i];
                  return Stack(
                    children: [
                      FutureBuilder<Uint8List>(
                        future: f.readAsBytes(),
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(snap.data!, fit: BoxFit.cover),
                          );
                        },
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: _submitting
                              ? null
                              : () => setState(() => _picked.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
