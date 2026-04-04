// import 'dart:io';s
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_room_controller.dart';
import '../../media/data/media_api.dart';
import '../../../core/di/providers.dart';
import '../data/models.dart';

import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'widgets/audio_bubble.dart';

import '../../presence/state/presence_controller.dart';
import '../../auth/state/auth_controller.dart';

import 'package:flutter/foundation.dart'; // kIsWeb
import 'dart:typed_data';

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

  bool _recording = false;

  XFile? _pendingImage;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _text.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = ref.read(
        chatRoomControllerProvider(widget.conversationId).notifier,
      );
      final other = c.otherUserId;
      if (other != null) {
        ref.read(presenceControllerProvider.notifier).fetchPresence(other);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomControllerProvider(widget.conversationId));
    final controller = ref.read(
      chatRoomControllerProvider(widget.conversationId).notifier,
    );
    final presenceMap = ref.watch(presenceControllerProvider);
    final otherId = controller.otherUserId;

    final presence = (otherId != null) ? presenceMap[otherId] : null;
    final statusText = () {
      if (otherId == null) return widget.title; // group
      if (presence?.isOnline == true) return 'Online';
      final seen = presence?.lastSeenAt;
      if (seen == null) return 'Last seen: unknown';
      return 'Last seen: ${_fmtTime(seen)}';
    }();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(statusText, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
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
                padding: const EdgeInsets.all(12),
                itemCount: state.messages.length,
                itemBuilder: (context, i) {
                  final m = state.messages[i];

                  final myId = ref.watch(authControllerProvider).user?.id;
                  final isMine = myId != null && m.senderId == myId;
                  final isLast = i == state.messages.length - 1;

                  final controller = ref.read(
                    chatRoomControllerProvider(widget.conversationId).notifier,
                  );

                  // ---------- Read / Seen Status ----------
                  Widget? status;

                  if (isLast && isMine) {
                    // Direct chat
                    if (controller.otherUserId != null) {
                      final other = controller.otherUserId!;
                      final seen = controller.isReadBy(other, m.id);

                      status = Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          seen ? 'Seen' : 'Delivered',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }
                    // Group chat
                    else if (state.members.length > 2) {
                      final count = controller.readByCount(m.id);

                      status = Padding(
                        padding: const EdgeInsets.only(top: 2),
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

                  // ---------- Message Bubble ----------
                  // final bubble = Container(
                  //   margin: const EdgeInsets.only(bottom: 4),
                  //   padding: const EdgeInsets.all(10),
                  //   decoration: BoxDecoration(
                  //     color: isMine
                  //         ? Colors.blue.withOpacity(0.15)
                  //         : Colors.grey.withOpacity(0.12),
                  //     borderRadius: BorderRadius.circular(14),
                  //   ),
                  //   child: _messageBody(m, state)
                  // );
                  final bubble = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _messageBody(m, state, isMine),
                    ),
                  );

                  return Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [bubble, if (status != null) status],
                    ),
                  );
                },
              ),
            ),
          ),
          if (state.typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Typing...',
                  style: TextStyle(color: Colors.grey.shade600),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _uploadingImage ? null : _pickImageForPreview,
                  ),
                  IconButton(
                    icon: Icon(
                      _recording
                          ? Icons.stop_circle_outlined
                          : Icons.mic_none_outlined,
                    ),
                    onPressed: () => _toggleRecord(controller),
                    // onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      onChanged: controller.onTextChanged,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final v = _text.text.trim();
                      if (v.isEmpty) return;
                      await controller.sendText(v);
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

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
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
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 220,
            height: 220,
            child: Center(child: Text('Image failed')),
          ),
        ),
      );
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

  Future<void> _sendImage(ChatRoomController controller) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dio = ref.read(dioProvider);
    final api = MediaApi(dio);

    final media = await api.uploadXFile(picked);

    await controller.sendMedia(
      MessageMedia(
        url: media['url'] as String,
        mime: media['mime'] as String,
        sizeBytes: (media['sizeBytes'] as num).toInt(),
        mediaType: 'image',
      ),
    );
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
          color: Colors.grey.withOpacity(0.08),
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
