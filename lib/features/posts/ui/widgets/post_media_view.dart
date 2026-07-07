import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:full_node_chat_app/core/theme/app_theme.dart';
import 'package:full_node_chat_app/features/posts/data/models.dart';
import 'package:full_node_chat_app/features/posts/utils/media_url.dart';

class PostMediaView extends StatelessWidget {
  const PostMediaView({
    super.key,
    required this.media,
    this.compact = false,
    this.onTap,
  });

  final PostMedia media;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isVideo = isVideoMediaUrl(media.url, mime: media.mime);
    final resolvedUrl = resolveMediaUrl(media.url);

    if (isVideo) {
      if (compact) {
        return _CompactVideoPreview(url: resolvedUrl);
      }

      return _VideoPlayerCard(url: resolvedUrl);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 24 : 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 24 : 20),
        child: Image.network(
          resolvedUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.chip,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerCard extends StatefulWidget {
  const _VideoPlayerCard({required this.url});

  final String url;

  @override
  State<_VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<_VideoPlayerCard> {
  late final VideoPlayerController _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initFuture = _controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 320,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_controller.value.hasError) {
          return Container(
            height: 320,
            color: AppColors.chip,
            child: const Center(child: Text('Video failed to load')),
          );
        }

        return AspectRatio(
          aspectRatio: _controller.value.aspectRatio == 0
              ? 16 / 9
              : _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final playing = _controller.value.isPlaying;
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          FloatingActionButton.small(
                            heroTag: UniqueKey(),
                            onPressed: () {
                              setState(() {
                                playing
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                            backgroundColor: Colors.black54,
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                          const Spacer(),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'Video',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactVideoPreview extends StatefulWidget {
  const _CompactVideoPreview({required this.url});

  final String url;

  @override
  State<_CompactVideoPreview> createState() => _CompactVideoPreviewState();
}

class _CompactVideoPreviewState extends State<_CompactVideoPreview> {
  late final VideoPlayerController _controller;
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F2EE), Color(0xFFD9EEE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width == 0
                      ? 16
                      : _controller.value.size.width,
                  height: _controller.value.size.height == 0
                      ? 9
                      : _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
