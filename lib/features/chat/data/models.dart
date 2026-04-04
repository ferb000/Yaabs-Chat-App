class Conversation {
  final String id;
  final String type; // direct/group
  final String? title;

  Conversation({required this.id, required this.type, this.title});

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String?,
  );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String type; // text/image/audio
  final String? text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId:
        json['conversation_id'] as String? ?? json['conversationId'] as String,
    senderId: json['sender_id'] as String? ?? json['senderId'] as String,
    type: json['type'] as String,
    text: json['text'] as String?,
    createdAt: DateTime.parse(
      json['created_at'] as String? ?? json['createdAt'] as String,
    ),
  );
}

class MessageMedia {
  final String url;
  final String mime;
  final int sizeBytes;
  final String mediaType; // image/audio
  final int? durationMs;

  MessageMedia({
    required this.url,
    required this.mime,
    required this.sizeBytes,
    required this.mediaType,
    this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'mime': mime,
    'sizeBytes': sizeBytes,
    'mediaType': mediaType,
    if (durationMs != null) 'durationMs': durationMs,
  };
}

class ConversationMember {
  final String userId;
  final String role;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String? lastReadMessageId;

  ConversationMember({
    required this.userId,
    required this.role,
    required this.email,
    this.username,
    this.avatarUrl,
    this.lastReadMessageId,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) =>
      ConversationMember(
        userId: json['user_id'] as String? ?? json['userId'] as String,
        role: json['role'] as String? ?? 'member',
        email: json['email'] as String,
        username: json['username'] as String?,
        avatarUrl:
            json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
        lastReadMessageId: json['last_read_message_id'] as String?,
      );

  String get displayName =>
      (username != null && username!.trim().isNotEmpty) ? username! : email;
}
