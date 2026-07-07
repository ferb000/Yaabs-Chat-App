import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_room_controller.dart';
import '../../media/data/media_api.dart';
import '../../../core/di/providers.dart';
import '../data/models.dart';
import '../../posts/utils/media_url.dart';

import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/audio_bubble.dart';

import '../../auth/state/auth_controller.dart';
import '../../presence/state/presence_controller.dart';
import '../../users/ui/widgets/profile_avatar.dart';

import 'package:flutter/foundation.dart'; // kIsWeb
import '../../../core/theme/app_theme.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final _scrollController = ScrollController();

  bool _recording = false;
  bool _initialJumpDone = false;

  XFile? _pendingImage;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _text.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (jump) {
      _scrollController.jumpTo(target);
    } else {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomControllerProvider(widget.conversationId));
    final controller = ref.read(
      chatRoomControllerProvider(widget.conversationId).notifier,
    );
    final presenceMap = ref.watch(presenceControllerProvider);
    final otherId = controller.otherUserId;
    ConversationMember? otherMember;
    if (otherId != null) {
      for (final member in state.members) {
        if (member.userId == otherId) {
          otherMember = member;
          break;
        }
      }
    }

    final presence = (otherId != null) ? presenceMap[otherId] : null;
    final statusText = () {
      if (otherId == null) return widget.title; // group
      if (presence?.isOnline == true) return 'Online';
      final seen = presence?.lastSeenAt;
      if (seen == null) return 'Last seen recently';
      return 'Last seen: ${_fmtTime(seen)}';
    }();

    if (state.messages.isNotEmpty && !_initialJumpDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _initialJumpDone) return;
        _initialJumpDone = true;
        _scrollToBottom(jump: true);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(
              name: widget.title,
              avatarUrl: otherMember?.avatarUrl,
              size: 40,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_rounded)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels < 120) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                    itemCount:
                        state.messages.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (state.isLoadingMore && i == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final messageIndex = i - (state.isLoadingMore ? 1 : 0);
                      final m = state.messages[messageIndex];

                      final myId = ref.watch(authControllerProvider).user?.id;
                      final isMine = myId != null && m.senderId == myId;
                      final isLast = messageIndex == state.messages.length - 1;

                      final controller = ref.read(
                        chatRoomControllerProvider(
                          widget.conversationId,
                        ).notifier,
                      );

                      Widget? status;

                      if (isLast && isMine) {
                        if (controller.otherUserId != null) {
                          final other = controller.otherUserId!;
                          final seen = controller.isReadBy(other, m.id);

                          status = Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              seen ? 'Seen' : 'Delivered',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        } else if (state.members.length > 2) {
                          final count = controller.readByCount(m.id);

                          status = Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              count == 0 ? 'Delivered' : 'Read by $count',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                      }

                      final bubble = ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMine
                                ? AppColors.outgoing
                                : AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(22),
                              topRight: const Radius.circular(22),
                              bottomLeft: Radius.circular(isMine ? 22 : 6),
                              bottomRight: Radius.circular(isMine ? 6 : 22),
                            ),
                            boxShadow: isMine ? null : AppShadows.soft,
                            border: Border.all(
                              color: isMine
                                  ? Colors.transparent
                                  : AppColors.border,
                            ),
                          ),
                          child: _messageBody(m, state, isMine),
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              bubble,
                              status ?? const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (state.typingUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Typing...',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                ),
              if (_pendingImage != null)
                _ImagePreviewBar(
                  file: _pendingImage!,
                  uploading: _uploadingImage,
                  onCancel: () => setState(() => _pendingImage = null),
                  onSend: () => _sendPendingImage(controller),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        _ComposerIcon(
                          icon: Icons.image_outlined,
                          onPressed: _uploadingImage
                              ? null
                              : _pickImageForPreview,
                        ),
                        _ComposerIcon(
                          icon: _recording
                              ? Icons.stop_circle_outlined
                              : Icons.mic_none_outlined,
                          onPressed: () => _toggleRecord(controller),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _text,
                            onChanged: controller.onTextChanged,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Message',
                              filled: true,
                              fillColor: AppColors.bg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final v = _text.text.trim();
                            if (v.isEmpty) return;
                            await controller.sendText(v);
                            _text.clear();
                            _scrollToBottom();
                          },
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(14),
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Icon(Icons.send_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _renderMessage(ChatMessage m) {
    if (m.type == 'text') return m.text ?? '';
    if (m.type == 'image') return '[Image message]';
    if (m.type == 'audio') return '[Voice note]';
    return '[Unknown]';
    // Later: render real image/audio UI by fetching message media details if you include it in payload
  }

  Widget _messageBody(ChatMessage m, ChatRoomState state, bool isMine) {
    if (m.type == 'image') {
      final media = state.mediaByMessageId[m.id];
      final url = media?.url;
      if (url == null) return const Text('[Image]');

      return _ChatMediaImage(url: url);
    }

    if (m.type == 'audio') {
      final media = state.mediaByMessageId[m.id];
      final url = media?.url;
      if (url == null) return const Text('[Voice note]');
      return AudioBubble(
        url: url,
        isMine: isMine, // we will pass correct isMine below (see note)
        durationMs: media?.durationMs,
      );
    }

    // text
    return Text(_renderMessage(m));
  }

  Future<void> _toggleRecord(ChatRoomController controller) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voice note recording is not implemented for web yet. Use mobile for now.',
          ),
        ),
      );
      return;
    }
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);

      if (path == null) return;

      final dio = ref.read(dioProvider);
      final api = MediaApi(dio);
      final media = await api.uploadXFile(XFile(path));

      await controller.sendMedia(
        MessageMedia(
          url: media['url'] as String,
          mime: media['mime'] as String,
          sizeBytes: (media['sizeBytes'] as num).toInt(),
          mediaType: 'audio',
        ),
      );
      _scrollToBottom();
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

    final canRecord = await _recorder.hasPermission();
    if (!canRecord) return;

    await _recorder.start(const RecordConfig(), path: filePath);
    setState(() => _recording = true);
  }

  String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $h:$m';
  }

  Future<void> _pickImageForPreview() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _pendingImage = picked;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _sendPendingImage(ChatRoomController controller) async {
    final img = _pendingImage;
    if (img == null) return;

    setState(() => _uploadingImage = true);

    try {
      final dio = ref.read(dioProvider);
      final api = MediaApi(dio);

      final media = await api.uploadXFile(img);

      await controller.sendMedia(
        MessageMedia(
          url: media['url'] as String,
          mime: media['mime'] as String,
          sizeBytes: (media['sizeBytes'] as num).toInt(),
          mediaType: 'image',
        ),
      );
      _scrollToBottom();

      if (mounted) {
        setState(() {
          _pendingImage = null;
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
    }
  }
}

class _ComposerIcon extends StatelessWidget {
  const _ComposerIcon({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.chip,
        foregroundColor: AppColors.primaryDark,
      ),
      icon: Icon(icon),
    );
  }
}

class _ChatMediaImage extends StatefulWidget {
  const _ChatMediaImage({required this.url});

  final String url;

  @override
  State<_ChatMediaImage> createState() => _ChatMediaImageState();
}

class _ChatMediaImageState extends State<_ChatMediaImage> {
  int _retryToken = 0;

  void _retry() => setState(() => _retryToken++);

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveMediaUrl(widget.url);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(
            resolvedUrl,
            key: ValueKey('${resolvedUrl}_$_retryToken'),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: 220,
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes == null
                        ? null
                        : progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                width: 220,
                height: 220,
                child: Container(
                  color: AppColors.chip,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 34),
                      const SizedBox(height: 10),
                      const Text('Image failed', textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
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
  }
}

class _ImagePreviewBar extends StatelessWidget {
  const _ImagePreviewBar({
    required this.file,
    required this.uploading,
    required this.onCancel,
    required this.onSend,
  });

  final XFile file;
  final bool uploading;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FutureBuilder<Uint8List>(
                future: file.readAsBytes(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(
                      width: 56,
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Image.memory(
                    snap.data!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                uploading ? "Uploading..." : "Ready to send",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            IconButton(
              onPressed: uploading ? null : onCancel,
              icon: const Icon(Icons.close),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: uploading ? null : onSend,
              child: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}
