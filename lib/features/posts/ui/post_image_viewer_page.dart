import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../utils/media_url.dart';

class PostImageViewerPage extends StatefulWidget {
  const PostImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<PostImageViewerPage> createState() => _PostImageViewerPageState();
}

class _PostImageViewerPageState extends State<PostImageViewerPage> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1}/${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final url = widget.images[i];
          if (isVideoMediaUrl(url)) {
            return const Center(
              child: Text(
                'This media is a video and cannot be opened in the image viewer.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          }

          return PhotoView(
            imageProvider: NetworkImage(resolveMediaUrl(url)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          );
        },
      ),
    );
  }
}
