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
  final List<XFile> _pickedImages = [];
  XFile? _pickedVideo;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_pickedVideo != null) {
      setState(() => _pickedVideo = null);
    }
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _pickedImages.addAll(files);
      if (_pickedImages.length > 10) {
        _pickedImages.removeRange(10, _pickedImages.length);
      }
    });
  }

  Future<void> _pickVideo() async {
    if (_pickedImages.isNotEmpty) {
      setState(() => _pickedImages.clear());
    }
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final size = await file.length();
    if (size > 4 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video must be 4MB or smaller')),
      );
      return;
    }

    setState(() {
      _pickedVideo = file;
    });
  }

  Future<void> _openMediaPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Add images'),
                  subtitle: const Text('Up to 10 images'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Add video'),
                  subtitle: const Text('One video, max 4MB'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final mediaApi = MediaApi(dio);
      final postsApi = ref.read(postsApiProvider);

      final hasVideo = _pickedVideo != null;
      final mediaFiles = hasVideo ? <XFile>[_pickedVideo!] : _pickedImages;

      // 1) upload images/video
      final uploaded = <Map<String, dynamic>>[];
      for (final f in mediaFiles) {
        final media = await mediaApi.uploadXFile(f);
        final item = <String, dynamic>{
          'url': media['url'],
          'mime': media['mime'],
          'sizeBytes': media['sizeBytes'],
        };
        if (media['width'] != null) item['width'] = media['width'];
        if (media['height'] != null) item['height'] = media['height'];
        if (media['durationMs'] != null) {
          item['durationMs'] = media['durationMs'];
        }
        uploaded.add(item);
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
                  onPressed: _submitting ? null : _openMediaPicker,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add media'),
                ),
                const SizedBox(width: 12),
                Text(
                  _pickedVideo != null
                      ? '1 video'
                      : '${_pickedImages.length}/10 images',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _pickedVideo != null
                  ? _VideoPreviewTile(
                      file: _pickedVideo!,
                      onRemove: _submitting
                          ? null
                          : () => setState(() => _pickedVideo = null),
                    )
                  : GridView.builder(
                      itemCount: _pickedImages.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemBuilder: (_, i) {
                        final f = _pickedImages[i];
                        return Stack(
                          children: [
                            FutureBuilder<Uint8List>(
                              future: f.readAsBytes(),
                              builder: (_, snap) {
                                if (!snap.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    snap.data!,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: _submitting
                                    ? null
                                    : () => setState(
                                        () => _pickedImages.removeAt(i),
                                      ),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
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

class _VideoPreviewTile extends StatelessWidget {
  const _VideoPreviewTile({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.videocam_rounded,
              size: 88,
              color: Colors.white70,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
